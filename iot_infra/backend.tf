terraform {
  backend "s3" {
    bucket                  = "hamer-terraform-backend"
    key                     = "tf-hamer/iot"
    region                  = "ap-southeast-2"
    profile                 = "hamer"
    dynamodb_table          = "hamer-terraform-lock"
    skip_metadata_api_check = true
  }
}
