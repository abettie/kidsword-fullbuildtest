variable "prefix" {
  description = "リソース名のプレフィックス (例: kidsword-dev)"
  type        = string
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
