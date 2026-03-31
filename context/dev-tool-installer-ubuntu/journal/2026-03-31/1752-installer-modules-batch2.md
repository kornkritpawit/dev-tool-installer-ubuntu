# Installer Modules — Batch 2: DevOps, Editors & IDEs, Terminal & Shell

**Date:** 2026-03-31 17:52 (UTC+7)
**Status:** ✅ Completed

## สรุป

สร้าง installer modules batch 2 จำนวน 3 ไฟล์ + config files 2 ไฟล์ ครอบคลุม 11 tools ใน 3 categories

## ไฟล์ที่สร้าง

### Config Files
| ไฟล์ | รายละเอียด |
|------|-----------|
| `config/vscode-settings.json` | VS Code user settings (fonts, formatting, themes, language-specific formatters) |
| `config/paradox.omp.json` | Oh My Posh paradox theme (os, session, path, git segments + ❯ prompt) |

### Installer Modules
| ไฟล์ | Category | Tools |
|------|----------|-------|
| `installers/devops.sh` | DevOps Tools (3) | docker, docker_compose, docker_config |
| `installers/editors.sh` | Editors & IDEs (3) | vscode, vscode_extensions, vscode_settings |
| `installers/terminal-shell.sh` | Terminal & Shell (5) | oh_my_posh, oh_my_posh_config, font_cascadia, font_thsarabun, gnome_terminal |

## Tool Details

### DevOps (devops) — 3 tools
- **docker** — Docker Engine install จาก official APT repo (remove old → GPG key → add repo → install docker-ce + cli + containerd + buildx + compose plugin → usermod -aG docker)
- **docker_compose** — Docker Compose v2 plugin detection + fallback standalone binary
- **docker_config** — daemon.json (log rotation, address pool) + pgvector/pgvector:pg16 image pull with retry

### Editors (editors) — 3 tools
- **vscode** — VS Code .deb download + dpkg install (ไม่ใช้ snap เพื่อ full file access)
- **vscode_extensions** — 31 extensions install via `su - $REAL_USER -c "code --install-extension"` (threshold: ≥20 = installed)
- **vscode_settings** — Copy/merge config/vscode-settings.json → ~/.config/Code/User/settings.json (jq merge if available)

### Terminal & Shell (terminal_shell) — 5 tools
- **oh_my_posh** — Install via official curl script to /usr/local/bin
- **oh_my_posh_config** — Deploy paradox.omp.json theme + add eval to .bashrc (idempotent)
- **font_cascadia** — Download CascadiaMono.zip from Nerd Fonts GitHub → extract → ~/.local/share/fonts/ → fc-cache
- **font_thsarabun** — Extract bundled font/THSARABUN_PSK.zip → ~/.local/share/fonts/ → fc-cache
- **gnome_terminal** — dconf write: custom font (CaskaydiaMono NF 12), Solarized Dark colors, 10000 scrollback, no bell

## Conventions ที่ใช้
- `REAL_USER="${SUDO_USER:-$USER}"` / `REAL_HOME=$(eval echo "~${REAL_USER}")` สำหรับ user-specific paths
- Naming: `{category}__{tool}__{description|is_installed|install}()`
- Registration: `register_tool "category" "tool_id" "Display Name" ["true"]`
- always_run=true สำหรับ config/font tools (vscode_extensions, vscode_settings, oh_my_posh_config, font_cascadia, font_thsarabun, gnome_terminal)
- Error isolation, retry patterns, graceful fallbacks ตาม architecture spec
- ใช้ `run_sudo`, `ensure_apt_updated`, `download_file`, `is_command_available`, `is_package_installed` จาก core.sh/sudo-helper.sh

## หมายเหตุ
- font/THSARABUN_PSK.zip ยังเป็น placeholder (.gitkeep) — ต้องใส่ไฟล์จริงก่อนใช้งาน
- pgvector pull อาจ fail ถ้า Docker ยัง start ไม่เสร็จ — graceful skip + warning
- VS Code extensions ต้องรันเป็น real user (ไม่ใช่ root)
- GNOME Terminal config ต้องเปิด terminal อย่างน้อย 1 ครั้งก่อนจึงจะมี profile