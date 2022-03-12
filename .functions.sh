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

function b() {
  command git branch --sort=-committerdate | cut -c 3- | head -n20 | cat -n
  read 'BranchNumber?Enter Branch Number: '
  command git checkout $(git branch --sort=-committerdate | cut -c 3- | head -n20 |awk NR==$BranchNumber)
}

function getssm() {
  command aws ssm get-parameter --name $1 --query 'Parameter.Value' --output text --with-decryption
}