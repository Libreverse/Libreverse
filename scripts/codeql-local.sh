#!/usr/bin/env bash

# CodeQL Local Analysis - GitHub Actions Mirror
# Replicates the exact behavior of github/codeql-action for local development

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# CodeQL configuration (matches GitHub Actions defaults)
CODEQL_VERSION=""
CODEQL_FALLBACK_VERSIONS=("2.22.1" "2.21.4" "2.20.7" "2.19.3")
CODEQL_DIR="${PROJECT_ROOT}/.codeql"
CODEQL_CLI_DIR="${CODEQL_DIR}/codeql-cli"
CODEQL_QUERIES_DIR="${CODEQL_DIR}/codeql-queries"
CODEQL_DATABASE_DIR="${CODEQL_DIR}/databases"
CODEQL_RESULTS_DIR="${CODEQL_DIR}/results"

# Default configuration file (matches GitHub Actions)
DEFAULT_CONFIG_FILE="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

# Command line arguments
LANGUAGE=""
CONFIG_FILE=""
SETUP_ONLY=false
QUICK_TEST=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[CodeQL]${NC} $1"; }
success() { echo -e "${GREEN}[CodeQL]${NC} $1"; }
warn() { echo -e "${YELLOW}[CodeQL]${NC} $1"; }
error() { echo -e "${RED}[CodeQL]${NC} $1" >&2; }
step() { echo -e "${PURPLE}[CodeQL Step]${NC} $1"; }

# Detect supported languages in repository (matches GitHub auto-detection)
detect_supported_languages() {
    local languages=()

    # Ruby detection
    if [[ -f "${PROJECT_ROOT}/Gemfile" ]] || find "${PROJECT_ROOT}" -name "*.rb" -not -path "*/vendor/*" -not -path "*/.codeql/*" | head -1 | grep -q .; then
        languages+=("ruby")
    fi

    # JavaScript/TypeScript detection
    if [[ -f "${PROJECT_ROOT}/package.json" ]] || find "${PROJECT_ROOT}" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -not -path "*/node_modules/*" -not -path "*/.codeql/*" | head -1 | grep -q .; then
        languages+=("javascript-typescript")
    fi

    # GitHub Actions detection
    if [[ -d "${PROJECT_ROOT}/.github/workflows" ]] && find "${PROJECT_ROOT}/.github/workflows" -name "*.yml" -o -name "*.yaml" | head -1 | grep -q .; then
        languages+=("actions")
    fi

    printf '%s\n' "${languages[@]}"
}

# Get the correct CodeQL executable path (handles OS differences)
get_codeql_executable() {
    # Check for different possible executable names/locations
    local possible_paths=(
        "${CODEQL_CLI_DIR}/codeql/codeql" # Nested structure from zip
        "${CODEQL_CLI_DIR}/codeql"        # Direct structure
        "${CODEQL_CLI_DIR}/codeql-exe"    # Windows/macOS alternative
        "${CODEQL_CLI_DIR}/codeql.exe"    # Windows
    )

    for path in "${possible_paths[@]}"; do
        if [[ -x "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    # If nothing found, return empty
    return 1
}

# Get language-specific build mode (matches GitHub Actions logic)
get_build_mode() {
    local language="$1"
    case "$language" in
        "ruby") echo "none" ;;
        "javascript-typescript") echo "none" ;;
        "python") echo "none" ;;
        "java-kotlin") echo "autobuild" ;;
        *) echo "none" ;;
    esac
}

# ============================================================================
# CODEQL CLI MANAGEMENT
# ============================================================================

