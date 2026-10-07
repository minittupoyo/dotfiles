import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property bool busy: false
    property string message: ""
    signal captureRequested(string mode)
    signal cancelRequested()
    implicitHeight: content.implicitHeight
    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: Theme.space16
        PanelSection {
            title: "必要な範囲だけを撮影"
            description: "ドラッグして範囲を選択。Escでキャンセルできます。"
            icon: "crop"
            ShellButton { Layout.fillWidth: true; emphasized: true; enabled: !page.busy; text: page.busy ? "範囲選択中…" : "範囲を選択して撮影"; icon: "crop"; onClicked: page.captureRequested("region") }
        }
        ControlTile { title: "このディスプレイ"; subtitle: "パネルを閉じて画面全体を撮影"; available: !page.busy; icon: "screenshot_monitor"; onToggled: page.captureRequested("monitor") }
        ControlTile { title: "すべてのディスプレイ"; subtitle: "接続中の画面をまとめて撮影"; available: !page.busy; icon: "screenshot_monitor"; onToggled: page.captureRequested("all") }
        ShellButton { Layout.fillWidth: true; visible: page.busy; text: "撮影をキャンセル"; icon: "close"; onClicked: page.cancelRequested() }
        Item { Layout.fillHeight: true }
        PanelSection { title: "保存とコピー"; description: "PNGをPictures/Screenshotsへ保存し、クリップボードにもコピーします。"; icon: "content_paste" }
        Text { Layout.fillWidth: true; visible: page.busy; text: "範囲をドラッグして離すと撮影します。Escでキャンセルできます。"; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
    }
}
