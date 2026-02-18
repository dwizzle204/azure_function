# Branch Protection Baseline (`main`)

Apply the following settings in GitHub repository settings for branch `main`.

## Protection Rules
- Require a pull request before merging.
- Require approvals (at least 1 reviewer).
- Dismiss stale approvals when new commits are pushed.
- Require status checks to pass before merging.
- Require branches to be up to date before merging.
- Restrict who can push directly to `main` (prefer no direct pushes).

## Required Status Checks
- `app-ci / validate`
- `infra-validate / terraform-validate`
- `infra-plan-dev / terraform-plan-dev`
- `infra-plan-prod / terraform-plan-prod`

## Environment Protection
- `production` environment must require reviewers.
- `production` environment holds prod-only secrets and credentials.
