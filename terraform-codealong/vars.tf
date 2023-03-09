variable "data_bucket_prefix" {
    type = string
    default = "infoomics-data-"
}

variable "code_bucket_prefix" {
    type = string
    default = "infoomics-code-"
}

variable "lambda_name" {
    type = string
    default = "s3-file-reader"
}