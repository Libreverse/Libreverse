# CodeQL Security Analysis

This repository is configured to run CodeQL in GitHub Actions (code scanning).

Local CodeQL runner/setup scripts are intentionally **not** included or maintained.

## Overview

CodeQL is GitHub's static analysis engine that helps find security vulnerabilities and coding errors. This project is configured to analyze:

- **Ruby code** (Rails application, models, controllers, etc.)
- **JavaScript/TypeScript code** (Frontend assets, Stimulus controllers, etc.)

## CI/CD Integration

### GitHub Actions

CodeQL analysis runs automatically on:

- **Push to main branch**
- **Pull requests to main branch**
- **Weekly schedule** (Sundays at 2:15 AM)

The workflow analyzes both Ruby and JavaScript/TypeScript code in parallel and uploads results to GitHub Security tab.

### Workflow Files

- `.github/workflows/codeql.yml` - Main CodeQL workflow
- `.github/codeql/codeql-config.yml` - CodeQL configuration

### Configuration

The CodeQL analysis includes:

- **Security queries** - Find security vulnerabilities
- **Quality queries** - Find code quality issues
- **Custom paths** - Focused on application code, excluding dependencies

Ignored paths:

- `node_modules/`
- `vendor/`
- `coverage/`
- `tmp/`
- `log/`
- `storage/`
- `licenses/`
- `public/assets/`
- `db/migrate/`

## Understanding Results

### SARIF Format

Results are provided in SARIF (Static Analysis Results Interchange Format):

- **Machine-readable** - Can be imported into various tools
- **Rich metadata** - Includes severity, rule information, and fix suggestions
- **VS Code support** - Install "SARIF Viewer" extension for visual inspection

### Result Interpretation

**Severity Levels:**

- 🚨 **Error** - High-priority security issues or critical bugs
- ⚠️ **Warning** - Medium-priority issues that should be addressed
- ℹ️ **Note** - Low-priority suggestions and style improvements

**Common Ruby Findings:**

- SQL injection vulnerabilities
- Cross-site scripting (XSS) risks
- Unsafe deserialization
- Information exposure
- Path traversal vulnerabilities

**Common JavaScript Findings:**

- DOM-based XSS
- Prototype pollution
- Unsafe HTML construction
- Missing input validation
- Client-side code injection

## Viewing results in VS Code

If the workflow uploads SARIF artifacts, you can download them from the workflow run and open them locally.

For a nicer UI, install the **SARIF Viewer** extension in VS Code.

## Troubleshooting (CI)

If the CodeQL workflow fails:

1. Check the failing job logs in GitHub Actions.
2. Common causes are dependency install failures or build steps that are required for extraction.
3. If you change what should be analyzed/excluded, update `.github/codeql/codeql-config.yml` accordingly.

## Further Reading

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [CodeQL Query Reference](https://codeql.github.com/codeql-standard-libraries/)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [SARIF Format Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
