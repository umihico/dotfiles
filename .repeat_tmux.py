#!/usr/bin/env python3
import subprocess
import time
import os
import tempfile
import difflib
import argparse


def kill_tmux_session(session_name):
    """指定されたtmuxセッションをkillする"""
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
    """新しいtmuxセッションを起動し、指定されたファイルの内容をclaudeコマンドで実行する"""
    try:
        # ファイルの内容を読み込み
        message = f"{command_file_path}を読み込んで、指示を実行してください。"

        # 新しいtmuxセッションを起動し、claudeコマンドを実行
        claude_command = f'claude --dangerously-skip-permissions "{message}"'
        subprocess.run(["tmux", "new-session", "-d", "-s", session_name,
                       claude_command], check=True)
        time.sleep(10)  # 起動に時間もかかり差分なしの判定防止
        print(
            f"新しいtmuxセッション '{session_name}' を起動し、claudeコマンドを実行しました: {claude_command}")
    except FileNotFoundError:
        print(f"ファイル '{command_file_path}' が見つかりません")
        raise
    except Exception as e:
        print(f"tmuxセッション '{session_name}' の起動中にエラーが発生しました: {e}")
        raise


def capture_tmux_pane(session_name):
    """指定されたtmuxセッションのペインの内容をキャプチャして返す"""
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
    """前回の内容と現在の内容の差分を取得し、行数も返す"""
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


WAIT_SEC = 5


def main():
    # argparseでセッション名とファイルパスを受け取る
    parser = argparse.ArgumentParser(
        description='指定されたtmuxセッションを監視し、claudeコマンドを実行します。実行例: clauder <session_name> <command_file_path>')
    parser.add_argument('session_name', help='tmuxセッション名')
    parser.add_argument('command_file_path',
                        help='claudeに送信するメッセージが含まれるファイルのパス')
    args = parser.parse_args()

    # 指定されたtmuxセッションをkillして新しく起動
    kill_tmux_session(args.session_name)
    start_new_tmux_session(args.session_name, args.command_file_path)

    previous_content = None
    start_time = time.time()
    max_duration = 60000  # 最大実行時間（秒）

    print(f"tmuxセッション '{args.session_name}' の監視を開始...")
    print(f"{max_duration}秒後に終了します")

    while True:
        try:
            # tmuxペインの内容をキャプチャ
            current_content = capture_tmux_pane(args.session_name)

            if current_content is None:
                print("ペインのキャプチャに失敗しました")
                time.sleep(WAIT_SEC)
                continue

            # 前回の内容と比較
            if previous_content is not None and current_content == previous_content:
                print(
                    f"変更が検出されませんでした {time.strftime('%Y-%m-%d %H:%M:%S')}")
                # 新しいtmuxセッションを起動
                kill_tmux_session(args.session_name)
                start_new_tmux_session(
                    args.session_name, args.command_file_path)
            else:
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

            # 5秒待機
            time.sleep(WAIT_SEC)

        except KeyboardInterrupt:
            print("\nユーザーによって監視が停止されました")
            break
        except Exception as e:
            print(f"予期しないエラー: {e}")
            time.sleep(WAIT_SEC)


if __name__ == "__main__":
    main()
