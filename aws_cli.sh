# Setup. #########################################

pyenv install 3.9.7
pyenv local 3.9.7
make requirements
make dev-setup
make run-checks

aws configure
ACCOUNT_NUM=$(aws sts get-caller-identity | jq .Account | tr -d '"')


# Create buckets. ##########################################

SUFFIX=$(date +%s)
DATA_BUCKET_NAME=infoomics-data-${SUFFIX}
CODE_BUCKET_NAME=infoomics-code-${SUFFIX}
aws s3 mb s3://${DATA_BUCKET_NAME}
aws s3 mb s3://${CODE_BUCKET_NAME}
aws s3 ls

# Upload lambda package.

FUNCTION_NAME=s3-file-reader
ZIP_NAME=function.zip
zip ../../${ZIP_NAME} src/file_reader/reader.py
aws s3 cp ${ZIP_NAME} s3://${CODE_BUCKET_NAME}/${FUNCTION_NAME}/${ZIP_NAME}
aws s3 ls --recursive ${CODE_BUCKET_NAME}


# Runs after bucket phase because bucket arn is needed. #####################

# Create policies.

# Insert bucket arn into the policy before running the following code.
S3_READ_POLICY_JSON=$(aws iam create-policy --policy-name s3-read-policy --policy-document file://deployment/s3_read_policy.json)
S3_READ_POLICY_ARN=$(echo ${S3_READ_POLICY_JSON} | jq .Policy.Arn | tr -d '"')

# Insert account number arn and log group arn containing the desired lambda function name
# into the policy before running the following code.
CLOUDWATCH_LOG_POLICY_JSON=$(aws iam create-policy --policy-name cloudwatch-log-policy --policy-document file://deployment/cloudwatch_log_policy.json)
CLOUDWATCH_LOG_POLICY_ARN=$(echo ${CLOUDWATCH_LOG_POLICY_JSON} | jq .Policy.Arn | tr -d '"')

# Create role.

ROLE_NAME=lambda-execution-role-s3-reader
EXECUTION_ROLE_JSON=$(aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://deployment/trust_policy.json)
EXECUTION_ROLE_ARN=$(echo ${EXECUTION_ROLE_JSON} | jq .Role.Arn | tr -d '"')

# Attach policies to role.

aws iam attach-role-policy --policy-arn ${S3_READ_POLICY_ARN} --role-name ${ROLE_NAME}
aws iam attach-role-policy --policy-arn ${CLOUDWATCH_LOG_POLICY_ARN} --role-name ${ROLE_NAME}


# Links code bucket and IAM to lambda. #####################################

# Create lambda function.

LAMBDA_FUNCTION_JSON=$(aws lambda create-function --function-name ${FUNCTION_NAME} \
--handler reader.lambda_handler --code S3Bucket=${CODE_BUCKET_NAME},S3Key=${FUNCTION_NAME}/${ZIP_NAME} \
--role ${EXECUTION_ROLE_ARN} --runtime python3.9 --package-type Zip)
LAMBDA_FUNCTION_ARN=$(echo ${LAMBDA_FUNCTION_JSON} | jq .FunctionArn | tr -d '"')


# Links lambda to < links event to data bucket. ###################################

# Add permission to lambda function.

LAMBDA_PERMISSION_JSON=$(aws lambda add-permission --statement s3_trigger \
--function-name ${FUNCTION_NAME} --action "lambda:InvokeFunction" \
--source-arn arn:aws:s3:::${DATA_BUCKET_NAME} \
--source-account ${ACCOUNT_NUM} --principal s3.amazonaws.com)

# Insert lambda function arn into the policy before running the following code.
aws s3api put-bucket-notification-configuration --bucket ${DATA_BUCKET_NAME} \
--notification-configuration file://deployment/s3_event_config.json


# Testing #######################################################################

aws s3 cp requirements.txt s3://${DATA_BUCKET_NAME}

# Wait some time for the logs to generate.
aws logs tail /aws/lambda/${FUNCTION_NAME}
