output "api_endpoint" {
  description = "API GatewayエンドポイントURL"
  value       = module.api_gateway.api_endpoint
}

output "users_table_name" {
  value = module.dynamodb.users_table_name
}

output "posts_table_name" {
  value = module.dynamodb.posts_table_name
}
