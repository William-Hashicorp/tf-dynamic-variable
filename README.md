# tf-dynamic-variable

Monorepo for testing Terraform 1.15+ dynamic module `source` and `version` attributes against the HCP Terraform private registry.

## Layout

```text
.
├── registry-module/
│   └── william-dynamic-s3/   # Private registry module (subfolder)
├── main.tf                   # Consumer test config
├── variables.tf
├── locals.tf
├── scripts/
│   └── publish-module.sh     # Manual publish to TFC private registry
└── run-test.sh               # init / validate / plan test
```

## Registry module

- **Name:** `william-dynamic-s3`
- **Provider:** `aws`
- **Source path in monorepo:** `registry-module/william-dynamic-s3`
- **Registry address:** `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws`

## Quick start

```bash
./run-test.sh
```

Requires Terraform `>= 1.15.0` and AWS credentials for `plan`/`apply`.

## Publish module updates

```bash
MODULE_VERSION=1.0.1 bash scripts/publish-module.sh
```

Then bump `s3_module_version` in `terraform.tfvars` and re-run `./run-test.sh`.
