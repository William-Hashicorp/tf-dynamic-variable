variable "aws_region" {
  description = "AWS region for the test bucket."
  type        = string
  default     = "us-west-2"
}

variable "tfc_org" {
  description = "TFC private registry organization (namespace)."
  type        = string
  default     = "William-Hashicorp"
  const       = true
}

variable "s3_module_name" {
  description = "Private registry module name to install."
  type        = string
  default     = "william-dynamic-s3"
  const       = true
}

variable "s3_module_provider" {
  description = "Private registry module provider."
  type        = string
  default     = "aws"
  const       = true
}

variable "s3_module_version" {
  description = "Private registry module version."
  type        = string
  default     = "1.0.2"
  const       = true
}

variable "bucket_prefix" {
  description = "Prefix for the test S3 bucket created by the module."
  type        = string
  default     = "tf-dynamic-module-src-test"
}
