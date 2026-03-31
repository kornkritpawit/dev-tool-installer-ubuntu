# 1840 — LibreOffice Configuration Tool

## Task
เพิ่ม tool ใหม่ `libreoffice_config` ใน Desktop Settings category สำหรับ configure LibreOffice ที่ติดตั้งมากับ Ubuntu

## Changes

### `installers/desktop-settings.sh`
- เพิ่ม 3 functions ตาม registry pattern:
  - `desktop_settings__libreoffice_config__description()` — คืน description string
  - `desktop_settings__libreoffice_config__is_installed()` — ตรวจ `registrymodifications.xcu` ว่ามี TH SarabunPSK และ MS Word 2007 XML settings
  - `desktop_settings__libreoffice_config__install()` — configure LibreOffice โดยเขียน XML entries ลง registrymodifications.xcu
- Register tool: `register_tool "desktop_settings" "libreoffice_config" "LibreOffice Configuration" "true"`

### Configuration Applied
| Setting | Value |
|---------|-------|
| Default CTL Font (Thai) | TH SarabunPSK (display, heading, spreadsheet, text) |
| Paper Size | A4 |
| Default Locale | th |
| UI Locale | th |
| Auto Save | Enabled, every 5 minutes |
| Default Writer Format | MS Word 2007 XML (.docx) |
| Default Calc Format | Calc MS Excel 2007 XML (.xlsx) |
| Default Impress Format | Impress MS PowerPoint 2007 XML (.pptx) |
| First Start Wizard | Completed (disabled) |

### Implementation Approach
- เขียน `<item>` XML entries ตรงเข้า `$REAL_HOME/.config/libreoffice/4/user/registrymodifications.xcu`
- Idempotent: ตรวจ oor:path + oor:name ก่อน insert เพื่อไม่ให้ซ้ำ
- Handle กรณี LibreOffice ยังไม่เคยเปิด → `soffice --headless --terminate_after_init` เพื่อสร้าง profile
- Kill running instances ก่อน modify
- Backup xcu file ก่อนแก้ไข
- Handle sudo context ด้วย `su - $REAL_USER`

### `tests/test-registry.sh`
- desktop_settings count: 2 → 3
- Total tools: 39 → 40

### `README.md`
- Tool count: 39 → 40
- Desktop Settings description updated to include LibreOffice configuration

## Status
✅ Complete