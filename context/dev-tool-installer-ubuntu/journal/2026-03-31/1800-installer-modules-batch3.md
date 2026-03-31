# 📦 Installer Modules — Batch 3: Applications + Desktop Settings

**Date:** 2026-03-31 18:00 (UTC+7)  
**Task:** สร้าง installer modules สำหรับ Applications และ Desktop Settings categories

---

## ไฟล์ที่สร้าง

### 1. `installers/applications.sh` — Applications Category (7 tools)

| Tool ID | Display Name | Install Method | Detection | always_run |
|---------|-------------|----------------|-----------|------------|
| postman | Postman | `snap install postman` | `snap list postman` | false |
| rustdesk | RustDesk | GitHub API → .deb download + `dpkg -i` (fallback: hardcoded v1.3.9) | `command -v rustdesk` / `dpkg -l rustdesk` | false |
| wireguard | WireGuard | `apt install wireguard wireguard-tools` | `command -v wg` | false |
| chrome | Google Chrome | .deb download จาก dl.google.com + `dpkg -i` + fix deps | `command -v google-chrome-stable` / `google-chrome` | false |
| firefox | Firefox | `snap install firefox` (preferred) → fallback `apt install firefox` | `command -v firefox` | false |
| brave | Brave Browser | Brave APT repo (GPG key + sources.list.d) + `apt install brave-browser` | `command -v brave-browser` | false |
| opera | Opera Browser | Opera APT repo (GPG key + sources.list.d) + `apt install opera-stable` | `command -v opera` | false |

**Design decisions:**
- **RustDesk**: ใช้ GitHub API (`/repos/rustdesk/rustdesk/releases/latest`) + jq เพื่อหา latest amd64.deb URL ถ้า API fail จะ fallback ไป hardcoded version 1.3.9
- **Chrome**: .deb จะเพิ่ม apt repo เองหลัง install ไม่ต้องเพิ่มเอง
- **Firefox**: Ubuntu 22.04+ ใช้ snap เป็น default ตรวจว่ามีก่อน ถ้ามีแล้ว skip ถ้ายังไม่มีลอง snap ก่อน → apt fallback
- **Brave/Opera**: ใช้ pattern เดียวกัน — add GPG keyring → add sources.list.d → apt install

### 2. `installers/desktop-settings.sh` — Desktop Settings Category (2 tools)

| Tool ID | Display Name | Install Method | Detection | always_run |
|---------|-------------|----------------|-----------|------------|
| gnome_settings | GNOME Desktop Settings | `gsettings` commands | ตรวจ key values | true |
| browser_policies | Browser Privacy Policies | สร้าง JSON policy files | ตรวจ file exists | true |

**GNOME Settings ที่ apply:**
- Show hidden files in Nautilus
- Dark theme (`prefer-dark` + `Yaru-dark`)
- Show battery percentage
- Window button layout (close, minimize, maximize)
- Disable screen idle timeout (idle-delay 0)

**Browser Policies ที่ deploy:**
- **Chrome** → `/etc/opt/chrome/policies/managed/dev-tool-installer.json`
- **Brave** → `/etc/brave/policies/managed/dev-tool-installer.json`
- **Firefox** → `/etc/firefox/policies/policies.json`

Policy content: ปิด password manager, autofill, notifications, translate, telemetry, Firefox studies, Pocket + เปิด tracking protection

**Design decisions:**
- gsettings ต้อง run เป็น real user (ไม่ใช่ root) — ใช้ `su - $REAL_USER -c` เมื่อ run ผ่าน sudo
- ตรวจ `command -v gsettings` ก่อน — ถ้าไม่มี (headless server) skip gracefully
- Browser policies จะ deploy เฉพาะ browser ที่ installed อยู่จริง
- Firefox snap vs apt ใช้ policy location เดียวกัน (`/etc/firefox/policies/policies.json`)

---

## สรุป Batch 3

| Category | Tools | Files |
|----------|-------|-------|
| Applications | 7 | `installers/applications.sh` |
| Desktop Settings | 2 | `installers/desktop-settings.sh` |
| **รวม** | **9** | **2 files** |

## Convention ที่ใช้
- Naming: `{category}__{tool}__{function}()` — double underscore separator
- LF line endings, 4 spaces indentation
- ใช้ functions จาก `core.sh`: `log_info`, `log_success`, `log_warning`, `log_error`, `log_debug`, `is_command_available`, `is_package_installed`, `is_snap_installed`, `ensure_apt_updated`, `download_file`
- ใช้ `run_sudo` จาก `sudo-helper.sh` สำหรับ privileged commands
- `register_tool` จาก `registry.sh` สำหรับ register tools
- `REAL_USER` / `REAL_HOME` สำหรับ user-space operations

## Cumulative Progress

| Batch | Categories | Tools | Status |
|-------|-----------|-------|--------|
| Batch 1 | System Essentials, Python, Node.js | 18 | ✅ Done |
| Batch 2 | .NET, DevOps, Editors, Terminal & Shell | 12 | ✅ Done |
| Batch 3 | Applications, Desktop Settings | 9 | ✅ Done |
| **Total** | **9 categories** | **39 tools** | **✅ Complete** |