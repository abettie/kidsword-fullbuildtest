variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "users_zip_path" {
  type        = string
  description = "users Lambda関数のZIPファイルパス"
  default     = "../../../backend/dist/users.zip"
}

variable "posts_zip_path" {
  type        = string
  description = "posts Lambda関数のZIPファイルパス"
  default     = "../../../backend/dist/posts.zip"
}
