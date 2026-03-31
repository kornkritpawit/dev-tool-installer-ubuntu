#!/usr/bin/env bash
# ==============================================================================
# tests/test-registry.sh — Registry Count Validation
# ==============================================================================
# Sources all project files and validates:
# - Total number of categories = 9
# - Total number of tools = 40
# - Each category has the expected tool count
#
# Usage: bash tests/test-registry.sh
# Exit:  0 = all counts match, 1 = count mismatch
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Registry Count Validation ==="
echo ""

# Expected counts per category
declare -A EXPECTED_COUNTS=(
    ["system_essentials"]=9
    ["python"]=5
    ["nodejs"]=4
    ["dotnet"]=1
    ["devops"]=3
    ["editors"]=3
    ["terminal_shell"]=5
    ["applications"]=7
    ["desktop_settings"]=3
)
EXPECTED_CATEGORIES=9
EXPECTED_TOTAL=40

# Create temp script that sources project files with mocks and reports counts
TMPSCRIPT=$(mktemp /tmp/test-registry-XXXXXX.sh)
cat > "$TMPSCRIPT" << MAINEOF
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR}"
export SCRIPT_DIR

# ==============================================================================
# Mock Ubuntu-specific commands
# ==============================================================================

tput() {
    case "\$1" in
        lines) echo "24" ;;
        cols)  echo "80" ;;
        *)     echo "" ;;
    esac
}
export -f tput

whiptail() { return 0; }
export -f whiptail

dpkg() { return 1; }
export -f dpkg

snap() { return 1; }
export -f snap

gsettings() { echo ""; return 0; }
export -f gsettings

dconf() { return 0; }
export -f dconf

fc-list() { echo ""; return 0; }
export -f fc-list

# ==============================================================================
# Source project files
# ==============================================================================

source "\${SCRIPT_DIR}/lib/core.sh"
source "\${SCRIPT_DIR}/lib/sudo-helper.sh"
source "\${SCRIPT_DIR}/lib/registry.sh"
source "\${SCRIPT_DIR}/lib/tui.sh"

for f in "\${SCRIPT_DIR}"/installers/*.sh; do
    [ -f "\$f" ] || continue
    source "\$f"
done

# ==============================================================================
# Report counts
# ==============================================================================

# Report category count
echo "CATEGORY_COUNT:\${#CATEGORIES[@]}"

# Report total tool count
echo "TOTAL_TOOLS:\${#TOOLS[@]}"

# Report per-category counts
for entry in "\${CATEGORIES[@]}"; do
    cat_id="\${entry%%:*}"
    count=0
    for tool_entry in "\${TOOLS[@]}"; do
        tool_cat="\${tool_entry%%:*}"
        if [ "\$tool_cat" = "\$cat_id" ]; then
            count=\$((count + 1))
        fi
    done
    echo "CAT:\${cat_id}:\${count}"
done
MAINEOF

# Execute the temp script and capture output
output=$(bash "$TMPSCRIPT" 2>/dev/null)
rm -f "$TMPSCRIPT"

# ==============================================================================
# Parse results and validate
# ==============================================================================

PASS=0
FAIL=0

# Extract category count
actual_categories=$(echo "$output" | grep "^CATEGORY_COUNT:" | cut -d: -f2)
if [ "$actual_categories" -eq "$EXPECTED_CATEGORIES" ]; then
    echo "  ✅ Category count: ${actual_categories} (expected: ${EXPECTED_CATEGORIES})"
    ((PASS++))
else
    echo "  ❌ Category count: ${actual_categories} (expected: ${EXPECTED_CATEGORIES})"
    ((FAIL++))
fi

# Extract total tool count
actual_total=$(echo "$output" | grep "^TOTAL_TOOLS:" | cut -d: -f2)
if [ "$actual_total" -eq "$EXPECTED_TOTAL" ]; then
    echo "  ✅ Total tools: ${actual_total} (expected: ${EXPECTED_TOTAL})"
    ((PASS++))
else
    echo "  ❌ Total tools: ${actual_total} (expected: ${EXPECTED_TOTAL})"
    ((FAIL++))
fi

echo ""
echo "--- Per-Category Counts ---"

# Validate each category's tool count
for cat_id in "${!EXPECTED_COUNTS[@]}"; do
    expected="${EXPECTED_COUNTS[$cat_id]}"
    actual=$(echo "$output" | grep "^CAT:${cat_id}:" | cut -d: -f3)

    if [ -z "$actual" ]; then
        echo "  ❌ ${cat_id}: NOT FOUND (expected: ${expected})"
        ((FAIL++))
    elif [ "$actual" -eq "$expected" ]; then
        echo "  ✅ ${cat_id}: ${actual} tools (expected: ${expected})"
        ((PASS++))
    else
        echo "  ❌ ${cat_id}: ${actual} tools (expected: ${expected})"
        ((FAIL++))
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0