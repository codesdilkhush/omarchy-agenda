import QtQuick
import qs.Commons

// Every piece of text from a calendar goes through this. Titles, places and
// notes come from servers and from anyone who can invite you to an event;
// Text's default AutoText would read `<img src=...>` in one as markup.
Text {
  textFormat: Text.PlainText
  font.family: Style.font.family
  font.pixelSize: Style.font.body
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  maximumLineCount: wrapMode === Text.NoWrap ? 1 : 8
}
