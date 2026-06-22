module "s3_core" {
  source = local.core_module_source_from_local

  bucket_prefix = var.bucket_prefix
  force_destroy = var.force_destroy
  tags          = var.tags
}
