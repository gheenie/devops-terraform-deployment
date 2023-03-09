resource "aws_s3_bucket" "code_bucket" {
    bucket_prefix = var.code_bucket_prefix
}

resource "aws_s3_bucket" "data_bucket" {
    bucket_prefix = var.data_bucket_prefix
}

resource "aws_s3_object" "code_object" {
    bucket = aws_s3_bucket.code_bucket.bucket
    key = "${var.lambda_name}/function.zip"
    source = "${path.module}/../function.zip"
}