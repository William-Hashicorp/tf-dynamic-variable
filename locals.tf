locals {
  # Validates locals (built only from const variables) in module source/version.
  registry_host = "app.terraform.io"

  module_source_from_locals = "${local.registry_host}/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
  module_version_from_local = var.s3_module_version
}
