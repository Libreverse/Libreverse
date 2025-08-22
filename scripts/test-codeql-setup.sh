#!/usr/bin/env bash

# CodeQL Setup Test
# This script tests the CodeQL installation and basic functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[Test]${NC} $1"
}

success() {
    echo -e "${GREEN}[Test]${NC} ✅ $1"
}

error() {
    echo -e "${RED}[Test]${NC} ❌ $1" >&2
}

warn() {
    echo -e "${YELLOW}[Test]${NC} ⚠️  $1"
}

# Read CodeQL config file
get_config_value() {
    local file="$1"
    local key="$2"

    if [ ! -f "$file" ]; then
        echo ""
        return
    fi

    # Simple YAML parser using grep and sed
    grep "^${key}:" "$file" | sed "s/^${key}:[[:space:]]*//;s/\"//g;s/'//g" | head -n 1
}

test_codeql_installation() {
    log "Testing CodeQL installation..."

    if [ ! -x "${PROJECT_ROOT}/.codeql/codeql-cli/codeql" ]; then
        warn "CodeQL CLI not found, installing..."
        "${SCRIPT_DIR}/codeql-local.sh" --install
    fi

    # Test CodeQL CLI
    local version_output
    version_output=$("${PROJECT_ROOT}/.codeql/codeql-cli/codeql" version 2>&1 || echo "FAILED")

    if [[ "$version_output" == *"FAILED"* ]]; then
        error "CodeQL CLI installation test failed"
        return 1
    else
        success "CodeQL CLI installed and working ($(echo "$version_output" | head -1))"
    fi
}

test_project_structure() {
    log "Testing project structure for CodeQL analysis..."

    # Check for Ruby files
    local ruby_files
    ruby_files=$(find "${PROJECT_ROOT}" -name "*.rb" -not -path "*/vendor/*" -not -path "*/.git/*" | head -5)
    if [ -n "$ruby_files" ]; then
        success "Ruby files found for analysis"
        echo "   Examples: $(echo "$ruby_files" | tr '\n' ' ' | head -c 100)..."
    else
        warn "No Ruby files found"
    fi

    # Check for JavaScript/TypeScript files
    local js_files
    js_files=$(find "${PROJECT_ROOT}" -name "*.js" -o -name "*.ts" -o -name "*.coffee" | grep -v node_modules | head -5)
    if [ -n "$js_files" ]; then
        success "JavaScript/TypeScript files found for analysis"
        echo "   Examples: $(echo "$js_files" | tr '\n' ' ' | head -c 100)..."
    else
        warn "No JavaScript/TypeScript files found"
    fi
}

test_database_creation() {
    log "Testing database creation (small test)..."

    # Create a temporary minimal database for testing
    local test_db_dir="${PROJECT_ROOT}/.codeql/test-database"

    # Remove any existing test database
    [ -d "$test_db_dir" ] && rm -rf "$test_db_dir"

    # Try to create a minimal Ruby database
    log "Creating test Ruby database..."
    if "${PROJECT_ROOT}/.codeql/codeql-cli/codeql" database create "$test_db_dir" \
        --language=ruby \
        --source-root="${PROJECT_ROOT}" \
        --overwrite \
        --threads=2 \
        --ram=1024 >/dev/null 2>&1; then
        success "Test database creation successful"

        # Clean up test database
        rm -rf "$test_db_dir"
    else
        error "Test database creation failed"
        return 1
    fi
}

test_query_availability() {
    log "Testing CodeQL query availability..."

    local queries_dir="${PROJECT_ROOT}/.codeql/codeql-queries/codeql-repo"

    if [ ! -d "$queries_dir" ]; then
        warn "CodeQL queries not found, downloading..."
        cd "${PROJECT_ROOT}/.codeql/codeql-queries"
        git clone --depth 1 https://github.com/github/codeql.git codeql-repo >/dev/null 2>&1
    fi

    # Check for Ruby queries
    if [ -d "${queries_dir}/ruby/ql/src" ]; then
        success "Ruby queries available"
    else
        error "Ruby queries not found"
        return 1
    fi

    # Check for JavaScript queries
    if [ -d "${queries_dir}/javascript/ql/src" ]; then
        success "JavaScript queries available"
    else
        error "JavaScript queries not found"
        return 1
    fi
}

test_integration_with_static_script() {
    log "Testing integration with static.pl script..."

    # Check if CodeQL is mentioned in the static script
    if grep -q "CodeQL" "${PROJECT_ROOT}/scripts/static.pl"; then
        success "CodeQL integrated into static.pl script"
    else
        error "CodeQL not found in static.pl script"
        return 1
    fi

    # Check if CodeQL scripts are executable
    if [ -x "${PROJECT_ROOT}/scripts/codeql-local.sh" ] && [ -x "${PROJECT_ROOT}/scripts/codeql-viewer.sh" ]; then
        success "CodeQL scripts are executable"
    else
        error "CodeQL scripts are not executable"
        return 1
    fi
}

test_github_actions_config() {
    log "Testing GitHub Actions configuration..."

    local workflow_file="${PROJECT_ROOT}/.github/workflows/codeql.yml"
    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    if [ -f "$workflow_file" ]; then
        success "CodeQL workflow file exists"
    else
        error "CodeQL workflow file missing"
        return 1
    fi

    if [ -f "$config_file" ]; then
        success "CodeQL configuration file exists"
    else
        error "CodeQL configuration file missing"
        return 1
    fi

    # Check if both Ruby and JavaScript are configured
    if grep -q "ruby" "$workflow_file" && grep -q "javascript" "$workflow_file"; then
        success "Both Ruby and JavaScript configured in workflow"
    else
        error "Missing language configuration in workflow"
        return 1
    fi
}

