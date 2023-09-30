resource "aws_dynamodb_table" "generic_data" {
  name           = "genericDataTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "timestamp"
    type = "N"
  }
  hash_key = "timestamp"
}
