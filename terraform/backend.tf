terraform {
    backend "s3" {
        bucket = "nc-jm-de-cicd-demo-state-001"
        key = "s3-file-reader/terraform.tfstate"
        region = "us-east-1"
    }
}