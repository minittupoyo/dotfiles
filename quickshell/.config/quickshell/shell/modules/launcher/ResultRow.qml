import QtQuick
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// ランチャーの結果 1 行。選択行は角丸が丸 (pill) にモーフし、色が secondary container になる。
// kind: "app" | "calc" | "clip"
Item {
    id: root

    required property var modelData    // { kind, title, subtitle, iconName, isImage, payload }
    required property int index

    property bool selected: false

    signal activated()
    signal moved(real gx, real gy)    // ポインタの画面座標つき (実際に動いたかを呼び出し側が判定する)

    implicitHeight: 56

    readonly property bool isImage: modelData.kind === "clip" && modelData.isImage === true

    // 選択・非選択の補間 (色) と角丸のモーフィング
    SpringValue {
        id: sel
        target: root.selected ? 1 : 0
        spec: Motion.effectsDefault
        epsilon: 0.002
    }
    SpringValue {
        id: corner
        target: root.selected ? root.height / 2 : Shapes.medium
        spec: Motion.spatialFast
        epsilon: 0.05
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.max(0, corner.value)
        color: Colors.m3SecondaryContainer
        opacity: sel.value
    }

    StateLayer {
        anchors.fill: parent
        radius: Math.max(0, corner.value)
        stateColor: Colors.m3OnSurface
        hovered: mouse.containsMouse
    }

    Ripple {
        id: ripple
        anchors.fill: parent
        radius: Math.max(0, corner.value)
        color: Colors.m3OnSurface
    }

    readonly property color titleColor: root.selected ? Colors.m3OnSecondaryContainer : Colors.m3OnSurface
    readonly property color subColor: root.selected ? Colors.m3OnSecondaryContainer : Colors.m3OnSurfaceVariant

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 12

        // アイコン (アプリ) / 計算 / クリップボード (画像はサムネイル)
        Item {
            width: 40
            height: parent.height

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 32
                height: 32
                sourceSize.width: 32
                sourceSize.height: 32
                visible: root.modelData.kind === "app" && source !== ""
                source: root.modelData.kind === "app" ? Quickshell.iconPath(root.modelData.iconName, true) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Icon {
                anchors.centerIn: parent
                visible: root.modelData.kind === "app" && !appIcon.visible
                name: "apps"
                size: 28
                color: root.subColor
            }
            Icon {
                anchors.centerIn: parent
                visible: root.modelData.kind === "calc"
                name: "calculate"
                size: 28
                color: Colors.m3Primary
            }
            Icon {
                anchors.centerIn: parent
                visible: root.modelData.kind === "clip" && !(root.isImage && thumb.status === Image.Ready)
                name: root.isImage ? "image" : "content_paste"
                size: 24
                color: root.subColor
            }
            Image {
                id: thumb
                anchors.centerIn: parent
                width: 40
                height: 40
                sourceSize.width: 80
                sourceSize.height: 80
                visible: root.isImage && status === Image.Ready
                source: root.isImage && Clipboard.imageReady(root.modelData.payload.id) ? Clipboard.imageUrl(root.modelData.payload.id) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: parent.width - 40 - 24 - 12 * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Label {
                width: parent.width
                text: root.modelData.title
                role: root.modelData.kind === "calc" ? Typography.titleMedium : Typography.bodyLarge
                color: root.titleColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.modelData.subtitle || ""
                role: Typography.bodySmall
                color: root.subColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "keyboard_return"
            size: 20
            color: root.subColor
            opacity: root.selected ? 1 : 0
        }
    }

    Component.onCompleted: {
        if (isImage)
            Clipboard.ensureImage(modelData.payload.id);
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: m => ripple.press(m.x, m.y)
        onReleased: ripple.release()
        onCanceled: ripple.release()
        onPositionChanged: m => {
            const p = root.mapToItem(null, m.x, m.y);
            root.moved(p.x, p.y);
        }
        onClicked: root.activated()
    }
}
