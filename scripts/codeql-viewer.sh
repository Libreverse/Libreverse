#!/usr/bin/env bash

# CodeQL Results Viewer
# This script helps view and interpret CodeQL analysis results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEQL_RESULTS_DIR="${PROJECT_ROOT}/.codeql/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                                CodeQL Results Viewer                              ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
}

print_summary() {
    local language="$1"
    local results_file="${CODEQL_RESULTS_DIR}/${language}-results.sarif"
    local readable_results="${CODEQL_RESULTS_DIR}/${language}-results.txt"

    echo -e "\n${CYAN}📊 ${language} Analysis Results${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────────${NC}"

    if [ ! -f "${results_file}" ]; then
        echo -e "${YELLOW}⚠️  No results file found for ${language}${NC}"
        echo -e "   Expected: ${results_file}"
        return 1
    fi

    # Check if jq is available for JSON parsing
    if command -v jq >/dev/null 2>&1; then
        local total_findings
        total_findings=$(jq -r '.runs[0].results | length' "${results_file}" 2>/dev/null || echo "0")

        if [ "${total_findings}" -eq 0 ]; then
            echo -e "${GREEN}✅ No security or quality issues found!${NC}"
            return 0
        fi

        echo -e "${PURPLE}📈 Total findings: ${total_findings}${NC}"

        # Count by severity level
        local error_count warning_count note_count
        error_count=$(jq -r '.runs[0].results | map(select(.level == "error")) | length' "${results_file}" 2>/dev/null || echo "0")
        warning_count=$(jq -r '.runs[0].results | map(select(.level == "warning")) | length' "${results_file}" 2>/dev/null || echo "0")
        note_count=$(jq -r '.runs[0].results | map(select(.level == "note")) | length' "${results_file}" 2>/dev/null || echo "0")

        [ "${error_count}" -gt 0 ] && echo -e "${RED}🚨 Errors: ${error_count}${NC}"
        [ "${warning_count}" -gt 0 ] && echo -e "${YELLOW}⚠️  Warnings: ${warning_count}${NC}"
        [ "${note_count}" -gt 0 ] && echo -e "${BLUE}ℹ️  Notes: ${note_count}${NC}"

        # Show top issues by rule
        echo -e "\n${CYAN}🔍 Top Issues by Rule:${NC}"
        jq -r '.runs[0].results | group_by(.ruleId) | map({rule: .[0].ruleId, count: length, level: .[0].level}) | sort_by(-.count) | .[:5] | .[] | "   \(.rule): \(.count) (\(.level))"' "${results_file}" 2>/dev/null | while read -r line; do
            # Color code by severity mentioned in the line
            if [[ "$line" == *"error"* ]]; then
                echo -e "${RED}   ${line}${NC}"
            elif [[ "$line" == *"warning"* ]]; then
                echo -e "${YELLOW}   ${line}${NC}"
            else
                echo -e "${BLUE}   ${line}${NC}"
            fi
        done

    else
        echo -e "${YELLOW}⚠️  jq not available - install jq for detailed analysis${NC}"
        echo -e "   SARIF file: ${results_file}"
    fi

    # Show human-readable results if available
    if [ -f "${readable_results}" ] && [ -s "${readable_results}" ]; then
        echo -e "\n${CYAN}📋 Human-readable results available at:${NC}"
        echo -e "   ${readable_results}"
    fi
}

