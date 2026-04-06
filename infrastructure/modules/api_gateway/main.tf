resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.prefix}-api"
  description = "kidsword API"
  tags        = var.tags
}

# /users リソース
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "users_me" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "me"
}

# GET /users/me
resource "aws_api_gateway_method" "users_me_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users_me.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "users_me_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.users_me.id
  http_method             = aws_api_gateway_method.users_me_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.users_function_invoke_arn
}

# PUT /users/me
resource "aws_api_gateway_method" "users_me_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users_me.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "users_me_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.users_me.id
  http_method             = aws_api_gateway_method.users_me_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.users_function_invoke_arn
}

# /posts リソース
resource "aws_api_gateway_resource" "posts" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "posts"
}

resource "aws_api_gateway_resource" "posts_me" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.posts.id
  path_part   = "me"
}

# POST /posts
resource "aws_api_gateway_method" "posts_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.posts.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "posts_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.posts.id
  http_method             = aws_api_gateway_method.posts_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.posts_function_invoke_arn
}

# GET /posts
resource "aws_api_gateway_method" "posts_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.posts.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "posts_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.posts.id
  http_method             = aws_api_gateway_method.posts_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.posts_function_invoke_arn
}

# GET /posts/me
resource "aws_api_gateway_method" "posts_me_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.posts_me.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "posts_me_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.posts_me.id
  http_method             = aws_api_gateway_method.posts_me_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.posts_function_invoke_arn
}

# Lambda 実行権限
resource "aws_lambda_permission" "users" {
  statement_id  = "AllowAPIGatewayInvokeUsers"
  action        = "lambda:InvokeFunction"
  function_name = var.users_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "posts" {
  statement_id  = "AllowAPIGatewayInvokePosts"
  action        = "lambda:InvokeFunction"
  function_name = var.posts_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# デプロイ
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.users_me_get,
      aws_api_gateway_method.users_me_put,
      aws_api_gateway_method.posts_post,
      aws_api_gateway_method.posts_get,
      aws_api_gateway_method.posts_me_get,
      aws_api_gateway_integration.users_me_get,
      aws_api_gateway_integration.users_me_put,
      aws_api_gateway_integration.posts_post,
      aws_api_gateway_integration.posts_get,
      aws_api_gateway_integration.posts_me_get,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name
  tags          = var.tags
}