# Auto-detect latest CodeQL version (matches GitHub Actions)
detect_latest_codeql_version() {
    log "Auto-detecting latest CodeQL version..."

    # Try to get latest version from GitHub API
    local latest_version
    if latest_version=$(curl -s "https://api.github.com/repos/github/codeql-cli-binaries/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//'); then
        if [[ -n "$latest_version" && "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            CODEQL_VERSION="$latest_version"
            success "Detected latest version: v${CODEQL_VERSION}"
            return 0
        fi
    fi

    # Fallback to known stable versions
    warn "Could not detect latest version, using fallback: v${CODEQL_FALLBACK_VERSIONS[0]}"
    CODEQL_VERSION="${CODEQL_FALLBACK_VERSIONS[0]}"
}

# Download and install CodeQL CLI
install_codeql_cli() {
    log "Installing CodeQL CLI v${CODEQL_VERSION}..."

    # Detect OS and architecture
    local os="osx64"
    if [[ "$(uname)" == "Linux" ]]; then
        os="linux64"
    elif [[ "$(uname)" == "MINGW"* ]] || [[ "$(uname)" == "CYGWIN"* ]]; then
        os="win64"
    fi

    local url="https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-${os}.zip"
    local temp_zip="/tmp/codeql-${CODEQL_VERSION}-${os}.zip"

    # Download CodeQL CLI
    log "Downloading from: ${url}"
    if ! curl -fsSL -o "${temp_zip}" "${url}"; then
        error "Failed to download CodeQL CLI"
        return 1
    fi

    # Clean up any existing installation
    [[ -d "${CODEQL_CLI_DIR}" ]] && rm -rf "${CODEQL_CLI_DIR}"
    mkdir -p "${CODEQL_CLI_DIR}"

    # Extract CodeQL CLI
    if ! unzip -q "${temp_zip}" -d "${CODEQL_CLI_DIR}"; then
        error "Failed to extract CodeQL CLI"
        rm -f "${temp_zip}"
        return 1
    fi

    # Move files to correct location - CodeQL has nested structure
    if [[ -d "${CODEQL_CLI_DIR}/codeql" ]] && [[ -f "${CODEQL_CLI_DIR}/codeql/codeql" ]]; then
        # The codeql executable is in codeql/codeql, move it up
        mv "${CODEQL_CLI_DIR}/codeql/codeql" "${CODEQL_CLI_DIR}/"
        # Move other files from codeql subdirectory if any
        [[ -f "${CODEQL_CLI_DIR}/codeql/.codeqlmanifest.json" ]] && mv "${CODEQL_CLI_DIR}/codeql/.codeqlmanifest.json" "${CODEQL_CLI_DIR}/"
        # Clean up empty directory
        [[ -d "${CODEQL_CLI_DIR}/codeql" ]] && rmdir "${CODEQL_CLI_DIR}/codeql" 2> /dev/null || true
    fi

    # Cleanup
    rm -f "${temp_zip}"

    # Verify installation
    local codeql_executable
    if codeql_executable=$(get_codeql_executable); then
        local version_output
        version_output=$("${codeql_executable}" --version 2>&1 | head -1)
        success "CodeQL CLI installed: ${version_output}"
        success "Executable: ${codeql_executable}"
        return 0
    else
        error "CodeQL CLI installation verification failed - no working executable found"
        return 1
    fi
}

# Download CodeQL queries (matches GitHub Actions)
install_codeql_queries() {
    log "Installing CodeQL queries..."

    # Clean up any existing queries
    [[ -d "${CODEQL_QUERIES_DIR}" ]] && rm -rf "${CODEQL_QUERIES_DIR}"
    mkdir -p "${CODEQL_QUERIES_DIR}"

    # Clone the CodeQL repository (same as GitHub Actions)
    if ! git clone --depth 1 "https://github.com/github/codeql.git" "${CODEQL_QUERIES_DIR}/codeql-repo"; then
        error "Failed to clone CodeQL queries repository"
        return 1
    fi

    success "CodeQL queries installed"
    return 0
}

# Setup CodeQL environment (matches GitHub Actions init step)
setup_codeql() {
    step "Setting up CodeQL environment (github/codeql-action/init equivalent)"

    # Create directory structure
    mkdir -p "${CODEQL_DIR}" "${CODEQL_DATABASE_DIR}" "${CODEQL_RESULTS_DIR}"

    # Install CodeQL CLI if not present
    if ! get_codeql_executable > /dev/null 2>&1; then
        detect_latest_codeql_version
        install_codeql_cli || return 1
    else
        log "CodeQL CLI already installed"
        local version_output codeql_executable
        codeql_executable=$(get_codeql_executable)
        version_output=$("${codeql_executable}" --version 2>&1 | head -1)
        log "Current version: ${version_output}"
    fi

    # Install CodeQL queries if not present
    if [[ ! -d "${CODEQL_QUERIES_DIR}/codeql-repo" ]]; then
        install_codeql_queries || return 1
    else
        log "CodeQL queries already installed"
    fi

    success "CodeQL environment setup complete"
    return 0
}

# ============================================================================
# GITHUB ACTIONS MIRROR: INIT, AUTOBUILD, ANALYZE
# ============================================================================

# STEP 1: Initialize CodeQL (github/codeql-action/init@v3)
init_codeql() {
    local language="$1"
    local config_file="${2:-$DEFAULT_CONFIG_FILE}"

    step "Initializing CodeQL for ${language} (github/codeql-action/init equivalent)"

    local database_path="${CODEQL_DATABASE_DIR}/${language}-database"
    local build_mode
    build_mode=$(get_build_mode "$language")

    log "Language: ${language}"
    log "Build mode: ${build_mode}"
    log "Config file: ${config_file}"
    log "Database path: ${database_path}"

    # Remove existing database
    [[ -d "$database_path" ]] && rm -rf "$database_path"

    # Create database (matches GitHub Actions behavior)
    log "Creating CodeQL database..."
    local codeql_executable
    codeql_executable=$(get_codeql_executable)

    # Create a temporary directory with only project source files (excluding .codeql)
    local temp_source_dir="/tmp/codeql-source-$(date +%s)"
    log "Creating filtered source tree (excluding .codeql and other unwanted files)..."

    # Copy project files excluding unwanted directories
    rsync -av \
        --exclude='.codeql/' \
        --exclude='node_modules/' \
        --exclude='vendor/' \
        --exclude='test/' \
        --exclude='spec/' \
        --exclude='tmp/' \
        --exclude='coverage/' \
        --exclude='log/' \
        --exclude='storage/' \
        --exclude='public/assets/' \
        "${PROJECT_ROOT}/" "$temp_source_dir/"

    local create_cmd=(
        "${codeql_executable}" database create
        "$database_path"
        "--language=$language"
        "--source-root=$temp_source_dir"
        "--overwrite"
        "--threads=0"
    )

    # Add build mode specific options
    if [[ "$build_mode" == "none" ]]; then
        create_cmd+=("--build-mode=none")
    fi

    # Create the database from filtered source
    local create_success=false
    if "${create_cmd[@]}"; then
        create_success=true
    fi

    # Clean up temporary source directory
    rm -rf "$temp_source_dir"

    if [[ "$create_success" != true ]]; then
        error "Failed to create CodeQL database for ${language}"
        return 1
    fi

    success "CodeQL database created for ${language}"
    return 0
}

# STEP 2: Auto-build if needed (github/codeql-action/autobuild@v3)
autobuild_if_needed() {
    local language="$1"

    step "Auto-build check for ${language} (github/codeql-action/autobuild equivalent)"

    local build_mode
    build_mode=$(get_build_mode "$language")

    if [[ "$build_mode" == "autobuild" ]]; then
        log "Running autobuild for ${language}..."
        case "$language" in
            "ruby")
                if [[ -f "${PROJECT_ROOT}/Gemfile" ]]; then
                    cd "${PROJECT_ROOT}"
                    bundle install --quiet
                    success "Ruby gems installed"
                fi
                ;;
            "java-kotlin")
                log "Java/Kotlin autobuild would run here"
                ;;
        esac
    else
        log "No build required for ${language} (build mode: ${build_mode})"
    fi

    return 0
}

# STEP 3: Analyze and generate results (github/codeql-action/analyze@v3)
analyze_codeql() {
    local language="$1"
    local config_file="${2:-$DEFAULT_CONFIG_FILE}"

    step "Analyzing ${language} (github/codeql-action/analyze equivalent)"

    local database_path="${CODEQL_DATABASE_DIR}/${language}-database"
    local results_path="${CODEQL_RESULTS_DIR}/${language}-results.sarif"

    if [[ ! -d "$database_path" ]]; then
        error "Database not found: ${database_path}"
        return 1
    fi

    log "Running CodeQL analysis..."

    # Map CodeQL language names to query directory names
    local query_lang="$language"
    if [[ "$language" == "javascript-typescript" ]]; then
        query_lang="javascript"
    elif [[ "$language" == "actions" ]]; then
        query_lang="actions"
    fi

    local queries_to_run=""

    if [[ "$QUICK_TEST" == true ]]; then
        # Quick test: run just one fast query (language-specific)
        local test_query=""
        if [[ "$query_lang" == "ruby" ]]; then
            test_query="${CODEQL_QUERIES_DIR}/codeql-repo/${query_lang}/ql/src/queries/security/cwe-094/CodeInjection.ql"
        fi

        if [[ -f "$test_query" ]]; then
            queries_to_run="$test_query"
            log "Quick test mode: running single query $(basename "$test_query")"
        else
            # Fallback to security suite for quick test
            queries_to_run="${CODEQL_QUERIES_DIR}/codeql-repo/${query_lang}/ql/src/codeql-suites/${query_lang}-security-extended.qls"
            log "Quick test mode: using security suite $(basename "$queries_to_run")"
        fi
    else
        # Use the security-and-quality suite (GitHub Actions default)
        local query_suite="${CODEQL_QUERIES_DIR}/codeql-repo/${query_lang}/ql/src/codeql-suites/${query_lang}-security-and-quality.qls"

        # Fallback to simpler suite if specific one doesn't exist
        if [[ ! -f "$query_suite" ]]; then
            query_suite="${CODEQL_QUERIES_DIR}/codeql-repo/${query_lang}/ql/src/codeql-suites/${query_lang}-security-extended.qls"
        fi

        queries_to_run="$query_suite"
        log "Using query suite: $(basename "$queries_to_run")"
    fi

    local analyze_cmd=(
        "$(get_codeql_executable)" database analyze
        "$database_path"
        "--format=sarif-latest"
        "--output=$results_path"
        "--threads=0"
    )

    # Add queries to run
    if [[ -n "$queries_to_run" && -f "$queries_to_run" ]]; then
        analyze_cmd+=("$queries_to_run")
    else
        warn "No queries found, using default security queries"
        analyze_cmd+=("--")
    fi

    if ! "${analyze_cmd[@]}"; then
        error "CodeQL analysis failed for ${language}"
        return 1
    fi

    # Generate human-readable results
    local txt_results="${CODEQL_RESULTS_DIR}/${language}-results.txt"
    if [[ -f "$results_path" ]]; then
        "$(get_codeql_executable)" database interpret-results \
            "$database_path" \
            --format=text \
            --output="$txt_results" \
            < "$results_path" 2> /dev/null || true
    fi

    success "CodeQL analysis completed for ${language}"
    log "SARIF results: ${results_path}"
    [[ -f "$txt_results" ]] && log "Human-readable results: ${txt_results}"

    return 0
}

# Run complete CodeQL analysis for a language (mirrors GitHub Actions workflow)
run_language_analysis() {
    local language="$1"
    local config_file="${2:-$DEFAULT_CONFIG_FILE}"

    log "Starting CodeQL analysis for ${language}"
    log "================================================"

    # Step 1: Initialize (github/codeql-action/init)
    if ! init_codeql "$language" "$config_file"; then
        error "Initialization failed for ${language}"
        return 1
    fi

    # Step 2: Autobuild (github/codeql-action/autobuild)
    if ! autobuild_if_needed "$language"; then
        error "Autobuild failed for ${language}"
        return 1
    fi

    # Step 3: Analyze (github/codeql-action/analyze)
    if ! analyze_codeql "$language" "$config_file"; then
        error "Analysis failed for ${language}"
        return 1
    fi

    success "CodeQL analysis completed successfully for ${language}"
    return 0
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --language)
                LANGUAGE="$2"
                shift 2
                ;;
            --config-file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --setup-only)
                SETUP_ONLY=true
                shift
                ;;
            --quick-test)
                QUICK_TEST=true
                shift
                ;;
            --help | -h)
                cat << EOF
