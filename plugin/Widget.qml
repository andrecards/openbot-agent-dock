import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Botão da barra que mostra o estado do OpenBot e liga o Agent Dock dele em
// modo flutuante (XWayland). Com o dock ligado, o OpenBot desenha a própria
// janela sobre as outras, na borda da tela, no estilo do dock do macOS.
BarWidget {
  id: root
  moduleName: "admin.openbot-dock"

  // O script que fala com o app: status, abrir, ligar/desligar o dock.
  readonly property string scriptPath: String(Qt.resolvedUrl("openbot-dock-ctl.sh")).replace(/^file:\/\//, "")

  property bool running: false
  property bool aboveApps: false
  property string version: ""
  property bool popupOpen: false
  property string pendingAction: ""
  property bool actionBusy: false

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function parseStatus(raw) {
    var values = ({})
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var at = lines[i].indexOf("=")
      if (at <= 0) continue
      values[lines[i].slice(0, at)] = lines[i].slice(at + 1)
    }
    if (values.running !== undefined) root.running = values.running === "1"
    if (values.above_apps !== undefined) root.aboveApps = values.above_apps === "1"
    if (values.version !== undefined) root.version = values.version
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function runAction(name) {
    if (actionProc.running) return
    root.actionBusy = true
    root.pendingAction = name
    actionProc.running = true
  }

  function close() { root.popupOpen = false }
  function togglePopup() { root.popupOpen = !root.popupOpen }

  IpcHandler {
    target: "admin.openbot-dock"

    function toggle(): void { root.togglePopup() }
    function refresh(): void { root.refresh() }
    function dock(): void { root.runAction(root.aboveApps ? "dock-off" : "dock-on") }
  }

  Process {
    id: statusProc
    command: ["bash", root.scriptPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    id: actionProc
    command: ["bash", root.scriptPath, root.pendingAction]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
    onExited: function(exitCode) {
      root.actionBusy = false
      root.refresh()
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    dimmed: !root.running
    tooltipText: root.running
      ? strings.t("bar.running").arg(root.version !== "" ? " " + root.version : "")
      : strings.t("bar.stopped")

    iconComponent: Component {
      Item {
        // A barra troca de cor conforme o modo (preta, blur, transparente). O
        // logo do OpenBot acompanha: tile branco em barra escura, tile preto
        // em barra clara, com um cross-fade curto na transição.
        readonly property real side: Math.max(10, Math.round(Math.min(width, height) * 0.8))
        readonly property color ink: button.foreground
        readonly property real lum: 0.299 * ink.r + 0.587 * ink.g + 0.114 * ink.b
        readonly property bool onDarkBar: lum > 0.5

        Image {
          anchors.centerIn: parent
          width: side
          height: side
          source: Qt.resolvedUrl("icons/openbot-icon-white.svg")
          sourceSize.width: Math.round(side * 2)
          sourceSize.height: Math.round(side * 2)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          opacity: onDarkBar ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Image {
          anchors.centerIn: parent
          width: side
          height: side
          source: Qt.resolvedUrl("icons/openbot-icon-black.svg")
          sourceSize.width: Math.round(side * 2)
          sourceSize.height: Math.round(side * 2)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          opacity: onDarkBar ? 0 : 1
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
      }
    }

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.runAction("restart")
      else root.togglePopup()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(card.implicitHeight)

    ColumnLayout {
      id: card
      anchors.fill: parent
      spacing: Style.space(10)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: strings.t("panel.title")
          color: Color.popups.text
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Rectangle {
          Layout.alignment: Qt.AlignVCenter
          implicitWidth: statusLabel.implicitWidth + Style.space(12)
          implicitHeight: statusLabel.implicitHeight + Style.space(4)
          radius: height / 2
          color: Util.alpha(root.running ? Color.accent : Color.urgent, 0.16)

          Text {
            id: statusLabel
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.running ? strings.t("panel.status.running") : strings.t("panel.status.stopped")
            color: root.running ? Color.accent : Color.urgent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      Text {
        Layout.fillWidth: true
        textFormat: Text.PlainText
        text: root.version !== "" ? strings.t("panel.subtitle").arg(root.version) : strings.t("panel.subtitleUnknown")
        color: Util.alpha(Color.popups.text, 0.72)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      PanelSeparator { Layout.fillWidth: true }

      Toggle {
        Layout.fillWidth: true
        label: strings.t("panel.aboveApps.title")
        description: strings.t("panel.aboveApps.description")
        checked: root.aboveApps
        enabled: !root.actionBusy
        foreground: Color.popups.text
        accent: Color.accent
        onClicked: root.runAction(root.aboveApps ? "dock-off" : "dock-on")
      }

      Text {
        Layout.fillWidth: true
        textFormat: Text.PlainText
        text: root.aboveApps
          ? strings.t("panel.aboveApps.hintOn")
          : strings.t("panel.aboveApps.hintOff")
        color: Util.alpha(Color.popups.text, 0.62)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      PanelSeparator { Layout.fillWidth: true }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Button {
          Layout.fillWidth: true
          text: strings.t("panel.action.open")
          bordered: true
          foreground: Color.popups.text
          accent: Color.accent
          enabled: !root.actionBusy
          onClicked: {
            root.runAction("open")
            root.close()
          }
        }

        Button {
          Layout.fillWidth: true
          text: strings.t("panel.action.restart")
          bordered: true
          foreground: Color.popups.text
          accent: Color.accent
          enabled: !root.actionBusy
          onClicked: root.runAction("restart")
        }
      }
    }
  }
}
