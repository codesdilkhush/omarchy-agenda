import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The bar pill: what is on now or next, and the door to the agenda popup.
//
// Left click opens the agenda, right click opens a new event, middle click
// syncs. The popup itself lives in Panel.qml, loaded once and handed the
// button to hang from, the same way the built-in clock does it.
BarWidget {
  id: root
  moduleName: "dadoux01.agenda"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // ------------------------------------------------------------- service

  property var service: null

  function bindService() {
    if (service) return
    var host = bar && bar.shell ? bar.shell : null
    var s = host && typeof host.serviceFor === "function" ? host.serviceFor("dadoux01.agenda") : null
    if (s) {
      service = s
      injectPanel()
    }
  }

  onBarChanged: { bindService(); injectPanel() }
  onSettingsChanged: injectPanel()

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.bindService()
  }

  Connections {
    target: root.service
    function onOpenRequested(page) {
      if (!root.onFocusedMonitor()) return
      if (!panelLoader.item) return
      if (page === "toggle") panelLoader.item.toggle()
      else panelLoader.item.openPage(page === "add" ? "form" : "agenda")
    }
  }

  // One bar per monitor: an IPC call or a notification click opens the
  // popup only on the monitor in use, not on all of them at once.
  function onFocusedMonitor() {
    var win = button.QsWindow ? button.QsWindow.window : null
    var mine = win && win.screen ? win.screen.name : ""
    var focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    return !mine || !focused || mine === focused
  }

  // ------------------------------------------------------------- label

  property double now: Date.now()
  Timer {
    interval: 20000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }

  readonly property var events: service ? service.events : []
  readonly property int maxTitle: Math.max(6, Math.min(60, Number(setting("maxTitle", 22)) || 22))
  readonly property bool showNext: setting("showNext", true) !== false
  readonly property bool use24h: !/a/i.test(Qt.locale(Commons.I18n.formatLocale).timeFormat(Locale.ShortFormat))
  readonly property var focusInfo: showNext ? Model.focusEvent(events, now, 12 * Model.HOUR) : null
  readonly property string calendarGlyph: "\u{F00ED}"

  readonly property string label: {
    if (!focusInfo) return ""
    var e = focusInfo.event
    var title = Model.truncate(e.title || "…", maxTitle)
    if (focusInfo.running) {
      var left = Model.minutesUntil(e.end, now)
      return left <= 90
        ? strings.t("bar.running").arg(title).arg(left)
        : strings.t("bar.runningHours").arg(title).arg(Model.timeText(e.end, use24h))
    }
    var mins = Model.minutesUntil(e.start, now)
    if (mins <= 60) return strings.t("bar.soon").arg(title).arg(mins)
    return strings.t("bar.later").arg(Model.timeText(e.start, use24h)).arg(title)
  }

  readonly property int todayCount: Model.countOn(events, Model.startOfDay(now))
  readonly property bool soon: focusInfo !== null && !focusInfo.running
    && Model.minutesUntil(focusInfo.event.start, now) <= 5

  // ------------------------------------------------------------- panel

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.service = root.service
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical || root.label === ""
      ? root.calendarGlyph
      : root.calendarGlyph + "  " + root.label
    active: root.soon
    tooltipText: root.label === ""
      ? strings.tn("bar.count", root.todayCount).arg(Commons.I18n.formatNumber(root.todayCount))
      : ""
    pressFeedbackButtons: Qt.NoButton

    onPressed: function(b) {
      if (b === Qt.RightButton) {
        if (panelLoader.item) panelLoader.item.openPage("form")
      } else if (b === Qt.MiddleButton) {
        if (root.service) root.service.sync(true)
      } else {
        root.togglePanel()
      }
    }
  }
}
