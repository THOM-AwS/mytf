terraform {
  required_version = ">=0.13"
  backend "s3" {
    bucket                  = "hamer-terraform-backend"
    key                     = "tf-hamer/gitlab-runner"
    region                  = "ap-southeast-2"
    profile                 = "hamer"
    dynamodb_table          = "hamer-terraform-lock"
    skip_metadata_api_check = true
  }
}
