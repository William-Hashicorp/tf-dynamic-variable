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

```bash
./run-test.sh
```

Requires Terraform `>= 1.15.0` and AWS credentials for `plan`/`apply`.

## Publish module updates

Push a new git tag, then bump the consumer version:

```bash
MODULE_VERSION=1.0.1 bash scripts/link-module-vcs.sh
```

Update `s3_module_version` in `terraform.tfvars` and re-run `./run-test.sh`.
