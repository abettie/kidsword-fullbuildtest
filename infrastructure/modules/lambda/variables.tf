variable "prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "users_table_name" {
  type = string
}

variable "posts_table_name" {
  type = string
}

variable "dynamodb_table_arns" {
  type = list(string)
}

variable "firebase_secret_arn" {
  type = string
}

variable "firebase_secret_name" {
  type = string
}

variable "users_zip_path" {
  type = string
}

variable "posts_zip_path" {
  type = string
}
