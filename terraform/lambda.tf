resource "aws_lambda_function" "s3_file_reader" {
  function_name = var.lambda_name
  handler = "reader.lambda_handler"
  s3_bucket = aws_s3_bucket.code_bucket.bucket
  s3_key = aws_s3_object.lambda_code.key
  role = aws_iam_role.lambda_role.arn
  runtime = "python3.9"
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_lambda_permission" "allow_s3" {
  action = "lambda:InvokeFunction"
  principal = "s3.amazonaws.com"
  function_name = aws_lambda_function.s3_file_reader.function_name
  source_arn = aws_s3_bucket.data_bucket.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_cloudwatch_event_rule" "scheduler" {
    name_prefix = "mistaker-scheduler-"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "scheduler_target" {
  rule      = aws_cloudwatch_event_rule.scheduler.name
  arn       = aws_lambda_function.s3_file_reader.arn
}

resource "aws_lambda_permission" "allow_scheduler" {
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  function_name = aws_lambda_function.s3_file_reader.function_name
  source_arn = aws_cloudwatch_event_rule.scheduler.arn
  source_account = data.aws_caller_identity.current.account_id
}
