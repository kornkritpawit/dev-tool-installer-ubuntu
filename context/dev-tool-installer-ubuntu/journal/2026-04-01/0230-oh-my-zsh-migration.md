# Oh My Posh → Oh My Zsh Migration

**Date:** 2026-04-01
**Task:** เปลี่ยน shell prompt framework จาก Oh My Posh เป็น Oh My Zsh
**Status:** ✅ Completed

## Summary

ทำการ migrate จาก Oh My Posh (cross-platform prompt theme engine) เป็น Oh My Zsh (zsh configuration framework) ตามคำขอของ user

## Changes Made

### 1. `installers/terminal-shell.sh`
- เปลี่ยน functions `terminal_shell__oh_my_posh__*` → `terminal_shell__oh_my_zsh__*`
- เปลี่ยน functions `terminal_shell__oh_my_posh_config__*` → `terminal_shell__oh_my_zsh_config__*`
- Install method: ติดตั้ง zsh + oh-my-zsh official script + plugins (autosuggestions, syntax-highlighting)
- Config method: ตั้ง theme agnoster + enable plugins ใน .zshrc
- อัปเดต `register_tool` calls

### 2. `config/paradox.omp.json`
- **ลบ** — Oh My Posh theme config ไม่จำเป็นแล้ว (oh-my-zsh ใช้ built-in themes)

### 3. `tests/test-structure.sh`
- ลบ `check_json "config/paradox.omp.json"` เนื่องจากไฟล์ถูกลบ

### 4. `context/dev-tool-installer-ubuntu/architecture.md`
- อัปเดต 12 จุดที่อ้างอิง oh-my-posh ให้เป็น oh-my-zsh
- รวมถึง: directory structure, registry, tool mapping, detection strategy, install method, config files, shell profile content

## Key Decisions

| Decision | Rationale |
|---|---|
| ใช้ theme `agnoster` | เป็น theme ยอดนิยมที่รองรับ Nerd Font ซึ่งโปรเจคมี CaskaydiaMono อยู่แล้ว |
| ติดตั้ง plugins autosuggestions + syntax-highlighting | เป็น must-have plugins สำหรับ zsh productivity |
| ลบ paradox.omp.json แทนที่จะเปลี่ยน | oh-my-zsh ใช้ระบบ theme ต่างจาก oh-my-posh สิ้นเชิง — JSON config ใช้ไม่ได้ |
| เปลี่ยน default shell เป็น zsh | oh-my-zsh ทำงานบน zsh เท่านั้น |

## Files Modified
- `installers/terminal-shell.sh` — major changes
- `tests/test-structure.sh` — minor (1 line removed)
- `context/dev-tool-installer-ubuntu/architecture.md` — documentation updates (12 points)

## Files Deleted
- `config/paradox.omp.json`

## Notes
- NVM integration: ผู้ใช้อาจต้อง source NVM ใน `.zshrc` ด้วยถ้าเปลี่ยน default shell
- GNOME Terminal font config ไม่ต้องเปลี่ยน — CaskaydiaMono Nerd Font ยังใช้ได้กับ oh-my-zsh