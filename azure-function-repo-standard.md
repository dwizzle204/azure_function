# Azure Function Repository Standard (Combined App + Terraform Cloud Infrastructure)

## Purpose

This document defines the required repository structure, identity model, and deployment workflows for Azure Function services.

Each Azure Function repository contains:
- application source code
- Terraform infrastructure code
- GitHub workflows for build and deployment

Infrastructure must be executed via Terraform Cloud remote execution using official HashiCorp GitHub Actions.

Goals:
- deterministic deployments
- traceability from repo -> workspace -> cloud resources
- least privilege identity separation
- controlled production promotion


---

# Repository Structure (Required)

```
azure-func-<name>/

README.md
CHANGELOG.md
VERSION
CODEOWNERS

.github/
  workflows/
    app-ci.yml
    app-release.yml
    app-deploy-dev.yml
    app-deploy-stage.yml
    app-swap-slots.yml
    infra-validate.yml
    infra-plan-dev.yml
    infra-plan-prod.yml
    infra-apply-dev.yml
    infra-apply-prod.yml

src/
  function_app/
    host.json
    requirements.txt
    <functions...>

tests/

infra/
  main.tf
  providers.tf
  variables.tf
  locals.tf
  outputs.tf

  env/
    dev.tfvars
    prod.tfvars

  modules/
```

---

# Application Delivery Model

Application code is packaged as a zip artifact.

Pipeline has two distinct paths:

## Dev validation path (non-release)

1. Build temporary package from selected git ref
2. Deploy to dedicated dev Function App (not a slot)
3. Validate in dev environment

Rules:

- must not deploy to stage slot
- must not deploy to production
- must use dedicated dev deploy identity
- dev environment infrastructure should use a single Function App instance without slots

## Release and promotion path

1. Build Python function
2. Package zip artifact
3. Publish versioned artifact
4. Manual workflow deploys artifact to stage slot
5. Separate workflow swaps stage into production

Production traffic must never be deployed directly.
Slot swap is the production promotion step.

## Slot Configuration Rules

- Slot creation must be variable-driven in Terraform.
- Dev environment must set:
  - `enable_stage_slot = false`
- Production environment must set:
  - `enable_stage_slot = true`
  - `stage_slot_name = "stage"` (or approved equivalent)

---

# Terraform Infrastructure Model

Terraform:

- must use Terraform Cloud remote execution
- must not run CLI plan/apply locally
- must use official HashiCorp GitHub Actions calling Terraform Cloud API

## Workspace Model

One workspace per environment:

```
azure-func-<name>-dev
azure-func-<name>-prod
```

Both use identical Terraform configuration.
Only tfvars differ.

## Remote Run Input Rules

Terraform Cloud remote runs must upload configuration from:

```
./infra
```

Plan/apply workflows must load env-specific values by copying:

```
infra/env/dev.tfvars  -> infra/terraform.tfvars
infra/env/prod.tfvars -> infra/terraform.tfvars
```

before upload-configuration is executed.

---

# Workflow Trigger Rules

## Dev infrastructure

Plan runs on:

- all pull requests (required branch protection check)

Apply runs automatically on merge to main.
Apply trigger scope:

- terraform file changes
- module changes
- dev tfvars change
- workflow file changes for the dev apply workflow

## Production infrastructure

Plan runs on:

- all pull requests (required branch protection check)

Apply runs only via:

```
workflow_dispatch
```

Production apply must never auto-run.
Production apply must require GitHub `production` environment approval.
Production apply dispatch input must require an approved change request number.

## Application workflows

`app-ci.yml` runs on pull request changes to:

- all pull requests (required branch protection check)

`app-release.yml` runs on push to `main` changes to:

- `src/**`
- `VERSION`
- `.github/workflows/app-release.yml`

`app-deploy-dev.yml` runs only via `workflow_dispatch` and deploys to dedicated dev Function App.

`app-deploy-stage.yml` and `app-swap-slots.yml` run only via `workflow_dispatch`.

