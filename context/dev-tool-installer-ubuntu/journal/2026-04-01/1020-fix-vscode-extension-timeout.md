# Fix: VSCode Extensions All Timeout During Installation

**Date:** 2026-04-01 10:20 (ICT)  
**Task:** Fix VSCode extensions timeout issue  
**File:** `installers/editors.sh`

## Problem

All 33 VSCode extensions were timing out during installation (every single one hitting the 180s timeout). This affected every extension uniformly, suggesting a systemic issue rather than individual extension problems.

## Root Cause Analysis

### Primary Cause: `su -` loses environment variables

The install function used `su - "$REAL_USER" -c "timeout 180 code --install-extension ..."` which creates a **fresh login shell** that does NOT inherit critical environment variables:

- `DISPLAY` — X11 display connection
- `WAYLAND_DISPLAY` — Wayland display connection
- `DBUS_SESSION_BUS_ADDRESS` — D-Bus session bus (IPC)
- `XDG_RUNTIME_DIR` — Electron temp files / runtime dir

VS Code is an Electron app. Without these vars, the `code` CLI may attempt to connect to D-Bus, IPC sockets, or resolve XDG paths and **hang indefinitely** until the 180s timeout kills it.

### Secondary Issue: `2>/dev/null` hid all errors

The command had `2>/dev/null` **inside** the `su -c` string, which suppressed all stderr from `code` and `timeout`. The outer `>> "$LOG_FILE" 2>&1` only captured stderr from `su` itself, not from the inner commands. This made debugging impossible.

## Changes Made

### 1. Added `_build_vscode_env_prefix()` helper function (new)

Builds an environment variable prefix string that preserves DISPLAY, WAYLAND_DISPLAY, DBUS_SESSION_BUS_ADDRESS, and XDG_RUNTIME_DIR when available. This prefix is prepended to commands inside `su -c`.

### 2. Fixed `editors__vscode_extensions__is_installed()`

- Now uses `_build_vscode_env_prefix()` to pass env vars through `su -c`
- Moved `2>/dev/null` to the outer command level for proper error handling

### 3. Fixed `editors__vscode_extensions__install()` — 4 improvements

1. **Environment variables**: All `su -c` calls now include env prefix to preserve DISPLAY/DBUS/XDG vars
2. **Removed `2>/dev/null` from inner commands**: stderr from `code` and `timeout` now properly flows to `$LOG_FILE` for debugging
3. **Added code CLI pre-check**: Runs `code --version` under `su -` context with 15s timeout before attempting extension installs. Fails fast with clear error message if VS Code CLI is not functional
4. **Added network pre-check**: Tests connectivity to `marketplace.visualstudio.com` with 15s timeout. Logs warning but continues (extensions may be cached)
5. **Added exit code to failure messages**: Failed extensions now log their exit code for easier debugging

### 4. Retry logic also fixed

Retry block now also uses env prefix and removed `2>/dev/null`

## Files Modified

| File | Lines | Change |
|------|-------|--------|
| `installers/editors.sh` | 59-76 (new) | Added `_build_vscode_env_prefix()` helper |
| `installers/editors.sh` | ~143-158 | Fixed `is_installed()` with env prefix |
| `installers/editors.sh` | ~160-240 | Rewrote `install()` with all 4 fixes |

## Verification

- `bash -n installers/editors.sh` — syntax check passed (exit code 0)
- No other files required changes

## Impact

- Should resolve the universal timeout issue for all extensions
- Proper error logging enables future debugging
- Pre-checks provide early failure with actionable error messages
- No breaking changes to existing functionality