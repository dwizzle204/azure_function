# Azure Function Service Repository

## Educational Use Only
This repository is a learning template, not a production-ready baseline.
It demonstrates patterns for Azure Functions, Terraform, and GitHub Actions governance.
Validate security, compliance, reliability, and operational controls before using any part of this in production.

## Purpose
This repository contains both:
- Azure Function application code (`src/function_app`)
- Terraform infrastructure code (`infra`)

Infrastructure changes are executed through Terraform Cloud remote runs. GitHub Actions orchestrates plans/applies and application delivery.

## Identity Model
Identity is separated by environment and privilege.

### Application identities
- Dev deploy identity (`AZURE_CLIENT_ID_DEV_DEPLOY`): can deploy non-release packages to the dedicated dev Function App only.
- Deploy identity (`AZURE_CLIENT_ID_DEPLOY`): can deploy zip artifacts to the `stage` slot only.
- Promotion identity (`AZURE_CLIENT_ID_PROMOTION`): can perform slot swap/promotion only.

### Terraform identities
- Dev plan token (`TF_API_TOKEN_DEV_PLAN`): plan access to dev workspace only.
- Dev apply token (`TF_API_TOKEN_DEV_APPLY`): apply access to dev workspace only.
- Prod plan token (`TF_API_TOKEN_PROD_PLAN`): plan access to prod workspace only.
- Prod apply token (`TF_API_TOKEN_PROD_APPLY`): apply access to prod workspace only.

Production credentials/tokens must be stored only in the GitHub `production` environment.

## Deployment Workflow
Application delivery uses two paths: non-release dev deployment and release promotion.
Local workflow files in this repo are wrappers; executable workflow logic is centralized in `github_pipeline_governance`.

1. `app-ci.yml` (PR): lint, dependency install, local runtime smoke test using Azure Functions Core Tools, and packaging validation.
2. `app-deploy-dev.yml` (manual): build temporary package from selected git ref and deploy directly to dedicated dev Function App (no stage slot).
3. `app-release.yml` (push to `main`): build zip from `src/function_app` and publish versioned artifact.
4. `app-deploy-stage.yml` (manual): deploy selected release artifact version to the production pre-production slot (`PROD_STAGE_SLOT_NAME`) using stage deploy identity.
5. `app-swap-slots.yml` (manual): swap `PROD_STAGE_SLOT_NAME` into `production` using promotion identity.

Production traffic is never deployed directly.

## Slot Strategy
- Dev environment uses a single dedicated Function App without deployment slots (`enable_stage_slot = false`).
- Production environment uses swap-based promotion with a stage slot (`enable_stage_slot = true`, `stage_slot_name = "stage"`).
- `app-deploy-stage.yml` and `app-swap-slots.yml` are for production promotion path only.
- Slot swap hardening settings are applied in app configuration:
  - `WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS=0`
  - `WEBSITE_OVERRIDE_STICKY_EXTENSION_VERSIONS=0`

## Local Developer Commands
Use the repository `Makefile` to align local checks with CI:

- `make install-dev` installs app and dev tooling dependencies.
- `make lint` runs Python lint checks used by CI.
- `make test` runs sample unit tests.
- `make package` builds the app zip artifact.

## Terraform Cloud Execution Model
Terraform is executed remotely in Terraform Cloud using official HashiCorp GitHub actions.

- Local `terraform plan/apply` is not part of delivery.
- One workspace per environment:
  - `<repo-name>-dev`
  - `<repo-name>-prod`
- Same Terraform code is used across environments; environment-specific values live in:
  - `infra/env/dev.tfvars`
  - `infra/env/prod.tfvars`
- Resource groups are expected to be pre-created by subscription bootstrap and referenced by `resource_group_name`.
- Plan/apply wrappers pass env-specific tfvars and Terraform root inputs to centralized reusable workflows.
- Remote runs upload from `infra` as the Terraform root module.
- Provider/module versions are pinned in code and `infra/.terraform.lock.hcl` is committed for deterministic provider selection.

## Infrastructure Hardening Baseline
Infrastructure is provisioned via `Azure/avm-ptn-function-app-storage-private-endpoints/azurerm`.

- Function App and stage slot use:
  - system-assigned managed identity
  - HTTPS only
  - minimum TLS 1.2
  - FTPS disabled
  - HTTP/2 enabled
- Storage account uses:
  - secure storage defaults from the AVM module
- Optional Key Vault is provisioned via `Azure/avm-res-keyvault-vault/azurerm` with secure defaults:
  - `public_network_access_enabled = false`
  - private endpoint enabled by default when Key Vault is enabled (`enable_key_vault_private_endpoint = true`)

## Network Isolation Options
Optional network controls are available per environment via tfvars:

- VNet integration (Function App):
  - `enable_vnet_integration`
  - `function_app_integration_subnet_id`
- Private endpoints:
  - shared subnet input: `private_endpoint_subnet_id`
  - storage blob: `enable_storage_private_endpoint`, `storage_private_dns_zone_id`
  - function app: `enable_function_app_private_endpoint`, `function_app_private_dns_zone_id`
  - key vault: `enable_key_vault`, `enable_key_vault_private_endpoint`, `key_vault_private_dns_zone_id`

