# Pipeline Governance Migration

This repository now uses wrapper workflows that delegate implementation to a centralized governance repository.

## Current Pointer
All wrappers point to:
- `your-org/github_pipeline_governance`
- tag: `v1.0.0`

## Required Follow-up
Before enabling in GitHub, replace:
- `your-org` with the real GitHub organization
- `replace-with-tfc-organization` with your Terraform Cloud organization

## Why wrappers remain
Wrappers keep repository-specific trigger behavior and environment wiring while centralizing pipeline logic.

## Source of Truth
- Update pipeline implementation in the governance repository, not in wrapper files.
- Update this repository by bumping the referenced governance tag in wrapper workflows.
