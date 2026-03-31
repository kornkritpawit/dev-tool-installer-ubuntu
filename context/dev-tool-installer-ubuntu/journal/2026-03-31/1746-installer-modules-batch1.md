# 🔧 Installer Modules — Batch 1: System Essentials, Python, Node.js, .NET

**Date:** 2026-03-31 17:46 ICT  
**Status:** ✅ Completed  
**Task:** สร้าง installer modules สำหรับ 4 categories แรก

---

## สรุปงาน

สร้าง installer shell scripts 4 ไฟล์ ตาม architecture design ใน `architecture.md` โดยใช้ naming convention `{category}__{tool}__{function}()` และ `register_tool()` pattern จาก `lib/registry.sh`

## ไฟล์ที่สร้าง

### 1. `installers/system-essentials.sh` — 9 tools
| Tool ID | Display Name | Install | Detection |
|---------|-------------|---------|-----------|
| build_essential | Build Essential | apt | `is_package_installed` |
| curl | curl | apt | `is_command_available` |
| wget | wget | apt | `is_command_available` |
| git | Git | apt | `is_command_available` |
| unzip | unzip | apt | `is_command_available` |
| zip | zip | apt | `is_command_available` |
| software_properties | software-properties-common | apt | `is_package_installed` |
| apt_transport | apt-transport-https | apt | `is_package_installed` |
| ca_certificates | ca-certificates | apt | `is_package_installed` |

### 2. `installers/python.sh` — 5 tools
| Tool ID | Display Name | Install | Detection |
|---------|-------------|---------|-----------|
| python3 | Python 3 | apt (python3, python3-dev, python3-venv) | `is_command_available` |
| pip | pip | apt + ensurepip fallback + upgrade | `pip3` or `python3 -m pip` |
| poetry | Poetry | curl official installer | command or ~/.local/bin |
| uv | uv | curl astral.sh script | command or ~/.local/bin |
| build_deps | Python Build Dependencies | apt (setuptools, wheel) | `python3 -c "import setuptools"` |

### 3. `installers/nodejs.sh` — 4 tools
| Tool ID | Display Name | Install | Detection |
|---------|-------------|---------|-----------|
| nvm | NVM (Node Version Manager) | curl nvm install script v0.40.3 | `~/.nvm/nvm.sh` exists |
| nodejs20 | Node.js 20 LTS | `nvm install 20` + alias default | `node --version` contains v20 |
| npm | npm (latest) | `npm install -g npm@latest` | `is_command_available` |
| nodejs_tools | Node.js Dev Tools | `npm install -g pnpm nodemon typescript ts-node express-generator` | `pnpm` available |

### 4. `installers/dotnet.sh` — 1 tool
| Tool ID | Display Name | Install | Detection |
|---------|-------------|---------|-----------|
| dotnet_sdk | .NET SDK (latest LTS) | dotnet-install.sh --channel LTS, APT fallback | `dotnet` or `~/.dotnet/dotnet` |

## รวม Tools ทั้งหมด: **19 tools** across 4 categories

## Design Decisions

1. **git**: ไม่ทำ user config prompt — แค่ install เท่านั้นตามที่ task ระบุ
2. **poetry/uv**: เพิ่ม `$HOME/.local/bin` ใน PATH ทั้ง current session และ .bashrc
3. **nvm**: ใช้ helper function `_ensure_nvm_loaded()` เพื่อ source nvm.sh ก่อนใช้งาน
4. **nodejs20/npm/nodejs_tools**: มี dependency chain — ถ้า dependency ไม่มี จะพยายาม install ให้อัตโนมัติ
5. **dotnet**: Primary = official script (user-space, no sudo), Fallback = Microsoft APT repo
6. **.bashrc PATH**: ใช้ comment markers เพื่อ identify entries ที่ installer เพิ่ม

## Conventions ที่ใช้
- ทุก function ใช้ `local` variables
- ใช้ `log_info`, `log_success`, `log_error`, `log_warning` จาก core.sh
- ใช้ `run_sudo` จาก sudo-helper.sh สำหรับ apt commands
- ใช้ `ensure_apt_updated` ก่อน apt install
- ใช้ `is_command_available`, `is_package_installed` จาก core.sh
- ใช้ `download_file` จาก core.sh สำหรับ retry-enabled downloads
- ทุก install function return 0 (success) หรือ 1 (fail)
- 4 spaces indentation, LF line endings