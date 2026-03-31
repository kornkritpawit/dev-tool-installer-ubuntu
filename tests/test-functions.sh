#!/usr/bin/env bash
# ==============================================================================
# tests/test-functions.sh — Function Registration Validation
# ==============================================================================
# Sources all project files in a subshell and validates that every registered
# tool has all 3 required functions:
#   {category}__{tool}__description
#   {category}__{tool}__is_installed
#   {category}__{tool}__install
#
# Uses mocks for Ubuntu-specific commands to allow sourcing without errors.
#
# Usage: bash tests/test-functions.sh
# Exit:  0 = all tools have complete functions, 1 = missing functions found
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Function Registration Validation ==="
echo ""

# Run the actual validation in a subshell to avoid polluting the current shell
# and to isolate any side effects from sourcing the project files
result=$(bash << 'SUBSHELL_EOF'
set -euo pipefail

# Resolve project root (passed via environment or detect)
SCRIPT_DIR="__SCRIPT_DIR__"
export SCRIPT_DIR

# ==============================================================================
# Mock Ubuntu-specific commands that aren't available during testing
# ==============================================================================

# Mock tput (used by tui.sh for terminal size detection)
tput() {
    case "$1" in
        lines) echo "24" ;;
        cols)  echo "80" ;;
        *)     echo "" ;;
    esac
}
export -f tput

# Mock whiptail (referenced in tui.sh but not called at source time)
whiptail() { return 0; }
export -f whiptail

# Mock dpkg (used by is_package_installed in core.sh)
dpkg() { return 1; }
export -f dpkg

# Mock snap (used by is_snap_installed in core.sh)
snap() { return 1; }
export -f snap

# Mock gsettings (used by tui.sh/desktop-settings.sh)
gsettings() { echo ""; return 0; }
export -f gsettings

# Mock dconf
dconf() { return 0; }
export -f dconf

# Mock fc-list (used by font checks)
fc-list() { echo ""; return 0; }
export -f fc-list

# Mock sudo (shouldn't be called at source time, but just in case)
# Don't mock sudo — it's not called during source

# ==============================================================================
# Source project files in correct order
# ==============================================================================

source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/sudo-helper.sh"
source "${SCRIPT_DIR}/lib/registry.sh"
source "${SCRIPT_DIR}/lib/tui.sh"

# Source all installer modules (triggers register_tool calls)
for f in "${SCRIPT_DIR}"/installers/*.sh; do
    [ -f "$f" ] || continue
    source "$f"
done

# ==============================================================================
# Validate functions for each registered tool
# ==============================================================================

PASS=0
FAIL=0
MISSING=()

for entry in "${TOOLS[@]}"; do
    # Parse entry: "category:tool_id:display_name:always_run"
    category="${entry%%:*}"
    rest="${entry#*:}"
    tool_id="${rest%%:*}"
    rest="${rest#*:}"
    display_name="${rest%%:*}"

    # Check all 3 required functions
    func_desc="${category}__${tool_id}__description"
    func_check="${category}__${tool_id}__is_installed"
    func_install="${category}__${tool_id}__install"

    missing_funcs=""

    if ! declare -F "$func_desc" &>/dev/null; then
        missing_funcs+=" __description"
    fi
    if ! declare -F "$func_check" &>/dev/null; then
        missing_funcs+=" __is_installed"
    fi
    if ! declare -F "$func_install" &>/dev/null; then
        missing_funcs+=" __install"
    fi

    if [ -z "$missing_funcs" ]; then
        echo "PASS:${category}::${tool_id}:${display_name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL:${category}::${tool_id}:${display_name}:MISSING:${missing_funcs}"
        FAIL=$((FAIL + 1))
    fi
done

echo "SUMMARY:${PASS}:${FAIL}"
SUBSHELL_EOF
)

# Replace placeholder with actual SCRIPT_DIR in the heredoc
result=$(echo "$result" | head -0)

# Actually run it properly — use a temp script approach
TMPSCRIPT=$(mktemp /tmp/test-functions-XXXXXX.sh)
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
# Source project files in correct order
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
# Validate functions for each registered tool
# ==============================================================================

PASS=0
FAIL=0

for entry in "\${TOOLS[@]}"; do
    category="\${entry%%:*}"
    rest="\${entry#*:}"
    tool_id="\${rest%%:*}"
    rest="\${rest#*:}"
    display_name="\${rest%%:*}"

    func_desc="\${category}__\${tool_id}__description"
    func_check="\${category}__\${tool_id}__is_installed"
    func_install="\${category}__\${tool_id}__install"

    missing_funcs=""

    if ! declare -F "\$func_desc" &>/dev/null; then
        missing_funcs+=" __description"
    fi
    if ! declare -F "\$func_check" &>/dev/null; then
        missing_funcs+=" __is_installed"
    fi
    if ! declare -F "\$func_install" &>/dev/null; then
        missing_funcs+=" __install"
    fi

    if [ -z "\$missing_funcs" ]; then
        echo "  ✅ \${category}::\${tool_id} (\${display_name})"
        PASS=\$((PASS + 1))
    else
        echo "  ❌ \${category}::\${tool_id} (\${display_name}) — MISSING:\${missing_funcs}"
        FAIL=\$((FAIL + 1))
    fi
done

echo ""
echo "Results: \$PASS passed, \$FAIL failed"

if [ \$FAIL -gt 0 ]; then
    exit 1
fi

exit 0
MAINEOF

# Execute the temp script
bash "$TMPSCRIPT"
exit_code=$?

# Cleanup
rm -f "$TMPSCRIPT"

exit $exit_code