import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "../components"
import "../Model.js" as Model

// Add an account in three steps: provider, credentials, calendars.
// The password field is cleared as soon as the helper has it.
Column {
  id: root

  property var panel
  property string step: "provider"     // provider | credentials | calendars
  property string kind: ""             // icloud | caldav
  property string error: ""
  property string token: ""
  property var found: []
  property var chosen: ({})

  spacing: Style.space(10)

  function reset() {
    step = "provider"
    kind = ""
    error = ""
    token = ""
    found = []
    chosen = ({})
    userField.text = ""
    passField.text = ""
    serverField.text = ""
    labelField.text = ""
  }

  function pick(k) {
    kind = k
    step = "credentials"
    error = ""
    Qt.callLater(function() { userField.forceActiveFocus() })
  }

  function connect() {
    error = ""
    var password = passField.text
    passField.text = ""
    root.panel.discover({
      kind: kind,
      server: kind === "icloud" ? "" : serverField.text,
      username: userField.text,
      password: password,
      label: labelField.text
    }, function(ok, result) {
      if (!ok) { root.error = result; Qt.callLater(function() { passField.forceActiveFocus() }); return }
      root.token = result.token
      root.found = result.calendars
      var c = {}
      for (var i = 0; i < result.calendars.length; i++) c[result.calendars[i].id] = true
      root.chosen = c
      if (!labelField.text) labelField.text = result.label
      root.step = "calendars"
    })
  }

  function save() {
    var selection = []
    for (var i = 0; i < found.length; i++)
      selection.push({ id: found[i].id, enabled: chosen[found[i].id] === true })
    root.panel.saveAccount(token, labelField.text, selection, function(ok, result) {
      if (!ok) { root.error = result; if (result) root.step = "credentials"; return }
      root.reset()
      root.panel.openPage("agenda")
    })
  }

  PageHeader {
    panel: root.panel
    title: root.panel.strings.t("add.title")
  }

  // ---- Step 1: provider
  Repeater {
    model: root.step !== "provider" ? [] : [
      { id: "icloud", title: root.panel.strings.t("add.icloud"), hint: root.panel.strings.t("add.icloudHint"), ready: true, glyph: "\u{F0035}" },
      { id: "caldav", title: root.panel.strings.t("add.caldav"), hint: root.panel.strings.t("add.caldavHint"), ready: true, glyph: "\u{F00ED}" },
      { id: "google", title: root.panel.strings.t("add.google"), hint: root.panel.strings.t("add.soon"), ready: false, glyph: "\u{F02AD}" },
      { id: "microsoft", title: root.panel.strings.t("add.microsoft"), hint: root.panel.strings.t("add.soon"), ready: false, glyph: "\u{F05AA}" },
      { id: "ics", title: root.panel.strings.t("add.ics"), hint: root.panel.strings.t("add.soon"), ready: false, glyph: "\u{F0337}" }
    ]

    Rectangle {
      id: providerCard
      required property var modelData
      width: root.width
      height: providerColumn.implicitHeight + Style.space(16)
      radius: Style.cornerRadius
      color: providerMouse.containsMouse && modelData.ready ? Util.alpha(root.panel.fg, 0.08) : Util.alpha(root.panel.fg, 0.03)
      opacity: modelData.ready ? 1 : 0.45

      MouseArea {
        id: providerMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: providerCard.modelData.ready
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pick(providerCard.modelData.id)
      }

      PlainLabel {
        id: providerGlyph
        x: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        text: providerCard.modelData.glyph
        color: root.panel.fg
        font.family: root.panel.fontFamily
        font.pixelSize: Style.font.icon
      }

      Column {
        id: providerColumn
        anchors.left: providerGlyph.right
        anchors.leftMargin: Style.space(12)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        PlainLabel {
          width: parent.width
          text: providerCard.modelData.title
          color: root.panel.fg
          font.family: root.panel.fontFamily
        }
        PlainLabel {
          width: parent.width
          text: providerCard.modelData.hint
          color: Util.alpha(root.panel.fg, 0.55)
          font.family: root.panel.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap
        }
      }
    }
  }

  // ---- Step 2: credentials
  component Field: TextField {
    width: root.width
    foreground: root.panel.fg
    font.family: root.panel.fontFamily
    Keys.onEscapePressed: root.step = "provider"
    onAccepted: if (userField.text && passField.text) root.connect()
  }

  Column {
    visible: root.step === "credentials"
    width: root.width
    spacing: Style.space(8)

    PlainLabel {
      width: parent.width
      text: root.kind === "icloud" ? root.panel.strings.t("add.icloud") : root.panel.strings.t("add.caldav")
      color: root.panel.fg
      font.family: root.panel.fontFamily
      font.bold: true
    }
    Field {
      id: userField
      placeholderText: root.kind === "icloud" ? root.panel.strings.t("add.email") : root.panel.strings.t("add.username")
      maximumLength: 320
      inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
    }
    Field {
      id: serverField
      visible: root.kind !== "icloud"
      placeholderText: root.panel.strings.t("add.server")
      maximumLength: 500
      inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
    }
    Field {
      id: passField
      password: true
      placeholderText: root.kind === "icloud" ? root.panel.strings.t("add.password") : root.panel.strings.t("add.passwordGeneric")
      maximumLength: 1024
      inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
    }
    Field {
      id: labelField
      placeholderText: root.panel.strings.t("add.label")
      maximumLength: 80
    }
    PlainLabel {
      width: parent.width
      text: root.kind === "icloud" ? root.panel.strings.t("add.guideIcloud") : root.panel.strings.t("add.guideCaldav")
      color: Util.alpha(root.panel.fg, 0.55)
      font.family: root.panel.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.Wrap
    }
    Button {
      width: parent.width
      text: root.panel.busy ? root.panel.strings.t("add.connecting") : root.panel.strings.t("add.connect")
      enabled: !root.panel.busy && userField.text.trim() !== "" && passField.text !== ""
      foreground: Commons.Color.accent
      fontFamily: root.panel.fontFamily
      bordered: true
      onClicked: root.connect()
    }
  }

  // ---- Step 3: calendars
  Column {
    visible: root.step === "calendars"
    width: root.width
    spacing: Style.space(6)

    PlainLabel {
      width: parent.width
      text: root.panel.strings.t("add.choose")
      color: root.panel.fg
      font.family: root.panel.fontFamily
    }

    Repeater {
      model: root.found

      Item {
        id: foundRow
        required property var modelData
        width: root.width
        height: Math.max(foundName.implicitHeight, foundToggle.height) + Style.space(4)

        Rectangle {
          id: foundSwatch
          x: Style.space(6)
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(10)
          height: width
          radius: width / 2
          color: Model.isHexColor(foundRow.modelData.color) ? foundRow.modelData.color : Commons.Color.accent
        }
        PlainLabel {
          id: foundName
          anchors.left: foundSwatch.right
          anchors.leftMargin: Style.space(10)
          anchors.right: foundToggle.left
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          text: foundRow.modelData.name + (foundRow.modelData.readOnly ? "  ·  " + root.panel.strings.t("panel.readOnly") : "")
          color: root.panel.fg
          font.family: root.panel.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        ToggleSwitch {
          id: foundToggle
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          checked: root.chosen[foundRow.modelData.id] === true
          foreground: root.panel.fg
          onToggled: {
            var c = Object.assign({}, root.chosen)
            c[foundRow.modelData.id] = !(c[foundRow.modelData.id] === true)
            root.chosen = c
          }
        }
      }
    }

    Button {
      width: parent.width
      text: root.panel.busy ? root.panel.strings.t("panel.working") : root.panel.strings.t("add.save")
      iconText: "\u{F012C}"
      enabled: !root.panel.busy
      foreground: Commons.Color.accent
      fontFamily: root.panel.fontFamily
      bordered: true
      onClicked: root.save()
    }
  }

  PlainLabel {
    visible: root.error !== ""
    width: root.width
    text: root.error
    color: Commons.Color.urgent
    font.family: root.panel.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.Wrap
  }
}
