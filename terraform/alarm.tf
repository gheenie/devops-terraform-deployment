resource "aws_cloudwatch_log_metric_filter" "three_error" {
    log_group_name = "/aws/lambda/${aws_lambda_function.s3_file_reader.function_name}"

    pattern        = "ERROR"
    name           = "ErrorFilter"

    metric_transformation {
        namespace = "CustomLambdaMetrics"
        name      = "ErrorCount"
        value     = "1"
    }
}

resource "aws_cloudwatch_metric_alarm" "alert_errors" {
    namespace                 = aws_cloudwatch_log_metric_filter.three_error.metric_transformation[0].namespace
    metric_name               = aws_cloudwatch_log_metric_filter.three_error.metric_transformation[0].name

    alarm_name                = "AlertErrors"
    statistic                 = "Sum"
    period                    = "60"
    evaluation_periods        = "1"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    threshold                 = "1"

    # After running deploy.sh, copy SNS topic ARN here.
    alarm_actions             = ["arn:aws:sns:us-east-1:921693990905:test-error-alerts"]
}
