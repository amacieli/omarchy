import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // ── Global-mode detection ─────────────────────────────────────────────────
  // The toggle flag file is present when workspace-global.lua is active.
  // FileView.exists() is a reactive property: it re-evaluates when the file
  // appears or disappears, so toggling global mode live updates the bar.
  readonly property string globalFlagPath: StandardPaths.writableLocation(
    StandardPaths.HomeLocation) + "/.local/state/omarchy/toggles/hypr/workspace-global.lua"

  FileView {
    id: globalFlagView
    path: root.globalFlagPath
    // We only need existence, not content; disable auto-read to save I/O.
    preload: false
  }

  readonly property bool globalModeActive: globalFlagView.exists

  // ── Slot/ID mapping helpers ───────────────────────────────────────────────
  // In local mode (globalModeActive == false):
  //   slot == raw workspace ID (IDs 1–10, one set per machine).
  // In global mode (globalModeActive == true):
  //   Each monitor owns IDs (base+1)..(base+10).
  //   slot = ((id - 1) % 10) + 1 maps any raw ID back to a logical slot 1–10.
  //   Example: monitor-2 base=10: ID 12 → slot 2.

  function slotOfId(id) {
    if (!root.globalModeActive) return id
    if (id <= 0 || id > 99) return -1
    return ((id - 1) % 10) + 1
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // Returns true if any workspace mapped to this slot (across all monitors) has windows.
  function slotOccupied(slot) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (slotOfId(id) === slot && values[i].toplevels.values.length > 0) return true
    }
    return false
  }

  // Returns true if the currently focused workspace maps to this slot.
  function slotFocused(slot) {
    if (Hyprland.focusedWorkspace === null) return false
    return slotOfId(Hyprland.focusedWorkspace.id) === slot
  }

  function workspaceIds() {
    var slots = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      var slot = slotOfId(id)
      // Include any occupied slot in range 1–10 (works for both modes).
      if (slot >= 1 && slot <= 10 && slots.indexOf(slot) === -1) slots.push(slot)
    }

    slots.sort(function(left, right) { return left - right })
    return slots
  }

  // In global mode, clicking slot N routes through omarchy-switch-to-aw so
  // all monitors switch together. In local mode, direct hyprctl dispatch.
  function focusWorkspace(slot) {
    if (!root.bar) return
    if (root.globalModeActive) {
      root.bar.run("omarchy-switch-to-aw " + slot)
    } else {
      root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + slot + "\" })"))
    }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        // modelData is always a logical slot (1–10) in both local and global mode.
        readonly property bool occupied: root.slotOccupied(modelData)
        readonly property bool focused: root.slotFocused(modelData)

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
