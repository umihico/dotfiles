#!/usr/bin/env python3
"""
.repeat_tmux_codex.py - Codex自動実行・監視スクリプト

【概要】
tmuxセッション内でcodexコマンドを自動実行し、画面の変化を監視します。
画面に変化がない場合は自動的にセッションを再起動し、長時間の自動実行を実現します。

【使い方】
    # 基本的な使い方
    python ~/.repeat_tmux_codex.py <セッション名> <命令ファイルパス>

    # または、シェル関数経由（推奨）
    codexr <セッション名> <命令ファイルパス>

【例】
    # test-sessionという名前のtmuxセッションで、command.txtの内容をcodexに実行させる
    codexr test-session ~/command.txt

    # 実行後、別ターミナルから以下で監視状況を確認可能
    tmux attach -t test-session

【動作】
1. 指定されたtmuxセッションが存在する場合は一旦終了
2. 新しいtmuxセッションを起動し、codexコマンドで指定ファイルの内容を実行
3. 3-5秒間隔でtmux画面の内容をキャプチャし、前回との差分を検出
4. 5回連続で変化がない場合、自動的にセッションを再起動
5. 最大60000秒（約16.7時間）まで実行

【ユースケース】
- CI/CD環境でcodexによるコード生成・修正を自動化
- 長時間かかるリファクタリング作業をバックグラウンドで実行
- 定期的な自動コードレビュー・修正

【備考】
- このスクリプトは.repeat_tmux.pyのcodexバージョンです
- claudeコマンドの代わりにcodexコマンドを使用します
- 元のclaudeバージョンは: ~/.repeat_tmux.py
"""

import subprocess
import time
import os
import tempfile
import difflib
import argparse
import random


def kill_tmux_session(session_name):
    """
    指定されたtmuxセッションをkillする

    Args:
        session_name (str): 終了させるtmuxセッションの名前

    動作:
        - セッションが存在するか確認
        - 存在する場合のみkillコマンドを実行
        - 存在しない場合は警告メッセージを表示
    """
    try:
        # 指定されたセッションが存在するかチェック
        result = subprocess.run(["tmux", "has-session", "-t", session_name],
                                capture_output=True, text=True)
        if result.returncode == 0:
            # セッションが存在する場合のみkill
            subprocess.run(["tmux", "kill-session", "-t",
                           session_name], check=True)
            print(f"tmuxセッション '{session_name}' をkillしました")
        else:
            print(f"tmuxセッション '{session_name}' は存在しません")
    except subprocess.CalledProcessError as e:
        print(f"tmuxセッション '{session_name}' のkill中にエラーが発生しました: {e}")
    except Exception as e:
        print(f"予期しないエラーが発生しました: {e}")


def start_new_tmux_session(session_name, command_file_path):
    """
    新しいtmuxセッションを起動し、指定されたファイルの内容をcodexコマンドで実行する

    Args:
        session_name (str): 作成するtmuxセッションの名前
        command_file_path (str): codexコマンドに渡す命令が書かれたファイルのパス

    動作:
        - command_file_pathを読み込んで指示を実行するようcodexに依頼
        - tmuxセッションをデタッチモード(-d)で起動
        - codexコマンドに--dangerously-skip-permissionsオプションを付与
        - 起動後10秒待機（起動時間確保と誤検知防止）

    注意:
        - command_file_pathはcodexがアクセス可能な場所に配置してください
        - --dangerously-skip-permissionsは権限確認をスキップします（自動化用）
    """
    try:
        # ファイルの内容を読み込み
        message = f"{command_file_path}を読み込んで、指示を実行してください。"

        # 新しいtmuxセッションを起動し、codexコマンドを実行
        # 注: claudeコマンドの代わりにcodexコマンドを使用
        codex_command = f'codex --dangerously-skip-permissions "{message}"'
        subprocess.run(["tmux", "new-session", "-d", "-s", session_name,
                       codex_command], check=True)
        time.sleep(10)  # 起動に時間もかかり差分なしの判定防止
        print(
            f"新しいtmuxセッション '{session_name}' を起動し、codexコマンドを実行しました: {codex_command}")
    except FileNotFoundError:
        print(f"ファイル '{command_file_path}' が見つかりません")
        raise
    except Exception as e:
        print(f"tmuxセッション '{session_name}' の起動中にエラーが発生しました: {e}")
        raise


def capture_tmux_pane(session_name):
    """
    指定されたtmuxセッションのペインの内容をキャプチャして返す

    Args:
        session_name (str): キャプチャするtmuxセッションの名前

    Returns:
        str: キャプチャしたペインの内容（テキスト形式）
             エラー時はNone

    動作:
        - tmux capture-pane -pコマンドで画面の内容を取得
        - ウィンドウ0のペイン0を対象（:0.0）
    """
    try:
        result = subprocess.run(
            ["tmux", "capture-pane", "-t", f"{session_name}:0.0", "-p"],
            capture_output=True,
            text=True
        )
        return result.stdout
    except Exception as e:
        print(f"ペインのキャプチャ中にエラーが発生しました: {e}")
        return None


