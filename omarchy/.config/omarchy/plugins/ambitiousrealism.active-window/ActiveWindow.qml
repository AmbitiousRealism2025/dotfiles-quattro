import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Shows the names of the apps open on the focused workspace (instead of the
// focused window's title), e.g. "Warp, bb". Click a name to focus it.

BarWidget {
  id: root
  moduleName: "omarchy.active-window"

  readonly property int maxLabelWidth: Number(setting("maxWidth", 320))
  readonly property var focusedWorkspace: Hyprland.focusedWorkspace
  // Optional display-name overrides from shell.json, e.g.
  // "aliases": { "TUI.tile": "herdr", "chatgpt": "Codex" }
  readonly property var aliases: setting("aliases", {})

  // Unique apps on the focused workspace, as { appId, name, count, toplevel }.
  readonly property var apps: {
    var workspace = root.focusedWorkspace
    if (!workspace) return []

    var byId = ({})
    var order = []
    var values = workspace.toplevels.values

    for (var i = 0; i < values.length; i++) {
      var toplevel = values[i]
      var appId = root.appIdFor(toplevel)
      if (appId === "") appId = "window:" + (toplevel.title || toplevel.address)

      if (byId[appId]) {
        byId[appId].count++
      } else {
        var entry = root.desktopEntryFor(appId)
        var app = {
          appId: appId,
          name: root.displayNameFor(appId, entry, toplevel),
          count: 1,
          toplevel: toplevel
        }
        byId[appId] = app
        order.push(app)
      }
    }

    return order
  }

  function appIdFor(toplevel) {
    var wayland = toplevel.wayland
    if (wayland && wayland.appId) return String(wayland.appId)
    var ipc = toplevel.lastIpcObject
    if (ipc && ipc.class) return String(ipc.class)
    return ""
  }

  function desktopEntryFor(appId) {
    if (!appId) return null
    return DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId)
  }

  // App-level name only: aliases, then the desktop entry, then a cleaned
  // appId (dropping noise suffixes like "-desktop" or "-Default"), then a
  // prettified appId. The window title is the last resort since per-window
  // detail is what this widget deliberately avoids.
  function displayNameFor(appId, entry, toplevel) {
    var alias = root.aliases ? root.aliases[appId] : undefined
    if (alias) return String(alias)

    if (entry && entry.name) return entry.name

    var cleaned = String(appId).replace(/-(desktop|default)$/i, "")
    if (cleaned !== appId) {
      var cleanedEntry = root.desktopEntryFor(cleaned)
      if (cleanedEntry && cleanedEntry.name) return cleanedEntry.name
    }

    return root.fallbackName(toplevel, appId)
  }

  function fallbackName(toplevel, appId) {
    if (appId && appId.indexOf("window:") !== 0) {
      var clean = String(appId)
      var dot = clean.lastIndexOf(".")
      if (dot >= 0 && dot < clean.length - 1) clean = clean.slice(dot + 1)
      return clean
    }
    var title = toplevel ? String(toplevel.title || "") : ""
    return title || "Window"
  }

  function tooltipFor(app) {
    if (!app) return ""
    return app.count > 1 ? app.name + " (" + app.count + " windows)" : app.name
  }

  function activate(app) {
    if (!app || !app.toplevel) return
    var address = String(app.toplevel.address || "")
    if (address && Hyprland.usingLua)
      Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + address + "\" })")
    else if (address)
      Hyprland.dispatch("focuswindow address:" + address)
    else if (app.toplevel.wayland)
      app.toplevel.wayland.activate()
  }

  visible: apps.length > 0 && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, row.implicitWidth) + Style.spacing.controlPaddingX * 2 : 0
  implicitHeight: barSize

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    spacing: 0
    clip: true

    Repeater {
      model: root.apps

      Text {
        id: nameLabel
        required property var modelData
        required property int index

        readonly property bool isFocused: {
          var active = ToplevelManager.activeToplevel
          if (!active) return false
          return String(active.appId || "") === modelData.appId
        }

        text: modelData.name + (index < root.apps.length - 1 ? ", " : "")
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        opacity: isFocused ? 1 : 0.72

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor

          onClicked: root.activate(nameLabel.modelData)
          onEntered: if (root.bar) root.bar.showTooltip(nameLabel, root.tooltipFor(nameLabel.modelData))
          onExited: if (root.bar) root.bar.hideTooltip(nameLabel)
        }
      }
    }
  }
}
