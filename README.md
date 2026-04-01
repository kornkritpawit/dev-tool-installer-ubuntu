# 🛠️ Dev Tool Installer — Ubuntu Desktop

Automated development environment setup for Ubuntu Desktop using an interactive TUI (whiptail).

> **Version:** 1.0.0  
> **Target OS:** Ubuntu Desktop 22.04+ / 24.04+  
> **Tech Stack:** Shell Script (bash) + whiptail TUI

## ✨ Features

- **Interactive TUI** — Category and tool selection via whiptail checklist
- **Idempotent** — Safe to run multiple times; checks before installing
- **Modular** — Each category is a separate installer module
- **Comprehensive Logging** — All output logged to `/tmp/dev-tool-installer-*.log`
- **Sudo Caching** — Prompts once, keeps credentials alive throughout

## 📋 Requirements

- Ubuntu Desktop 22.04+ or 24.04+
- bash 4.0+
- Internet connection
- `whiptail` (auto-installed if missing)

## 🚀 Quick Start

```bash
git clone <repo-url> dev-tool-installer-ubuntu
cd dev-tool-installer-ubuntu
chmod +x install.sh
./install.sh
```

## 📦 Tool Categories (40 tools across 9 categories)

| Category | Tools | Description |
|----------|-------|-------------|
| 🔧 System Essentials | 9 | build-essential, curl, wget, git, unzip, zip, software-properties-common, apt-transport-https, ca-certificates |
| 🐍 Python Development | 5 | Python 3, pip, Poetry, uv, build dependencies |
| 📦 Node.js Development | 4 | NVM, Node.js 20 LTS, npm, dev tools (pnpm, typescript, etc.) |
| 🟣 .NET Development | 1 | .NET SDK (latest LTS) |
| 🐳 DevOps Tools | 3 | Docker Engine, Docker Compose, Docker Configuration (daemon.json) |
| 📝 Editors and IDEs | 3 | VS Code + 31 extensions + settings.json |
| 🖥️ Terminal and Shell | 5 | Oh My Zsh, Oh My Zsh Config, CaskaydiaMono Nerd Font, TH Sarabun PSK, GNOME Terminal config |
| 📦 Applications | 7 | Postman, RustDesk, WireGuard, Chrome, Firefox, Brave, Opera |
| 🖥️ Desktop Settings | 3 | GNOME desktop settings, browser privacy policies, LibreOffice configuration |

**Total: 40 tools** across 9 categories.

## 📁 Project Structure

```
dev-tool-installer-ubuntu/
├── install.sh                          # Main entry point (executable)
├── README.md                           # This file
├── lib/
│   ├── core.sh                         # Core utilities: logging, colors, helpers, real user detection
│   ├── sudo-helper.sh                  # Privilege management: sudo caching, keep-alive
│   ├── registry.sh                     # Tool registry: categories, tool metadata, registration
│   └── tui.sh                          # TUI functions: whiptail wrappers for interactive flow
├── installers/
│   ├── system-essentials.sh            # 🔧 build-essential, curl, wget, git, etc. (9 tools)
│   ├── python.sh                       # 🐍 Python 3, pip, Poetry, uv, build deps (5 tools)
│   ├── nodejs.sh                       # 📦 NVM, Node.js 20, npm, dev tools (4 tools)
│   ├── dotnet.sh                       # 🟣 .NET SDK latest LTS (1 tool)
│   ├── devops.sh                       # 🐳 Docker CE, Compose, daemon config (3 tools)
│   ├── editors.sh                      # 📝 VS Code + extensions + settings (3 tools)
│   ├── terminal-shell.sh               # 🖥️ Oh My Zsh, config, fonts, GNOME Terminal (5 tools)
│   ├── applications.sh                 # 📦 Postman, RustDesk, WireGuard, browsers (7 tools)
│   └── desktop-settings.sh             # 🖥️ GNOME settings, browser policies, LibreOffice config (3 tools)
├── config/
│   ├── .gitkeep
│   └── vscode-settings.json            # VS Code user settings template
├── font/
│   └── (THSARABUN_PSK.zip)            # Bundled TH Sarabun PSK font (place here)
└── context/                            # Architecture & planning docs
    ├── INDEX.md
    └── dev-tool-installer-ubuntu/
        ├── INDEX.md
        ├── architecture.md
        └── journal/
```

## 🏗️ Architecture

The installer follows a modular design:

1. **`install.sh`** — Entry point that sources all libraries and runs the TUI flow
2. **`lib/core.sh`** — Logging, color output, OS detection, download helpers, real user detection
3. **`lib/sudo-helper.sh`** — sudo credential caching with background keep-alive
4. **`lib/registry.sh`** — Tool registration system with category/tool metadata
5. **`lib/tui.sh`** — whiptail wrappers for the interactive TUI flow

### Source Order

```
install.sh → lib/core.sh → lib/sudo-helper.sh → lib/registry.sh → lib/tui.sh → installers/*.sh
```

### TUI Flow

```
Welcome → Category Checklist → Tool Checklist (per category) → Confirm → Install → Summary → Logout?
```

### Installer Module Convention

Each installer module defines tools using the naming pattern:

```bash
{category}__{tool}__description()    # Return tool description
{category}__{tool}__is_installed()   # Return 0 if installed
{category}__{tool}__install()        # Perform installation
```

Tools are registered at the bottom of each module via `register_tool()`:

```bash
register_tool "python" "poetry" "Poetry" "false"
#              ^category ^tool_id ^display  ^always_run
```

## 📝 Logging

All operations are logged to `/tmp/dev-tool-installer-YYYYMMDD-HHMMSS.log` with entries like:

```
[INFO]    17:20:00 Starting Dev Tool Installer v1.0.0
[SUCCESS] 17:20:18 Installed: python3-venv
[ERROR]   17:20:45 Failed: RustDesk (exit code: 1)
```

## 🧪 Testing

Test scripts are designed to run on **Ubuntu** (bash, not PowerShell) and validate the project before deployment.

### Run All Tests

```bash
bash tests/run-all-tests.sh
```

### Individual Tests

| Test | Command | Description |
|------|---------|-------------|
| Syntax | `bash tests/test-syntax.sh` | Validates bash syntax for all `.sh` files via `bash -n` |
| Structure | `bash tests/test-structure.sh` | Checks all required files/directories exist; validates JSON configs |
| Functions | `bash tests/test-functions.sh` | Sources all modules and verifies every registered tool has 3 required functions |
| Registry | `bash tests/test-registry.sh` | Validates category count (9), total tool count (40), and per-category counts |

### Test Files

```
tests/
├── run-all-tests.sh      # Test runner — runs all tests in order with summary
├── test-syntax.sh         # Bash syntax validation (bash -n)
├── test-structure.sh      # Project structure validation
├── test-functions.sh      # Function registration validation
└── test-registry.sh       # Registry count validation
```

### Notes

- Tests use mocks for Ubuntu-specific commands (`dpkg`, `snap`, `gsettings`, etc.)
- `test-functions.sh` and `test-registry.sh` require syntax test to pass first
- All test scripts exit `0` (pass) or `1` (fail)

## ⚠️ Notes

- Run as a **normal user** (not root) — sudo is requested when needed
- The script uses `set -euo pipefail` for strict error handling
- Each tool installation is isolated in a subshell — one failure won't stop others
- Press **Ctrl+C** at any time to cancel gracefully
- Some changes require **logout** to take effect (Docker group, fonts, PATH updates)

## 📄 License

*TBD*