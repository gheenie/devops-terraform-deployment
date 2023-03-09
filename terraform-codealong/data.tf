data "aws_caller_identity" "current_acc" {}

data "aws_region" "current_region" {}

data "archive_file" "lambda_code" {
    type = "zip"
    source_file = "${path.module}/../src/file_reader/reader.py"
    output_file_mode = "0666"
    output_path = "${path.module}/../function.zip"
}

data "aws_iam_policy_document" "s3_document" {
    statement {
        actions = ["s3:GetObject"]

        resources = [
            "${aws_s3_bucket.code_bucket.arn}/*",
            "${aws_s3_bucket.data_bucket.arn}/*"
        ]
    }
}

data "aws_iam_policy_document" "cw_document" {
    statement {
        actions = ["logs:CreateLogGroup"]

        resources = ["arn:aws:logs:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_acc.account_id}:*"]
    }

    statement {
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]

        resources = ["arn:aws:logs:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_acc.account_id}:log-group:/aws/lambda/${var.lambda_name}"]
    }
}