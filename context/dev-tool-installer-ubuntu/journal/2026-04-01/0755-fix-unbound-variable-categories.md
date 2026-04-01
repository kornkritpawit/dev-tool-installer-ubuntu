# Fix: CATEGORIES unbound variable (registry.sh line 98)

**Date**: 2026-04-01 07:55 ICT  
**Type**: Bug Fix  
**Status**: Completed

## Problem

After the previous fix (silent exit bug), a new error appeared:

```
[SUCCESS] 07:54:40 sudo access granted
/home/admins/.../lib/registry.sh: line 98: CATEGORIES: unbound variable
```

## Root Cause

`install.sh` uses `set -euo pipefail` where `-u` (nounset) treats unset variables as errors.

The **real issue** was that `install.sh` sources all library files inside the `source_libraries()` **function** (line 84-101):

```bash
source_libraries() {
    source "${lib_dir}/core.sh"      # ← sourced inside a function
    source "${lib_dir}/registry.sh"  # ← sourced inside a function
    ...
}
```

In bash, when `declare -a VARIABLE=(...)` is executed inside a function (even via `source`), it creates a **local** variable scoped to that function. When `source_libraries()` returns, the local variables `CATEGORIES`, `TOOLS`, `SELECTED_TOOLS` (from registry.sh) and `FAILED_TOOLS`, `SUCCESS_TOOLS`, `SKIPPED_TOOLS` (from core.sh) are **destroyed**.

When `main()` later calls `registry_init()` which references `${#CATEGORIES[@]}`, the variable no longer exists → `set -u` raises "unbound variable".

## Fix Applied

Changed `declare -a VAR=(...)` to plain `VAR=(...)` in:

### lib/registry.sh
- `declare -a CATEGORIES=(...)` → `CATEGORIES=(...)`
- `declare -a TOOLS=()` → `TOOLS=()`
- `declare -a SELECTED_TOOLS=()` → `SELECTED_TOOLS=()`

### lib/core.sh
- `declare -a FAILED_TOOLS=()` → `FAILED_TOOLS=()`
- `declare -a SUCCESS_TOOLS=()` → `SUCCESS_TOOLS=()`
- `declare -a SKIPPED_TOOLS=()` → `SKIPPED_TOOLS=()`

**Why this works**: In bash, plain assignment (without `declare`/`local`/`typeset`) always creates/modifies a **global** variable, even when executed inside a function. This ensures the arrays survive after `source_libraries()` returns.

## Files Modified

- `lib/registry.sh` — 3 changes (lines 20, 39, 53)
- `lib/core.sh` — 3 changes (lines 55-57)

## Key Lesson

**Never use `declare` at the top-level of a file that will be `source`d inside a function**, unless you want local scope. Use plain assignment for global variables.