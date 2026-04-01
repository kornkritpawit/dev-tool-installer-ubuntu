# Performance Optimization: is_installed() Cache & Fast Checks

**Date:** 2026-04-01 11:00 (UTC+7)
**Type:** Performance Fix

## Problem
เมื่อผู้ใช้เคยติดตั้งทุกอย่างแล้ว รันใหม่ ระบบค้าง 30-90 วินาทีก่อนแสดง UI
- `registry_get_new_tool_count()` เรียก `is_installed()` ทุก 41 tools โดยไม่มี cache
- `is_installed()` ถูกเรียก 3 ครั้งต่อ tool (category checklist, tool checklist, install)
- `code --list-extensions` ช้า 15-30 วินาที (Electron startup)
- `snap list` ช้า 5-15 วินาที (snapd daemon)
- `fc-list` ช้า 1-3 วินาที (font cache scan) × 2 ครั้ง

## Changes

### 1. `lib/registry.sh` — Install Cache
- เพิ่ม `declare -gA _INSTALL_CACHE=()` 
- แก้ `registry_is_tool_installed()` ให้ cache ผลลัพธ์
- เพิ่ม `registry_clear_cache()` และ `registry_clear_tool_cache()`

### 2. `installers/editors.sh` — Filesystem Check
- แทน `code --list-extensions` (Electron) ด้วย `find ~/.vscode/extensions` (filesystem)

### 3. `lib/core.sh` — Snap Fast Path
- `is_snap_installed()` เช็ค `/snap/bin/<name>` ก่อน (instant) แล้ว fallback เป็น `snap list`

### 4. `installers/terminal-shell.sh` — fc-list Cache
- เพิ่ม `_FC_LIST_CACHE` + `_get_fc_list()` helper
- `fc-list` รันแค่ 1 ครั้ง แทน 2+ ครั้ง

### 5. `lib/tui.sh` — Clear Cache After Install
- เพิ่ม `registry_clear_tool_cache` หลัง install แต่ละ tool

## Performance Impact
- **Before:** ~30-90 seconds (41 tools × 3 calls × slow commands)
- **After:** ~1-3 seconds (cache + filesystem checks + fast path)

## Files Modified
- `lib/registry.sh`
- `lib/core.sh`
- `lib/tui.sh`
- `installers/editors.sh`
- `installers/terminal-shell.sh`