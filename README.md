# tf-dynamic-variable

Monorepo for testing Terraform 1.16+ dynamic module `source` and `version` attributes against the HCP Terraform private registry.

## Test results

Validated end-to-end in the **William-Hashicorp** org with **Terraform 1.16.3**.

| Test | Result |
|------|--------|
| Local `terraform init` (TF 1.16.3) | Passed — consumer + nested `s3_core` modules resolved via dynamic `source` / `version` |
| Local `terraform validate` | Passed |
| HCP Terraform private registry ingress | Passed for `william-dynamic-s3` **1.1.0** (const-based nested `source`) |
| HCP Terraform remote apply | Passed — workspace `tf-dynamic-module-source-test` (`run-aA1BUbQ5r1HMjvAp`) |
| Earlier ingress regression | `1.0.2` still shows `reg_ingress_failed`; retest succeeded on `1.1.0` |

**HCP Terraform workspace:** [tf-dynamic-module-source-test](https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test)

- **Project:** `terraform-oss-ent-demo`
- **Terraform version:** `1.16.3`
- **VCS:** `William-Hashicorp/tf-dynamic-variable` (branch `main`)
- **AWS credentials:** inherited from project variable set `aws_doormat_credentials`
- **Registry module:** `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws` @ `1.1.0`

## How dynamic module `source` and `version` works

Terraform **1.15.0+** (tested here on **1.16.3**) allows `module` blocks to use **variables** and **locals** in `source` and `version`. Before 1.15, both attributes had to be static string literals.

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
  default = "1.1.0"
  const   = true
}
```

Rules:

- Only **`const` variables** (or **locals built from `const` variables**) may appear in `source` / `version`
- `const` cannot be combined with `sensitive` or `ephemeral`
- Values can come from defaults, `.tfvars`, `-var`, `TF_VAR_*`, or HCP Terraform workspace variables
- After changing `source` or `version`, re-run `terraform init` (use `-upgrade` when needed)

### Variables in `source` and `version` (workspace / consumer)

```hcl
module "s3_bucket_from_vars" {
  source  = "app.terraform.io/${var.tfc_org}/${var.s3_module_name}/${var.s3_module_provider}"
  version = var.s3_module_version
}
```

Terraform resolves the interpolated string at init, then downloads the module from the private registry.

### Locals in `source` and `version` (workspace / consumer)

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

### Const rules inside a published registry module

As of the HCP Terraform registry ingress update validated with module **1.1.0**, published modules may also use `const` variables / locals for **child** `module.source` paths (for example `./modules/${var.core_module_subdir}`). Local Terraform 1.16.3 and registry ingress both accept this.

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
│   ├── tfc-apply.sh          # Queue apply run on HCP Terraform workspace
│   ├── tfc-destroy.sh        # Queue destroy run and wait for completion
│   ├── tfc-common.sh         # Shared TFC API helpers (run polling)
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
- **Tag prefix:** `william-dynamic-s3/` (e.g. `william-dynamic-s3/v1.1.0`)
- **Current test version:** `1.1.0`

## Quick start

Local test (requires Terraform `>= 1.16.0` and AWS credentials for `plan`):

```bash
./run-test.sh
```

Remote test on HCP Terraform (uses workspace AWS credentials from project variable set):

```bash
bash scripts/tfc-apply.sh
bash scripts/tfc-destroy.sh   # clean up test S3 buckets afterwards
```

Or open the [workspace](https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test) and queue a run from the UI.

### HCP Terraform run polling note

Successful **destroy** runs report `status=applied` (not `destroyed`). Use the run's `is-destroy` attribute to distinguish destroy from apply. The `scripts/tfc-*.sh` helpers poll for terminal statuses including `applied`, `planned_and_finished`, and `errored`.

## Publish module updates

Push a new git tag, then bump the consumer version:

```bash
MODULE_VERSION=1.1.1 bash scripts/link-module-vcs.sh
```

Update `s3_module_version` in `terraform.tfvars` and re-run `./run-test.sh` or trigger a workspace run.
