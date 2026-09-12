resource "aws_dynamodb_table" "simple_answer" {
  name         = "simple-answer"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  # Demo environment: keep teardown easy, no accidental-delete guard needed
  deletion_protection_enabled = false

  tags = {
    Name      = "simple-answer"
    Namespace = var.env_vars["namespace"]
    Stage     = var.env_vars["stage"]
  }
}
