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
        PanelHeader { Layout.fillWidth: true; title: "スクリーンショット"; onDismissed: panel.dismissed() }
        Text { Layout.fillWidth: true; text: "PNGをPictures/Screenshotsへ保存し、クリップボードにもコピーします。範囲はドラッグして指定し、Escでキャンセルできます。"; wrapMode: Text.Wrap; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        ShellButton { Layout.fillWidth: true; enabled: !panel.busy; text: "このディスプレイを撮影"; icon: "screenshot_monitor"; onClicked: panel.captureRequested("monitor") }
        ShellButton { Layout.fillWidth: true; enabled: !panel.busy; text: "すべてのディスプレイを撮影"; icon: "screenshot_monitor"; onClicked: panel.captureRequested("all") }
        ShellButton { Layout.fillWidth: true; enabled: !panel.busy; text: panel.busy ? "範囲選択中…" : "範囲を選択して撮影"; icon: "crop"; onClicked: panel.captureRequested("region") }
        ShellButton { Layout.fillWidth: true; visible: panel.busy; text: "撮影をキャンセル"; icon: "close"; onClicked: panel.cancelRequested() }
        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; text: panel.busy ? "範囲をドラッグして離すと撮影します。Escでキャンセルできます。" : panel.message; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
    }
}
