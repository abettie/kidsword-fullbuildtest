terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "tfstate-d0ecb71b-6149-48ce-99c8-94e41b353713"
    key    = "kidsword/dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  prefix = "kidsword-${var.env}"
  tags = {
    Project     = "kidsword"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# Firebase Admin SDK認証情報をSecrets Managerに保存
resource "aws_secretsmanager_secret" "firebase" {
  name                    = "${local.prefix}-firebase-secret"
  description             = "Firebase Admin SDK サービスアカウントキー"
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "firebase" {
  secret_id     = aws_secretsmanager_secret.firebase.id
  secret_string = file("${path.module}/firebase-service-account.json")
}

module "dynamodb" {
  source = "../../modules/dynamodb"
  prefix = local.prefix
  tags   = local.tags
}

module "lambda" {
  source = "../../modules/lambda"
  prefix = local.prefix
  tags   = local.tags

  users_table_name     = module.dynamodb.users_table_name
  posts_table_name     = module.dynamodb.posts_table_name
  dynamodb_table_arns  = [module.dynamodb.users_table_arn, module.dynamodb.posts_table_arn]
  firebase_secret_arn  = aws_secretsmanager_secret.firebase.arn
  firebase_secret_name = aws_secretsmanager_secret.firebase.name

  users_zip_path = var.users_zip_path
  posts_zip_path = var.posts_zip_path
}

module "api_gateway" {
  source = "../../modules/api_gateway"
  prefix = local.prefix
  tags   = local.tags

  stage_name                = var.env
  users_function_invoke_arn = module.lambda.users_function_invoke_arn
  posts_function_invoke_arn = module.lambda.posts_function_invoke_arn
  users_function_name       = module.lambda.users_function_name
  posts_function_name       = module.lambda.posts_function_name
}
