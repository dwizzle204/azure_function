# Production Promotion Runbook

## Scope
This runbook covers promotion of an already-built artifact from stage to production and rollback for this repository's Azure Function deployment model.

## Preconditions
- `app-release.yml` has produced a versioned artifact.
- Terraform infrastructure is healthy and slots exist.
- Required reviewers approve `production` environment workflows.
- Required secrets and identities are configured.
- `production` environment variables are configured:
  - `PROD_FUNCTION_APP_NAME`
  - `PROD_RESOURCE_GROUP_NAME`
  - `PROD_STAGE_SLOT_NAME` (must match Terraform `stage_slot_name` in prod)

## Promotion Procedure
1. Identify the artifact version and the release workflow `run_id` from `app-release.yml`.
2. Run `app-deploy-stage.yml` (`workflow_dispatch`) with:
   - `artifact_version`
   - `source_run_id`
3. Validate stage behavior:
   - Function health endpoint
   - critical business path checks
   - logs/telemetry in Application Insights
4. Run `app-swap-slots.yml` (`workflow_dispatch`).
   - This workflow swaps `${PROD_STAGE_SLOT_NAME}` -> `production`.
5. Validate production behavior and monitor telemetry.

## Rollback Procedure
If post-swap validation fails:

1. Immediate rollback via reverse swap:
   - Run an explicit Azure CLI swap command using a break-glass operator identity:
     - `az functionapp deployment slot swap --name <app> --resource-group <rg> --slot production --target-slot <PROD_STAGE_SLOT_NAME>`
2. Re-validate production health and business paths.
3. If reverse swap is not acceptable:
   - Deploy a previously known-good artifact to stage using `app-deploy-stage.yml`.
   - Re-run swap to promote that known-good version.

## Evidence and Audit
- Link the relevant workflow runs:
  - release run
  - stage deploy run
  - swap (and rollback, if used) run
- Record:
  - artifact version
  - approver(s)
  - start/end time
  - validation results
  - incident/ticket reference (if rollback occurred)
