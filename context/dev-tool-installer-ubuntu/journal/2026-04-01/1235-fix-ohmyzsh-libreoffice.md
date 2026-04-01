# Fix: Oh My Zsh Plugin Overwrite + LibreOffice always_run

**Date:** 2026-04-01 12:35 (UTC+7)
**Type:** Bug Fix

## Problems Found

### 🔴 Oh My Zsh — Plugin list overwrite (CRITICAL)
- `oh_my_zsh_config__install()` ใช้ `sed -i 's/^plugins=.*/plugins=(...)/` ที่ **overwrite plugin list ทั้งหมด** ทุกครั้งที่รัน
- `always_run = "true"` → ผู้ใช้ที่เพิ่ม plugin เอง (nvm, aws, python) จะ **ถูกลบทิ้ง**

### 🔴 Oh My Zsh — ไม่มี .zshrc backup
- แก้ไข `.zshrc` ด้วย `sed -i` โดยตรง **ไม่มี backup**

### 🟡 LibreOffice — always_run=true ไม่จำเป็น
- `is_installed()` ตรวจ grep XCU จริงอยู่แล้ว ไม่จำเป็นต้อง always_run

## Changes

### `installers/terminal-shell.sh`
1. **Plugin additive approach** — เปลี่ยนจาก overwrite เป็นอ่าน current plugins แล้วเพิ่มเฉพาะที่ขาด
   - รองรับ: `plugins=()` ว่าง, มีอยู่แล้วบางส่วน, ไม่มีบรรทัด `plugins=` เลย
2. **Backup .zshrc** — เพิ่ม `cp "$zshrc" "${zshrc}.bak.$(date +%Y%m%d%H%M%S)"` ก่อนแก้ไข

### `installers/desktop-settings.sh`
- `register_tool "desktop_settings" "libreoffice_config"` เปลี่ยน `always_run` จาก `"true"` → `"false"`

## Files Modified
- `installers/terminal-shell.sh`
- `installers/desktop-settings.sh`