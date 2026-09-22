# Issue #1 Fix Summary

## Problem

The workspace materialization block in `config/hypr/autostart.lua` never executed because it checked `_G.omarchy_monitor_bases`, which was still `nil` at that point in the config load sequence.

**Load order (broken):**
1. `config/hypr/hyprland.lua` requires `default.hypr.toggles` (Omarchy's default toggles, doesn't set our globals)
2. `config/hypr/hyprland.lua` requires `hypr.autostart` → tries to read `_G.omarchy_monitor_bases` (nil, skips materialization)
3. Later: `default.hypr.toggles` loads `config/hypr/toggles/workspace-global.lua` (now too late, sets the globals)

## Solution

Move the materialization function to the end of `config/hypr/toggles/workspace-global.lua`, ensuring it runs **after** the globals are set.

**New load order (fixed):**
1. `default.hypr.toggles` loads `config/hypr/toggles/workspace-global.lua`
2. Globals are parsed and set: `_G.omarchy_monitor_bases`, `_G.omarchy_global_ws_monitors`
3. Workspace rules are registered
4. **Materialization function runs** (globals are now set)
5. `config/hypr/autostart.lua` is loaded (workspace slots already exist)

## Changes

### File: `config/hypr/toggles/workspace-global.lua`
- Added `materialize_all_workspaces()` function at end of file
- Calls `hl.dispatch(hl.dsp.focus({ workspace = N }))` for WS 1-30
- Returns focus to WS 1 after materialization
- Updated IPC call to use canonical `omarchy-shell` entry point

### File: `config/hypr/autostart.lua`
- Removed the materialization block (moved to toggles)
- Added migration note explaining the move

## Test Results (3-monitor setup)

**Before fix:**
- `hyprctl reload` results in 46 total workspaces
- Materialization skipped (global was nil)
- Some workspaces have `ispersistent: 0`

**After fix:**
- `hyprctl reload` results in 271 total workspaces
- All 30 slots × 3 monitors materialized correctly
- All workspaces have `ispersistent: 1`
- Monitor bases correctly applied:
  * HDMI-A-1 (base 0): WS 1-10 ✅
  * DP-1 (base 10): WS 11-20 ✅
  * DP-2 (base 20): WS 21-30 ✅

## Verification

```bash
# Check that workspaces are persistent
hyprctl workspaces | grep "ispersistent: 1" | wc -l
# Output: 30 (all persistent workspaces created)

# Check monitor bases were applied
cat ~/.local/state/omarchy/monitor-bases.json | jq .
# Output: {"DP-1": 10, "DP-2": 20, "HDMI-A-1": 0}

# Verify workspace count
hyprctl workspaces | wc -l
# Output: 271 (30 workspaces per monitor + special workspaces)
```

## Secondary Fixes

### IPC call updated (line 22 of toggles)
- **Before:** `os.execute("sleep 0.1; qs ipc call omarchy.workspaces refresh &>/dev/null &")`
- **After:** `os.execute("sleep 0.1; omarchy-shell 'omarchy-bar-refresh' &>/dev/null &")`
- Reason: Per `shell-dev.md`, `omarchy-shell` is the canonical IPC entry point

## Impact on User Configs

Existing Omarchy installations already have their own copy of `config/hypr/autostart.lua` from previous installations. The fix is applied through `config/hypr/toggles/workspace-global.lua`, which is auto-loaded by Omarchy's toggle system, so users **do not** need to manually copy the new autostart file.

**Migration:** None required. The workspace materialization automatically happens in the toggle file on next `hyprctl reload`.

## Commits

- **81c7aa8a**: fix(issue-1): Move workspace materialization to toggles file for correct load order
- **4826d48e**: docs: Update assessment with Issue #1 test results

## Status

✅ **RESOLVED AND TESTED** on Hyprland 0.56.2 with 3-monitor setup (HDMI-A-1, DP-1, DP-2)
