import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../tokens"

// 通知の履歴の 1 件。本体クリックで "default" アクション (あれば) を実行して閉じる。
Item {
    id: root

    required property var modelData    // Notification

    implicitHeight: card.implicitHeight

    function iconSource(name) {
        if (!name)
            return "";
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    // 閉じるとこの行自体が破棄されるので、必要な参照を先に取ってから最後に閉じる
    function activate() {
        const n = root.modelData;
        for (const a of n.actions)
            if (a.identifier === "default") {
                a.invoke();
                return;
            }
        n.dismiss();
    }

    Rectangle {
        id: card
        width: root.width
        implicitHeight: col.implicitHeight + 24
        radius: Shapes.large
        color: Colors.m3SurfaceContainerHighest

        StateLayer {
            anchors.fill: parent
            radius: card.radius
            stateColor: Colors.m3OnSurface
            hovered: area.containsMouse
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate()
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignTop

                    // 画像は角丸でクリップする
                    Rectangle {
                        id: imgMask
                        anchors.fill: parent
                        radius: Shapes.small
                        visible: false
                        layer.enabled: true
                    }
                    Image {
                        id: img
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: imgMask
                        }
                        visible: source !== ""
                        source: root.modelData.image !== "" ? root.modelData.image : root.iconSource(root.modelData.appIcon)
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: !img.visible
                        name: "notifications"
                        size: 24
                        color: Colors.m3OnSurfaceVariant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: root.modelData.appName
                        role: Typography.labelSmall
                        color: Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.modelData.summary
                        role: Typography.titleSmall
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.modelData.body
                        textFormat: Text.StyledText
                        role: Typography.bodySmall
                        color: Colors.m3OnSurfaceVariant
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    Layout.alignment: Qt.AlignTop
                    size: "s"
                    variant: "standard"
                    icon: "close"
                    onClicked: root.modelData.dismiss()
                }
            }
        }
    }
}
