# william-dynamic-s3

Minimal S3 bucket module for testing Terraform 1.16+ dynamic module `source` and `version` attributes against the HCP Terraform private registry.

This module lives in the monorepo at `registry-module/william-dynamic-s3`.

## Const rules inside a published module

Child modules use dynamic `source` paths built from `const` variables and locals:

- `core_module_subdir` / `core_module_subdir_name` — `const = true`
- `local.core_module_source_from_var` — `"./modules/${var.core_module_subdir}"`
- `local.core_module_source_from_local` — `"./modules/${local.core_module_subdir_name}"`
- `module.s3_core` — `source = local.core_module_source_from_local`

Implementation details live in `modules/s3-core/`.

## Validation notes

| Check | Result |
|------|--------|
| Local `terraform init` + `validate` (Terraform **1.16.3**) | Passed |
| HCP Terraform private registry ingress **1.1.0** | Passed (`ok`) |
| Earlier ingress **1.0.2** | Failed (`reg_ingress_failed`) — pre-upgrade parser |

Use registry version **`1.1.0`** (or newer) for the const-based nested module source test.
