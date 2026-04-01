# Add ModelHarbor.modelharbor-agent VSCode Extension

**Date:** 2026-04-01 10:03 (UTC+7)
**Type:** Feature Addition

## Summary

Added the `ModelHarbor.modelharbor-agent` VSCode extension to the `VSCODE_EXTENSIONS` array in [`installers/editors.sh`](../../../../installers/editors.sh). The extension is placed in the **AI** category, immediately after `github.copilot-chat`.

## Files Modified

### [`installers/editors.sh`](../../../../installers/editors.sh)

Three changes were made:

1. **Line 12 — Comment count update**
   - Changed extension count from `32` to `33` in the header comment.

2. **Line 43 — Array entry**
   - Added `"ModelHarbor.modelharbor-agent"` to the `VSCODE_EXTENSIONS` array under the AI section, after `github.copilot-chat`.

3. **Line 125 — Description function**
   - Added a description entry for the new extension in the `get_extension_description()` function.

## Impact

- Total VSCode extension count increased from **32 → 33**.
- No changes to installation logic or control flow.
- No breaking changes to existing functionality.

## Test Scripts

No test script modifications required — the test files (`tests/test-structure.sh`, `tests/test-functions.sh`, etc.) do not contain hardcoded extension counts. Extension count validation is dynamic.