---

# Identity Model (Required)

Use federated identity where supported.
Separate identities by:

- environment
- privilege level

## Application identities

### Dev deploy identity
Used for:
- deploy non-release package to dedicated dev Function App

Permissions:
- write dedicated dev Function App only

### Deploy identity
Used for:
- deploy zip to stage slot

Permissions:
- write stage slot only

### Promotion identity (production only)
Used for:
- slot swap

Permissions:
- swap slots only

## Terraform identities

### Dev plan identity
- plan only
- dev workspace scope

### Dev apply identity
- apply only
- dev workspace scope

### Prod plan identity
- plan only
- prod workspace scope

### Prod apply identity
- apply only
- stored only in GitHub production environment

## Required Secret Names

Application deployment:
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID_DEV_DEPLOY`
- `AZURE_CLIENT_ID_DEPLOY`
- `AZURE_CLIENT_ID_PROMOTION`

Terraform Cloud:
- `TF_API_TOKEN_DEV_PLAN`
- `TF_API_TOKEN_DEV_APPLY`
- `TF_API_TOKEN_PROD_PLAN`
- `TF_API_TOKEN_PROD_APPLY`

Required placement:
- `AZURE_CLIENT_ID_PROMOTION` and `TF_API_TOKEN_PROD_APPLY` must exist only in GitHub `production` environment.
- `AZURE_CLIENT_ID_DEV_DEPLOY` should be stored in GitHub `dev` environment.
- `AZURE_CLIENT_ID_DEPLOY` must be scoped to stage deployment permissions only.

---

# GitHub Environments (Required)

Create:

```
dev
production
```

Production must enforce:

- required reviewers
- restricted secrets
- promotion credentials only stored here
- prod apply credentials only stored here

This prevents PR workflows from accessing production identities.

---

# Workflow Security Requirements

Pull request workflows:

- may lint
- may test
- may build artifacts
- may run Terraform remote plan

Pull request workflows must never:

- deploy
- apply Terraform
- swap slots

Do not use:

```
pull_request_target
```

for deployment workflows.

## Workflow Concurrency Rules

The following workflows must define `concurrency` with `cancel-in-progress: false`:

- `app-deploy-dev.yml`
- `app-deploy-stage.yml`
- `app-swap-slots.yml`
- `infra-apply-dev.yml`
- `infra-apply-prod.yml`

---

# CODEOWNERS Requirement

CODEOWNERS must separate:

- infra ownership -> cloud engineering
- app ownership -> application engineering

Required protected paths:

```
infra/**
.github/workflows/**
CODEOWNERS
```

---

# Naming Traceability Requirement

The following must align:

- GitHub repository name
- Terraform Cloud workspace name
- Azure resource group
- Azure Function App name

This ensures full traceability:

repo -> workspace -> infrastructure -> cloud resource

---

# README Required Sections

Every repo must contain:

## Identity Model

Explain:

- deploy vs promotion identities
- Terraform workspace credentials
- production secrets stored only in GitHub environment

## Deployment Flow

Explain:

- build artifact
- deploy to stage
- manual slot swap

## Infrastructure Execution

Explain:

- Terraform Cloud remote execution
- GitHub orchestrates runs
- Terraform CLI not used locally

## Branch Protection

Document required branch protection status checks for `main`:

- `app-ci / validate`
- `infra-validate / terraform-validate`
- `infra-plan-dev / terraform-plan-dev`
- `infra-plan-prod / terraform-plan-prod`

---

# When Repo Separation Is Allowed

Separate infra and app repos only if:

- ownership teams differ completely
- release cadence differs materially
- infra reused across many apps
- regulatory separation required

Otherwise default is single combined repo.

---

# Summary

This repository model ensures:

- application and infrastructure remain traceable in one location
- Terraform Cloud executes all infrastructure changes
- GitHub orchestrates build and promotion workflows
- production deploys require explicit approval
- least privilege identities limit blast radius
- repository structure is predictable across all Azure Functions
