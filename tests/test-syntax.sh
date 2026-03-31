#!/usr/bin/env bash
# ==============================================================================
# tests/test-syntax.sh — Bash Syntax Validation
# ==============================================================================
# Validates bash syntax for all .sh files in the project using `bash -n`.
# This catches syntax errors without executing any code.
#
# Usage: bash tests/test-syntax.sh
# Exit:  0 = all files pass, 1 = syntax errors found
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=()

echo "=== Bash Syntax Validation ==="
echo ""

for f in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh "$SCRIPT_DIR"/installers/*.sh; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    if bash -n "$f" 2>/dev/null; then
        echo "  ✅ $filename"
        ((PASS++))
    else
        echo "  ❌ $filename"
        ERRORS+=("$filename: $(bash -n "$f" 2>&1)")
        ((FAIL++))
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "=== Errors ==="
    for err in "${ERRORS[@]}"; do
        echo "  $err"
    done
    exit 1
fi

exit 0