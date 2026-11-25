import QtQuick
import qs.Commons
import qs.Ui

// Title row of a sub-page: a back arrow, the page name, and room on the
// right for the page's own actions.
Item {
  id: root

  property var panel
  property string title: ""
  property bool showBack: true
  default property alias actions: actionRow.data

  width: parent ? parent.width : 0
  height: Math.max(heading.implicitHeight, actionRow.height, back.visible ? back.height : 0)

  PanelActionButton {
    id: back
    visible: root.showBack
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    iconText: "\u{F004D}"
    tooltipText: root.panel.strings.t("panel.back")
    foreground: root.panel.fg
    fontFamily: root.panel.fontFamily
    onClicked: root.panel.openPage("agenda")
  }

  PanelSectionHeader {
    id: heading
    anchors.left: back.visible ? back.right : parent.left
    anchors.leftMargin: back.visible ? Style.space(6) : 0
    anchors.verticalCenter: parent.verticalCenter
    text: root.title
    foreground: root.panel.fg
    fontFamily: root.panel.fontFamily
  }

  Row {
    id: actionRow
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)
  }
}
