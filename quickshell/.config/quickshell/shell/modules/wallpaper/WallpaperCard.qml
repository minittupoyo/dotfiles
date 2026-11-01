import QtQuick
import QtQuick.Effects
import "../../components"
import "../../services"
import "../../tokens"

// 壁紙のカード。選択中のカードだけ、拡大と角丸のモーフィング (スプリング)。
Item {
    id: root

    // FolderListModel のロール (delegate に required property として渡される)
    required property int index
    required property string fileName
    required property string filePath
    required property var fileModified

    property bool selected: false
    property bool isCurrent: false    // いま適用されている壁紙

    signal clicked()
    signal moved()                    // ポインタが動いた (hover による選択用)

    // 拡大したカードが隣に隠れないよう、選択中は前面に出す
    z: selected ? 1 : 0

    readonly property bool thumbReady: Wallpaper.thumbReady(fileName, fileModified)

    SpringValue {
        id: grow
        target: root.selected ? 1.06 : 1.0
        spec: Motion.spatialDefault
        epsilon: 0.0005
    }
    SpringValue {
        id: corner
        target: root.selected ? Shapes.extraLarge : Shapes.large
        spec: Motion.spatialDefault
        epsilon: 0.05
    }

    Item {
        id: card
        anchors.fill: parent
        anchors.margins: 8
        scale: grow.value

        // 角丸でクリップするためのマスク
        Rectangle {
            id: mask
            anchors.fill: parent
            radius: Math.max(0, corner.value)
            visible: false
            layer.enabled: true
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
            }

            // サムネイルが出来るまでのプレースホルダー
            Rectangle {
                anchors.fill: parent
                color: Colors.m3SurfaceContainerHighest
            }
            Icon {
                anchors.centerIn: parent
                name: "image"
                size: 32
                color: Colors.m3OutlineVariant
                visible: img.status !== Image.Ready
            }

            Image {
                id: img
                anchors.fill: parent
                source: root.thumbReady ? Wallpaper.thumbUrl(root.fileName, root.fileModified) : ""
                sourceSize: Qt.size(root.width * 2, root.height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: fadeIn.value

                SpringValue {
                    id: fadeIn
                    target: img.status === Image.Ready ? 1 : 0
                    spec: Motion.effectsDefault
                    epsilon: 0.002
                }
            }

            // 選択中はファイル名を下に重ねる
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 48
                opacity: root.selected ? 1 : 0
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(Colors.m3Scrim.r, Colors.m3Scrim.g, Colors.m3Scrim.b, 0.7) }
                }
                Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    text: root.fileName
                    role: Typography.labelMedium
                    color: Colors.m3OnSurface
                    elide: Text.ElideMiddle
                }
            }
        }

        // 現在の壁紙の印 (マスクの外に出して切れないようにする)
        Rectangle {
            visible: root.isCurrent
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: 28
            height: 28
            radius: Shapes.full
            color: Colors.m3Primary
            Icon {
                anchors.centerIn: parent
                name: "check"
                size: 20
                weight: 600
                color: Colors.m3OnPrimary
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.moved()
        onClicked: root.clicked()
    }
}
