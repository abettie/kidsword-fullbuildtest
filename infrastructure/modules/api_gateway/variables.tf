variable "prefix" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "users_function_invoke_arn" {
  type = string
}

variable "posts_function_invoke_arn" {
  type = string
}

variable "users_function_name" {
  type = string
}

variable "posts_function_name" {
  type = string
}