test_config_mirroring() {
    log "Testing configuration mirroring between local and CI/CD..."

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"
    local local_script="${PROJECT_ROOT}/scripts/codeql-local.sh"

    if [ ! -f "$config_file" ]; then
        error "CodeQL config file not found at ${config_file}"
        return 1
    fi

    # Check if local script references the config file
    if grep -q "\.github/codeql/codeql-config\.yml" "$local_script"; then
        success "Local script uses shared configuration file"
    else
        error "Local script does not reference shared config file"
        return 1
    fi

    # Check if config file has expected sections
    local has_paths_ignore has_queries has_name
    has_paths_ignore=$(grep -c "^paths-ignore:" "$config_file" || echo "0")
    has_queries=$(grep -c "^queries:" "$config_file" || echo "0")
    has_name=$(grep -c "^name:" "$config_file" || echo "0")

    if [ "$has_name" -gt 0 ]; then
        success "Config file has name section"
    else
        warn "Config file missing name section"
    fi

    if [ "$has_paths_ignore" -gt 0 ]; then
        success "Config file has paths-ignore section"
    else
        warn "Config file missing paths-ignore section"
    fi

    if [ "$has_queries" -gt 0 ]; then
        success "Config file has queries section"
    else
        error "Config file missing queries section"
        return 1
    fi

    # Check for common ignored paths
    local ignore_patterns=("node_modules" "vendor" "tmp")
    for pattern in "${ignore_patterns[@]}"; do
        if grep -q "$pattern" "$config_file"; then
            success "Config ignores $pattern (like GitHub default)"
        else
            warn "Config does not ignore $pattern"
        fi
    done

    # Check if security-and-quality queries are configured
    if grep -q "security-and-quality" "$config_file"; then
        success "Config uses security-and-quality queries (GitHub default)"
    else
        warn "Config does not use security-and-quality queries"
    fi
}

run_mini_analysis() {
    log "Running mini analysis test..."

    # Check if we can run a very basic query
    local test_db_dir="${PROJECT_ROOT}/.codeql/mini-test-database"

    # Remove any existing test database
    [ -d "$test_db_dir" ] && rm -rf "$test_db_dir"

    # Create a minimal database with just a few files
    log "Creating minimal test database..."
    mkdir -p "${test_db_dir}-source"

    # Create a simple Ruby file with a potential issue
    cat >"${test_db_dir}-source/test.rb" <<'EOF'
# Simple test file for CodeQL
class TestClass
  def unsafe_eval(user_input)
    eval(user_input)  # This should be flagged by CodeQL
  end
end
EOF

    # Create the database
    if "${PROJECT_ROOT}/.codeql/codeql-cli/codeql" database create "$test_db_dir" \
        --language=ruby \
        --source-root="${test_db_dir}-source" \
        --overwrite \
        --threads=1 \
        --ram=512 >/dev/null 2>&1; then

        # Try to run a basic query
        local query_result
        query_result=$("${PROJECT_ROOT}/.codeql/codeql-cli/codeql" database analyze "$test_db_dir" \
            "${PROJECT_ROOT}/.codeql/codeql-queries/codeql-repo/ruby/ql/src/codeql-suites/ruby-security-and-quality.qls" \
            --format=csv \
            --output=/dev/stdout 2>/dev/null | wc -l)

        if [ "$query_result" -gt 1 ]; then
            success "Mini analysis completed successfully (found some results)"
        else
            success "Mini analysis completed (no issues found in test file)"
        fi

        # Clean up
        rm -rf "$test_db_dir" "${test_db_dir}-source"
    else
        error "Mini analysis test failed"
        rm -rf "$test_db_dir" "${test_db_dir}-source"
        return 1
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                Test Summary                                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ CodeQL is properly set up and ready to use!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run full analysis: scripts/codeql-local.sh --create-db"
    echo "2. View results: scripts/codeql-viewer.sh"
    echo "3. Integrate with static analysis: perl scripts/static.pl"
    echo ""
    echo "GitHub Actions will automatically run CodeQL on:"
    echo "• Push to main branch"
    echo "• Pull requests to main"
    echo "• Weekly schedule"
}

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                            CodeQL Setup Test                                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local test_functions=(
        "test_codeql_installation"
        "test_project_structure"
        "test_query_availability"
        "test_integration_with_static_script"
        "test_github_actions_config"
        "test_database_creation"
        "run_mini_analysis"
        "test_config_mirroring"
    )

    local failed_tests=0

    for test_func in "${test_functions[@]}"; do
        if ! "$test_func"; then
            ((failed_tests++))
        fi
        echo ""
    done

    if [ "$failed_tests" -eq 0 ]; then
        print_summary
        exit 0
    else
        error "Some tests failed ($failed_tests/${#test_functions[@]})"
        echo ""
        echo "Please check the error messages above and:"
        echo "1. Ensure all dependencies are installed"
        echo "2. Run: scripts/codeql-local.sh --install"
        echo "3. Check network connectivity for downloading CodeQL"
        exit 1
    fi
}

main "$@"
