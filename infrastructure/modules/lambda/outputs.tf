output "users_function_arn" {
  value = aws_lambda_function.users.arn
}

output "posts_function_arn" {
  value = aws_lambda_function.posts.arn
}

output "users_function_invoke_arn" {
  value = aws_lambda_function.users.invoke_arn
}

output "posts_function_invoke_arn" {
  value = aws_lambda_function.posts.invoke_arn
}

output "users_function_name" {
  value = aws_lambda_function.users.function_name
}

output "posts_function_name" {
  value = aws_lambda_function.posts.function_name
}
