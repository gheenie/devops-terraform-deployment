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

resource "aws_iam_policy" "s3_policy" {
    name_prefix = "s3-reader-policy-"
    policy = data.aws_iam_policy_document.s3_document.json
}

resource "aws_iam_policy" "cw_policy" {
    name_prefix = "cloudwatch-policy-"
    policy = data.aws_iam_policy_document.cw_document.json
}

resource "aws_iam_role" "lambda_role" {
    name_prefix = "role-${var.lambda_name}-"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "cw_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.cw_policy.arn
}