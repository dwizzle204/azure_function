# Copilot Instructions

## Source of Truth
- Treat `azure-function-repo-standard.md` as the canonical repository standard.
- Keep app, infrastructure, and workflow changes aligned with that standard.

## Repository Model
- This is a combined app + infrastructure repository.
- Application code lives in `src/function_app`.
- Terraform code lives in `infra` with env values only in `infra/env/*.tfvars`.

## Delivery and Promotion Rules
- Do not deploy directly to production.
- Deploy artifacts to the `stage` slot first, then promote via slot swap.
- Keep production operations manual and approval-gated.
- `app-ci.yml`: PR trigger for `src/**`, `tests/**`, and workflow file changes.
- `app-deploy-dev.yml`: `workflow_dispatch` only, deploys non-release package directly to dedicated dev Function App (no slot).
- `app-release.yml`: push to `main` trigger for `src/**`, `VERSION`, and workflow file changes.
- `app-deploy-stage.yml` and `app-swap-slots.yml`: `workflow_dispatch` only.
- Dev environment must be single-slot (no stage slot); production uses stage slot + swap promotion.

## Terraform Rules
- Use Terraform Cloud remote execution through official HashiCorp GitHub Actions.
- Do not introduce local `terraform plan`/`terraform apply` execution into delivery workflows.
- Preserve workspace split: `<repo>-dev` and `<repo>-prod`.
- For remote plan/apply workflows, ensure the correct env file is loaded by copying:
  - `infra/env/dev.tfvars` -> `infra/terraform.tfvars` (dev workflows)
  - `infra/env/prod.tfvars` -> `infra/terraform.tfvars` (prod workflows)
- Upload Terraform Cloud configuration from `infra` as the root module directory.
- Infra triggers:
  - Dev plan: PR on `infra/*.tf`, `infra/modules/**`, `infra/env/dev.tfvars`, workflow file.
  - Prod plan: PR on `infra/*.tf`, `infra/modules/**`, `infra/env/prod.tfvars`, workflow file.
  - Dev apply: push to `main` on `infra/*.tf`, `infra/modules/**`, `infra/env/dev.tfvars`, workflow file.
  - Prod apply: `workflow_dispatch` only.
- Apply/deploy workflows must define `concurrency` with `cancel-in-progress: false`.

## Identity and Secrets
- Preserve least-privilege identity separation:
  - app deploy identity (stage deploy only)
  - app promotion identity (slot swap only)
  - separate dev/prod Terraform plan/apply credentials
- Keep production-only credentials in the GitHub `production` environment.
- Required secret names:
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_CLIENT_ID_DEV_DEPLOY`
  - `AZURE_CLIENT_ID_DEPLOY`
  - `AZURE_CLIENT_ID_PROMOTION`
  - `TF_API_TOKEN_DEV_PLAN`
  - `TF_API_TOKEN_DEV_APPLY`
  - `TF_API_TOKEN_PROD_PLAN`
  - `TF_API_TOKEN_PROD_APPLY`
- `AZURE_CLIENT_ID_PROMOTION` and `TF_API_TOKEN_PROD_APPLY` are production-environment-only.
- `AZURE_CLIENT_ID_DEV_DEPLOY` should be kept in GitHub `dev` environment.

## Workflow Security
- PR workflows may lint/test/build/plan, but must not deploy, apply, or swap slots.
- Avoid `pull_request_target` for deployment-related workflows.

## Governance
- Maintain ownership boundaries in `CODEOWNERS`:
  - `infra/**` -> cloud engineering
  - `src/**` and `tests/**` -> application engineering
  - `.github/workflows/**` and `CODEOWNERS` protected by shared ownership

## Implementation Guidance
- Prefer minimal, deterministic changes.
- Keep naming traceable across repository, Terraform workspace, and Azure resources.
- Update `README.md`, `CHANGELOG.md`, and workflow docs when behavior changes.
- Keep local developer commands aligned with CI via `Makefile` targets.
- Keep production promotion and rollback guidance aligned with `docs/production-promotion-runbook.md`.
- Keep branch protection required checks aligned:
  - `app-ci / validate`
  - `infra-validate / terraform-validate`
  - `infra-plan-dev / terraform-plan-dev`
  - `infra-plan-prod / terraform-plan-prod`
- Required-check workflows should run on all pull requests (no path filters) to avoid merge deadlocks.
