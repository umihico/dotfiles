function save-session-key {
  PROFILE=$1
  CRED=$(aws configure get aws_access_key_id && aws sts get-session-token --profile $PROFILE --query 'Credentials' || aws sts assume-role --duration-seconds 3600 --role-session-name ${PROFILE}-$(command date +%s) --role-arn $(aws configure get role_arn) --query 'Credentials')
  AWS_ACCESS_KEY_ID=$(echo $CRED | jq -r ".AccessKeyId")
  AWS_SECRET_ACCESS_KEY=$(echo $CRED | jq -r ".SecretAccessKey")
  AWS_SESSION_TOKEN=$(echo $CRED | jq -r ".SessionToken")

  NEW_PROFILE="${PROFILE}-temp"
  cat ~/.aws/credentials | grep -q "\[$NEW_PROFILE\]" || echo "[$NEW_PROFILE]" >> ~/.aws/credentials
  aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile $NEW_PROFILE
  aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile $NEW_PROFILE
  aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile $NEW_PROFILE
  aws configure set region "$(aws configure get region --profile $PROFILE)" --profile $NEW_PROFILE
  aws configure set output "json" --profile $NEW_PROFILE
}