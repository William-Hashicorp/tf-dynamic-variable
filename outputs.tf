output "resolved_module_source_from_vars" {
  description = "Expected registry address resolved from const variables."
  value       = "app.terraform.io/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
}

output "resolved_module_source_from_locals" {
  description = "Expected registry address resolved from locals."
  value       = local.module_source_from_locals
}

output "resolved_module_version" {
  description = "Module version used by both module blocks."
  value       = var.s3_module_version
}

output "bucket_names" {
  description = "S3 buckets created by the test modules (after apply)."
  value = {
    from_vars   = module.s3_bucket_from_vars.bucket_id
    from_locals = module.s3_bucket_from_locals.bucket_id
  }
}
