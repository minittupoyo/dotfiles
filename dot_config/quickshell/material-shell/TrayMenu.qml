import Quickshell
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property var entry: null
    property string title: ""
    property var stack: []
    readonly property var entries: opener.children.values
    onVisibleChanged: if (!visible) { opener.menu = null; stack = []; }
    function openEntry(menu, label) { entry = menu; title = label; stack = []; opener.menu = menu; }
    function choose(item) {
        if (!item.enabled || item.isSeparator) return;
        if (item.hasChildren) { stack = [...stack, opener.menu]; opener.menu = item; }
        else { item.triggered(); dismissed(); }
    }
    // Keep the root referenced while browsing descendants. Unreferencing it
    // destroys the D-Bus child entries that the submenu opener needs.
    QsMenuOpener { id: rootOpener; menu: panel.visible ? panel.entry : null }
    QsMenuOpener { id: opener }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: panel.title || "メニュー"; onDismissed: panel.dismissed() }
        ShellButton { visible: panel.stack.length > 0; text: "戻る"; onClicked: { const previous = panel.stack.slice(); opener.menu = previous.pop(); panel.stack = previous; } }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: panel.entries
            clip: true
            spacing: Theme.space4
            delegate: Item {
                required property var modelData
                width: list.width
                height: modelData.isSeparator ? Theme.space12 : Theme.buttonHeight
                Rectangle { visible: parent.modelData.isSeparator; anchors.centerIn: parent; width: parent.width; height: 1; color: Theme.outlineVariant }
                ShellButton { visible: !parent.modelData.isSeparator; anchors.fill: parent; text: parent.modelData.text.replace(/&/g, ""); icon: parent.modelData.checkState === Qt.Checked ? "check" : ""; trailingIcon: parent.modelData.hasChildren ? "chevron_right" : ""; enabled: parent.modelData.enabled; onClicked: panel.choose(parent.modelData) }
            }
        }
    }
}
