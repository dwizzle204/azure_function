# Infra Environment Expansion

This repository uses wrapper workflows that call centralized reusable workflows from `github_pipeline_governance`.

## Pattern
- Auto apply: lower-risk environments, `push` trigger.
- Manual apply: higher-risk environments, `workflow_dispatch` trigger.
- Environment selection is passed through wrapper inputs (`environment_name`, workspace, tfvars).

## Add a new plan wrapper (example: qa)
Create `.github/workflows/infra-plan-qa.yml`:

```yaml
name: infra-plan-qa

on:
  pull_request:

permissions:
  contents: read
  pull-requests: write

jobs:
  terraform-plan-qa:
    uses: your-org/github_pipeline_governance/.github/workflows/infra-plan.yml@v1.0.0
    with:
      tf_cloud_organization: replace-with-tfc-organization
      tf_workspace: ${{ github.event.repository.name }}-qa
      config_directory: ./infra
      tfvars_file: infra/env/qa.tfvars
      summary_title: Terraform Cloud QA Speculative Plan
    secrets:
      tf_api_token: ${{ secrets.TF_API_TOKEN_QA_PLAN }}
```

## Add a new manual apply wrapper (example: preprod)
Create `.github/workflows/infra-apply-preprod.yml`:

```yaml
name: infra-apply-preprod

on:
  workflow_dispatch:
    inputs:
      change_request_number:
        description: "Approved change request number"
        required: true
        type: string

permissions:
  contents: read

concurrency:
  group: terraform-apply-preprod
  cancel-in-progress: false

jobs:
  terraform-apply-preprod:
    uses: your-org/github_pipeline_governance/.github/workflows/infra-apply.yml@v1.0.0
    with:
      tf_cloud_organization: replace-with-tfc-organization
      tf_workspace: ${{ github.event.repository.name }}-preprod
      config_directory: ./infra
      tfvars_file: infra/env/preprod.tfvars
      apply_comment: "${{ format('Manual preprod apply (change request): {0}', inputs.change_request_number) }}"
      environment_name: preprod
    secrets:
      tf_api_token: ${{ secrets.TF_API_TOKEN_PREPROD_APPLY }}
```

## Add a new auto apply wrapper (example: qa)
Create `.github/workflows/infra-apply-qa.yml`:

```yaml
name: infra-apply-qa

on:
  push:
    branches:
      - main
    paths:
      - "infra/*.tf"
      - "infra/modules/**"
      - "infra/env/qa.tfvars"
      - ".github/workflows/infra-apply-qa.yml"

permissions:
  contents: read

concurrency:
  group: terraform-apply-qa
  cancel-in-progress: false

jobs:
  terraform-apply-qa:
    uses: your-org/github_pipeline_governance/.github/workflows/infra-apply.yml@v1.0.0
    with:
      tf_cloud_organization: replace-with-tfc-organization
      tf_workspace: ${{ github.event.repository.name }}-qa
      config_directory: ./infra
      tfvars_file: infra/env/qa.tfvars
      apply_comment: Automated qa apply from main branch
      environment_name: qa
    secrets:
      tf_api_token: ${{ secrets.TF_API_TOKEN_QA_APPLY }}
```

## Checklist for each new environment
- Create `infra/env/<env>.tfvars`.
- Create plan/apply tokens in GitHub secrets.
- Create optional GitHub environment (`qa`, `stage`, `preprod`) and approvals if needed.
- Add branch-protection required status checks if this environment must gate merges.
- Keep wrapper pinned to a governance tag; upgrade by tag bump.
