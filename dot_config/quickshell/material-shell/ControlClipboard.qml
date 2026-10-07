import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property bool active: false
    property var entries: []
    property int selectedIndex: 0
    property string error: ""
    property string message: ""
    property string operation: "list"
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    readonly property var results: entries.filter(entry => entry.preview.normalize("NFKC").toLocaleLowerCase().includes(search.text.normalize("NFKC").toLocaleLowerCase()))
    onActiveChanged: if (active) { search.text = ""; refresh(); Qt.callLater(search.focusInput); }
    onResultsChanged: selectedIndex = 0
    function refresh() { if (worker.running) return; operation = "list"; error = ""; worker.command = [cliDir + "/material-clipboard", "list"]; worker.running = true; }
    function operate(action, id) { if (worker.running || !id) return; operation = action; error = ""; message = ""; worker.command = [cliDir + "/material-clipboard", action, id]; worker.running = true; }
    Process {
        id: worker
        stdout: SplitParser { onRead: data => { if (page.operation === "list") { try { page.entries = JSON.parse(data); } catch (error) { page.error = "履歴を読み込めません"; } } } }
        stderr: SplitParser { onRead: data => page.error = data.trim() }
        onExited: (code, status) => {
            if (code !== 0) { page.error = page.error || "操作に失敗しました"; return; }
            if (page.operation === "copy") page.message = "クリップボードにコピーしました";
            else if (page.operation === "delete") Qt.callLater(page.refresh);
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space8
        SearchField { id: search; Layout.fillWidth: true; placeholder: "履歴を検索"; onNavigate: direction => { page.selectedIndex = Math.max(0, Math.min(page.results.length - 1, page.selectedIndex + direction)); list.positionViewAtIndex(page.selectedIndex, ListView.Contain); }; onSubmit: page.operate("copy", page.results[page.selectedIndex]?.id) }
        ListView {
            id: list
            PanelScrollIndicator { parent: list; view: list }
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: page.results
            spacing: Theme.space4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width - (list.contentHeight > list.height ? Theme.space8 : 0)
                readonly property bool hasImage: !!modelData.image
                height: hasImage ? Theme.clipboardImageRowHeight : Theme.listRowHeight
                radius: Theme.shapeMedium
                color: page.selectedIndex === index ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space8
                    spacing: Theme.space12
                    RoundedArtwork {
                        Layout.preferredWidth: row.hasImage ? Theme.clipboardPreviewSize : 0
                        Layout.preferredHeight: row.hasImage ? Theme.clipboardPreviewSize : 0
                        visible: row.hasImage
                        radius: Theme.shapeSmall
                        backgroundColor: page.selectedIndex === row.index ? Theme.secondaryContainer : Theme.surfaceContainerHigh
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
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { page.selectedIndex = row.index; page.operate("copy", row.modelData.id); } }
            }
            PanelEmptyState { anchors.fill: parent; visible: page.results.length === 0; icon: "content_paste"; title: search.text ? "一致する履歴がありません" : "履歴はまだありません"; description: search.text ? "別のキーワードで検索してください。" : "コピーしたテキストや画像がここに表示されます。" }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: page.error || page.message || "↑ ↓ 選択 · Enter コピー"; color: page.error ? Theme.error : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
            ShellButton { text: "削除"; flat: true; destructive: true; enabled: page.results.length > 0 && !worker.running; onClicked: page.operate("delete", page.results[page.selectedIndex]?.id) }
        }
    }
}
