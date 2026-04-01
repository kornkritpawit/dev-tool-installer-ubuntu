# 📚 Dev Tool Installer Ubuntu — Context Index

> Ubuntu Desktop version ของ Dev Tool Installer (Shell Script + whiptail TUI)

## Project Files

### Entry Point
- [`install.sh`](../../install.sh) — Main entry point: OS checks, source libs, TUI flow

### Libraries
- [`lib/core.sh`](../../lib/core.sh) — Core utilities: logging, colors, OS detection, download helpers, real user detection
- [`lib/sudo-helper.sh`](../../lib/sudo-helper.sh) — Privilege management: sudo caching, keep-alive
- [`lib/registry.sh`](../../lib/registry.sh) — Tool registry: categories, tool metadata, registration
- [`lib/tui.sh`](../../lib/tui.sh) — TUI functions: whiptail wrappers for interactive flow

### Installer Modules (9 categories, 41 tools)
- [`installers/system-essentials.sh`](../../installers/system-essentials.sh) — 🔧 System Essentials (9 tools): build-essential, curl, wget, git, unzip, zip, software-properties-common, apt-transport-https, ca-certificates
- [`installers/python.sh`](../../installers/python.sh) — 🐍 Python Development (5 tools): Python 3, pip, Poetry, uv, build dependencies
- [`installers/nodejs.sh`](../../installers/nodejs.sh) — 📦 Node.js Development (4 tools): NVM, Node.js 20 LTS, npm, dev tools
- [`installers/dotnet.sh`](../../installers/dotnet.sh) — 🟣 .NET Development (1 tool): .NET SDK latest LTS
- [`installers/devops.sh`](../../installers/devops.sh) — 🐳 DevOps Tools (3 tools): Docker Engine, Docker Compose, Docker Configuration
- [`installers/editors.sh`](../../installers/editors.sh) — 📝 Editors and IDEs (3 tools): VS Code, 32 extensions, settings
- [`installers/terminal-shell.sh`](../../installers/terminal-shell.sh) — 🖥️ Terminal and Shell (6 tools): Oh My Zsh, Powerlevel10k, Oh My Zsh Config, CaskaydiaCove font, TH Sarabun PSK, GNOME Terminal
- [`installers/applications.sh`](../../installers/applications.sh) — 📦 Applications (7 tools): Postman, RustDesk, WireGuard, Chrome, Firefox, Brave, Opera
- [`installers/desktop-settings.sh`](../../installers/desktop-settings.sh) — 🖥️ Desktop Settings (3 tools): GNOME settings, browser privacy policies, LibreOffice config

### Configuration Templates
- [`config/vscode-settings.json`](../../config/vscode-settings.json) — VS Code user settings template

### Test Scripts
- [`tests/run-all-tests.sh`](../../tests/run-all-tests.sh) — Test runner: executes all tests in order with summary
- [`tests/test-syntax.sh`](../../tests/test-syntax.sh) — Bash syntax validation via `bash -n`
- [`tests/test-structure.sh`](../../tests/test-structure.sh) — Project structure validation (files, JSON)
- [`tests/test-functions.sh`](../../tests/test-functions.sh) — Function registration validation (3 functions per tool)
- [`tests/test-registry.sh`](../../tests/test-registry.sh) — Registry count validation (categories, tools)

### Bundled Assets
- [`font/`](../../font/) — Font files directory (place THSARABUN_PSK.zip here)

## Documents

- [architecture.md](architecture.md) — Complete architecture document: project structure, module system, tool mapping, TUI flow, installation patterns, error handling, logging

## Journal

- [2026-03-31/1720-architecture-design.md](journal/2026-03-31/1720-architecture-design.md) — Architecture design session: analysis of Windows reference, key design decisions, outcomes
- [2026-03-31/1745-core-framework.md](journal/2026-03-31/1745-core-framework.md) — Core framework implementation: project structure, lib files, install.sh entry point
- [2026-03-31/1746-installer-modules-batch1.md](journal/2026-03-31/1746-installer-modules-batch1.md) — Installer modules batch 1: system-essentials, python, nodejs
- [2026-03-31/1752-installer-modules-batch2.md](journal/2026-03-31/1752-installer-modules-batch2.md) — Installer modules batch 2: dotnet, devops, editors
- [2026-03-31/1800-installer-modules-batch3.md](journal/2026-03-31/1800-installer-modules-batch3.md) — Installer modules batch 3: terminal-shell, applications, desktop-settings
- [2026-03-31/1803-integration-review.md](journal/2026-03-31/1803-integration-review.md) — Integration review: full project audit, bug fixes, documentation updates
- [2026-03-31/1810-test-scripts-qa.md](journal/2026-03-31/1810-test-scripts-qa.md) — Test scripts & QA: syntax validation, structure checks, function/registry validation
- [2026-03-31/1840-libreoffice-config.md](journal/2026-03-31/1840-libreoffice-config.md) — LibreOffice configuration: Thai locale, fonts, A4, .docx default
- [2026-03-31/2045-fix-silent-exit-bug.md](journal/2026-03-31/2045-fix-silent-exit-bug.md) — Fix silent exit bug
- [2026-04-01/0230-oh-my-zsh-migration.md](journal/2026-04-01/0230-oh-my-zsh-migration.md) — Oh My Zsh migration notes
- [2026-04-01/0755-fix-unbound-variable-categories.md](journal/2026-04-01/0755-fix-unbound-variable-categories.md) — Fix unbound variable in categories
- [2026-04-01/0900-review-fix-ohmyzsh-font-extensions-tui.md](journal/2026-04-01/0900-review-fix-ohmyzsh-font-extensions-tui.md) — Review & fix: Powerlevel10k, CaskaydiaCove font, VS Code extensions, TUI default selection, is_installed audit