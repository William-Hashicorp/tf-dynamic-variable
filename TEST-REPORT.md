# Dynamic Module Source & Version — Test Report & Customer Briefing

**Audience:** Customer technical stakeholders  
**Product:** Terraform / HCP Terraform private module registry  
**Feature:** Variables and locals in module `source` and `version` (`const = true`)  
**Test date:** 2026-09-18  
**Terraform version under test:** 1.16.3  
**Organization:** William-Hashicorp  

---

## A. Test report

### Objective

Validate that Terraform can use **variables** and **locals** in a module’s `source` and `version` attributes when consuming modules from the **HCP Terraform private registry**, and that the same `const` rules work **inside** a published private registry module (nested child modules).

### Environment

| Item | Value |
|------|--------|
| HCP Terraform org | `William-Hashicorp` |
| Project | `terraform-oss-ent-demo` |
| Workspace | [`tf-dynamic-module-source-test`](https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test) |
| Terraform version (workspace) | `1.16.3` |
| Private registry module | `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws` |
| Module version tested | `1.1.0` |
| Module source repo | https://github.com/William-Hashicorp/tf-dynamic-variable (`registry-module/william-dynamic-s3`) |
| Cloud provider | AWS (credentials via workspace variable set `aws_doormat_credentials`) |
| Region | `us-west-2` |

### What was tested

1. **Workspace / consumer config** — module `source` and `version` built from:
   - `const` input variables (string interpolation)
   - locals composed only from `const` variables
2. **Published private registry module** — nested child module `source` built from `const` variables and locals (for example `./modules/${var.core_module_subdir}`)
3. **End-to-end lifecycle** — registry publish (git tag) → `terraform init` → validate → remote plan/apply → destroy

### Results

| # | Test case | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Local `terraform init` (1.16.3) resolves dynamic private-registry `source`/`version` | **PASS** | Downloaded `william-dynamic-s3` `1.1.0` for both consumer modules; nested `s3_core` also resolved |
| 2 | Local `terraform validate` | **PASS** | Configuration valid |
| 3 | HCP Terraform private registry ingress of module with const-based nested `source` | **PASS** | Version `1.1.0` status = `ok` |
| 4 | HCP Terraform remote apply using project AWS credentials | **PASS** | Run `run-aA1BUbQ5r1HMjvAp` applied |
| 5 | Destroy / cleanup | **PASS** | Destroy run `run-M9Zq2Vipa6Wgrbgn` completed with `status=applied` |

### Historical note (regression then fixed)

| Module version | Registry ingress | Notes |
|----------------|------------------|--------|
| `1.0.0` / `1.0.1` | `ok` | Baseline module without nested dynamic `source` |
| `1.0.2` | `reg_ingress_failed` | Older registry parser rejected variables in nested `module.source` |
| `1.1.0` | `ok` | Retest after HCP Terraform upgrade — **accepted** |

### Conclusion

The feature works for customer-relevant paths:

- Consuming a **private registry** module with dynamic `source` / `version` in a workspace
- Publishing a private registry module that itself uses `const`-based nested module sources

**Recommendation for customers:** Use Terraform **≥ 1.15** (validated here on **1.16.3**), mark init-time inputs with `const = true`, and keep HCP Terraform / registry on a current platform release so module ingress accepts the same language features.

---

## B. Customer-friendly explanation

### The problem (before)

In older Terraform versions, every module block had to hard-code where the module came from and which version to use:

```hcl
module "network" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "3.2.1"
}
```

That made multi-environment and multi-org setups awkward. Teams often duplicated module blocks, patched `.tf` files in CI, or maintained separate branches just to change an org name or version pin.

### What changed

Starting in **Terraform 1.15**, and validated in this lab on **Terraform 1.16.3**, you can drive `source` and `version` from **known inputs**:

```hcl
variable "tfc_org" {
  type  = string
  const = true
}

variable "module_version" {
  type  = string
  const = true
}

module "network" {
  source  = "app.terraform.io/${var.tfc_org}/vpc/aws"
  version = var.module_version
}
```

You can also compose those values with **locals**, as long as those locals only depend on `const` variables.

### Why `const = true`?

Terraform downloads modules during **`terraform init`**, *before* it creates a plan. So any value used in `source` or `version` must already be known at init time.

`const = true` tells Terraform: “this input is fixed for this run; it will not come from a resource or data source later.” That is the safety boundary that makes dynamic module addresses possible without turning init into a full plan.

Simple rules to share with customers:

1. Use `const = true` on variables referenced in `source` / `version`
2. Do not combine `const` with `sensitive` or `ephemeral`
3. Locals are fine if they are built only from `const` variables
4. After changing `source` or `version`, re-run `terraform init` (use `-upgrade` when needed)

### Does this work with the HCP Terraform private registry?

**Yes.** This repo specifically tested:

| Scenario | Supported? |
|----------|------------|
| Workspace consumes a private registry module using variables/locals in `source`/`version` | Yes |
| Private registry module contains nested modules whose `source` is built from `const` variables/locals | Yes (validated with module `1.1.0` after platform update) |

Private registry address format remains:

```text
app.terraform.io/<organization>/<module-name>/<provider>
```

### Business value (one-liner for stakeholders)

Teams can **parameterize module location and version** across environments and organizations without duplicating Terraform code, while still keeping module installation deterministic at init time.

### Suggested talking points for a customer meeting

1. **What it is:** Parameterized module `source` / `version` using init-time (`const`) inputs  
2. **When to use it:** Different orgs, registries, or version pins per environment without copy-paste module blocks  
3. **Requirement:** Terraform ≥ 1.15; prefer current HCP Terraform for private-registry publishing/ingress  
4. **Proof:** This lab published `william-dynamic-s3` `1.1.0` to a private registry, consumed it dynamically from a workspace on Terraform 1.16.3, applied real AWS resources, then destroyed them  

### Minimal demo path (if the customer wants to reproduce)

```bash
# Local validation (Terraform >= 1.16)
./run-test.sh

# Remote apply / destroy on HCP Terraform
bash scripts/tfc-apply.sh
bash scripts/tfc-destroy.sh
```

---

## Related artifacts

- Repo: https://github.com/William-Hashicorp/tf-dynamic-variable  
- Workspace: https://app.terraform.io/app/William-Hashicorp/workspaces/tf-dynamic-module-source-test  
- Module: `app.terraform.io/William-Hashicorp/william-dynamic-s3/aws` @ `1.1.0`  
- Operator README: [`README.md`](./README.md)  
