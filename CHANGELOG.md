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

### Changed
- App CI now includes local Azure Functions Core Tools smoke test in addition to linting and package validation.
- Terraform plan/apply workflows now load environment-specific tfvars explicitly by copying `infra/env/<env>.tfvars` to `infra/terraform.tfvars` before Terraform Cloud remote runs.
- Terraform Cloud upload directory in plan/apply workflows is now `infra`.
- Documentation now explicitly separates non-release dev deployment from release/stage/production promotion path.
- Terraform slot strategy is now environment-driven: dev disables stage slot; prod enables stage slot for swap-based promotion.
