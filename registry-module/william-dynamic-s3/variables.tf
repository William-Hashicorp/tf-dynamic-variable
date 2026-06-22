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

variable "core_module_subdir" {
  description = "Subdirectory name under ./modules for the core S3 child module."
  type        = string
  default     = "s3-core"
  const       = true
}

variable "core_module_subdir_name" {
  description = "Duplicate const input used to build a local value for the child module source."
  type        = string
  default     = "s3-core"
  const       = true
}
