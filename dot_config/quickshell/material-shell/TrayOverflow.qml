import Quickshell
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    panelWidth: Theme.trayPanelWidth
    panelHeight: Math.min(Theme.launcherMaxHeight,
        Theme.panelPadding * 2 + header.implicitHeight + Theme.space16
        + Math.max(Theme.buttonHeight, Math.min(items.length * (Theme.buttonHeight + Theme.space4), Theme.launcherMaxHeight - Theme.panelPadding * 2 - header.implicitHeight - Theme.space32)))
    property var items: []
    signal activateItem(var item)
    signal openMenu(var item)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader {
            id: header
            Layout.fillWidth: true
            title: "システムトレイ"
            icon: "apps"
            subtitle: "追加のインジケーター"
            onDismissed: panel.dismissed()
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.space4
            boundsBehavior: Flickable.StopAtBounds
            model: panel.items
            delegate: Rectangle {
                id: row
                required property var modelData
                width: list.width
                height: Theme.buttonHeight
                radius: Theme.shapeMedium
                color: rowArea.pressed ? Theme.pressedState : rowArea.containsMouse ? Theme.hoverState : "transparent"
                readonly property bool inputMethod: String(modelData.id || "").toLowerCase().includes("fcitx") || String(modelData.title || "").toLowerCase().includes("input method")
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space12
                    anchors.rightMargin: Theme.space12
                    spacing: Theme.space12
                    Item {
                        Layout.preferredWidth: Theme.iconSize
                        Layout.preferredHeight: Theme.iconSize
                        Image {
                            id: itemIcon
                            anchors.fill: parent
                            source: row.inputMethod ? "" : row.modelData.icon
                            sourceSize.width: Theme.iconSize * 2
                            sourceSize.height: Theme.iconSize * 2
                            fillMode: Image.PreserveAspectFit
                        }
                        MaterialIcon { anchors.fill: parent; name: row.inputMethod ? "keyboard" : "apps"; visible: row.inputMethod || itemIcon.status !== Image.Ready }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.tooltipTitle || row.modelData.title || row.modelData.id || "トレイ項目"
                        elide: Text.ElideRight
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                    MaterialIcon { visible: row.modelData.hasMenu; name: "chevron_right"; color: Theme.surfaceVariantText }
                }
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton || row.modelData.onlyMenu) {
                            if (row.modelData.hasMenu) panel.openMenu(row.modelData);
                        }
                        else if (mouse.button === Qt.MiddleButton) row.modelData.secondaryActivate();
                        else panel.activateItem(row.modelData);
                    }
                    onWheel: wheel => row.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
            PanelScrollIndicator { parent: list; view: list }
        }
    }
}
