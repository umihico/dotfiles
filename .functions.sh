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
  HASH=$(git log --oneline | peco | head -c 7)
  command git commit --fixup $HASH
  command git -c sequence.editor=: rebase -i --autosquash HEAD~$(git log --oneline --pretty=format:"%h" | grep -n $HASH | cut -d : -f 1)
}

function chat() {
  curl --silent --output /dev/null "http://localhost:7464"
  if [ $? -ne 0 ]; then
    # docker stop $(docker ps -a -q  --filter ancestor=ghcr.io/mckaywrigley/chatbot-ui:main)
    echo $(gh config get -h github.com oauth_token) | docker login ghcr.io -u umihico --password-stdin
    docker run -d -e DEFAULT_MODEL=gpt-4 -e OPENAI_API_KEY=${OPENAI_API_KEY} -p 7464:3000 ghcr.io/mckaywrigley/chatbot-ui:main
  fi
  chrome 'http://localhost:7464'
}

approve() {
  local pr_number=$1
  local emoji=${2} # Default emoji is "100" if not provided
  h pr review --approve --body ":${emoji}:" $pr_number
}
