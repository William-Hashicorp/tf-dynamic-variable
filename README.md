# tf-dynamic-variable

Monorepo for testing Terraform 1.15+ dynamic module `source` and `version` attributes against the HCP Terraform private registry.

## Test results

Validated end-to-end in the **William-Hashicorp** org.

| Test | Result |
|------|--------|
| Local `terraform init` (TF 1.15.6) | Passed — both modules downloaded via dynamic `source` / `version` |
| Local `terraform validate` | Passed |
| HCP Terraform remote run | Passed — plan and apply in workspace `tf-dynamic-module-source-test` |
| Private registry module | `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws` @ `1.0.0` |
| VCS publishing | Linked to GitHub monorepo subfolder `registry-module/william-dynamic-s3` |

**HCP Terraform workspace:** [tf-dynamic-module-source-test](https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test)

- **Project:** `terraform-oss-ent-demo`
- **Terraform version:** `1.15.6`
- **VCS:** `William-Hashicorp/tf-dynamic-variable` (branch `main`)
- **AWS credentials:** inherited from project variable set `aws_doormat_credentials`

## How dynamic module `source` and `version` works

Terraform **1.15.0+** allows `module` blocks to use **variables** and **locals** in `source` and `version`. Before 1.15, both attributes had to be static string literals.

### Why `const = true` is required

Terraform installs modules during **`terraform init`**, before plan-time variable evaluation. Any variable referenced in `source` or `version` must therefore be known at init time.

Mark those variables with `const = true`:

```hcl
variable "tfc_org" {
  type    = string
  default = "William-Hashicorp"
  const   = true
}

variable "s3_module_version" {
  type    = string
  default = "1.0.0"
  const   = true
}
```

Rules:

- Only **`const` variables** (or **locals built from `const` variables**) may appear in `source` / `version`
- `const` cannot be combined with `sensitive` or `ephemeral`
- Values can come from defaults, `.tfvars`, `-var`, `TF_VAR_*`, or HCP Terraform workspace variables
- After changing `source` or `version`, re-run `terraform init` (use `-upgrade` when needed)

### Variables in `source` and `version`

```hcl
module "s3_bucket_from_vars" {
  source  = "app.terraform.io/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
  version = var.s3_module_version
}
```

Terraform resolves the interpolated string at init, then downloads the module from the private registry.

### Locals in `source` and `version`

```hcl
locals {
  module_source_from_locals = "app.terraform.io/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
  module_version_from_local = var.s3_module_version
}

module "s3_bucket_from_locals" {
  source  = local.module_source_from_locals
  version = local.module_version_from_local
}
```

Locals work the same way, as long as they only reference `const` variables (not resources, data sources, or plan-time values).

### Private registry support

This works with **HCP Terraform private registry** modules using the standard address format:

```text
app.terraform.io/<org>/<module-name>/<provider>
```

The test in this repo confirms both **variable interpolation** and **locals** against a VCS-linked private module published from a monorepo subfolder.

## Layout

```text
.
├── registry-module/
│   └── william-dynamic-s3/   # Private registry module (subfolder)
├── main.tf                   # Consumer test config
├── variables.tf
├── locals.tf
├── scripts/
│   ├── link-module-vcs.sh    # Link module to GitHub + publish via git tags
│   └── publish-module.sh     # Legacy manual tarball upload (deprecated)
└── run-test.sh               # init / validate / plan test
```

## Registry module

- **Name:** `william-dynamic-s3`
- **Provider:** `aws`
- **GitHub repo:** https://github.com/William-Hashicorp/tf-dynamic-variable
- **Source path in monorepo:** `registry-module/william-dynamic-s3`
- **Registry address:** `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws`
- **Publishing:** VCS-linked (`git_tag`) from the monorepo subfolder
- **Tag prefix:** `william-dynamic-s3/` (e.g. `william-dynamic-s3/v1.0.0`)

## Quick start

Local test (requires Terraform `>= 1.15.0` and AWS credentials for `plan`):

```bash
./run-test.sh
```

Remote test on HCP Terraform: open the [workspace](https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test) and queue a new run, or push changes to `main`.

## Publish module updates

Push a new git tag, then bump the consumer version:

```bash
MODULE_VERSION=1.0.1 bash scripts/link-module-vcs.sh
```

Update `s3_module_version` in `terraform.tfvars` and re-run `./run-test.sh` or trigger a workspace run.
