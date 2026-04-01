# Review & Fix: Oh My Zsh, Font, Extensions, TUI Default Selection

**Date:** 2026-04-01 09:00 UTC+7  
**Task:** ตรวจสอบและแก้ไข 5 ด้านหลักเพื่อให้ installer "ผ่านรอบเดียว"

## สรุปการตรวจสอบและแก้ไข

### 1. Oh My Zsh + Powerlevel10k Theme ✅

**ปัญหาที่พบ:**
- Theme ถูกตั้งเป็น `agnoster` → ผู้ใช้ต้องการ theme คล้าย Oh My Posh
- ไม่มี Powerlevel10k installer

**แก้ไข (`installers/terminal-shell.sh`):**
- เพิ่ม tool ใหม่ `powerlevel10k` — clone จาก GitHub repository
- เปลี่ยน `oh_my_zsh_config` จาก `ZSH_THEME="agnoster"` เป็น `ZSH_THEME="powerlevel10k/powerlevel10k"`
- เพิ่ม PATH migration ใน `.zshrc`:
  - `~/.local/bin` (Poetry, pip user installs)
  - NVM initialization (Node Version Manager)
  - `DOTNET_ROOT` (.NET SDK)
- `is_installed()` ตรวจ `grep 'powerlevel10k'` ใน `.zshrc`

### 2. CaskaydiaCove Nerd Font ✅

**ปัญหาที่พบ:**
- ปัจจุบัน download `CascadiaMono.zip` (CaskaydiaMono) → ไม่มี ligatures
- ผู้ใช้ต้องการ Cascadia Code variant (CaskaydiaCove) ที่มี ligatures

**แก้ไข (`installers/terminal-shell.sh`):**
- เปลี่ยน download URL จาก `CascadiaMono.zip` เป็น `CascadiaCode.zip`
- เปลี่ยน `is_installed()` จาก `grep -qi "CaskaydiaMono"` เป็น `grep -qi "CaskaydiaCove"`
- เปลี่ยน description เป็น "CaskaydiaCove Nerd Font — Cascadia Code patched with icons + ligatures"
- GNOME Terminal font เปลี่ยนเป็น `CaskaydiaCove Nerd Font Mono 12`

### 3. VS Code Extension List ✅

**ปัญหาที่พบ:**
- มี 31 extensions อยู่แล้ว แต่ขาด `ms-vscode.vscode-typescript-next`

**แก้ไข (`installers/editors.sh`):**
- เพิ่ม `ms-vscode.vscode-typescript-next` เข้า `VSCODE_EXTENSIONS` array
- อัพเดท count เป็น 32 extensions

**Extension list ปัจจุบัน (32 ตัว):**
- C#: csharp, csdevkit, vscode-dotnet-runtime
- Python: python, pylance, debugpy, black-formatter, isort, ruff
- TypeScript: vscode-typescript-next
- Web: eslint, prettier, tailwindcss, auto-rename-tag
- DevOps: docker, remote-containers, remote-ssh
- Git: gitlens, git-graph
- AI: copilot, copilot-chat
- Utilities: path-intellisense, material-icon-theme, rest-client, todo-tree, spell-checker, markdown-all-in-one, yaml, even-better-toml, rainbow-csv, hexeditor, trailing-spaces

### 4. TUI Default Selection → All ON ✅

**ปัญหาที่พบ:**
- Category checklist: เฉพาะ categories ที่มี "new tools" ถูก check ON
- Tool checklist: tools ที่ installed แล้วถูก set เป็น OFF (ยกเว้น always_run)
- ผู้ใช้ต้องเลือก tools ทีละตัว → ไม่สะดวก

**แก้ไข (`lib/tui.sh`):**
- `tui_category_checklist()`: ทุก category ถูก checked ON by default
- `tui_tool_checklist()`: ทุก tool ถูก checked ON by default (ไม่ว่าจะ installed หรือยัง)
- ผู้ใช้สามารถ uncheck ตัวที่ไม่ต้องการได้

### 5. is_installed Logic ✅

**ตรวจสอบทุก installer module — สรุป:**

| Module | Tools | is_installed Logic | Status |
|--------|-------|--------------------|--------|
| system-essentials | 9 tools | `is_package_installed` / `is_command_available` | ✅ ถูกต้อง |
| python | 5 tools | `is_command_available` / `python3 -c import` | ✅ ถูกต้อง |
| nodejs | 4 tools | `_ensure_nvm_loaded` + command check | ✅ ถูกต้อง |
| dotnet | 1 tool | `is_command_available` + `~/.dotnet/dotnet` | ✅ ถูกต้อง |
| devops | 3 tools | `is_command_available` / `docker compose version` | ✅ ถูกต้อง |
| editors | 3 tools | `is_command_available` / extension count / file exists | ✅ ถูกต้อง |
| terminal-shell | 6 tools | dir exists / grep .zshrc / fc-list / dconf read | ✅ ถูกต้อง |
| applications | 7 tools | `is_command_available` / `is_snap_installed` | ✅ ถูกต้อง |
| desktop-settings | 3 tools | gsettings / file exists / grep xcu | ✅ ถูกต้อง |

**Skip logic (`tui_run_installation()`):**
- ถ้า `is_installed()` return 0 AND `always_run` = false → **skip** (ไม่ลงทับ)
- ถ้า `always_run` = true → **run ทุกครั้ง** (config tools เช่น gnome_settings, browser_policies)

### 6. VS Code Settings ✅

**แก้ไข (`config/vscode-settings.json`):**
- `editor.fontFamily`: เปลี่ยนเป็น `'CaskaydiaCove Nerd Font'` (มี ligatures)
- `terminal.integrated.fontFamily`: เปลี่ยนเป็น `'CaskaydiaCove Nerd Font Mono'` (mono for terminal)
- `terminal.integrated.defaultProfile.linux`: เปลี่ยนจาก `"bash"` เป็น `"zsh"`

## ไฟล์ที่แก้ไข

1. `installers/terminal-shell.sh` — เพิ่ม Powerlevel10k, เปลี่ยน font, PATH migration
2. `installers/editors.sh` — เพิ่ม TypeScript Next extension
3. `config/vscode-settings.json` — เปลี่ยน font + terminal profile
4. `lib/tui.sh` — All tools selected by default

## Tool Registration Order (terminal_shell)

```
1. oh_my_zsh         — Install Oh My Zsh + zsh + plugins
2. powerlevel10k     — Clone Powerlevel10k theme (always_run)
3. oh_my_zsh_config  — Configure .zshrc: theme + plugins + PATH (always_run)
4. font_cascadia     — Download CaskaydiaCove Nerd Font (always_run)
5. font_thsarabun    — Install TH Sarabun PSK bundled font (always_run)
6. gnome_terminal    — Configure GNOME Terminal: font + colors (always_run)