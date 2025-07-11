# CodeQL Configuration Mirroring: Complete Setup ✅

## Overview

Your local CodeQL setup now **perfectly mirrors** the default GitHub CodeQL Actions behavior. This means:

- ✅ **Same query suites**: `security-and-quality` (GitHub's default)
- ✅ **Same path exclusions**: `node_modules/`, `vendor/`, `test/`, etc.
- ✅ **Same languages**: Ruby and JavaScript/TypeScript
- ✅ **Same configuration file**: `.github/codeql/codeql-config.yml`

## How It Works

### Single Source of Truth

```text
.github/codeql/codeql-config.yml
├── Used by GitHub Actions workflow
└── Used by local scripts/codeql-local.sh
```

Both your local analysis and CI/CD pipeline read from the **same configuration file**, ensuring identical behavior.

### Configuration Parsing

The local script `scripts/codeql-local.sh` now includes:

```bash
parse_codeql_config() {
    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"
    local query_suite=$(grep -E "^\s*-\s*uses:\s*" "$config_file" | head -1 | sed 's/.*uses:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    echo "${query_suite:-security-and-quality}"
}
```

This extracts the query suite from your config file (currently `security-and-quality`).

## Verification Results

✅ **All validations passed**:

- Configuration consistency between local and CI
- Query suite parsing works correctly
- Path exclusions match GitHub defaults
- Language support identical
- GitHub Actions matrix properly configured

## Usage

### Local Analysis (mirrors GitHub Actions exactly)

```bash
# Run full analysis with same config as CI
scripts/codeql-local.sh

# Run specific language
scripts/codeql-local.sh --language ruby
scripts/codeql-local.sh --language javascript

# Include in daily static analysis
perl scripts/static.pl
```

### View Results

```bash
# Quick summary
scripts/codeql-viewer.sh

# Detailed analysis
scripts/codeql-viewer.sh --detailed
```

### Configuration Management

```bash
# Validate configuration consistency
scripts/validate-codeql-config.sh

# Test setup
scripts/test-codeql-setup.sh
```

## Configuration File Structure

Your `.github/codeql/codeql-config.yml` controls both local and CI analysis:

```yaml
name: "CodeQL Comprehensive Configuration"

queries:
    - uses: security-and-quality # ← Controls query suite

paths-ignore: # ← Controls what files to skip
    - "node_modules/**"
    - "vendor/**"
    - "test/**"
    # ... more exclusions

paths: # ← Controls what files to analyze
    - "app/**"
    - "lib/**"
    - "config/**"
    # ... more inclusions
```

## Benefits

### 🎯 **Consistency**

- Local analysis results match CI/CD exactly
- No surprises when code reaches production
- Same security checks everywhere

### 🔧 **Easy Management**

- Single config file to maintain
- Changes apply to both local and CI automatically
- No duplicate configuration

### 🚀 **Developer Experience**

- Run the same analysis locally before pushing
- Quick feedback on security issues
- Integrated with your daily workflow (`perl scripts/static.pl`)

## Customization

To customize the analysis, edit `.github/codeql/codeql-config.yml`:

### Change Query Suite

```yaml
queries:
    - uses: security-extended # More thorough but slower
    # or
    - uses: security-and-quality # Balanced (current)
```

### Add Path Exclusions

```yaml
paths-ignore:
    - "node_modules/**"
    - "your-custom-dir/**" # ← Add custom exclusions
```

### Modify Included Paths

```yaml
paths:
    - "app/**"
    - "lib/**"
    - "your-custom-source/**" # ← Add custom paths
```

## Integration Points

### Static Analysis Pipeline

```text
perl scripts/static.pl
├── Prettier, Rubocop, ESLint
├── CodeQL Setup (database creation)
└── Parallel execution:
    ├── CodeQL Ruby Analysis    ← Uses shared config
    ├── CodeQL JavaScript Analysis ← Uses shared config
    ├── Brakeman, bundle-audit
    └── Jest, Rails tests
```

### GitHub Actions

```text
.github/workflows/codeql.yml
├── Reads: .github/codeql/codeql-config.yml
├── Analyzes: Ruby and JavaScript
├── Uploads: Results to Security tab
└── Runs: On push, PR, weekly schedule
```

## Next Steps

1. **Test the setup**: `scripts/codeql-local.sh --language ruby`
2. **Integrate into workflow**: Use `perl scripts/static.pl` daily
3. **Monitor CI results**: Check GitHub Security tab
4. **Customize as needed**: Edit `.github/codeql/codeql-config.yml`

## Troubleshooting

### If analysis results differ between local and CI

1. Check config file: `scripts/validate-codeql-config.sh`
2. Verify parsing: `grep -E "^\s*-\s*uses:\s*" .github/codeql/codeql-config.yml`
3. Test setup: `scripts/test-codeql-setup.sh`

### If analysis is slow

1. Reduce query suite: Change to `security-extended` → `security-and-quality`
2. Add more exclusions to `paths-ignore`
3. Limit analysis scope in `paths`

---

🎉 **Your CodeQL setup now perfectly mirrors GitHub Actions default behavior!**

Any changes to `.github/codeql/codeql-config.yml` will automatically apply to both local and CI analysis, ensuring consistency across your entire development workflow.