All are disabled by default and can be enabled per environment.
Subnet IDs are expected to reference existing bootstrap network resources.

### Infra workflows
- `infra-validate.yml` (PR wrapper): invokes centralized Terraform validate reusable workflow.
- `infra-plan-dev.yml` (PR wrapper): invokes centralized dev speculative plan reusable workflow.
- `infra-plan-prod.yml` (PR wrapper): invokes centralized prod speculative plan reusable workflow.
- `infra-apply-dev.yml` (push wrapper): invokes centralized dev apply reusable workflow.
- `infra-apply-prod.yml` (manual wrapper): invokes centralized prod apply reusable workflow, gated by `production` environment.

## Workflow Reference
Application workflows:
- `app-ci.yml`: PR wrapper for centralized CI checks.
- `app-deploy-dev.yml`: manual wrapper for centralized dev deploy workflow.
- `app-release.yml`: push-to-main wrapper for centralized artifact build/publish workflow.
- `app-deploy-stage.yml`: manual wrapper for centralized stage deploy workflow, including release provenance checks.
- `app-swap-slots.yml`: manual wrapper for centralized slot swap workflow.

Infrastructure workflows:
- `infra-validate.yml`: PR wrapper for centralized formatting and validation checks.
- `infra-plan-dev.yml`: PR wrapper for centralized dev speculative plan.
- `infra-plan-prod.yml`: PR wrapper for centralized prod speculative plan.
- `infra-apply-dev.yml`: push wrapper for centralized dev apply.
- `infra-apply-prod.yml`: manual wrapper for centralized prod apply.

## Promotion Process
Promotion to production is a controlled, manual step.

1. Build and publish a versioned artifact from `main`.
2. Manually deploy that artifact to the pre-production slot (`PROD_STAGE_SLOT_NAME`).
3. Validate behavior in the pre-production slot.
4. Manually run slot swap to promote that slot to production.

This process provides deterministic promotion and a clear audit trail.

Operational procedure reference: `docs/production-promotion-runbook.md`

## Pre-Setup Requirements
Complete the following before running workflows.

### GitHub environments
Create environments:
- `dev`
- `production`

Configure `production` with:
- Required reviewers for manual approvals.
- Restricted environment secrets.
- Promotion and prod-apply credentials only.

### Required secrets
Repository-level (or `dev` environment where preferred):
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID_DEV_DEPLOY` (dev app deploy only)
- `AZURE_CLIENT_ID_DEPLOY` (non-prod scope where possible)
- `TF_API_TOKEN_DEV_PLAN`
- `TF_API_TOKEN_DEV_APPLY`
- `TF_API_TOKEN_PROD_PLAN` (restrict appropriately)

`production` environment only:
- `AZURE_CLIENT_ID_PROMOTION`
- `TF_API_TOKEN_PROD_APPLY`
- Any additional prod-only credentials

### Required GitHub Variables
Set these in the `production` environment to hard-lock deployment targets:
- `PROD_FUNCTION_APP_NAME`
- `PROD_RESOURCE_GROUP_NAME`
- `PROD_STAGE_SLOT_NAME` (must match Terraform `stage_slot_name` for production)

### Branch protection
Configure branch protection on `main` to require:
- Pull request review approval
- Required status checks for CI and Terraform plan workflows
- No direct pushes by default

Reference baseline: `.github/branch-protection.md`

### Versioning guard
- `version-bump-check.yml` enforces that `VERSION` must be updated in any PR that changes `src/**` or `infra/**`.

### Terraform Cloud setup
- Create organization and workspaces matching naming convention:
  - `<repo-name>-dev`
  - `<repo-name>-prod`
- Configure workspace permissions/tokens to enforce plan/apply separation.
- Ensure workspace variable sets do not duplicate env-specific tfvars values.
- Ensure pre-created resource groups exist and are set in `infra/env/*.tfvars`.
- Storage account naming is deterministic and globally unique per environment/subscription:
  - prefix derives from `project_name` + workspace
  - suffix derives from hash(workspace + subscription ID)
- If enabling network isolation features, ensure required VNet/subnets/private DNS zones already exist and pass their IDs in tfvars.

### Azure identity setup
- Configure federated credentials for GitHub OIDC on deploy and promotion app registrations.
- Scope role assignments to least privilege:
  - deploy identity: stage slot deployment permissions only
  - promotion identity: slot swap permissions only

## Governance
`CODEOWNERS` enforces separation of responsibilities:
- `infra/**` owned by cloud engineering
- `src/**` and `tests/**` owned by application engineering
- `.github/workflows/**` and `CODEOWNERS` protected by shared ownership

## Pipeline Governance Model
Workflows under `.github/workflows` are wrapper workflows that call reusable workflows from a centralized governance repository pinned by version tag.
Behavior changes should be made in the governance repository and consumed here by tag upgrade.

Migration details: `docs/pipeline-governance-migration.md`
