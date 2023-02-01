resource "aws_lambda_function" "s3_file_reader" {
# TO BE IMPLEMENTED
}

resource "aws_lambda_permission" "allow_s3" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_file_reader.function_name
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.data_bucket.arn
  source_account = data.aws_caller_identity.current.account_id
}