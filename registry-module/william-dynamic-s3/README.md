# william-dynamic-s3

Minimal S3 bucket module for testing Terraform 1.15+ dynamic module `source` and `version` attributes against the HCP Terraform private registry.

This module lives in the monorepo at `registry-module/william-dynamic-s3`.

## Const rules inside a published module

Child modules use dynamic `source` paths built from `const` variables and locals:

- `core_module_subdir` / `core_module_subdir_name` — `const = true`
- `module.s3_core_from_var` — `source = "./modules/${var.core_module_subdir}"`
- `module.s3_core_from_local` — `source = local.core_module_source_from_local`

Implementation details live in `modules/s3-core/`.

## Validation notes

- `terraform init` + `terraform validate` (Terraform 1.15.6) — **passes** locally
- HCP Terraform private registry ingress for `1.0.2` — **fails** with:

  ```text
  Variables not allowed: Variables may not be used here.
  Unsuitable value: value must be known
  ```

  The registry parser does not yet accept dynamic child `module` `source` values, even with `const = true`. Use version `1.0.0` from the registry until ingress supports Terraform 1.15 module source expressions.
