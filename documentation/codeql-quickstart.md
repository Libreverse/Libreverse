# CodeQL Quick Start Guide

## Immediate Setup

Run this command to set up CodeQL locally:

```bash
# Install and test CodeQL setup
scripts/test-codeql-setup.sh
```

## Run Analysis

```bash
# Quick analysis via static.pl (includes CodeQL)
perl scripts/static.pl

# Or run CodeQL independently
scripts/codeql-local.sh --create-db

# View results
scripts/codeql-viewer.sh --detailed
```

## Files Created

- `.github/workflows/codeql.yml` - GitHub Actions workflow
- `.github/codeql/codeql-config.yml` - CodeQL configuration
- `.github/actions/codeql-analysis/action.yml` - Reusable action
- `scripts/codeql-local.sh` - Local analysis script
- `scripts/codeql-viewer.sh` - Results viewer
- `scripts/test-codeql-setup.sh` - Setup verification
- `documentation/codeql_security_analysis.md` - Full documentation

## Integration Points

1. **static.pl script** - CodeQL is now part of the static analysis pipeline
2. **GitHub Actions** - Runs on push/PR to main branch
3. **Local development** - Use scripts for manual analysis

## What CodeQL Analyzes

### Ruby

- SQL injection vulnerabilities
- Cross-site scripting (XSS) risks
- Unsafe deserialization
- Information exposure
- Path traversal vulnerabilities

### JavaScript/TypeScript

- DOM-based XSS
- Prototype pollution
- Unsafe HTML construction
- Missing input validation
- Client-side code injection

## Results Location

- Local: `.codeql/results/`
- GitHub: Security tab in repository
- CI artifacts: Downloaded from Actions

## Next Steps

1. Run the test script to verify setup
2. Execute your first analysis
3. Review results and address findings
4. Set up regular analysis schedule
