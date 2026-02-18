# Azure Function Service Repository

## Purpose
This repository contains both:
- Azure Function application code (`src/function_app`)
- Terraform infrastructure code (`infra`)

Infrastructure changes are executed through Terraform Cloud remote runs. GitHub Actions orchestrates plans/applies and application delivery.

## Identity Model
Identity is separated by environment and privilege.

### Application identities
- Deploy identity (`AZURE_CLIENT_ID_DEPLOY`): can deploy zip artifacts to the `stage` slot only.
- Promotion identity (`AZURE_CLIENT_ID_PROMOTION`): can perform slot swap/promotion only.

### Terraform identities
- Dev plan token (`TF_API_TOKEN_DEV_PLAN`): plan access to dev workspace only.
- Dev apply token (`TF_API_TOKEN_DEV_APPLY`): apply access to dev workspace only.
- Prod plan token (`TF_API_TOKEN_PROD_PLAN`): plan access to prod workspace only.
- Prod apply token (`TF_API_TOKEN_PROD_APPLY`): apply access to prod workspace only.

Production credentials/tokens must be stored only in the GitHub `production` environment.

## Deployment Workflow
Application delivery uses zip artifacts and slot-based promotion.

1. `app-ci.yml` (PR): lint, dependency install, local runtime smoke test using Azure Functions Core Tools, and packaging validation.
2. `app-release.yml` (push to `main`): build zip from `src/function_app` and publish versioned artifact.
3. `app-deploy-stage.yml` (manual): deploy selected artifact version to `stage` slot using deploy identity.
4. `app-swap-slots.yml` (manual): swap `stage` into `production` using promotion identity.

Production traffic is never deployed directly.

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
- Plan/apply workflows copy the matching env tfvars file into `infra/terraform.tfvars` before uploading configuration to Terraform Cloud.
- Remote runs upload from `infra` as the Terraform root module.

### Infra workflows
- `infra-validate.yml` (PR): `terraform fmt` and `terraform validate` only.
- `infra-plan-dev.yml` (PR): speculative remote plan in dev workspace.
- `infra-plan-prod.yml` (PR): speculative remote plan in prod workspace.
- `infra-apply-dev.yml` (push to `main`): remote apply in dev workspace.
- `infra-apply-prod.yml` (manual): remote apply in prod workspace, gated by `production` environment.

## Workflow Reference
Application workflows:
- `app-ci.yml`: pull request quality gate for app code only (no deploy).
- `app-release.yml`: builds and publishes versioned app artifact on `main`.
- `app-deploy-stage.yml`: manual deploy of selected artifact version to stage slot.
- `app-swap-slots.yml`: manual stage-to-production slot swap.

Infrastructure workflows:
- `infra-validate.yml`: PR formatting and validation checks only.
- `infra-plan-dev.yml`: PR speculative remote plan for dev workspace.
- `infra-plan-prod.yml`: PR speculative remote plan for prod workspace.
- `infra-apply-dev.yml`: automatic remote apply on merge to `main` for dev.
- `infra-apply-prod.yml`: manual remote apply for prod, gated by `production`.

## Promotion Process
Promotion to production is a controlled, manual step.

1. Build and publish a versioned artifact from `main`.
2. Manually deploy that artifact to the `stage` slot.
3. Validate behavior in stage.
4. Manually run slot swap to promote stage to production.

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
- `AZURE_CLIENT_ID_DEPLOY` (non-prod scope where possible)
- `TF_API_TOKEN_DEV_PLAN`
- `TF_API_TOKEN_DEV_APPLY`
- `TF_API_TOKEN_PROD_PLAN` (restrict appropriately)

`production` environment only:
- `AZURE_CLIENT_ID_PROMOTION`
- `TF_API_TOKEN_PROD_APPLY`
- Any additional prod-only credentials

### Branch protection
Configure branch protection on `main` to require:
- Pull request review approval
- Required status checks for CI and Terraform plan workflows
- No direct pushes by default

Reference baseline: `.github/branch-protection.md`

### Terraform Cloud setup
- Create organization and workspaces matching naming convention:
  - `<repo-name>-dev`
  - `<repo-name>-prod`
- Configure workspace permissions/tokens to enforce plan/apply separation.
- Ensure workspace variable sets do not duplicate env-specific tfvars values.

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