print_detailed_findings() {
    local language="$1"
    local limit="${2:-10}"
    local results_file="${CODEQL_RESULTS_DIR}/${language}-results.sarif"

    if [ ! -f "${results_file}" ]; then
        echo -e "${YELLOW}⚠️  No results file found for ${language}${NC}"
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  jq required for detailed findings. Install with: brew install jq${NC}"
        return 1
    fi

    echo -e "\n${CYAN}🔍 Detailed Findings (Top ${limit}) - ${language}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"

    jq -r --arg limit "${limit}" '.runs[0].results[:($limit | tonumber)] | .[] | "
🚨 \(.ruleId // "Unknown Rule")
   Severity: \(.level // "unknown")
   Message: \(.message.text // "No message")
   File: \(.locations[0].physicalLocation.artifactLocation.uri // "unknown")
   Line: \(.locations[0].physicalLocation.region.startLine // "unknown")
   "' "${results_file}" 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" == 🚨* ]]; then
            echo -e "${RED}${line}${NC}"
        elif [[ "$line" == *"Severity: error"* ]]; then
            echo -e "${RED}   ${line}${NC}"
        elif [[ "$line" == *"Severity: warning"* ]]; then
            echo -e "${YELLOW}   ${line}${NC}"
        elif [[ "$line" == *"Severity:"* ]]; then
            echo -e "${BLUE}   ${line}${NC}"
        else
            echo -e "   ${line}"
        fi
    done
}

show_files() {
    echo -e "\n${CYAN}📁 Available Result Files:${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"

    if [ ! -d "${CODEQL_RESULTS_DIR}" ]; then
        echo -e "${YELLOW}⚠️  Results directory not found: ${CODEQL_RESULTS_DIR}${NC}"
        echo -e "   Run CodeQL analysis first with: scripts/codeql-local.sh"
        return 1
    fi

    local found_files=false
    for file in "${CODEQL_RESULTS_DIR}"/*.sarif "${CODEQL_RESULTS_DIR}"/*.txt; do
        if [ -f "$file" ]; then
            found_files=true
            local basename=$(basename "$file")
            local size=$(du -h "$file" | cut -f1)
            local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "   📄 ${basename} (${size}, ${mtime})"
        fi
    done

    if [ "$found_files" = false ]; then
        echo -e "${YELLOW}⚠️  No result files found${NC}"
        echo -e "   Run CodeQL analysis first with: scripts/codeql-local.sh"
    fi
}

print_help() {
    echo "Usage: $0 [OPTIONS] [LANGUAGE]"
    echo ""
    echo "View CodeQL analysis results for Ruby and JavaScript/TypeScript code."
    echo ""
    echo "Arguments:"
    echo "  LANGUAGE    Language to view results for (ruby, javascript, all)"
    echo "              Default: all"
    echo ""
    echo "Options:"
    echo "  --detailed, -d        Show detailed findings (default: summary only)"
    echo "  --limit N             Limit detailed findings to N results (default: 10)"
    echo "  --files, -f           List available result files"
    echo "  --help, -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Show summary for all languages"
    echo "  $0 ruby               # Show summary for Ruby only"
    echo "  $0 --detailed         # Show detailed findings for all languages"
    echo "  $0 -d ruby --limit 5  # Show top 5 detailed findings for Ruby"
    echo "  $0 --files            # List available result files"
}

main() {
    local show_detailed=false
    local limit=10
    local show_files_only=false
    local languages=("ruby" "javascript")

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        --detailed | -d)
            show_detailed=true
            shift
            ;;
        --limit)
            limit="$2"
            shift 2
            ;;
        --files | -f)
            show_files_only=true
            shift
            ;;
        --help | -h)
            print_help
            exit 0
            ;;
        ruby | javascript)
            languages=("$1")
            shift
            ;;
        all)
            languages=("ruby" "javascript")
            shift
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            exit 1
            ;;
        esac
    done

    print_header

    if [ "$show_files_only" = true ]; then
        show_files
        exit 0
    fi

    for language in "${languages[@]}"; do
        print_summary "$language"

        if [ "$show_detailed" = true ]; then
            print_detailed_findings "$language" "$limit"
        fi
    done

    echo -e "\n${CYAN}💡 Tips:${NC}"
    echo -e "   • Use --detailed flag to see specific findings"
    echo -e "   • Install jq for better JSON parsing: brew install jq"
    echo -e "   • SARIF files can be viewed in VS Code with the SARIF viewer extension"
    echo -e "   • Run 'scripts/codeql-local.sh' to update analysis results"
}

main "$@"
