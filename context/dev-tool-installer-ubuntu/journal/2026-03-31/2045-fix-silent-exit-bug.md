# Fix: install.sh Silent Exit Bug

**Date:** 2026-03-31 20:45 (UTC+7)
**Type:** Bug Fix
**Severity:** Critical (script completely non-functional)

## Problem

Users reported that running `./install.sh` or `sudo ./install.sh` on Ubuntu produced **zero output** — no error, no menu, no indication of anything happening.

## Root Cause

**`set -e` + `[ ] && action` pattern in `tui_detect_size()` causing silent exit**

### Execution flow:

1. `install.sh:18` sets `set -euo pipefail`
2. `main()` calls `source_libraries()` at line 152
3. `source_libraries()` sources `lib/tui.sh` at line 101
4. `tui.sh:34` calls `tui_detect_size` **at source time** (top-level call, not inside a function definition)
5. `tui_detect_size()` ends with:
   ```bash
   [ "$LIST_HEIGHT" -lt 5 ] && LIST_HEIGHT=5
   ```
6. With a normal terminal (height ~24), `LIST_HEIGHT` ≈ 12, which is **not** less than 5
7. The `[ ]` test returns exit code **1** (false)
8. Since `&&` short-circuits, `LIST_HEIGHT=5` is never executed
9. The `[ ]` command with exit code 1 becomes the **last command of the function**
10. Function returns exit code **1**
11. `set -e` sees non-zero return → **script exits immediately**

### Why no error message:

- `trap handle_exit EXIT` and `trap 'error_handler $LINENO' ERR` are set at lines 156-157
- These come **after** `source_libraries()` at line 152
- Script exits before traps are registered → no error handler runs
- `log_info` (line 160) is never reached → no log file written

## Fix Applied

Added `return 0` at the end of `tui_detect_size()` in `lib/tui.sh`:

```bash
tui_detect_size() {
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    DIALOG_HEIGHT=$((TERM_HEIGHT - 4))
    DIALOG_WIDTH=$((TERM_WIDTH - 10))
    [ "$DIALOG_HEIGHT" -lt 15 ] && DIALOG_HEIGHT=15
    [ "$DIALOG_HEIGHT" -gt 40 ] && DIALOG_HEIGHT=40
    [ "$DIALOG_WIDTH" -lt 50 ] && DIALOG_WIDTH=50
    [ "$DIALOG_WIDTH" -gt 90 ] && DIALOG_WIDTH=90
    LIST_HEIGHT=$((DIALOG_HEIGHT - 8))
    [ "$LIST_HEIGHT" -lt 5 ] && LIST_HEIGHT=5

    return 0  # Prevent set -e from triggering on [ ] && pattern
}
```

## Audit Results

All `.sh` files were audited for the same `[ ] && action` pattern as last statement:

| Function | File | Pattern | Safe? | Reason |
|---|---|---|---|---|
| `tui_detect_size()` | lib/tui.sh:30 | `[ ] && action` (last line, source-time call) | **NO → FIXED** | void function, called outside `if` |
| `nodejs__nvm__is_installed()` | installers/nodejs.sh:57 | `[ ] && [ ]` (last line) | Yes | is_installed — designed to return 0/1 |
| `terminal_shell__oh_my_zsh__is_installed()` | installers/terminal-shell.sh:31 | `[ ]` (last line) | Yes | is_installed pattern |
| `terminal_shell__gnome_terminal__is_installed()` | installers/terminal-shell.sh:326 | `[ ]` (last line) | Yes | is_installed pattern |
| `editors__vscode_extensions__is_installed()` | installers/editors.sh:136 | `[ ]` (last line) | Yes | is_installed pattern |
| `editors__vscode_settings__is_installed()` | installers/editors.sh:191 | `[ ]` (last line) | Yes | is_installed pattern |

All `__is_installed()` functions are **intentionally** returning 0/1 and are always called from `if` contexts (which shield against `set -e`), so they are safe.

## Lesson Learned

**Classic bash gotcha**: When using `set -e`, any `[ test ] && action` as the last statement of a function will cause the function to return non-zero if the test is false. This applies even when the function is a "void" function that only sets variables.

**Best practice**: Always add `return 0` (or `|| true`) at the end of functions that use `[ ] && action` patterns and are not intended to signal failure through their return code.

## Files Changed

- `lib/tui.sh` — Added `return 0` to `tui_detect_size()`