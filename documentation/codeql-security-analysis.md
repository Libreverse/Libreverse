# CodeQL Security Analysis

This document describes how to use CodeQL for security analysis in the Libreverse project, both locally and in CI/CD.

## Overview

CodeQL is GitHub's static analysis engine that helps find security vulnerabilities and coding errors. This project is configured to analyze:

- **Ruby code** (Rails application, models, controllers, etc.)
- **JavaScript/TypeScript code** (Frontend assets, Stimulus controllers, etc.)

## Local Analysis

### Quick Start

1. **Run the analysis with the static script:**

    ```bash
    perl scripts/static.pl
    ```

    This automatically includes CodeQL analysis as part of the comprehensive static analysis suite.

2. **Run CodeQL analysis independently:**

    ```bash
    # Install CodeQL CLI (first time only)
    scripts/codeql-local.sh --install

    # Run analysis for all languages
    scripts/codeql-local.sh --create-db

    # Run analysis for specific language
    scripts/codeql-local.sh --language ruby --create-db
    scripts/codeql-local.sh --language javascript --create-db
    ```

3. **View results:**

    ```bash
    # View summary for all languages
    scripts/codeql-viewer.sh

    # View detailed findings
    scripts/codeql-viewer.sh --detailed

    # View results for specific language
    scripts/codeql-viewer.sh ruby --detailed --limit 5

    # List available result files
    scripts/codeql-viewer.sh --files
    ```

### Directory Structure

After running CodeQL locally, the following structure is created:

```text
.codeql/
├── codeql-cli/          # CodeQL CLI binaries
├── codeql-queries/      # Standard CodeQL queries and libraries
│   └── codeql-repo/     # GitHub's CodeQL repository
├── databases/           # Analysis databases
│   ├── ruby-database/
│   └── javascript-database/
└── results/             # Analysis results
    ├── ruby-results.sarif
    ├── ruby-results.txt
    ├── javascript-results.sarif
    └── javascript-results.txt
```

### Script Options

#### `scripts/codeql-local.sh`

```bash
# Install CodeQL CLI
scripts/codeql-local.sh --install

# Create databases and run analysis
scripts/codeql-local.sh --create-db

# Analyze specific languages
scripts/codeql-local.sh --language ruby,javascript --create-db

# Run analysis without creating new databases
scripts/codeql-local.sh --no-summary

# Get help
scripts/codeql-local.sh --help
```

#### `scripts/codeql-viewer.sh`

```bash
# Show summary for all languages
scripts/codeql-viewer.sh

# Show detailed findings
scripts/codeql-viewer.sh --detailed

# Limit number of detailed findings
scripts/codeql-viewer.sh --detailed --limit 10

# View specific language results
scripts/codeql-viewer.sh ruby --detailed

# List available files
scripts/codeql-viewer.sh --files

# Get help
scripts/codeql-viewer.sh --help
```

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

## Integration with Static Analysis

CodeQL is integrated into the main static analysis pipeline (`scripts/static.pl`):

1. **Sequential setup** - Creates databases for analysis
2. **Parallel analysis** - Runs Ruby and JavaScript analysis in parallel with other tools
3. **Result aggregation** - Exit codes contribute to overall static analysis status

## Troubleshooting

### Common Issues

1. **Database creation fails**

    ```bash
    # Ensure project dependencies are installed
    bundle install
    bun install

    # Try recreating databases
    rm -rf .codeql/databases/
    scripts/codeql-local.sh --create-db
    ```

2. **Analysis takes too long**

    ```bash
    # Analyze one language at a time
    scripts/codeql-local.sh --language ruby
    scripts/codeql-local.sh --language javascript
    ```

3. **No results shown**

    ```bash
    # Check if analysis completed successfully
    scripts/codeql-viewer.sh --files

    # Re-run analysis with verbose output
    scripts/codeql-local.sh --create-db
    ```

### Requirements

- **macOS/Linux** - CodeQL CLI supports macOS and Linux
- **curl** - For downloading CodeQL CLI
- **unzip** - For extracting CodeQL CLI
- **git** - For downloading CodeQL queries
- **jq** (optional) - For better result parsing and display

### Performance Tips

- **Incremental analysis** - Only recreate databases when code structure changes significantly
- **Language-specific analysis** - Use `--language` flag to analyze specific languages
- **Parallel execution** - The static.pl script runs analyses in parallel for better performance

## VS Code Integration

For the best experience viewing CodeQL results in VS Code:

1. Install the **SARIF Viewer** extension
2. Open SARIF files directly: `.codeql/results/*.sarif`
3. Use the Problems panel to see findings inline with your code

## Security Considerations

- **Local databases** - Contains analyzed code structure, added to `.gitignore`
- **Result files** - May contain file paths and code snippets, also ignored
- **CI/CD results** - Uploaded to GitHub Security tab, visible to repository collaborators

## Further Reading

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [CodeQL Query Reference](https://codeql.github.com/codeql-standard-libraries/)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [SARIF Format Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
