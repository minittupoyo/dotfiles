import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property string message: ""
    signal captureRequested(string mode)
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "スクリーンショット"; onDismissed: panel.dismissed() }
        Text { Layout.fillWidth: true; text: "画像はPictures/Screenshotsへ保存し、クリップボードにもコピーします。"; wrapMode: Text.Wrap; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        ShellButton { Layout.fillWidth: true; text: "全画面を撮影"; icon: "screenshot_monitor"; onClicked: panel.captureRequested("all") }
        ShellButton { Layout.fillWidth: true; text: "範囲を選択して撮影"; icon: "crop"; onClicked: panel.captureRequested("region") }
        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; text: panel.message; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
    }
}
