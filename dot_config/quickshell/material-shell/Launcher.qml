import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: launcher
    property int applicationRevision: 0
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { launcher.applicationRevision++; }
    }
    readonly property var applications: {
        applicationRevision;
        return DesktopEntries.applications.values;
    }
    readonly property string query: search.text
    property int selectedIndex: 0
    readonly property var results: {
        const terms = query.normalize("NFKC").toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
        return applications.filter(entry => {
            const haystack = [entry.name, entry.genericName, entry.comment, entry.id, ...(entry.keywords || [])]
                .join(" ").normalize("NFKC").toLocaleLowerCase();
            return terms.every(term => haystack.includes(term));
        }).sort((a, b) => a.name.localeCompare(b.name, "ja"));
    }
    onResultsChanged: { selectedIndex = 0; list.positionViewAtBeginning(); }
    onVisibleChanged: {
        if (visible) {
            search.text = "";
            selectedIndex = 0;
            Qt.callLater(search.focusInput);
        }
    }
    function setQuery(value) { search.text = value; }
    function moveSelection(direction) {
        if (!results.length) return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + direction));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
    function launch(index) {
        const entry = results[index];
        if (!entry || !entry.command.length) return;
        if (entry.runInTerminal) {
            Quickshell.execDetached({ command: ["kitty", "-e", ...entry.command], workingDirectory: entry.workingDirectory });
        } else {
            entry.execute();
        }
        dismissed();
    }
    function status() {
        return JSON.stringify({visible: visible, screen: screen?.name ?? "", query: query,
            selectedIndex: selectedIndex, count: results.length,
            names: results.slice(0, 8).map(entry => entry.name), composing: search.composing});
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "アプリケーション"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleSize
                font.weight: Font.Medium
            }
            Rectangle {
                implicitWidth: Theme.buttonHeight
                implicitHeight: Theme.buttonHeight
                radius: Theme.buttonHeight / 2
                color: closeArea.pressed ? Theme.pressedState : closeArea.containsMouse ? Theme.hoverState : "transparent"
                activeFocusOnTab: true
                border.width: activeFocus ? 1 : 0
                border.color: Theme.primary
                Accessible.role: Accessible.Button
                Accessible.name: "閉じる"
                MaterialIcon { anchors.centerIn: parent; name: "close" }
                Keys.onReturnPressed: launcher.dismissed()
                Keys.onSpacePressed: launcher.dismissed()
                MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: launcher.dismissed() }
            }
        }
        SearchField {
            id: search
            Layout.fillWidth: true
            onNavigate: direction => launcher.moveSelection(direction)
            onSubmit: launcher.launch(launcher.selectedIndex)
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: launcher.results
                spacing: Theme.space4
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: launcher.selectedIndex === index
                    width: list.width
                    height: Theme.listRowHeight
                    radius: Theme.shapeSmall
                    color: selected ? Theme.secondaryContainer : "transparent"
                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.name
                    Accessible.selected: selected
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: rowArea.pressed ? Theme.pressedState : rowArea.containsMouse ? Theme.hoverState : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space12
                        anchors.rightMargin: Theme.space12
                        spacing: Theme.space12
                        Item {
                            Layout.preferredWidth: Theme.appIconSize
                            Layout.preferredHeight: Theme.appIconSize
                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: row.modelData.icon ? (row.modelData.icon.startsWith("/") ? "file://" + row.modelData.icon : Quickshell.iconPath(row.modelData.icon, true)) : ""
                                sourceSize.width: Theme.appIconSize
                                sourceSize.height: Theme.appIconSize
                                Accessible.ignored: true
                            }
                            MaterialIcon { anchors.centerIn: parent; name: "apps"; visible: appIcon.status !== Image.Ready }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                color: row.selected ? Theme.secondaryContainerText : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.bodySize
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: row.modelData.genericName || row.modelData.comment || ""
                                color: Theme.surfaceVariantText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.labelSize
                                elide: Text.ElideRight
                            }
                        }
                        MaterialIcon { name: "arrow_forward"; visible: row.selected }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.launch(row.index)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: launcher.results.length === 0
                text: "一致するアプリがありません"
                color: Theme.surfaceVariantText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "↑ ↓ 選択  ·  Enter 起動  ·  Esc 閉じる"
                color: Theme.surfaceVariantText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
            }
            Text {
                text: launcher.results.length + " 件"
                color: Theme.surfaceVariantText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
            }
        }
    }
}
