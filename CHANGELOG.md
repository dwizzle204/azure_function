## [0.2.8] - 2026-02-21

### Changed
- Fixed deterministic Storage Account naming for Terraform template safety across environments/subscriptions:
  - Storage name now uses workspace-aware prefix plus deterministic hash suffix derived from workspace + subscription context.
- Updated repository documentation to codify globally unique Azure naming requirements for template consumers:
  - Added naming guidance in `README.md` Terraform Cloud setup section.
  - Added naming traceability hardening rule in `azure-function-repo-standard.md`.

## [0.2.7] - 2026-02-21

### Changed
- Implemented senior cloud-engineering alignment for slot-driven promotion:
  - `app-deploy-stage.yml` now deploys to `PROD_STAGE_SLOT_NAME` (from GitHub production environment variables).
  - `app-swap-slots.yml` now swaps `${PROD_STAGE_SLOT_NAME}` to `production`.
- Corrected Function App public network access logic to use resolved private endpoint state (`local.function_app_private_endpoint_enabled`) rather than raw toggle intent.
- Added fail-fast Terraform validations for networking toggles to prevent silent no-op configurations:
  - VNet integration now requires `function_app_integration_subnet_id`.
  - Storage private endpoint now requires both `private_endpoint_subnet_id` and `storage_private_dns_zone_id`.
  - Function App private endpoint now requires both `private_endpoint_subnet_id` and `function_app_private_dns_zone_id`.
- Updated repository documentation and runbook to include `PROD_STAGE_SLOT_NAME` setup and operational behavior.

## [0.2.6] - 2026-02-21

### Changed
- Hardened production deployment workflows to remove free-form app/slot targeting:
  - `app-deploy-stage.yml` now deploys only to the fixed production Function App from `PROD_FUNCTION_APP_NAME`.
  - `app-swap-slots.yml` now performs fixed `stage` -> `production` swap using `PROD_FUNCTION_APP_NAME` and `PROD_RESOURCE_GROUP_NAME`.
- Added explicit validation checks for required production GitHub environment variables in deployment workflows.
- Pinned Terraform provider and module versions for deterministic dependency selection:
  - `hashicorp/azurerm` pinned to `4.61.0`
  - `Azure/avm-res-keyvault-vault/azurerm` pinned to `0.10.2`
- Added and committed `infra/.terraform.lock.hcl`.
- Updated README, standards, Copilot instructions, and promotion runbook to match the hardened workflow model.

## [0.2.5] - 2026-02-19

### Changed
- Final repo polish for release readiness, including cross-file consistency checks across workflows, Terraform layout, and documentation.
- Version/changelog alignment cleanup to keep release tagging deterministic.

## [0.2.4] - 2026-02-18

### Added
- Optional Terraform networking controls for per-environment VNet integration and per-resource private endpoints (storage and function app).
- Optional Key Vault support via `Azure/avm-res-keyvault-vault/azurerm` with private-access defaults.
- Terrascan IaC scanning in both Terraform plan workflows prior to Terraform Cloud run creation.

### Changed
- `app-deploy-stage.yml` is now hard-locked to deploy only to the `stage` slot.
- README identity section now explicitly includes the dedicated dev deploy identity.
- Added production slot-swap app setting safeguards for sticky diagnostics/extension behavior.
- Replaced custom Function App/Storage/private endpoint Terraform resources with the AVM module `Azure/avm-ptn-function-app-storage-private-endpoints/azurerm`.
- Terraform now assumes resource groups are pre-created by subscription bootstrap and references them by `resource_group_name` input.
- Removed placeholder Terraform outputs that were always `null` to keep module outputs clean.

## [0.1.0] - 2026-02-18

### Added
- Repository scaffold for Azure Function app + Terraform Cloud infrastructure.
- Minimal Python Azure Function sample (`HttpExample`) with host/runtime config.
- Terraform base configuration for remote execution, shared config, and stage slot resources.
- Environment-specific Terraform variable files for dev/prod.
- Full GitHub workflow set for app CI/release/deploy/swap and infra validate/plan/apply.
- CODEOWNERS ownership split for app, infra, and workflow governance.
- README operational documentation for identity, deployment, promotion, and setup.
- `Makefile` for local developer parity commands (`install-dev`, `lint`, `test`, `package`).
- Production promotion and rollback runbook at `docs/production-promotion-runbook.md`.
- `app-deploy-dev.yml` manual workflow for non-release deployment directly to dedicated dev Function App.
- `version-bump-check.yml` PR guard requiring `VERSION` updates when `src/**` or `infra/**` changes.

### Changed
- App CI now includes local Azure Functions Core Tools smoke test in addition to linting and package validation.
- Terraform plan/apply workflows now load environment-specific tfvars explicitly by copying `infra/env/<env>.tfvars` to `infra/terraform.tfvars` before Terraform Cloud remote runs.
- Terraform Cloud upload directory in plan/apply workflows is now `infra`.
- Documentation now explicitly separates non-release dev deployment from release/stage/production promotion path.
- Terraform slot strategy is now environment-driven: dev disables stage slot; prod enables stage slot for swap-based promotion.
- Terraform hardening baseline expanded for Function App, Storage, and Key Vault (managed identity, TLS/FTPS settings, storage safety defaults, and Key Vault RBAC + purge protection).
- Terraform now supports optional per-environment network isolation controls for VNet integration and private endpoints (storage, key vault, function app) with optional private DNS zone binding.
