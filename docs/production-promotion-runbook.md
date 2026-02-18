# Production Promotion Runbook

## Scope
This runbook covers promotion of an already-built artifact from stage to production and rollback for this repository's Azure Function deployment model.

## Preconditions
- `app-release.yml` has produced a versioned artifact.
- Terraform infrastructure is healthy and slots exist.
- Required reviewers approve `production` environment workflows.
- Required secrets and identities are configured.

## Promotion Procedure
1. Identify the artifact version and the release workflow `run_id` from `app-release.yml`.
2. Run `app-deploy-stage.yml` (`workflow_dispatch`) with:
   - `artifact_version`
   - `source_run_id`
   - `function_app_name`
   - `slot_name` (default `stage`)
3. Validate stage behavior:
   - Function health endpoint
   - critical business path checks
   - logs/telemetry in Application Insights
4. Run `app-swap-slots.yml` (`workflow_dispatch`) with:
   - `function_app_name`
   - `resource_group_name`
   - `source_slot=stage`
   - `target_slot=production`
5. Validate production behavior and monitor telemetry.

## Rollback Procedure
If post-swap validation fails:

1. Immediate rollback via reverse swap:
   - Run `app-swap-slots.yml` with:
     - `source_slot=production`
     - `target_slot=stage`
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
