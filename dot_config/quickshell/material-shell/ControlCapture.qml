import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property bool busy: false
    property string message: ""
    signal captureRequested(string mode)
    signal cancelRequested()
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space8
        Text { Layout.fillWidth: true; text: "PNGを保存し、クリップボードにもコピーします。"; wrapMode: Text.Wrap; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        ShellButton { Layout.fillWidth: true; enabled: !page.busy; text: "このディスプレイを撮影"; icon: "screenshot_monitor"; onClicked: page.captureRequested("monitor") }
        ShellButton { Layout.fillWidth: true; enabled: !page.busy; text: "すべてのディスプレイを撮影"; icon: "screenshot_monitor"; onClicked: page.captureRequested("all") }
        ShellButton { Layout.fillWidth: true; enabled: !page.busy; text: page.busy ? "範囲選択中…" : "範囲を選択して撮影"; icon: "crop"; onClicked: page.captureRequested("region") }
        ShellButton { Layout.fillWidth: true; visible: page.busy; text: "撮影をキャンセル"; icon: "close"; onClicked: page.cancelRequested() }
        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; text: page.busy ? "範囲をドラッグして離すと撮影します。Escでキャンセルできます。" : page.message; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
    }
}
