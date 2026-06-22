# Test 1: variable interpolation in source + variable in version
module "s3_bucket_from_vars" {
  source  = "app.terraform.io/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
  version = var.s3_module_version

  bucket_prefix = "${var.bucket_prefix}-vars-"
  force_destroy = true

  tags = {
    Test = "dynamic-module-source-vars"
  }
}

# Test 2: locals in source + locals in version
module "s3_bucket_from_locals" {
  source  = local.module_source_from_locals
  version = local.module_version_from_local

  bucket_prefix = "${var.bucket_prefix}-locals-"
  force_destroy = true

  tags = {
    Test = "dynamic-module-source-locals"
  }
}
