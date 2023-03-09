data "aws_caller_identity" "current_acc" {}

data "aws_region" "current_region" {}

data "archive_file" "lambda_code" {
    type = "zip"
    source_file = "${path.module}/../src/file_reader/reader.py"
    output_file_mode = "0666"
    output_path = "${path.module}/function.zip"
}