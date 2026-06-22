variable "bucket_prefix" {
  description = "Prefix for the generated S3 bucket name."
  type        = string
}

variable "force_destroy" {
  description = "Delete all bucket objects when destroying the bucket."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default     = {}
}