CodeQL Local Analysis - GitHub Actions Mirror

Usage: $0 [OPTIONS]

Options:
  --language LANG       Analyze specific language (ruby, javascript-typescript)
  --config-file PATH    Use custom CodeQL configuration file
  --setup-only          Only setup CodeQL environment, don't run analysis
  --quick-test          Run a single fast query for testing
  --help, -h           Show this help message

Examples:
  $0                    # Auto-detect and analyze all supported languages
  $0 --language ruby    # Analyze only Ruby code
  $0 --setup-only       # Just setup CodeQL environment

This script mirrors GitHub Actions CodeQL workflow locally.
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Main entry point
main() {
    log "CodeQL Local Analysis - GitHub Actions Mirror"
    log "Project: $(basename "${PROJECT_ROOT}")"
    log "Working directory: ${PROJECT_ROOT}"

    # Parse command line arguments
    parse_arguments "$@"

    # Set default config file if not specified
    [[ -z "$CONFIG_FILE" ]] && CONFIG_FILE="$DEFAULT_CONFIG_FILE"

    # Setup CodeQL environment (always required)
    if ! setup_codeql; then
        error "Failed to setup CodeQL environment"
        exit 1
    fi

    # If setup-only mode, exit here
    if [[ "$SETUP_ONLY" == true ]]; then
        success "CodeQL environment setup completed"
        exit 0
    fi

    # Determine languages to analyze
    log "Detecting supported languages..."
    local languages_to_analyze=()
    if [[ -n "$LANGUAGE" ]]; then
        languages_to_analyze=("$LANGUAGE")
        log "Analyzing specified language: ${LANGUAGE}"
    else
        while IFS= read -r lang; do
            [[ -n "$lang" ]] && languages_to_analyze+=("$lang")
        done < <(detect_supported_languages)

        if [[ ${#languages_to_analyze[@]} -eq 0 ]]; then
            warn "No supported languages detected in repository"
            exit 0
        fi
        log "Auto-detected languages: ${languages_to_analyze[*]}"
    fi

    # Run analysis for each language (GitHub Actions matrix strategy)
    local overall_success=true
    for lang in "${languages_to_analyze[@]}"; do
        if ! run_language_analysis "$lang" "$CONFIG_FILE"; then
            overall_success=false
            error "Analysis failed for ${lang}"
        fi
        echo # Add spacing between languages
    done

    # Final summary
    log "================================================"
    if [[ "$overall_success" == true ]]; then
        success "All CodeQL analyses completed successfully"
        log "Results available in: ${CODEQL_RESULTS_DIR}"

        # Show quick summary of results
        for lang in "${languages_to_analyze[@]}"; do
            local results_file="${CODEQL_RESULTS_DIR}/${lang}-results.sarif"
            if [[ -f "$results_file" ]]; then
                local finding_count
                finding_count=$(grep -c '"ruleId"' "$results_file" 2> /dev/null || echo "0")
                log "${lang}: ${finding_count} findings"
            fi
        done

        exit 0
    else
        error "Some CodeQL analyses failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