def get_diff_content(previous_content, current_content):
    """
    前回の内容と現在の内容の差分を取得し、行数も返す

    Args:
        previous_content (str): 前回キャプチャした内容
        current_content (str): 今回キャプチャした内容

    Returns:
        tuple: (差分文字列, 差分行数)
               初回実行時は ("初回実行のため差分なし", 0)

    動作:
        - difflibを使用してUnified diff形式で差分を生成
        - +/-で始まる行（実際の差分）のみを抽出
        - +++/---（ファイルヘッダ）は除外
    """
    try:
        if previous_content is None:
            return "初回実行のため差分なし", 0

        # 前回の内容と現在の内容を行に分割
        previous_lines = previous_content.splitlines(keepends=True)
        current_lines = current_content.splitlines(keepends=True)

        # difflibを使用して差分を生成
        diff = difflib.unified_diff(
            previous_lines,
            current_lines,
            fromfile='previous',
            tofile='current',
            lineterm=''
        )
        diff = [
            line for line in diff
            if line.startswith('+') or line.startswith('-')
            if not line.startswith('+++') and not line.startswith('---')
        ]

        diff_content = '\n'.join(diff)
        diff_lines = diff_content.split('\n')

        # 行数を計算
        line_count = len(diff_lines)

        return diff_content, line_count
    except Exception as e:
        print(f"差分の取得中にエラーが発生しました: {e}")
        return None, 0


def get_random_wait_sec():
    """
    待機時間を3-5秒のランダム値で取得

    Returns:
        int: 3から5の間のランダムな整数

    理由:
        - API制限やサーバー負荷を軽減
        - 定期的な監視パターンを分散
    """
    return random.randint(3, 5)


def main():
    """
    メイン処理

    処理フロー:
    1. コマンドライン引数からセッション名とファイルパスを取得
    2. 既存のtmuxセッションを終了
    3. 新しいtmuxセッションでcodexコマンドを実行
    4. 画面の変化を監視（3-5秒間隔）
    5. 5回連続で変化なし → 自動再起動
    6. 60000秒（約16.7時間）で終了

    監視ロジック:
    - 画面が変化した場合: 差分を表示し、カウンタをリセット
    - 画面が変化しない場合: カウンタを増加
    - 5回連続で変化なし: tmuxセッションを再起動してカウンタリセット

    終了条件:
    - 最大実行時間（60000秒）に到達
    - ユーザーによるキーボード割り込み（Ctrl+C）
    """
    # argparseでセッション名とファイルパスを受け取る
    parser = argparse.ArgumentParser(
        description='指定されたtmuxセッションを監視し、codexコマンドを実行します。実行例: codexr <session_name> <command_file_path>')
    parser.add_argument('session_name', help='tmuxセッション名')
    parser.add_argument('command_file_path',
                        help='codexに送信するメッセージが含まれるファイルのパス')
    args = parser.parse_args()

    # 指定されたtmuxセッションをkillして新しく起動
    kill_tmux_session(args.session_name)
    start_new_tmux_session(args.session_name, args.command_file_path)

    previous_content = None
    start_time = time.time()
    max_duration = 60000  # 最大実行時間（秒）= 約16.7時間
    same_content_count = 0  # 同じ内容が連続した回数をカウント

    print(f"tmuxセッション '{args.session_name}' の監視を開始...")
    print(f"{max_duration}秒後に終了します")
    print(f"別のターミナルから 'tmux attach -t {args.session_name}' で画面を確認できます")

    while True:
        try:
            # tmuxペインの内容をキャプチャ
            current_content = capture_tmux_pane(args.session_name)

            if current_content is None:
                print("ペインのキャプチャに失敗しました")
                wait_sec = get_random_wait_sec()
                time.sleep(wait_sec)
                continue

            # 前回の内容と比較
            if previous_content is not None and current_content == previous_content:
                same_content_count += 1
                print(
                    f"変更が検出されませんでした {time.strftime('%Y-%m-%d %H:%M:%S')} (連続{same_content_count}回目)")

                # 5回連続で同じ内容ならtmuxセッションを再起動
                # 理由: codexコマンドがハングした可能性があるため
                if same_content_count >= 5:
                    print("\n5回連続で同じ内容が検出されました。tmuxセッションを再起動します...")
                    same_content_count = 0  # カウントをリセット
                    kill_tmux_session(args.session_name)
                    start_new_tmux_session(
                        args.session_name, args.command_file_path)
            else:
                same_content_count = 0  # 変更が検出されたらカウントをリセット
                print(
                    f"変更が検出されました {time.strftime('%Y-%m-%d %H:%M:%S')}")

                # 差分を取得
                diff_content, line_count = get_diff_content(
                    previous_content, current_content)
                if diff_content:
                    print(f"差分行数: {line_count}")
                    if line_count > 0:
                        print("差分内容:")
                        print(diff_content)
                else:
                    print("差分が利用できません")

                previous_content = current_content

            # 経過時間チェック
            elapsed_time = time.time() - start_time
            if elapsed_time >= max_duration:
                print(
                    f"\n最大実行時間 ({max_duration}秒) に達しました。終了します...")
                break

            # 3-5秒のランダム待機
            wait_sec = get_random_wait_sec()
            time.sleep(wait_sec)

        except KeyboardInterrupt:
            print("\nユーザーによって監視が停止されました")
            break
        except Exception as e:
            print(f"予期しないエラー: {e}")
            wait_sec = get_random_wait_sec()
            time.sleep(wait_sec)


if __name__ == "__main__":
    main()
