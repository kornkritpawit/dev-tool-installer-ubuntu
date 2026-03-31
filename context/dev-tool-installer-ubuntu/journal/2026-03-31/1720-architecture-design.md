# 📝 Journal: Architecture Design — Dev Tool Installer Ubuntu

> **Date:** 2026-03-31 17:20 (ICT)  
> **Task:** ออกแบบ Architecture สำหรับ Ubuntu Desktop version ของ dev-tool-installer

---

## บริบท

ได้รับ task ให้ออกแบบ architecture สำหรับ **Dev Tool Installer — Ubuntu Desktop Version** โดย map จาก Windows version ที่ใช้ C# .NET 10 + AOT มาเป็น Shell Script + whiptail TUI

## การวิเคราะห์ Reference Project

สำรวจ Windows reference project เพื่อเข้าใจ pattern:

### Key Files ที่ศึกษา
- `IInstaller.cs` — Interface pattern: Name, Category, Description, Dependencies, AlwaysRun, IsInstalledAsync, InstallAsync
- `ToolRegistry.cs` — Static list ของ IInstaller instances, จัดกลุ่มตาม DevelopmentCategory enum (4 categories)
- `MenuSystem.cs` — TUI flow: CategoryGroup + DisplayRow, nested category/tool list, scroll, batch install
- `DevelopmentCategory.cs` — Enum: CSharp, Python, NodeJS, CrossPlatform
- ตัวอย่าง Installers: GitInstaller (winget + fallback), VSCodeInstaller (extensions + settings merge), DockerDesktopInstaller (config + auto-start), OhMyPoshInstaller (theme + profile + terminal config), FontInstaller (download + registry + broadcast)

### Pattern ที่เรียนรู้
1. **Dual install strategy**: ทุก tool มี primary method + fallback
2. **Configuration-after-install**: หลาย tool ไม่แค่ install แต่ config ด้วย (VS Code settings, Docker config, Oh My Posh profile)
3. **AlwaysRun pattern**: บาง items เช่น fonts, settings ต้อง re-apply ทุกครั้ง
4. **Flat category list**: Windows ใช้ 4 categories เป็น flat list, Ubuntu ควรแยกละเอียดกว่า

## การตัดสินใจสำคัญ

### 1. Tech Stack: Shell Script + whiptail
- **เหตุผล**: Zero dependencies บน Ubuntu, Linux culture ใช้ shell scripts
- **ข้อดี**: ไม่ต้อง compile, แก้ไขง่าย, portable
- **ข้อเสีย**: ไม่มี type safety, testing ยากกว่า

### 2. Module Pattern: Naming Convention Functions
- Windows ใช้ IInstaller interface → Ubuntu ใช้ function naming convention: `category__tool__function()`
- เลือก double underscore `__` เพื่อแยก category, tool, function ชัดเจน
- ทุก tool ต้อง implement: `__description()`, `__is_installed()`, `__install()`

### 3. Categories: 9 หมวดแทน 4
- Windows มี 4 categories (CSharp, Python, NodeJS, CrossPlatform)
- Ubuntu แยกเป็น 9 categories เพราะ:
  - เพิ่ม **System Essentials** (build-essential etc.) — Linux-specific
  - แยก **DevOps** จาก CrossPlatform
  - แยก **Terminal/Shell** จาก CrossPlatform
  - แยก **Desktop Settings** จาก CrossPlatform

### 4. Font Install: User-space แทน System-wide
- Windows ต้อง admin install ไป C:\Windows\Fonts + registry
- Ubuntu: install ไป `~/.local/share/fonts/` + `fc-cache -fv` → ไม่ต้อง sudo

### 5. Tool Count: 39 vs 28
- Ubuntu เพิ่ม System Essentials 9 ตัว (Linux prerequisites)
- Skip 5 tools ที่ Windows-specific (Notepad++, Windows Terminal, PowerShell 7, WSL2, VC++ Build Tools)
- แยก VS Code Extensions/Settings เป็น separate items (always_run)

## ผลลัพธ์

สร้าง architecture document ที่ `context/dev-tool-installer-ubuntu/architecture.md` ครอบคลุม:
- Project directory structure (install.sh + lib/ + installers/ + config/ + font/)
- Module system design (naming convention + registry arrays)
- Complete tool mapping table (39 tools, 9 categories)
- TUI flow design (5 screens: main menu, tool selection, progress, summary, logout)
- Installation patterns (7 patterns: apt, apt-repo, snap, curl, binary, deb, config-only)
- Error handling (set -e, trap, subshell isolation, retry)
- Logging strategy (timestamped log file)
- Privilege management (sudo caching + background keepalive)
- Idempotency guarantees
- Mermaid diagrams (component architecture + install flow sequence)
- Windows vs Ubuntu comparison table

## Next Steps

- [ ] Review architecture กับ user
- [ ] เริ่ม implementation ตาม architecture
- [ ] สร้าง lib/core.sh, lib/tui.sh, lib/registry.sh ก่อน
- [ ] สร้าง installers ทีละ category เริ่มจาก system-essentials