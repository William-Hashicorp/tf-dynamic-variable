locals {
  core_module_subdir_name = var.core_module_subdir_name

  # Nested module sources built from const variables / locals (valid in published registry modules).
  core_module_source_from_var   = "./modules/${var.core_module_subdir}"
  core_module_source_from_local = "./modules/${local.core_module_subdir_name}"
}
