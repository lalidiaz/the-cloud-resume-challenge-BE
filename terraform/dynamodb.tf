# ----------------------------- DynamoDB -----------------------------

resource "aws_dynamodb_table_item" "initial_counter" {
  table_name = aws_dynamodb_table.count_table.name
  hash_key   = aws_dynamodb_table.count_table.hash_key

  item = <<ITEM
{
  "id": {"S": "visitors"},
  "counter": {"N": "0"}
 }
ITEM

}

resource "aws_dynamodb_table" "count_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }


  tags = {
    Name = "TheCloudResumeChallenge"
  }
}