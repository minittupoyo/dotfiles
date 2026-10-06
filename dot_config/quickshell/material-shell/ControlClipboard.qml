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
                width: list.width
                readonly property bool hasImage: !!modelData.image
                height: hasImage ? 104 : Theme.listRowHeight
                radius: Theme.shapeSmall
                color: page.selectedIndex === index ? Theme.secondaryContainer : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space8
                    spacing: Theme.space12
                    Rectangle {
                        Layout.preferredWidth: row.hasImage ? 88 : 0
                        Layout.preferredHeight: row.hasImage ? 88 : 0
                        visible: row.hasImage
                        radius: Theme.shapeSmall
                        color: Theme.surfaceContainerHigh
                        clip: true
                        Image { anchors.fill: parent; source: row.modelData.image || ""; sourceSize.width: 176; sourceSize.height: 176; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true }
                    }
                    Text { Layout.fillWidth: true; text: row.modelData.preview; textFormat: Text.PlainText; elide: Text.ElideRight; maximumLineCount: row.hasImage ? 3 : 1; wrapMode: row.hasImage ? Text.Wrap : Text.NoWrap; verticalAlignment: Text.AlignVCenter; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { page.selectedIndex = row.index; page.operate("copy", row.modelData.id); } }
            }
            Text { anchors.centerIn: parent; visible: page.results.length === 0; text: search.text ? "一致する履歴がありません" : "履歴がありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: page.error || page.message || "↑ ↓ 選択 · Enter コピー"; color: page.error ? Theme.error : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
            ShellButton { text: "削除"; destructive: true; enabled: page.results.length > 0 && !worker.running; onClicked: page.operate("delete", page.results[page.selectedIndex]?.id) }
        }
    }
}
