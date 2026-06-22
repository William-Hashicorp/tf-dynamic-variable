output "bucket_id" {
  description = "Name of the S3 bucket."
  value       = module.s3_core.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = module.s3_core.bucket_arn
}

output "bucket_region" {
  description = "AWS region of the S3 bucket."
  value       = module.s3_core.bucket_region
}

output "resolved_core_module_source_from_var" {
  description = "Child module source path resolved from a const variable."
  value       = local.core_module_source_from_var
}

output "resolved_core_module_source_from_local" {
  description = "Child module source path resolved from a local built from const variables."
  value       = local.core_module_source_from_local
}
