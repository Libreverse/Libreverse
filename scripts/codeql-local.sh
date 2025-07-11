#!/usr/bin/env bash

# CodeQL Local Setup and Execution Script
# This script sets up CodeQL CLI and runs analysis on Ruby and JavaScript/TypeScript code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# Auto-detect latest CodeQL version with fallback
CODEQL_VERSION=""
CODEQL_FALLBACK_VERSIONS=("2.21.4" "2.20.7" "2.19.3" "2.18.4" "2.17.6")
CODEQL_DIR="${PROJECT_ROOT}/.codeql"
CODEQL_CLI_DIR="${CODEQL_DIR}/codeql-cli"
CODEQL_QUERIES_DIR="${CODEQL_DIR}/codeql-queries"
CODEQL_DATABASE_DIR="${CODEQL_DIR}/databases"
CODEQL_RESULTS_DIR="${CODEQL_DIR}/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[CodeQL]${NC} $1"
}

success() {
    echo -e "${GREEN}[CodeQL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[CodeQL]${NC} $1"
}

error() {
    echo -e "${RED}[CodeQL]${NC} $1" >&2
}

# Check if CodeQL CLI is installed
check_codeql_installation() {
    if [ -x "${CODEQL_CLI_DIR}/codeql" ]; then
        return 0
    else
        return 1
    fi
}

# Parse CodeQL config file to get query suites and paths
parse_codeql_config() {
    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    if [ ! -f "$config_file" ]; then
        warn "CodeQL config file not found, using defaults"
        echo "security-and-quality"
        return 1
    fi

    # Extract query suites (simplified YAML parsing)
    # Look for lines like "  - uses: security-and-quality"
    local query_suite
    query_suite=$(grep -E "^\s*-\s*uses:\s*" "$config_file" | head -1 | sed 's/.*uses:\s*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [ -n "$query_suite" ]; then
        echo "$query_suite"
    else
        echo "security-and-quality" # default
    fi
}

# Get CodeQL database creation options from config
get_database_options() {
    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"
    local options=""

    if [ -f "$config_file" ]; then
        # Check if there are paths-ignore patterns
        if grep -q "^paths-ignore:" "$config_file"; then
            # For now, we'll use the source-root filtering
            # CodeQL CLI handles path filtering during analysis, not database creation
            log "Using path filters from config file during analysis"
        fi
    fi

    echo "$options"
}

# Auto-detect latest CodeQL version
detect_latest_version() {
    log "Auto-detecting latest CodeQL version..."

    # Try to get latest release from GitHub API
    if command -v curl > /dev/null 2>&1; then
        local latest_version
        latest_version=$(curl -s "https://api.github.com/repos/github/codeql-cli-binaries/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' 2> /dev/null)

        if [ -n "$latest_version" ] && [ "$latest_version" != "null" ]; then
            # Test if the detected version actually exists by trying to download it
            local os arch
            os=$(uname -s | tr '[:upper:]' '[:lower:]')
            arch=$(uname -m)

            case "${arch}" in
                x86_64) arch="x64" ;;
                arm64 | aarch64) arch="arm64" ;;
            esac

            case "${os}" in
                darwin) os="osx" ;;
                linux) os="linux" ;;
            esac

            local test_urls=(
                "https://github.com/github/codeql-cli-binaries/releases/download/v${latest_version}/codeql-${os}64.zip"
                "https://github.com/github/codeql-cli-binaries/releases/download/v${latest_version}/codeql-${os}-${arch}.zip"
            )

            # Test if any URL is accessible (just check headers, don't download)
            for test_url in "${test_urls[@]}"; do
                if curl -sSf --head "${test_url}" > /dev/null 2>&1; then
                    CODEQL_VERSION="$latest_version"
                    log "Detected and verified latest version: v${CODEQL_VERSION}"
                    return 0
                fi
            done
            warn "Latest version v${latest_version} detected but not available for download"
        fi
    fi

    warn "Could not auto-detect working version, using fallback versions..."
    return 1
}

