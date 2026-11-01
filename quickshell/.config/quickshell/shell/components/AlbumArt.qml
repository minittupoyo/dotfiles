import QtQuick
import QtQuick.Effects
import "../tokens"

// ジャケット画像 (角丸でクリップ)。画像が無いとき・読み込み中は音符のアイコンを出す。
Item {
    id: root

    property url source
    property real radius: Shapes.medium
    property real iconSize: 28

    implicitWidth: 64
    implicitHeight: 64

    Rectangle {
        id: artMask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Colors.m3SecondaryContainer
    }
    Icon {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        name: "music_note"
        size: root.iconSize
        color: Colors.m3OnSecondaryContainer
    }
    Image {
        id: art
        anchors.fill: parent
        source: root.source
        sourceSize.width: 128
        sourceSize.height: 128
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: artMask
        }
    }
}
