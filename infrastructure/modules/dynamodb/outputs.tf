output "users_table_name" {
  value = aws_dynamodb_table.users.name
}

output "posts_table_name" {
  value = aws_dynamodb_table.posts.name
}

output "users_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "posts_table_arn" {
  value = aws_dynamodb_table.posts.arn
}
