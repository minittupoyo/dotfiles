import Quickshell
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property real anchorX: -1
    rightAnchorX: anchorX
    panelWidth: Theme.trayPanelWidth
    panelHeight: Math.min(Theme.launcherMaxHeight, menuHeader.implicitHeight + Theme.panelPadding * 2 + Theme.space16 + (stack.length > 0 ? Theme.buttonHeight + Theme.space16 : 0) + Math.max(Theme.buttonHeight, entries.reduce((sum, item) => sum + (item.isSeparator ? Theme.space12 : Theme.buttonHeight) + Theme.space4, 0)))
    property var entry: null
    property string title: ""
    property var stack: []
    readonly property var entries: opener.children.values
    onVisibleChanged: if (!visible) { opener.menu = null; stack = []; }
    function openEntry(menu, label, itemRightX) { entry = menu; title = label; anchorX = itemRightX ?? -1; stack = []; opener.menu = menu; }
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
        PanelHeader { id: menuHeader; Layout.fillWidth: true; title: panel.title || "メニュー"; icon: "apps"; subtitle: "アプリケーションの操作"; onDismissed: panel.dismissed() }
        ShellButton { visible: panel.stack.length > 0; text: "戻る"; flat: true; onClicked: { const previous = panel.stack.slice(); opener.menu = previous.pop(); panel.stack = previous; } }
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
                ShellButton { visible: !parent.modelData.isSeparator; anchors.fill: parent; flat: true; alignLeft: true; text: parent.modelData.text.replace(/&/g, ""); icon: parent.modelData.checkState === Qt.Checked ? "check" : ""; trailingIcon: parent.modelData.hasChildren ? "chevron_right" : ""; enabled: parent.modelData.enabled; onClicked: panel.choose(parent.modelData) }
            }
            Text { anchors.centerIn: parent; visible: list.count === 0; text: "利用できるメニューがありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        }
    }
}
