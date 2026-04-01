# Fix: VS Code CLI Hang — "Verifying VS Code CLI works under user"

**Date:** 2026-04-01 11:55 (UTC+7)
**Type:** Bug Fix

## Problem
ผู้ใช้รายงานว่า script ค้างที่ "Verifying VS Code CLI works under user ..." นานมาก
- สาเหตุ: `su - "$REAL_USER" -c "code --version"` ไม่มี outer timeout
- ถ้า `su -` ค้าง (เช่น login shell มี interactive prompt) → inner timeout ไม่ถูกเรียก → ค้างไม่จำกัดเวลา

## Changes

### `installers/editors.sh` — เพิ่ม 2-layer timeout ทุกจุดที่เรียก `code` CLI

1. **Pre-check `code --version`**: เพิ่ม outer `timeout 30` ครอบ `su -` + เปลี่ยนจาก fatal error เป็น non-fatal warning
2. **Extension install loop**: เพิ่ม outer `timeout $((ext_timeout + 30))` ครอบ `su -`
3. **Retry extension install**: เพิ่ม outer timeout เช่นเดียวกัน

### กลยุทธ์ 2-layer timeout
- **Inner timeout** (ใน `su -c`): ควบคุม `code` process — ป้องกัน Electron ค้าง
- **Outer timeout** (ครอบ `su -`): safety net — ป้องกัน login shell ค้าง
- ทุกจุดที่ timeout แล้ว log warning แต่ไม่ fail script

## Files Modified
- `installers/editors.sh`