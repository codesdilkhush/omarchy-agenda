import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "components"
import "pages"
import "Model.js" as Model

// The Agenda popup. BarWidget.qml owns the bar label and hands this panel
// the button to hang from and the session service to talk to.
Panel {
  id: root
  moduleName: "dadoux01.agenda"
  ipcTarget: "dadoux01.agenda"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  readonly property var barIdentity: hostWidget || root

  Commons.Translations { id: translations; directory: Qt.resolvedUrl("i18n") }
  readonly property alias strings: translations

  // ------------------------------------------------------------ look

  readonly property color fg: bar ? bar.foreground : Commons.Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool use24h: !/a/i.test(Qt.locale(Commons.I18n.formatLocale).timeFormat(Locale.ShortFormat))
  readonly property var locale: Qt.locale(Commons.I18n.formatLocale)

  // ------------------------------------------------------------ state

  readonly property bool backendUp: service ? service.backendUp : false
  readonly property var accounts: service ? service.accounts : []
  readonly property var events: service ? service.events : []
  readonly property bool syncing: service ? service.syncing : false
  readonly property double syncedAt: service ? service.syncedAt : 0

  property string page: "agenda"
  property bool editing: false
  property bool busy: false
  property string selectedKey: ""
  property string expandedKey: ""
  property double now: Date.now()

  function settingsValue(key, fallback) {
    var s = service ? service.settings : null
    return s && s[key] !== undefined && s[key] !== null ? s[key] : fallback
  }

  readonly property int agendaDays: Number(settingsValue("agendaDays", 7)) || 7
  readonly property var groups: Model.groupByDay(events, now, agendaDays)

  readonly property var flatRows: {
    var out = []
    for (var i = 0; i < groups.length; i++)
      for (var j = 0; j < groups[i].events.length; j++)
        out.push({ key: rowKey(groups[i], groups[i].events[j]), event: groups[i].events[j] })
    return out
  }

  function rowKey(group, ev) { return group.day + ":" + ev.key }

  readonly property var writableCalendars: {
    var out = []
    for (var i = 0; i < accounts.length; i++) {
      var a = accounts[i]
      for (var j = 0; j < a.calendars.length; j++) {
        var c = a.calendars[j]
        if (c.readOnly || !c.enabled) continue
        out.push({ key: a.id + "|" + c.id, accountId: a.id, calendarId: c.id,
                   label: accounts.length > 1 ? a.label + " › " + c.name : c.name })
      }
    }
    return out
  }

  readonly property bool multipleCalendars: {
    var n = 0
    for (var i = 0; i < accounts.length; i++)
      for (var j = 0; j < accounts[i].calendars.length; j++)
        if (accounts[i].calendars[j].enabled) n++
    return n > 1
  }

  readonly property string defaultCalendarKey: {
    var wanted = String(settingsValue("defaultCalendar", ""))
    for (var i = 0; i < writableCalendars.length; i++)
      if (writableCalendars[i].key === wanted) return wanted
    return writableCalendars.length > 0 ? writableCalendars[0].key : ""
  }

  readonly property string defaultCalendarName: {
    var c = calendarByKey(defaultCalendarKey)
    return c ? c.label : ""
  }

  function calendarByKey(key) {
    for (var i = 0; i < writableCalendars.length; i++)
      if (writableCalendars[i].key === key) return writableCalendars[i]
    return null
  }

  readonly property int syncErrorCount: {
    var n = 0
    for (var i = 0; i < accounts.length; i++) if (accounts[i].error) n++
    return n
  }

  property string flash: ""

  readonly property string statusText: {
    if (flash) return flash
    if (syncing) return strings.t("panel.syncing")
    if (syncErrorCount > 0) return strings.tn("panel.syncErrors", syncErrorCount).arg(syncErrorCount)
    if (syncedAt <= 0) return strings.t("panel.neverSynced")
    return strings.t("panel.synced").arg(Model.timeText(syncedAt, use24h))
  }

  Timer {
    id: flashTimer
    interval: 3500
    onTriggered: root.flash = ""
  }

  function showFlash(text) {
    flash = text
    flashTimer.restart()
  }

  function dayTitle(group) {
    if (group.offset === 0) return strings.t("panel.today") + "  ·  " + new Date(group.day).toLocaleDateString(locale, "d MMMM")
    if (group.offset === 1) return strings.t("panel.tomorrow") + "  ·  " + new Date(group.day).toLocaleDateString(locale, "d MMMM")
    return new Date(group.day).toLocaleDateString(locale, "dddd d MMMM")
  }

  function errorText(code) {
    if (!code) return ""
    var key = "error." + code
    var text = strings.t(key, "")
    if (text) return text
    if (code === "backend_down") return strings.t("panel.backendDown")
    return strings.t("error.generic").arg(code)
  }

  // ------------------------------------------------------------ lifecycle

  function open() {
    root.now = Date.now()
    root.controller.show()
    if (service && (Date.now() - syncedAt) > 60000) service.sync(false)
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
    page = "agenda"
    editing = false
    expandedKey = ""
    confirm.close()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function openPage(p) {
    if (p === "form" && writableCalendars.length === 0) p = accounts.length === 0 ? "add" : "agenda"
    if (!root.opened) root.open()
    editing = false
    page = p
    if (p === "form") Qt.callLater(function() { var f = pageItem("form"); if (f) f.reset(root.pendingPreset); root.pendingPreset = null })
    else if (p === "add") Qt.callLater(function() { var a = pageItem("add"); if (a) a.reset() })
    else Qt.callLater(focusList)
  }

  function pageItem(name) {
    var c = panel.loadedContent
    if (!c) return null
    var loader = name === "agenda" ? c.agendaLoader : name === "form" ? c.formLoader : name === "add" ? c.addLoader : null
    return loader ? loader.item : null
  }

  function focusList() {
    editing = false
    if (panel.loadedContent) panel.loadedContent.forceActiveFocus()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && typeof root.bar.setCenterHoverRevealSuppressed === "function")
      root.bar.setCenterHoverRevealSuppressed(value)
  }

  Timer {
    interval: 20000
    repeat: true
    running: root.opened
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }

  // ------------------------------------------------------------ agenda keys

  function moveSelection(dy) {
    if (flatRows.length === 0) return
    var idx = -1
    for (var i = 0; i < flatRows.length; i++) if (flatRows[i].key === selectedKey) idx = i
    if (idx === -1) idx = dy > 0 ? 0 : flatRows.length - 1
    else idx = Math.max(0, Math.min(flatRows.length - 1, idx + dy))
    selectedKey = flatRows[idx].key
  }

  function selectedEvent() {
    for (var i = 0; i < flatRows.length; i++) if (flatRows[i].key === selectedKey) return flatRows[i].event
    return null
  }

  function toggleExpanded(key) {
    selectedKey = key
    expandedKey = expandedKey === key ? "" : key
  }

  function join(ev) {
    var url = Model.safeMeetingUrl(ev.meetingUrl)
    if (url === "") return
    Qt.openUrlExternally(url)
    close()
  }

  // ------------------------------------------------------------ calls

  function call(op, params, done) {
    if (!service) { if (done) done(false, errorText("backend_down")); return }
    busy = true
    service.request(op, params, function(msg) {
      busy = false
      if (done) done(msg.ok === true, msg.ok ? msg.result : errorText(msg.error ? msg.error.code : "internal"))
    })
  }

  function syncNow() { if (service) service.sync(true) }

  property var pendingPreset: null

  function quickAdd(text) {
    var parsed = Model.parseQuickAdd(text, Date.now())
    if (!parsed) { quickToForm(text); showFlash(strings.t("panel.quickAddFailed")); return }
    var target = calendarByKey(defaultCalendarKey)
    if (!target) return
    var m = Number(settingsValue("defaultReminderMinutes", 10))
    createEvent({
      accountId: target.accountId, calendarId: target.calendarId,
      title: parsed.title, start: parsed.start, end: parsed.end, allDay: parsed.allDay,
      reminders: parsed.allDay || m < 0 ? [] : [m]
    }, function(err) { showFlash(err) })
  }

  function quickToForm(text) {
    var parsed = Model.parseQuickAdd(text, Date.now())
    pendingPreset = parsed || { title: String(text || "").trim() }
    openPage("form")
  }

  function createEvent(params, onError) {
    call("createEvent", params, function(ok, result) {
      if (!ok) { if (onError) onError(result); return }
      var agenda = pageItem("agenda")
      if (agenda) agenda.quickField.text = ""
      showFlash(strings.t("form.saved"))
      openPage("agenda")
    })
  }

  function testNotification() { call("testNotification", {}, null) }

  function saveSettings(values) { call("setSettings", { settings: values }, null) }

  function setCalendarEnabled(accountId, calendarId, enabled) {
    call("updateAccount", { id: accountId, calendars: [{ id: calendarId, enabled: enabled }] }, null)
  }

  function discover(params, done) { call("discover", params, done) }

  function saveAccount(token, label, calendars, done) {
    call("saveAccount", { token: token, label: label, calendars: calendars }, function(ok, result) {
      if (ok && result.secretStore === "@file") showFlash(strings.t("accounts.secretFile"))
      done(ok, result)
    })
  }

  // ------------------------------------------------------------ confirmations

  function askDelete(ev) {
    var choices = []
    if (ev.recurring && ev.recurrenceId) {
      choices.push({ id: "occurrence", label: strings.t("panel.deleteOccurrence"), destructive: true })
      choices.push({ id: "series", label: strings.t("panel.deleteSeries"), destructive: true })
    } else {
      choices.push({ id: "series", label: strings.t("panel.deleteSingle"), destructive: true })
    }
    choices.push({ id: "cancel", label: strings.t("panel.cancel"), destructive: false })
    confirm.ask(strings.t("panel.deleteConfirm").arg(ev.title || "…"), choices, function(choice) {
      if (choice === "cancel") return
      call("deleteEvent", { key: ev.key, scope: choice }, function(ok, result) {
        if (!ok) showFlash(result)
        expandedKey = ""
      })
    })
  }

  function askRemoveAccount(acc) {
    confirm.ask(strings.t("accounts.removeConfirm").arg(acc.label), [
      { id: "remove", label: strings.t("accounts.remove"), destructive: true },
      { id: "cancel", label: strings.t("panel.cancel"), destructive: false }
    ], function(choice) {
      if (choice === "remove") call("removeAccount", { id: acc.id }, null)
    })
  }

  QtObject {
    id: confirm
    property bool opened: false
    property string message: ""
    property var choices: []
    property var callback: null

    function ask(message, choices, callback) {
      confirm.message = message
      confirm.choices = choices
      confirm.callback = callback
      confirm.opened = true
    }
    function answer(id) {
      var cb = confirm.callback
      confirm.close()
      if (cb) cb(id)
      Qt.callLater(root.focusList)
    }
    function close() {
      confirm.opened = false
      confirm.callback = null
    }
  }

  // ------------------------------------------------------------ the popup

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: keys
      // The content is its own component: Panel reaches the pages through these.
      property alias agendaLoader: agendaLoader
      property alias formLoader: formLoader
      property alias addLoader: addLoader
      implicitHeight: Math.min(pages.implicitHeight, Style.space(760))
      anchors.fill: parent
      blocked: root.page !== "agenda" || root.editing || confirm.opened

      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveSelection(dy) }
      onActivateRequested: { if (root.selectedKey) root.toggleExpanded(root.selectedKey) }
      onCloseRequested: root.close()
      onDeleteRequested: {
        var ev = root.selectedEvent()
        if (ev && !ev.readOnly) root.askDelete(ev)
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "n" || t === "+") root.openPage("form")
        else if (t === "s" || t === "r") root.syncNow()
        else if (t === "a") root.openPage("accounts")
        else if (t === ",") root.openPage("settings")
        else if (t === "/" || t === "q") {
          if (agendaLoader.item && agendaLoader.item.quickField.visible) agendaLoader.item.quickField.forceActiveFocus()
        } else if (t === "j" || t === "J") {
          var ev = root.selectedEvent()
          if (ev) root.join(ev)
        }
      }

      // Escape on a sub-page goes back to the agenda; on the agenda the
      // catcher above closes the popup.
      Keys.onEscapePressed: function(event) {
        if (confirm.opened) confirm.answer("cancel")
        else if (root.page !== "agenda") root.openPage("agenda")
        else root.close()
      }

      Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: pages.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: pages
          width: scroller.width

          Loader {
            id: agendaLoader
            width: parent.width
            active: true
            visible: root.page === "agenda"
            sourceComponent: AgendaPage { panel: root; width: agendaLoader.width }
          }
          Loader {
            id: formLoader
            width: parent.width
            active: root.page === "form"
            visible: active
            sourceComponent: EventForm { panel: root; width: formLoader.width }
            onLoaded: item.reset(root.pendingPreset)
          }
          Loader {
            id: accountsLoader
            width: parent.width
            active: root.page === "accounts"
            visible: active
            sourceComponent: AccountsPage { panel: root; width: accountsLoader.width }
          }
          Loader {
            id: addLoader
            width: parent.width
            active: root.page === "add"
            visible: active
            sourceComponent: AddAccountPage { panel: root; width: addLoader.width }
            onLoaded: item.reset()
          }
          Loader {
            id: settingsLoader
            width: parent.width
            active: root.page === "settings"
            visible: active
            sourceComponent: SettingsPage { panel: root; width: settingsLoader.width }
          }
        }
      }

      ChoiceDialog {
        anchors.fill: parent
        z: 10
        panel: root
        opened: confirm.opened
        message: confirm.message
        choices: confirm.choices
        onChosen: function(id) { confirm.answer(id) }
      }
    }
  }
}
