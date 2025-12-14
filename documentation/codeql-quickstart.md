# CodeQL Quick Start Guide

CodeQL analysis runs via GitHub Actions (code scanning) for this repository.

Local CodeQL runner/setup scripts have been removed; use the workflow to generate and publish results.

## Where it’s configured

- Workflow: `.github/workflows/codeql.yml`
- Config: `.github/codeql/codeql-config.yml`
- Reusable action: `.github/actions/codeql-analysis/action.yml`

## Where to find results

- GitHub UI: **Security → Code scanning alerts**
- For a specific run: **Actions → CodeQL workflow run** (job logs and any uploaded artifacts)

## What’s analyzed

- Ruby (Rails app code)
- JavaScript/TypeScript (frontend code)
