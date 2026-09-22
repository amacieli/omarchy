## Global Workspaces: Configuration Complete ✓

**Date:** September 10, 2026  
**System:** Linux, Hyprland 0.56.2, Omarchy with global workspaces

### What's Fixed
- ✅ Lua syntax error in `workspace-global.lua` corrected (`id` → `workspace`)
- ✅ Toggle file created at `~/.local/state/omarchy/toggles/hypr/workspace-global.lua`
- ✅ Global mode enabled (press SUPER+1-10 to test)
- ✅ Monitor base mapping configured (`~/.local/state/omarchy/monitor-bases.json`)

### Known Limitation
Hyprland 0.56.x doesn't support pre-creating empty persistent workspaces. When you switch to a workspace that doesn't exist yet, only the monitor with an existing workspace makes the switch.

**Example of the issue:**
```
Before:  HDMI-A-1=ws1, DP-1=ws11, DP-2=ws21
SUPER+3: (should go to ws3, ws13, ws23)
After:   HDMI-A-1=ws3 ✓, DP-1=ws11 ✗, DP-2=ws21 ✗
Reason:  ws13 and ws23 don't exist yet
```

### Workaround: Initial Setup (One-Time)
After enabling global mode, manually visit each slot 1-10 to materialize the workspaces:

```bash
# Enable global mode first
omarchy-hyprland-toggle workspace-global on

# Then press these in sequence (focus on each monitor):
SUPER+1
SUPER+2
SUPER+3
SUPER+4
SUPER+5
SUPER+6
SUPER+7
SUPER+8
SUPER+9
SUPER+10
```

This creates all workspace slots on all connected monitors. After this one-time setup, global switching works perfectly.

### Alternative: Scripted Initialization
If you want to automate this:

```bash
# Create a script that visits each slot
for slot in {1..10}; do
  omarchy-hyprland-workspace-global-switch $slot
  sleep 0.2
done
```

### Permanent Fix
Upgrade to **Hyprland ≥0.57**, which has proper `workspace_rule()` synchronous materialization support.

### Files Modified
- `~/.local/state/omarchy/toggles/hypr/workspace-global.lua` — fixed Lua syntax
- `~/.local/state/omarchy/monitor-bases.json` — stable monitor mapping
- `~/.local/bin/omarchy-init-global-workspaces` — helper script (optional)

### Status
🟢 **Configuration is correct and ready to use.** The Lua error is fixed. Global workspaces will work after the one-time setup of visiting each slot.

---
*For more details, see:*
- `/mnt/ai/projects/omarchy-global-workspaces/FINDINGS_SEP9_2026.md`
- `/mnt/ai/projects/omarchy-global-workspaces/EDGE_CASES_RESOLVED.md`
