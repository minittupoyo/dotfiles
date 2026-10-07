import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property var entries: []
    property int selectedIndex: 0
    property string error: ""
    property string operation: "list"
    signal messageRequested(string text, bool failed)
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    readonly property var results: entries.filter(entry => entry.preview.normalize("NFKC").toLocaleLowerCase().includes(search.text.normalize("NFKC").toLocaleLowerCase()))
    onResultsChanged: selectedIndex = 0
    onVisibleChanged: if (visible) { search.text = ""; refresh(); Qt.callLater(search.focusInput); }
    function refresh() { if (worker.running) return; operation = "list"; error = ""; worker.command = [cliDir + "/material-clipboard", "list"]; worker.running = true; }
    function operate(action, id) { if (worker.running || !id) return; operation = action; error = ""; worker.command = [cliDir + "/material-clipboard", action, id]; worker.running = true; }
    Process {
        id: worker
        stdout: SplitParser { onRead: data => { if (panel.operation === "list") { try { panel.entries = JSON.parse(data); } catch (error) { panel.error = "履歴を読み込めません"; } } } }
        stderr: SplitParser { onRead: data => panel.error = data }
        onExited: (code, status) => {
            if (code !== 0) {
                panel.error = panel.error || "操作に失敗しました";
                panel.messageRequested(panel.error, true);
                return;
            }
            if (panel.operation === "copy") {
                panel.messageRequested("クリップボードにコピーしました", false);
                panel.dismissed();
            } else if (panel.operation === "delete") {
                panel.messageRequested("履歴から削除しました", false);
                Qt.callLater(panel.refresh);
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "クリップボード"; icon: "content_paste"; subtitle: "コピーしたテキストと画像"; onDismissed: panel.dismissed() }
        SearchField { id: search; Layout.fillWidth: true; placeholder: "履歴を検索"; onNavigate: direction => { panel.selectedIndex = Math.max(0, Math.min(panel.results.length - 1, panel.selectedIndex + direction)); list.positionViewAtIndex(panel.selectedIndex, ListView.Contain); }; onSubmit: panel.operate("copy", panel.results[panel.selectedIndex]?.id) }
        ListView {
            id: list
            PanelScrollIndicator { parent: list; view: list }
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: panel.results
            spacing: Theme.space4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width - (list.contentHeight > list.height ? Theme.space8 : 0)
                readonly property bool hasImage: !!row.modelData.image
                height: hasImage ? Theme.clipboardImageRowHeight : Theme.listRowHeight
                radius: Theme.shapeMedium
                color: panel.selectedIndex === index ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space8
                    spacing: Theme.space12
                    RoundedArtwork {
                        Layout.preferredWidth: row.hasImage ? Theme.clipboardPreviewSize : 0
                        Layout.preferredHeight: row.hasImage ? Theme.clipboardPreviewSize : 0
                        visible: row.hasImage
                        radius: Theme.shapeSmall
                        backgroundColor: panel.selectedIndex === row.index ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                        source: row.modelData.image || ""
                        sourceSize.width: Theme.clipboardPreviewSize * 2
                        sourceSize.height: Theme.clipboardPreviewSize * 2
                        fillMode: Image.PreserveAspectCrop
                        fallbackIcon: "content_paste"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space4
                        Text { Layout.fillWidth: true; text: row.hasImage ? "画像" : row.modelData.preview; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: row.hasImage ? Font.Medium : Font.Normal }
                        Text { visible: row.hasImage; Layout.fillWidth: true; text: (row.modelData.preview.match(/\d+x\d+/)?.[0] || "クリップボードの画像") + " · クリックしてコピー"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.selectedIndex = row.index; panel.operate("copy", row.modelData.id); } }
            }
            PanelEmptyState { anchors.fill: parent; visible: panel.results.length === 0; icon: "content_paste"; title: search.text ? "一致する履歴がありません" : "履歴はまだありません"; description: search.text ? "別のキーワードで検索してください。" : "コピーしたテキストや画像がここに表示されます。" }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "↑ ↓ 選択 · Enter コピー · Esc 閉じる"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            ShellButton { text: "削除"; flat: true; destructive: true; enabled: panel.results.length > 0 && !worker.running; onClicked: panel.operate("delete", panel.results[panel.selectedIndex]?.id) }
        }
    }
}
