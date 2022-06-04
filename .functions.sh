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
  command git rebase -i --autosquash HEAD~$(git log --oneline --pretty=format:"%h" | grep -n $HASH | cut -d : -f 1)
}

function login(){
  open -a 'Google Chrome' "https://signin.aws.amazon.com/oauth?Action=logout&redirect_uri=https://aws.amazon.com"

  IAM_USERNAME=$(aws sts get-caller-identity --output text --query 'Arn' | awk -F/ '{print $NF}')
  TEMP_CRED=$(aws sts get-federation-token \
    --name $IAM_USERNAME$(date +%s) \
    --policy '{"Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]}' \
    --output text \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    | sed $'s/\t/ /g')
  SIGNIN_TOKEN=$(curl -sG \
    --data-urlencode "Action=getSigninToken" \
    --data-urlencode "SessionDuration=1800" \
    --data-urlencode "Session={\"sessionId\":\"$(echo $TEMP_CRED | cut -d ' ' -f1)\",\"sessionKey\":\"$(echo $TEMP_CRED | cut -d ' ' -f2)\",\"sessionToken\":\"$(echo $TEMP_CRED | cut -d ' ' -f3)\"}" \
    https://signin.aws.amazon.com/federation | jq -r .SigninToken)

  CONSOLE_URL="https://console.aws.amazon.com/"
  LOGIN_URL="https://signin.aws.amazon.com/federation?Action=login&Destination=${CONSOLE_URL}&SigninToken=${SIGNIN_TOKEN}"

  open -a 'Google Chrome' $LOGIN_URL
}
