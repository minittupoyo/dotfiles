import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

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
    property bool folderPickerOpen: false
    property string folderPickerPath: ""
    signal messageRequested(string text, bool failed)
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
    function pathUrl(path) {
        return "file://" + String(path).split("/").map(part => encodeURIComponent(part)).join("/");
    }
    function localPath(url) {
        return decodeURIComponent(String(url).replace(/^file:\/\//, ""));
    }
    function parentPath(path) {
        const clean = String(path).replace(/\/+$/, "");
        const slash = clean.lastIndexOf("/");
        return slash <= 0 ? "/" : clean.slice(0, slash);
    }
    FolderListModel {
        id: directoryModel
        folder: selector.pathUrl(selector.folderPickerPath || (Quickshell.env("HOME") || "/home"))
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
    }
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
                selector.messageRequested(selector.message, true);
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
            selector.messageRequested(selector.message, selector.failed);
        }
    }
    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "壁紙と配色"; icon: "wallpaper"; subtitle: "画像を選ぶと、壁紙に合わせたテーマを生成します"; onDismissed: selector.dismissed() }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8
            SearchField { id: folder; Layout.fillWidth: true; placeholder: "壁紙フォルダーのパス"; enabled: !selector.busy && !scanProcess.running; onSubmit: selector.refresh(text) }
            ShellButton { text: "参照"; icon: "folder_open"; enabled: !selector.busy && !scanProcess.running; onClicked: { selector.folderPickerPath = folder.text.trim() || (Quickshell.env("HOME") || "/home"); selector.folderPickerOpen = true; } }
            ShellButton { text: scanProcess.running ? "読み込み中…" : "フォルダーを読み込む"; icon: "wallpaper"; enabled: !selector.busy && !scanProcess.running && folder.text.trim() !== ""; onClicked: selector.refresh(folder.text.trim()) }
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
                PanelScrollIndicator { parent: list; view: list }
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.space4
                    boundsBehavior: Flickable.StopAtBounds
                    model: selector.results
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width - (list.contentHeight > list.height ? Theme.space8 : 0)
                        height: Theme.wallpaperRowHeight
                        radius: Theme.shapeMedium
                        color: selector.selectedIndex === index ? Theme.secondaryContainer : "transparent"
                        Accessible.role: Accessible.ListItem
                        Accessible.name: modelData.name
                        Accessible.selected: selector.selectedIndex === index
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space12
                            spacing: Theme.space12
                            RoundedArtwork { backgroundColor: selector.selectedIndex === row.index ? Theme.secondaryContainer : Theme.surfaceContainer; radius: Theme.shapeSmall; Layout.preferredWidth: Theme.wallpaperThumbnailWidth; Layout.preferredHeight: Theme.wallpaperThumbnailHeight; source: row.modelData.url; sourceSize.width: Theme.wallpaperThumbnailWidth * 2; sourceSize.height: Theme.wallpaperThumbnailHeight * 2; fillMode: Image.PreserveAspectCrop }
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
                PanelEmptyState { anchors.fill: parent; visible: selector.results.length === 0; icon: "wallpaper"; title: "壁紙がありません"; description: "画像のあるフォルダーを指定してください。" }
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
                    RoundedArtwork { id: preview; radius: Theme.shapeSmall; backgroundColor: Theme.inputBackground; anchors.fill: parent; anchors.margins: Theme.space8; source: selector.selected?.url ?? ""; sourceSize.width: Theme.wallpaperWidth; sourceSize.height: Theme.wallpaperMaxHeight; fillMode: Image.PreserveAspectFit; cache: false }
                    Text { anchors.centerIn: parent; visible: preview.status !== Image.Ready; text: preview.status === Image.Error ? "画像を読み込めません" : selector.selected ? "プレビューを読み込み中…" : "画像を選択してください"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                }
                Text { Layout.fillWidth: true; text: selector.selected?.name ?? ""; elide: Text.ElideMiddle; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                Text { Layout.fillWidth: true; text: selector.selected?.path ?? ""; wrapMode: Text.NoWrap; maximumLineCount: 1; elide: Text.ElideMiddle; clip: true; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                Item { Layout.fillHeight: true }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "↑ ↓ 選択 · Enter 適用 · Esc 閉じる  /  " + selector.results.length + " 件"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            ShellButton { text: selector.busy ? "適用中…" : "壁紙と配色を適用"; emphasized: true; enabled: !!selector.selected && !selector.busy && !scanProcess.running && preview.status === Image.Ready; onClicked: selector.applySelection() }
        }
    }
    Rectangle {
        id: folderPicker
        anchors.fill: parent
        z: 10
        visible: selector.folderPickerOpen
        focus: visible
        radius: Theme.panelRadius
        color: Theme.surfaceContainer
        Keys.onEscapePressed: selector.folderPickerOpen = false
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            spacing: Theme.space16
            PanelHeader { Layout.fillWidth: true; title: "壁紙フォルダーを選択"; icon: "folder_open"; subtitle: "壁紙画像のあるフォルダーを選びます"; onDismissed: selector.folderPickerOpen = false }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                ShellButton { text: "上へ"; enabled: selector.folderPickerPath !== "/"; onClicked: selector.folderPickerPath = selector.parentPath(selector.folderPickerPath) }
                Text { Layout.fillWidth: true; text: selector.folderPickerPath; elide: Text.ElideMiddle; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            }
            ListView {
                id: directoryList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.space4
                boundsBehavior: Flickable.StopAtBounds
                model: directoryModel
                delegate: Rectangle {
                    required property string fileName
                    required property url fileUrl
                    width: directoryList.width - (directoryList.contentHeight > directoryList.height ? Theme.space8 : 0)
                    height: Theme.controlHeight
                    radius: Theme.shapeMedium
                    color: directoryArea.pressed ? Theme.pressedState : directoryArea.containsMouse ? Theme.hoverState : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space12
                        anchors.rightMargin: Theme.space12
                        spacing: Theme.space12
                        MaterialIcon { name: "folder_open"; color: Theme.surfaceText }
                        Text { Layout.fillWidth: true; text: fileName; elide: Text.ElideMiddle; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        MaterialIcon { name: "chevron_right"; color: Theme.surfaceVariantText }
                    }
                    MouseArea { id: directoryArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: selector.folderPickerPath = selector.localPath(fileUrl) }
                }
                PanelEmptyState { anchors.fill: parent; visible: directoryModel.count === 0; icon: "folder_open"; title: "サブフォルダーがありません"; description: "この場所にあるフォルダーはありません。" }
                PanelScrollIndicator { parent: directoryList; view: directoryList }
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                ShellButton { text: "キャンセル"; flat: true; onClicked: selector.folderPickerOpen = false }
                ShellButton {
                    text: "このフォルダーを選択"
                    icon: "check"
                    emphasized: true
                    enabled: selector.folderPickerPath !== "" && !selector.busy && !scanProcess.running
                    onClicked: {
                        folder.text = selector.folderPickerPath;
                        selector.folderPickerOpen = false;
                        selector.refresh(selector.folderPickerPath);
                    }
                }
            }
        }
    }
}
