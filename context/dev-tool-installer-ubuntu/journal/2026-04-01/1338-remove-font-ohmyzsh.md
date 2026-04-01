# Remove Font and Oh My Zsh Installers

**Date:** 2026-04-01 13:38 (UTC+7)
**Type:** Feature Removal
**Requested by:** User

## Reason

User requested removal due to persistent issues:
- Font installation failures
- Oh My Zsh compatibility issues

These tools caused more problems than they solved, so they were removed entirely.

## Changes

### Modified Files

1. **`installers/terminal-shell.sh`**
   - Removed 5 installer functions: `oh_my_zsh`, `powerlevel10k`, `oh_my_zsh_config`, `font_cascadia`, `font_thsarabun`
   - Removed helper functions: `_FC_LIST_CACHE`, `_get_fc_list`
   - Remaining: `gnome_terminal` only (1 tool)

2. **`lib/registry.sh`**
   - Updated `terminal_shell` category description to reflect reduced scope

3. **`README.md`**
   - Updated total tool count: 40 → 35
   - Removed `font/` directory from project structure listing

4. **`tests/test-registry.sh`**
   - Updated expected counts: `terminal_shell` 5 → 1, total 39 → 35

5. **`context/dev-tool-installer-ubuntu/architecture.md`**
   - Removed all Oh My Zsh and font-related sections

### Deleted Files/Directories

- `font/` directory (entire directory removed)

## What Was Preserved

- `gnome_terminal` tool remains functional in `terminal-shell.sh`
- Zsh was never a standalone installer in this project (it was only configured via Oh My Zsh)

## Impact

- 5 tools removed from the project
- Simpler `terminal-shell` module with single responsibility
- No font management overhead