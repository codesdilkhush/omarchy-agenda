import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../components"

// Reminders, notifications, recap and sync. Saved by the helper in
// ~/.config/dadoux01.agenda/settings.json the moment they change.
Column {
  id: root

  property var panel

  spacing: Style.space(8)

  function value(key, fallback) { return root.panel.settingsValue(key, fallback) }
  function set(key, v) { var o = {}; o[key] = v; root.panel.saveSettings(o) }

  function minutesLabel(m) {
    var s = root.panel.strings
    if (m <= 0) return s.t("settings.off")
    if (m % 1440 === 0) return s.tn("form.reminderDays", m / 1440).arg(m / 1440)
    if (m % 60 === 0) return s.tn("form.reminderHours", m / 60).arg(m / 60)
    return s.tn("form.reminderMinutes", m).arg(m)
  }

  PageHeader {
    panel: root.panel
    title: root.panel.strings.t("settings.title")
  }

  component SettingToggle: Toggle {
    property string key: ""
    width: root.width
    checked: root.value(key, true) === true
    foreground: root.panel.fg
    fontFamily: root.panel.fontFamily
    onClicked: root.set(key, !checked)
  }

  SettingToggle {
    key: "reminders"
    label: root.panel.strings.t("settings.reminders")
    description: root.panel.strings.t("settings.remindersDesc")
  }
  SettingToggle {
    key: "notifyAtStart"
    label: root.panel.strings.t("settings.notifyAtStart")
    description: root.panel.strings.t("settings.notifyAtStartDesc")
  }
  SettingToggle {
    key: "dailyRecap"
    label: root.panel.strings.t("settings.recap")
    description: root.panel.strings.t("settings.recapDesc")
  }
  SettingToggle {
    key: "privateNotifications"
    checked: root.value(key, false) === true
    label: root.panel.strings.t("settings.private")
    description: root.panel.strings.t("settings.privateDesc")
  }

  Dropdown {
    width: root.width
    label: root.panel.strings.t("settings.extra")
    value: String(root.value("extraReminderMinutes", 0))
    options: [0, 1, 2, 5, 10, 15, 30].map(function(m) { return { value: String(m), label: root.minutesLabel(m) } })
    fontFamily: root.panel.fontFamily
    onChanged: function(v) { root.set("extraReminderMinutes", Number(v)) }
  }

  Dropdown {
    width: root.width
    label: root.panel.strings.t("settings.defaultReminder")
    value: String(root.value("defaultReminderMinutes", 10))
    options: [-1, 0, 5, 10, 15, 30, 60, 1440].map(function(m) {
      return { value: String(m), label: m < 0 ? root.panel.strings.t("form.reminderNone")
        : (m === 0 ? root.panel.strings.t("form.reminderAtStart") : root.minutesLabel(m)) }
    })
    fontFamily: root.panel.fontFamily
    onChanged: function(v) { root.set("defaultReminderMinutes", Number(v)) }
  }

  Dropdown {
    width: root.width
    label: root.panel.strings.t("settings.sync")
    value: String(root.value("syncMinutes", 10))
    options: [5, 10, 15, 30, 60].map(function(m) {
      return { value: String(m), label: root.panel.strings.tn("settings.minutes", m).arg(m) }
    })
    fontFamily: root.panel.fontFamily
    onChanged: function(v) { root.set("syncMinutes", Number(v)) }
  }

  Dropdown {
    width: root.width
    label: root.panel.strings.t("settings.days")
    value: String(root.value("agendaDays", 7))
    options: [3, 7, 14, 31].map(function(d) {
      return { value: String(d), label: root.panel.strings.tn("settings.daysValue", d).arg(d) }
    })
    fontFamily: root.panel.fontFamily
    onChanged: function(v) { root.set("agendaDays", Number(v)) }
  }

  Button {
    width: root.width
    text: root.panel.strings.t("settings.test")
    iconText: "\u{F009A}"
    foreground: root.panel.fg
    fontFamily: root.panel.fontFamily
    bordered: true
    onClicked: root.panel.testNotification()
  }

  PlainLabel {
    width: root.width
    text: "Agenda " + (root.panel.service ? root.panel.service.version : "")
    horizontalAlignment: Text.AlignRight
    color: Util.alpha(root.panel.fg, 0.35)
    font.family: root.panel.fontFamily
    font.pixelSize: Style.font.caption
  }
}
