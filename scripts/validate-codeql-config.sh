#!/usr/bin/env bash

# CodeQL Configuration Validation Script
# This script validates that local CodeQL setup mirrors GitHub Actions behavior

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[Validate]${NC} $1"
}

success() {
    echo -e "${GREEN}[Validate]${NC} ✅ $1"
}

error() {
    echo -e "${RED}[Validate]${NC} ❌ $1" >&2
}

warn() {
    echo -e "${YELLOW}[Validate]${NC} ⚠️  $1"
}

info() {
    echo -e "${CYAN}[Validate]${NC} ℹ️  $1"
}

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     CodeQL Configuration Validation                           ║${NC}"
    echo -e "${BLUE}║                    Local Setup vs GitHub Actions                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

validate_config_consistency() {
    log "Validating configuration consistency..."

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"
    local workflow_file="${PROJECT_ROOT}/.github/workflows/codeql.yml"
    local local_script="${PROJECT_ROOT}/scripts/codeql-local.sh"

    # Check if all files exist
    if [ ! -f "$config_file" ]; then
        error "Configuration file missing: $config_file"
        return 1
    fi

    if [ ! -f "$workflow_file" ]; then
        error "Workflow file missing: $workflow_file"
        return 1
    fi

    if [ ! -f "$local_script" ]; then
        error "Local script missing: $local_script"
        return 1
    fi

    success "All required files present"

    # Check if workflow references config file
    if grep -q "config-file.*codeql-config.yml" "$workflow_file"; then
        success "GitHub workflow uses shared config file"
    else
        error "GitHub workflow does not reference shared config file"
        return 1
    fi

    # Check if local script references config file
    if grep -q "\.github/codeql/codeql-config\.yml" "$local_script"; then
        success "Local script uses shared config file"
    else
        error "Local script does not reference shared config file"
        return 1
    fi
}

validate_query_suites() {
    log "Validating query suite configuration..."

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    # Extract query suite
    local query_suite
    query_suite=$(grep -E "^\s*-\s*uses:\s*" "$config_file" | head -1 | sed 's/.*uses:\s*//' | sed 's/[[:space:]]*$//' || echo "")

    if [ -n "$query_suite" ]; then
        success "Query suite configured: '$query_suite'"

        if [ "$query_suite" = "security-and-quality" ]; then
            success "Using GitHub's default query suite"
        else
            info "Using custom query suite: $query_suite"
        fi
    else
        error "No query suite found in configuration"
        return 1
    fi
}

validate_path_exclusions() {
    log "Validating path exclusions..."

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    # Check for standard exclusions
    local standard_exclusions=("node_modules" "vendor" "test" "tmp" "coverage")
    local missing_exclusions=()

    for exclusion in "${standard_exclusions[@]}"; do
        if grep -q "$exclusion" "$config_file"; then
            success "Excludes $exclusion"
        else
            missing_exclusions+=("$exclusion")
        fi
    done

    if [ ${#missing_exclusions[@]} -gt 0 ]; then
        warn "Missing standard exclusions: ${missing_exclusions[*]}"
    fi
}

validate_language_support() {
    log "Validating language support..."

    local workflow_file="${PROJECT_ROOT}/.github/workflows/codeql.yml"

    # Check for Ruby and JavaScript support
    if grep -q "ruby" "$workflow_file" && grep -q "javascript" "$workflow_file"; then
        success "Both Ruby and JavaScript configured in workflow"
    else
        error "Missing language configuration in workflow"
        return 1
    fi

    # Check if local script supports the same languages
    local local_script="${PROJECT_ROOT}/scripts/codeql-local.sh"
    if grep -q 'languages=("ruby" "javascript")' "$local_script"; then
        success "Local script supports same languages"
    else
        warn "Local script may have different language defaults"
    fi
}

test_config_parsing() {
    log "Testing configuration parsing..."

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    # Test the same parsing logic as the local script
    local parsed_suite
    parsed_suite=$(grep -E "^\s*-\s*uses:\s*" "$config_file" | head -1 | sed 's/.*uses:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [ -z "$parsed_suite" ]; then
        error "Configuration parsing failed - no query suite found"
        return 1
    else
        success "Configuration parsing works: '$parsed_suite'"
    fi
}

validate_github_actions_matrix() {
    log "Validating GitHub Actions matrix configuration..."

    local workflow_file="${PROJECT_ROOT}/.github/workflows/codeql.yml"

    # Check matrix strategy
    if grep -A 10 "strategy:" "$workflow_file" | grep -q "matrix:"; then
        success "Matrix strategy configured"
    else
        error "Matrix strategy missing"
        return 1
    fi

    # Check for parallel execution
    if grep -q "fail-fast: false" "$workflow_file"; then
        success "Parallel execution enabled (fail-fast: false)"
    else
        warn "Sequential execution (fail-fast not disabled)"
    fi
}

show_configuration_summary() {
    log "Configuration Summary:"
    echo ""

    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    # Show query suite
    local query_suite
    query_suite=$(grep -E "^\s*-\s*uses:\s*" "$config_file" | head -1 | sed 's/.*uses:\s*//' | sed 's/[[:space:]]*$//' || echo "default")
    echo -e "  ${CYAN}Query Suite:${NC} $query_suite"

    # Count excluded paths
    local excluded_count
    excluded_count=$(grep -c "^  - " "$config_file" | head -1 || echo "0")
    echo -e "  ${CYAN}Excluded Paths:${NC} $excluded_count patterns"

    # Show languages from workflow
    local languages
    languages=$(grep -A 5 "include:" "${PROJECT_ROOT}/.github/workflows/codeql.yml" | grep "language:" | sed 's/.*language: //' | tr '\n' ', ' | sed 's/, $//')
    echo -e "  ${CYAN}Languages:${NC} $languages"

    echo ""
    echo -e "${GREEN}✨ Local CodeQL analysis will mirror GitHub Actions behavior${NC}"
}

print_usage_guide() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                              Usage Guide                                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}To run CodeQL analysis locally (mirrors GitHub Actions):${NC}"
    echo "  scripts/codeql-local.sh"
    echo ""
    echo -e "${CYAN}To run CodeQL as part of static analysis:${NC}"
    echo "  perl scripts/static.pl"
    echo ""
    echo -e "${CYAN}To view results:${NC}"
    echo "  scripts/codeql-viewer.sh"
    echo "  scripts/codeql-viewer.sh --detailed"
    echo ""
    echo -e "${CYAN}Configuration file:${NC}"
    echo "  .github/codeql/codeql-config.yml"
    echo ""
    echo -e "${GREEN}Any changes to the config file will affect both local and CI analysis!${NC}"
}

main() {
    print_header

    local validation_functions=(
        "validate_config_consistency"
        "validate_query_suites"
        "validate_path_exclusions"
        "validate_language_support"
        "test_config_parsing"
        "validate_github_actions_matrix"
    )

    local failed_validations=0

    for validation_func in "${validation_functions[@]}"; do
        if ! "$validation_func"; then
            ((failed_validations++))
        fi
        echo ""
    done

    if [ "$failed_validations" -eq 0 ]; then
        show_configuration_summary
        print_usage_guide
        exit 0
    else
        error "Some validations failed ($failed_validations/${#validation_functions[@]})"
        echo ""
        echo "Please review the errors above and ensure:"
        echo "1. Configuration files are properly set up"
        echo "2. Local script references shared config"
        echo "3. GitHub workflow uses config file"
        exit 1
    fi
}

main "$@"
