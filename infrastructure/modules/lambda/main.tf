data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
    ]
    resources = concat(var.dynamodb_table_arns, [
      for arn in var.dynamodb_table_arns : "${arn}/index/*"
    ])
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.firebase_secret_arn]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "${var.prefix}-lambda-permissions"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_cloudwatch_log_group" "users" {
  name              = "/aws/lambda/${var.prefix}-users"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "posts" {
  name              = "/aws/lambda/${var.prefix}-posts"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_lambda_function" "users" {
  function_name    = "${var.prefix}-users"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.users_zip_path
  source_code_hash = filebase64sha256(var.users_zip_path)
  memory_size      = 256
  timeout          = 30

  environment {
    variables = {
      USERS_TABLE          = var.users_table_name
      FIREBASE_SECRET_NAME = var.firebase_secret_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.users]
  tags       = var.tags
}

resource "aws_lambda_function" "posts" {
  function_name    = "${var.prefix}-posts"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.posts_zip_path
  source_code_hash = filebase64sha256(var.posts_zip_path)
  memory_size      = 256
  timeout          = 30

  environment {
    variables = {
      USERS_TABLE          = var.users_table_name
      POSTS_TABLE          = var.posts_table_name
      FIREBASE_SECRET_NAME = var.firebase_secret_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.posts]
  tags       = var.tags
}
