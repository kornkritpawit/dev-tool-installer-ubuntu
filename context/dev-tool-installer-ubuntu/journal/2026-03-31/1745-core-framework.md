# Core Framework Implementation

> **Date:** 2026-03-31 17:45 (ICT)  
> **Task:** สร้าง project structure + core framework files

## สิ่งที่ทำ

### 1. Directory Structure
สร้างโครงสร้างตาม architecture.md:
- `lib/` — library files (core.sh, sudo-helper.sh, registry.sh, tui.sh)
- `installers/` — ว่าง, รอ installer modules
- `config/` — ว่าง, รอ config templates
- `font/` — ว่าง, รอ font files
- `.gitattributes` — enforce LF line endings สำหรับ .sh files

### 2. lib/core.sh — Core Utilities
- Color constants (RED, GREEN, YELLOW, BLUE, CYAN, BOLD, RESET)
- Logging functions: `log_info()`, `log_success()`, `log_warning()`, `log_error()`, `log_debug()`
- `run_cmd()` — command wrapper พร้อม logging
- Detection helpers: `is_command_available()`, `is_package_installed()`, `is_snap_installed()`
- OS detection: `get_ubuntu_version()`, `get_ubuntu_codename()`, `get_distro_id()`, `is_ubuntu()`
- `ensure_apt_updated()` — apt update กับ flag ป้องกัน duplicate
- `download_file()` — download พร้อม retry support (curl/wget)
- `add_apt_repository_key()` — เพิ่ม GPG key + apt repo
- Global variables: `SCRIPT_DIR`, `LOG_FILE`, `APT_UPDATED`, counters, result arrays

### 3. lib/sudo-helper.sh — Privilege Management
- `ensure_sudo()` — ขอ sudo ล่วงหน้า, warn ถ้า running as root
- `keep_sudo_alive()` — background loop renew sudo ทุก 50 วินาที
- `stop_sudo_keeper()` — kill background process
- `run_sudo()` — wrapper สำหรับ sudo command พร้อม logging

### 4. lib/registry.sh — Tool Registry
- `CATEGORIES` array — 9 categories ตาม architecture
- `TOOLS` array — ว่าง, populated โดย installer modules ผ่าน `register_tool()`
- `SELECTED_TOOLS` array — populated โดย TUI
- Registration: `register_tool()`
- Init: `registry_init()` — source all installer modules
- Category queries: `registry_get_categories()`, `registry_get_category_name()`, `registry_get_category_description()`
- Tool queries: `registry_get_tools()`, `registry_get_tool_name()`, `registry_get_tool_description()`
- Install: `registry_is_tool_installed()`, `registry_install_tool()` (with subshell isolation)
- Selection: `registry_select_tool()`, `registry_clear_selections()`, `registry_get_all_selected_tools()`
- Stats: `registry_get_tool_count()`, `registry_get_new_tool_count()`

### 5. lib/tui.sh — TUI Functions
- Terminal size detection: `tui_detect_size()` กับ clamping
- Basic helpers: `tui_msgbox()`, `tui_yesno()`, `tui_gauge()`, `tui_infobox()`
- `tui_welcome()` — welcome screen กับ system info
- `tui_category_checklist()` — category selection พร้อม tool count
- `tui_tool_checklist()` — per-category tool selection พร้อม installed status
- `tui_confirm_install()` — confirmation dialog กับ summary
- `tui_run_installation()` — install loop กับ progress tracking
- `tui_show_summary()` — summary screen (success/failed/skipped)
- `tui_ask_logout()` — logout prompt
- `tui_main_flow()` — orchestrate complete TUI flow

### 6. install.sh — Main Entry Point
- `set -euo pipefail` strict mode
- Pre-flight: bash version check, Ubuntu check, whiptail check (auto-install)
- Source libraries ตามลำดับ: core → sudo-helper → registry → tui
- Signal handlers: Ctrl+C (INT), exit cleanup, ERR handler
- Main flow: logging init → sudo → registry init → TUI flow

### 7. README.md
- Quick Start guide
- Tool categories table (39 tools, 9 categories)
- Project structure tree
- Architecture overview
- Installer module convention docs

## Key Design Decisions

1. **`register_tool()` pattern** — แทนที่จะ hardcode TOOLS array, installer modules เรียก `register_tool()` ทำให้ modular กว่า
2. **Subshell isolation** — `registry_install_tool()` รัน install function ใน subshell ป้องกัน `set -e` จาก propagate
3. **Source order** — core → sudo-helper → registry → tui เพราะ tui ใช้ functions จาก registry ซึ่งใช้ functions จาก core
4. **`.gitattributes`** — enforce LF สำหรับ .sh files เพราะพัฒนาบน Windows แต่ run บน Linux

## สิ่งที่ยังไม่ได้ทำ (next subtasks)
- [ ] สร้าง installer modules (installers/*.sh)
- [ ] สร้าง config files (vscode-settings.json, etc.)
- [ ] สร้าง .gitignore
- [ ] Testing on Ubuntu