# Try downloading with version fallback
download_with_fallback() {
    local os="$1"
    local arch="$2"

    # Clean up any existing temp files
    rm -f /tmp/codeql-*.zip 2> /dev/null || true

    # Try latest version first if detected
    if [ -n "$CODEQL_VERSION" ]; then
        # Try both new and old naming conventions
        local urls=(
            "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-${os}64.zip"
            "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-${os}-${arch}.zip"
        )

        for url in "${urls[@]}"; do
            local temp_zip="/tmp/codeql-${CODEQL_VERSION}-${os}-${arch}.zip"
            log "Trying version ${CODEQL_VERSION} with URL: ${url}" >&2

            # Clean up any existing file with this name
            rm -f "${temp_zip}"

            # Use silent curl to avoid output pollution
            if curl -fsSL -o "${temp_zip}" "${url}" > /dev/null 2>&1; then
                # Verify the download was successful
                if [ -f "${temp_zip}" ] && [ -s "${temp_zip}" ]; then
                    success "Successfully downloaded CodeQL v${CODEQL_VERSION}" >&2
                    echo "${temp_zip}"
                    return 0
                else
                    warn "Downloaded file is empty or corrupted" >&2
                    rm -f "${temp_zip}"
                fi
            else
                warn "Failed to download from ${url}" >&2
            fi
        done
        warn "Failed to download version ${CODEQL_VERSION}" >&2
    fi

    # Try fallback versions
    for version in "${CODEQL_FALLBACK_VERSIONS[@]}"; do
        # Try both new and old naming conventions
        local urls=(
            "https://github.com/github/codeql-cli-binaries/releases/download/v${version}/codeql-${os}64.zip"
            "https://github.com/github/codeql-cli-binaries/releases/download/v${version}/codeql-${os}-${arch}.zip"
        )

        for url in "${urls[@]}"; do
            local temp_zip="/tmp/codeql-${version}-${os}-${arch}.zip"
            log "Trying fallback version ${version} from: ${url}" >&2

            # Clean up any existing file with this name
            rm -f "${temp_zip}"

            if curl -fsSL -o "${temp_zip}" "${url}" > /dev/null 2>&1; then
                # Verify the download was successful
                if [ -f "${temp_zip}" ] && [ -s "${temp_zip}" ]; then
                    CODEQL_VERSION="$version"
                    success "Successfully downloaded CodeQL v${CODEQL_VERSION}" >&2
                    echo "${temp_zip}"
                    return 0
                else
                    warn "Downloaded file is empty or corrupted" >&2
                    rm -f "${temp_zip}"
                fi
            else
                warn "Failed to download from ${url}" >&2
            fi
        done
        warn "Failed to download version ${version}" >&2
    done

    error "Failed to download any CodeQL version" >&2
    return 1
}

