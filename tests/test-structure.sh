#!/usr/bin/env bash
# ==============================================================================
# tests/test-structure.sh — Project Structure Validation
# ==============================================================================
# Validates that all required files and directories exist in the project.
# Also validates JSON config files for correct syntax.
#
# Usage: bash tests/test-structure.sh
# Exit:  0 = all checks pass, 1 = missing files or invalid configs
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Project Structure Validation ==="
echo ""

# ------------------------------------------------------------------------------
# Helper: Check file exists
# ------------------------------------------------------------------------------
check_file() {
    local filepath="$1"
    local description="${2:-$filepath}"

    if [ -f "${SCRIPT_DIR}/${filepath}" ]; then
        echo "  ✅ ${description}"
        ((PASS++))
    else
        echo "  ❌ ${description} — MISSING: ${filepath}"
        ((FAIL++))
    fi
}

# ------------------------------------------------------------------------------
# Helper: Check file exists and is executable
# ------------------------------------------------------------------------------
check_executable() {
    local filepath="$1"
    local description="${2:-$filepath}"

    if [ -f "${SCRIPT_DIR}/${filepath}" ]; then
        if [ -x "${SCRIPT_DIR}/${filepath}" ]; then
            echo "  ✅ ${description} (executable)"
            ((PASS++))
        else
            echo "  ⚠️  ${description} — exists but NOT executable"
            ((FAIL++))
        fi
    else
        echo "  ❌ ${description} — MISSING: ${filepath}"
        ((FAIL++))
    fi
}

# ------------------------------------------------------------------------------
# Helper: Check file exists and is valid JSON
# ------------------------------------------------------------------------------
check_json() {
    local filepath="$1"
    local description="${2:-$filepath}"

    if [ ! -f "${SCRIPT_DIR}/${filepath}" ]; then
        echo "  ❌ ${description} — MISSING: ${filepath}"
        ((FAIL++))
        return
    fi

    # Try python3 for JSON validation, fallback to jq, fallback to basic check
    if command -v python3 &>/dev/null; then
        if python3 -c "import json; json.load(open('${SCRIPT_DIR}/${filepath}'))" 2>/dev/null; then
            echo "  ✅ ${description} (valid JSON)"
            ((PASS++))
        else
            echo "  ❌ ${description} — INVALID JSON"
            ((FAIL++))
        fi
    elif command -v jq &>/dev/null; then
        if jq empty "${SCRIPT_DIR}/${filepath}" 2>/dev/null; then
            echo "  ✅ ${description} (valid JSON)"
            ((PASS++))
        else
            echo "  ❌ ${description} — INVALID JSON"
            ((FAIL++))
        fi
    else
        # No JSON validator available — just check file exists
        echo "  ✅ ${description} (exists, no JSON validator available)"
        ((PASS++))
    fi
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

echo "--- Main Entry Point ---"
check_executable "install.sh" "install.sh"

echo ""
echo "--- Library Files ---"
check_file "lib/core.sh" "lib/core.sh"
check_file "lib/sudo-helper.sh" "lib/sudo-helper.sh"
check_file "lib/registry.sh" "lib/registry.sh"
check_file "lib/tui.sh" "lib/tui.sh"

echo ""
echo "--- Installer Modules ---"
check_file "installers/system-essentials.sh" "installers/system-essentials.sh"
check_file "installers/python.sh" "installers/python.sh"
check_file "installers/nodejs.sh" "installers/nodejs.sh"
check_file "installers/dotnet.sh" "installers/dotnet.sh"
check_file "installers/devops.sh" "installers/devops.sh"
check_file "installers/editors.sh" "installers/editors.sh"
check_file "installers/terminal-shell.sh" "installers/terminal-shell.sh"
check_file "installers/applications.sh" "installers/applications.sh"
check_file "installers/desktop-settings.sh" "installers/desktop-settings.sh"

echo ""
echo "--- Config Files ---"
check_json "config/vscode-settings.json" "config/vscode-settings.json"
check_json "config/paradox.omp.json" "config/paradox.omp.json"

echo ""
echo "--- Documentation ---"
check_file "README.md" "README.md"
check_file ".gitattributes" ".gitattributes"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0