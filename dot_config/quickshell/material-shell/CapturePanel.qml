import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    animateClose: !busy
    property string message: ""
    property bool busy: false
    signal captureRequested(string mode)
    signal cancelRequested()
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "スクリーンショット"; icon: "screenshot_monitor"; subtitle: "画面を撮影して保存・コピー"; onDismissed: panel.dismissed() }
        ControlCapture {
            Layout.fillWidth: true
            Layout.fillHeight: true
            busy: panel.busy
            message: panel.message
            onCaptureRequested: mode => panel.captureRequested(mode)
            onCancelRequested: panel.cancelRequested()
        }
    }
}