# Install CodeQL CLI
install_codeql() {
    log "Installing CodeQL CLI..."

    # Clean up any existing installation
    [ -d "${CODEQL_DIR}" ] && rm -rf "${CODEQL_DIR}"

    # Create directories
    mkdir -p "${CODEQL_CLI_DIR}"
    mkdir -p "${CODEQL_QUERIES_DIR}"
    mkdir -p "${CODEQL_DATABASE_DIR}"
    mkdir -p "${CODEQL_RESULTS_DIR}"

    # Determine OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "${ARCH}" in
        x86_64) ARCH="x64" ;;
        arm64 | aarch64) ARCH="arm64" ;;
        *)
            error "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    case "${OS}" in
        darwin) OS="osx" ;;
        linux) OS="linux" ;;
        *)
            error "Unsupported OS: ${OS}"
            exit 1
            ;;
    esac

    # Auto-detect version or use fallback
    detect_latest_version || true

    # Download with fallback system
    local temp_zip
    if ! temp_zip=$(download_with_fallback "$OS" "$ARCH"); then
        error "Failed to download CodeQL CLI"
        exit 1
    fi

    # Verify download exists and is valid
    if [ ! -f "${temp_zip}" ] || [ ! -s "${temp_zip}" ]; then
        error "Downloaded file is missing or empty: ${temp_zip}"
        rm -f "${temp_zip}" 2> /dev/null || true
        exit 1
    fi

    # Extract
    log "Extracting CodeQL CLI from ${temp_zip}..."
    cd "${CODEQL_DIR}"

    # Test unzip first
    if ! unzip -tq "${temp_zip}" > /dev/null 2>&1; then
        error "Downloaded file is corrupted: ${temp_zip}"
        rm -f "${temp_zip}"
        exit 1
    fi

    # Extract the zip file
    if ! unzip -q "${temp_zip}"; then
        error "Failed to extract CodeQL CLI"
        rm -f "${temp_zip}"
        exit 1
    fi

    # Move files to correct location
    if [ -d "codeql" ]; then
        mv codeql/* "${CODEQL_CLI_DIR}/"
        rm -rf codeql # Use rm -rf instead of rmdir to handle non-empty directories
    else
        error "Extracted directory structure is unexpected"
        ls -la
        exit 1
    fi

    # Clean up download
    rm -f "${temp_zip}"

    # Verify CodeQL binary
    if [ ! -x "${CODEQL_CLI_DIR}/codeql" ]; then
        error "CodeQL binary not found or not executable"
        exit 1
    fi

    # Download CodeQL standard libraries and queries with retry
    log "Downloading CodeQL standard libraries..."
    cd "${CODEQL_QUERIES_DIR}"

    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if git clone --depth 1 --single-branch https://github.com/github/codeql.git codeql-repo; then
            break
        else
            retry_count=$((retry_count + 1))
            warn "Retry $retry_count/$max_retries: Failed to clone CodeQL repository"
            [ -d codeql-repo ] && rm -rf codeql-repo
            [ $retry_count -lt $max_retries ] && sleep 5
        fi
    done

    if [ $retry_count -eq $max_retries ]; then
        warn "Failed to download CodeQL queries, but CLI is installed"
        warn "You can download queries manually or use GitHub Actions for analysis"
    else
        success "CodeQL queries downloaded successfully"
    fi

    success "CodeQL CLI v${CODEQL_VERSION} installed successfully"
}

# Create database for a specific language
create_database() {
    local language="$1"
    local database_path="${CODEQL_DATABASE_DIR}/${language}-database"

    log "Creating ${language} database..."

    # Remove existing database if it exists
    [ -d "${database_path}" ] && rm -rf "${database_path}"

    # Set timeout for database creation
    local timeout_duration=600 # 10 minutes - increased for large projects

    case "${language}" in
        "ruby")
            timeout "${timeout_duration}" "${CODEQL_CLI_DIR}/codeql" database create "${database_path}" \
                --language=ruby \
                --source-root="${PROJECT_ROOT}" \
                --overwrite \
                --threads=0 \
                --exclude-pattern=".codeql/**" \
                --exclude-pattern="vendor/**" \
                --exclude-pattern="node_modules/**" \
                --exclude-pattern="test/**" \
                --exclude-pattern="spec/**" \
                2> /dev/null || {
                error "Failed to create Ruby database (timeout or error)"
                return 1
            }
            ;;
        "javascript")
            timeout "${timeout_duration}" "${CODEQL_CLI_DIR}/codeql" database create "${database_path}" \
                --language=javascript \
                --source-root="${PROJECT_ROOT}" \
                --overwrite \
                --threads=0 \
                --exclude-pattern=".codeql/**" \
                --exclude-pattern="vendor/**" \
                --exclude-pattern="node_modules/**" \
                --exclude-pattern="test/**" \
                --exclude-pattern="spec/**" \
                2> /dev/null || {
                error "Failed to create JavaScript database (timeout or error)"
                return 1
            }
            ;;
        *)
            error "Unsupported language: ${language}"
            return 1
            ;;
    esac

    success "${language} database created at ${database_path}"
}

# Run analysis for a specific language
run_analysis() {
    local language="$1"
    local database_path="${CODEQL_DATABASE_DIR}/${language}-database"
    local results_file="${CODEQL_RESULTS_DIR}/${language}-results.sarif"

    if [ ! -d "${database_path}" ]; then
        warn "Database not found for ${language}. Creating database first..."
        if ! create_database "${language}"; then
            error "Failed to create database for ${language}"
            return 1
        fi
    fi

    log "Running ${language} analysis using GitHub configuration..."

    # Set timeout for analysis (increased for first run)
    local timeout_duration=1200 # 20 minutes for first run

    # Use the same configuration as GitHub Actions
    local config_file="${PROJECT_ROOT}/.github/codeql/codeql-config.yml"

    if [ ! -f "$config_file" ]; then
        error "CodeQL config file not found at ${config_file}"
        return 1
    fi

    # Parse query suite from config file
    local query_suite
    query_suite=$(parse_codeql_config)
    log "Using query suite: ${query_suite}"

    # Check if the query suite file exists
    local query_file="${CODEQL_QUERIES_DIR}/codeql-repo/${language}/ql/src/codeql-suites/${language}-${query_suite}.qls"
    if [ ! -f "$query_file" ]; then
        error "Query suite file not found: ${query_file}"
        log "Available query suites:"
        ls -la "${CODEQL_QUERIES_DIR}/codeql-repo/${language}/ql/src/codeql-suites/" 2> /dev/null || log "Query suites directory not found"
        return 1
    fi

    log "Starting analysis with config file: ${config_file}"
    timeout "${timeout_duration}" "${CODEQL_CLI_DIR}/codeql" database analyze "${database_path}" \
        --config-file="${config_file}" \
        --format=sarif-latest \
        --output="${results_file}" \
        --sarif-category="${language}" \
        --threads=0 \
        --verbose || {
        error "${language} analysis failed or timed out"
        log "Check the CodeQL logs above for details"
        return 1
    }

    success "${language} analysis completed. Results saved to ${results_file}"

    # Also create a human-readable report (don't fail if this fails)
    local readable_results="${CODEQL_RESULTS_DIR}/${language}-results.txt"
    log "Generating human-readable results..."
    timeout 180 "${CODEQL_CLI_DIR}/codeql" database analyze "${database_path}" \
        --config-file="${config_file}" \
        --format=csv \
        --output="${readable_results}" \
        --threads=0 \
        2> /dev/null || warn "Could not generate human-readable results for ${language}"

    if [ -f "${readable_results}" ]; then
        success "Human-readable results saved to ${readable_results}"
    fi
}

# Print results summary
print_results() {
    local language="$1"
    local results_file="${CODEQL_RESULTS_DIR}/${language}-results.sarif"
    local readable_results="${CODEQL_RESULTS_DIR}/${language}-results.txt"

    if [ -f "${results_file}" ]; then
        log "Results for ${language}:"

        # Count findings by severity using jq if available
        if command -v jq > /dev/null 2>&1; then
            local total_findings
            total_findings=$(jq -r '.runs[0].results | length' "${results_file}" 2> /dev/null || echo "0")
            echo "  Total findings: ${total_findings}"

            # Count by severity level
            local error_count warning_count note_count
            error_count=$(jq -r '.runs[0].results | map(select(.level == "error")) | length' "${results_file}" 2> /dev/null || echo "0")
            warning_count=$(jq -r '.runs[0].results | map(select(.level == "warning")) | length' "${results_file}" 2> /dev/null || echo "0")
            note_count=$(jq -r '.runs[0].results | map(select(.level == "note")) | length' "${results_file}" 2> /dev/null || echo "0")

            echo "  Errors: ${error_count}"
            echo "  Warnings: ${warning_count}"
            echo "  Notes: ${note_count}"
        fi

        echo "  SARIF results: ${results_file}"

        if [ -f "${readable_results}" ]; then
            echo "  Human-readable: ${readable_results}"
        fi
    else
        warn "No results found for ${language}"
    fi
}

# Main execution
main() {
    local action="analyze"
    local languages=("ruby" "javascript")
    local create_db=true # Default to true for automatic operation
    local print_summary=true
    local force_install=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                action="install"
                shift
                ;;
            --force-install)
                force_install=true
                shift
                ;;
            --no-create-db)
                create_db=false
                shift
                ;;
            --create-db)
                create_db=true
                shift
                ;;
            --language)
                IFS=',' read -ra languages <<< "$2"
                shift 2
                ;;
            --no-summary)
                print_summary=false
                shift
                ;;
            --help | -h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --install          Install CodeQL CLI only"
                echo "  --force-install    Force reinstall CodeQL CLI"
                echo "  --create-db        Create databases before analysis (default)"
                echo "  --no-create-db     Don't create databases (use existing)"
                echo "  --language LANG    Comma-separated list of languages (ruby,javascript)"
                echo "  --no-summary       Don't print results summary"
                echo "  --help, -h         Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                 # Automatic: install, create DBs, analyze all languages"
                echo "  $0 --language ruby # Analyze only Ruby code"
                echo "  $0 --no-create-db  # Use existing databases"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    cd "${PROJECT_ROOT}"

    # Install CodeQL if requested, forced, or not installed
    if [ "${action}" = "install" ] || [ "${force_install}" = true ] || ! check_codeql_installation; then
        if ! install_codeql; then
            error "Failed to install CodeQL CLI"
            exit 1
        fi
    fi

    if [ "${action}" = "install" ]; then
        success "CodeQL installation completed"
        exit 0
    fi

    # Verify installation
    if ! check_codeql_installation; then
        error "CodeQL CLI not available after installation"
        exit 1
    fi

    # Run analysis for each language
    local failed_languages=()
    for language in "${languages[@]}"; do
        log "Processing ${language}..."

        if [ "${create_db}" = true ]; then
            if ! create_database "${language}"; then
                failed_languages+=("${language}")
                continue
            fi
        fi

        if ! run_analysis "${language}"; then
            failed_languages+=("${language}")
            continue
        fi

        if [ "${print_summary}" = true ]; then
            print_results "${language}"
            echo ""
        fi
    done

    # Report results
    if [ ${#failed_languages[@]} -eq 0 ]; then
        success "CodeQL analysis completed successfully for all languages"
        exit 0
    else
        error "CodeQL analysis failed for: ${failed_languages[*]}"
        warn "Check logs above for specific error details"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
