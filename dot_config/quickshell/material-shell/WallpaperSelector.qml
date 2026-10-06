import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: selector
    attachedToBar: true
    panelWidth: Theme.wallpaperWidth
    panelHeight: Theme.wallpaperMaxHeight
    property var images: []
    property var directories: []
    property string currentPath: ""
    property int selectedIndex: 0
    property string message: ""
    property bool failed: false
    property string processError: ""
    property string applyingPath: ""
    property bool applying: false
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    property string scannerPath: cliDir + "/material-wallpapers"
    property string palettePath: cliDir + "/material-palette"
    readonly property bool busy: applying || applyProcess.running
    readonly property var results: {
        const terms = search.text.normalize("NFKC").toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
        return images.filter(image => terms.every(term => (image.name + " " + image.path).normalize("NFKC").toLocaleLowerCase().includes(term)));
    }
    readonly property var selected: results[selectedIndex] ?? null
    onResultsChanged: { selectedIndex = 0; list.positionViewAtBeginning(); }
    onVisibleChanged: if (visible) {
        search.text = "";
        if (!busy) message = "";
        refresh();
        Qt.callLater(search.focusInput);
    }
    function refresh(directory) {
        if (scanProcess.running || busy) return;
        failed = false; message = "読み込み中…"; processError = "";
        scanProcess.command = [scannerPath];
        if (directory) scanProcess.command = [...scanProcess.command, "--directory", directory];
        scanProcess.running = true;
    }
    function moveSelection(direction) {
        if (!results.length) return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + direction));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
    function applySelection() {
        if (!selected || busy || scanProcess.running || preview.status !== Image.Ready) return;
        applying = true;
        applyingPath = selected.path;
        failed = false; message = "壁紙と配色を適用中…"; processError = "";
        applyProcess.command = [palettePath, applyingPath];
        applyProcess.running = true;
    }
    function status() {
        return JSON.stringify({visible: visible, screen: screen?.name ?? "", count: results.length,
            query: search.text, selectedIndex: selectedIndex, path: selected?.path ?? "", current: currentPath,
            busy: busy, scanning: scanProcess.running, message: message, failed: failed, previewReady: preview.status === Image.Ready});
    }
    function setQuery(value) { search.text = value; }
    Process {
        id: scanProcess
        stdout: SplitParser {
            onRead: data => {
                try {
                    const library = JSON.parse(data);
                    selector.images = library.images;
                    selector.directories = library.directories;
                    selector.currentPath = library.current;
                    folder.text = library.directories[0] ?? "";
                    selector.selectedIndex = Math.max(0, selector.results.findIndex(image => image.path === library.current));
                    list.positionViewAtIndex(selector.selectedIndex, ListView.Contain);
                    selector.message = "";
                } catch (error) { selector.processError = "壁紙一覧を読み込めません"; }
            }
        }
        stderr: SplitParser { onRead: data => selector.processError = data }
        onExited: (code, status) => {
            if (code !== 0 || selector.processError) {
                selector.failed = true;
                selector.message = selector.processError || "フォルダーを読み込めません";
            }
        }
    }
    Process {
        id: applyProcess
        stdout: SplitParser { onRead: data => {} }
        stderr: SplitParser { onRead: data => selector.processError = data }
        onExited: (code, status) => {
            selector.applying = false;
            selector.failed = code !== 0;
            if (code === 0) { selector.currentPath = selector.applyingPath; selector.message = "壁紙と配色を適用しました"; }
            else selector.message = "適用できませんでした。" + (selector.processError || "再度お試しください");
        }
    }
    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Theme.space16
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "壁紙"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; font.weight: Font.Medium }
            ShellButton { text: "再読み込み"; enabled: !selector.busy && !scanProcess.running; onClicked: selector.refresh() }
            ShellButton { icon: "close"; Accessible.name: "閉じる"; onClicked: selector.dismissed() }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8
            SearchField { id: folder; Layout.fillWidth: true; placeholder: "壁紙フォルダーのパス"; enabled: !selector.busy && !scanProcess.running; onSubmit: selector.refresh(text) }
            ShellButton { text: "読み込む"; enabled: !selector.busy && !scanProcess.running && folder.text.trim() !== ""; onClicked: selector.refresh(folder.text) }
        }
        SearchField { id: search; objectName: "wallpaperSearch"; Layout.fillWidth: true; placeholder: "壁紙を検索"; onNavigate: direction => selector.moveSelection(direction); onSubmit: selector.applySelection() }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space24
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: previewColumn.visible ? layout.width * 0.42 : layout.width
                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.space4
                    boundsBehavior: Flickable.StopAtBounds
                    model: selector.results
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width
                        height: Theme.wallpaperRowHeight
                        radius: Theme.shapeSmall
                        color: selector.selectedIndex === index ? Theme.secondaryContainer : "transparent"
                        Accessible.role: Accessible.ListItem
                        Accessible.name: modelData.name
                        Accessible.selected: selector.selectedIndex === index
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space12
                            spacing: Theme.space12
                            Image { Layout.preferredWidth: Theme.wallpaperThumbnailWidth; Layout.preferredHeight: Theme.wallpaperThumbnailHeight; source: row.modelData.url; sourceSize.width: Theme.wallpaperThumbnailWidth * 2; sourceSize.height: Theme.wallpaperThumbnailHeight * 2; fillMode: Image.PreserveAspectCrop; clip: true; asynchronous: true; autoTransform: true }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space4
                                Text { Layout.fillWidth: true; text: row.modelData.name; elide: Text.ElideMiddle; color: selector.selectedIndex === row.index ? Theme.secondaryContainerText : Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                                Text { visible: selector.currentPath === row.modelData.path; text: "適用中"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                            }
                        }
                        Rectangle { anchors.fill: parent; radius: parent.radius; color: rowArea.pressed ? Theme.pressedState : rowArea.containsMouse ? Theme.hoverState : "transparent" }
                        MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { selector.selectedIndex = row.index; search.focusInput(); } }
                    }
                }
                Text { anchors.centerIn: parent; width: parent.width; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; visible: selector.results.length === 0; text: "壁紙がありません\nフォルダーを指定してください"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
            }
            ColumnLayout {
                id: previewColumn
                visible: layout.width >= Theme.wallpaperCompactWidth
                Layout.preferredWidth: layout.width * 0.58 - Theme.space24
                Layout.fillHeight: true
                spacing: Theme.space12
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    color: Theme.inputBackground
                    radius: Theme.shapeMedium
                    Image { id: preview; anchors.fill: parent; anchors.margins: Theme.space8; source: selector.selected?.url ?? ""; sourceSize.width: Theme.wallpaperWidth; sourceSize.height: Theme.wallpaperMaxHeight; fillMode: Image.PreserveAspectFit; asynchronous: true; autoTransform: true; cache: false }
                    Text { anchors.centerIn: parent; visible: preview.status !== Image.Ready; text: preview.status === Image.Error ? "画像を読み込めません" : selector.selected ? "プレビューを読み込み中…" : "画像を選択してください"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                }
                Text { Layout.fillWidth: true; text: selector.selected?.name ?? ""; elide: Text.ElideMiddle; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                Text { Layout.fillWidth: true; text: selector.selected?.path ?? ""; wrapMode: Text.WrapAnywhere; maximumLineCount: 3; elide: Text.ElideMiddle; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                Item { Layout.fillHeight: true }
            }
        }
        Text { Layout.fillWidth: true; visible: selector.message !== ""; text: selector.message; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; color: selector.failed ? Theme.error : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "↑ ↓ 選択 · Enter 適用 · Esc 閉じる  /  " + selector.results.length + " 件"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            ShellButton { text: selector.busy ? "適用中…" : "壁紙と配色を適用"; emphasized: true; enabled: !!selector.selected && !selector.busy && !scanProcess.running && preview.status === Image.Ready; onClicked: selector.applySelection() }
        }
    }
}
