function save-session-key {
  PROFILE=$1
  aws configure get mfa_serial --profile $PROFILE > /dev/null && echo "Enter MFA code:" && read TOKEN_CODE || TOKEN_CODE=""
  MFA=$(aws configure get mfa_serial --profile $PROFILE > /dev/null && echo " --serial-number $(aws configure get mfa_serial --profile $PROFILE) --token-code $TOKEN_CODE " || echo "")
  CRED=$(aws configure get aws_access_key_id --profile $PROFILE > /dev/null && aws sts get-session-token --profile $PROFILE --query 'Credentials' $(echo $MFA) || aws sts assume-role --duration-seconds 3600 --role-session-name ${PROFILE}-$(command date +%s) --role-arn $(aws configure get role_arn --profile $PROFILE) --query 'Credentials' --profile $PROFILE)
  AWS_ACCESS_KEY_ID=$(echo $CRED | jq -r ".AccessKeyId")
  AWS_SECRET_ACCESS_KEY=$(echo $CRED | jq -r ".SecretAccessKey")
  AWS_SESSION_TOKEN=$(echo $CRED | jq -r ".SessionToken")
  REGION=$(aws configure get region --profile $PROFILE)

  NEW_PROFILE="${PROFILE}-temp"
  cat ~/.aws/credentials | grep -q "\[$NEW_PROFILE\]" || echo "[$NEW_PROFILE]" >> ~/.aws/credentials
  aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile $NEW_PROFILE
  aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile $NEW_PROFILE
  aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile $NEW_PROFILE
  aws configure set region "$REGION" --profile $NEW_PROFILE
  aws configure set output "json" --profile $NEW_PROFILE
  echo export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \&\& export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \&\& export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \&\& export AWS_DEFAULT_REGION="$REGION" \&\& export AWS_DEFAULT_OUTPUT="json"
}

function getssm() {
  command aws ssm get-parameter --name $1 --query 'Parameter.Value' --output text --with-decryption
}

function rebase() {
  local COMMIT_ARG=$1
  HASH=$(git log --oneline | peco | head -c 7)
  command git commit --fixup $HASH $COMMIT_ARG
  command git -c sequence.editor=: rebase -i --autosquash HEAD~$(git log --oneline --pretty=format:"%h" | grep -n $HASH | cut -d : -f 1)
}

function wt() {
  local BRANCH_NAME=$1
  mkdir -p ~/repo/worktrees/$(date +%Y%m)
  command git worktree add -b $BRANCH_NAME ~/repo/worktrees/$(date +%Y%m)/$BRANCH_NAME $(default_branch)
  cd ~/repo/worktrees/$(date +%Y%m)/$BRANCH_NAME
}

function clauder() {
  local SESSION_NAME=$1
  local COMMAND_FILE_PATH=$2
  python ~/.repeat_tmux.py $SESSION_NAME $COMMAND_FILE_PATH
}

# codexr - Codex自動実行・監視コマンド
#
# 【概要】
# tmuxセッション内でcodexコマンドを自動実行し、画面の変化を監視します。
# 画面に変化がない場合は自動的にセッションを再起動し、長時間の自動実行を実現します。
#
# 【使い方】
#   codexr <セッション名> <命令ファイルパス>
#
# 【引数】
#   セッション名: tmuxで使用するセッションの一意な名前
#   命令ファイルパス: codexに実行させたい指示が書かれたファイルのパス
#
# 【例】
#   # test-sessionという名前のtmuxセッションで、command.txtの内容をcodexに実行させる
#   codexr test-session ~/command.txt
#
#   # 実行後、別ターミナルから以下で監視状況を確認可能
#   tmux attach -t test-session
#
# 【動作】
#   1. 指定されたtmuxセッションが存在する場合は一旦終了
#   2. 新しいtmuxセッションを起動し、codexコマンドで指定ファイルの内容を実行
#   3. 3-5秒間隔でtmux画面の内容をキャプチャし、前回との差分を検出
#   4. 5回連続で変化がない場合、自動的にセッションを再起動
#   5. 最大60000秒（約16.7時間）まで実行
#
# 【実装】
#   ~/.repeat_tmux_codex.py を呼び出します
#   詳細な動作は .repeat_tmux_codex.py のコメントを参照してください
#
# 【clauderコマンドとの違い】
#   - clauder: claudeコマンドを使用（~/.repeat_tmux.py）
#   - codexr: codexコマンドを使用（~/.repeat_tmux_codex.py）
#
# 【ユースケース】
#   - CI/CD環境でcodexによるコード生成・修正を自動化
#   - 長時間かかるリファクタリング作業をバックグラウンドで実行
#   - 定期的な自動コードレビュー・修正
#
function codexr() {
  local SESSION_NAME=$1
  local COMMAND_FILE_PATH=$2
  python ~/.repeat_tmux_codex.py $SESSION_NAME $COMMAND_FILE_PATH
}

function nuke_docker() {
  sudo pkill -f docker
  sleep 1
  sudo pkill -f docker && true
  sleep 1
  sudo pkill -f docker && true
  sleep 1
  killall Docker && true
  rm ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw
  open -a Docker
}

approve() {
  local pr_number=$1
  local emoji=${2} # Default emoji is "100" if not provided
  h pr review --approve --body ":${emoji}:" $pr_number
}

# checkout_or_cd
cocd() {
  local branch="$1"

  if [ -z "$branch" ]; then
    echo "Usage: cocd <branch-name>"
    return 1
  fi

  # チェックアウトを試みる
  if git checkout "$branch" 2>/dev/null; then
    echo "Checked out to branch: $branch"
    return 0
  fi

  # チェックアウト失敗時、エラーメッセージからworktreeのパスを抽出
  local error_msg=$(git checkout "$branch" 2>&1)
  local worktree_path=$(echo "$error_msg" | grep -o "worktree at '[^']*'" | sed "s/worktree at '//;s/'//")

  if [ -n "$worktree_path" ]; then
    echo "Branch is used by worktree at: $worktree_path"
    cd "$worktree_path"
    echo "Changed directory to: $(pwd)"
    return 0
  else
    echo "Error: $error_msg"
    return 1
  fi
}
