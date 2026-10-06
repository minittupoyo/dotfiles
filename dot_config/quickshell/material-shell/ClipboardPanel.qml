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
            if (code !== 0) { panel.error = panel.error || "操作に失敗しました"; return; }
            if (panel.operation === "copy") panel.dismissed();
            else if (panel.operation === "delete") Qt.callLater(panel.refresh);
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "クリップボード"; onDismissed: panel.dismissed() }
        SearchField { id: search; Layout.fillWidth: true; placeholder: "履歴を検索"; onNavigate: direction => { panel.selectedIndex = Math.max(0, Math.min(panel.results.length - 1, panel.selectedIndex + direction)); list.positionViewAtIndex(panel.selectedIndex, ListView.Contain); }; onSubmit: panel.operate("copy", panel.results[panel.selectedIndex]?.id) }
        ListView {
            id: list
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
                width: list.width
                readonly property bool hasImage: !!row.modelData.image
                height: hasImage ? 104 : Theme.listRowHeight
                radius: Theme.shapeSmall
                color: panel.selectedIndex === index ? Theme.secondaryContainer : "transparent"
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
                        Image {
                            anchors.fill: parent
                            source: row.modelData.image || ""
                            sourceSize.width: 176
                            sourceSize.height: 176
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.preview
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        maximumLineCount: row.hasImage ? 3 : 1
                        wrapMode: row.hasImage ? Text.Wrap : Text.NoWrap
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.selectedIndex = row.index; panel.operate("copy", row.modelData.id); } }
            }
            Text { anchors.centerIn: parent; visible: panel.results.length === 0; text: "履歴がありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        }
        Text { Layout.fillWidth: true; visible: panel.error !== ""; text: panel.error; wrapMode: Text.Wrap; color: Theme.error; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "↑ ↓ 選択 · Enter コピー · Esc 閉じる"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            ShellButton { text: "削除"; enabled: panel.results.length > 0 && !worker.running; onClicked: panel.operate("delete", panel.results[panel.selectedIndex]?.id) }
        }
    }
}
