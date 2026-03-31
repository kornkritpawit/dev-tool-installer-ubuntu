#!/usr/bin/env bash
# ==============================================================================
# tests/run-all-tests.sh — Test Runner
# ==============================================================================
# Runs all test scripts in order and displays a summary.
#
# Test execution order:
#   1. test-syntax.sh      — Bash syntax validation (must pass first)
#   2. test-structure.sh   — Project structure validation
#   3. test-functions.sh   — Function registration validation (requires syntax pass)
#   4. test-registry.sh    — Registry count validation (requires syntax pass)
#
# Usage: bash tests/run-all-tests.sh
# Exit:  0 = all tests pass, 1 = one or more tests failed
# ==============================================================================

set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

# ------------------------------------------------------------------------------
# Helper: Run a single test
# ------------------------------------------------------------------------------
run_test() {
    local test_file="$1"
    local test_name="$2"
    local require_syntax="${3:-false}"

    TOTAL=$((TOTAL + 1))

    # Skip if syntax test failed and this test requires it
    if [ "$require_syntax" = "true" ] && [ "$SYNTAX_PASSED" = "false" ]; then
        echo -e "${YELLOW}⏭️  SKIP: ${test_name} (syntax test failed)${RESET}"
        SKIPPED=$((SKIPPED + 1))
        RESULTS+=("SKIP: ${test_name}")
        echo ""
        return
    fi

    echo -e "${CYAN}${BOLD}▶ Running: ${test_name}${RESET}"
    echo "─────────────────────────────────────────────"

    if bash "${TEST_DIR}/${test_file}"; then
        echo -e "${GREEN}✅ PASS: ${test_name}${RESET}"
        PASSED=$((PASSED + 1))
        RESULTS+=("PASS: ${test_name}")
    else
        echo -e "${RED}❌ FAIL: ${test_name}${RESET}"
        FAILED=$((FAILED + 1))
        RESULTS+=("FAIL: ${test_name}")
    fi

    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Dev Tool Installer — Test Suite            ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

SYNTAX_PASSED="true"

# --- Test 1: Syntax Validation ---
run_test "test-syntax.sh" "Bash Syntax Validation"

# Check if syntax test passed
if [ "$FAILED" -gt 0 ]; then
    SYNTAX_PASSED="false"
fi

# --- Test 2: Structure Validation ---
run_test "test-structure.sh" "Project Structure Validation"

# --- Test 3: Function Registration (requires syntax pass) ---
run_test "test-functions.sh" "Function Registration Validation" "true"

# --- Test 4: Registry Count (requires syntax pass) ---
run_test "test-registry.sh" "Registry Count Validation" "true"

# ==============================================================================
# Summary
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}                   SUMMARY${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for result in "${RESULTS[@]}"; do
    case "$result" in
        PASS:*) echo -e "  ${GREEN}✅ ${result}${RESET}" ;;
        FAIL:*) echo -e "  ${RED}❌ ${result}${RESET}" ;;
        SKIP:*) echo -e "  ${YELLOW}⏭️  ${result}${RESET}" ;;
    esac
done

echo ""
echo -e "  Total:   ${TOTAL}"
echo -e "  Passed:  ${GREEN}${PASSED}${RESET}"
echo -e "  Failed:  ${RED}${FAILED}${RESET}"
echo -e "  Skipped: ${YELLOW}${SKIPPED}${RESET}"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}${BOLD}❌ TESTS FAILED${RESET}"
    exit 1
else
    echo -e "${GREEN}${BOLD}✅ ALL TESTS PASSED${RESET}"
    exit 0
fi