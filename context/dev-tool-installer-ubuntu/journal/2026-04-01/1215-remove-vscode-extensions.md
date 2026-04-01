# Remove VS Code Extensions from Installer

**Date:** 2026-04-01 12:15 (UTC+7)
**Type:** Feature Removal

## Reason
VS Code Extensions installation ใช้เวลานานมาก (ค้างที่ "Verifying VS Code CLI works under user") เพราะต้องเปิด Electron runtime ผ่าน `su -` ซึ่งช้าและไม่เสถียร ผู้ใช้ตัดสินใจลบออกทั้งหมด

## What Was Removed

### `installers/editors.sh`
- `VSCODE_EXTENSIONS` array (33 extensions)
- `_build_vscode_env_prefix()` helper function
- `editors__vscode_extensions__description()`
- `editors__vscode_extensions__is_installed()`
- `editors__vscode_extensions__install()` (รวม retry logic, marketplace check)
- `register_tool "editors" "vscode_extensions" "VS Code Extensions" "true"`

### `tests/test-registry.sh`
- editors tool count: 3 → 2
- total tools: 40 → 39

### `context/dev-tool-installer-ubuntu/architecture.md`
- ลบ vscode_extensions จากทุก section ที่เกี่ยวข้อง

## What Was Kept
- `editors__vscode__*` (VS Code installation) — ยังคงอยู่
- `editors__vscode_settings__*` (VS Code Settings sync) — ยังคงอยู่

## Files Modified
- `installers/editors.sh`
- `tests/test-registry.sh`
- `context/dev-tool-installer-ubuntu/architecture.md`