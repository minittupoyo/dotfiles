import QtQuick
import QtQuick.Shapes
import ".."

Item {
    id: artwork
    property alias source: image.source
    property alias sourceSize: image.sourceSize
    property alias status: image.status
    property alias cache: image.cache
    property alias fillMode: image.fillMode
    property real radius: Theme.shapeMedium
    property color backgroundColor: Theme.surfaceContainerHigh
    property string fallbackIcon: ""
    Rectangle { anchors.fill: parent; radius: artwork.radius; color: artwork.backgroundColor }
    Image {
        id: image
        anchors.fill: parent
        asynchronous: true; autoTransform: true; smooth: true; mipmap: true
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }
    // Cover the corners using an antialiased inverse rounded path. This keeps
    // images visible without an offscreen texture/mask for every list delegate.
    Shape {
        anchors.fill: parent
        antialiasing: true
        visible: image.status === Image.Ready
        ShapePath {
            fillRule: ShapePath.OddEvenFill
            fillColor: artwork.backgroundColor; strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: artwork.width; y: 0 }
            PathLine { x: artwork.width; y: artwork.height }
            PathLine { x: 0; y: artwork.height }
            PathLine { x: 0; y: 0 }
            PathMove { x: artwork.radius; y: 0 }
            PathLine { x: artwork.width - artwork.radius; y: 0 }
            PathArc { x: artwork.width; y: artwork.radius; radiusX: artwork.radius; radiusY: artwork.radius }
            PathLine { x: artwork.width; y: artwork.height - artwork.radius }
            PathArc { x: artwork.width - artwork.radius; y: artwork.height; radiusX: artwork.radius; radiusY: artwork.radius }
            PathLine { x: artwork.radius; y: artwork.height }
            PathArc { x: 0; y: artwork.height - artwork.radius; radiusX: artwork.radius; radiusY: artwork.radius }
            PathLine { x: 0; y: artwork.radius }
            PathArc { x: artwork.radius; y: 0; radiusX: artwork.radius; radiusY: artwork.radius }
        }
    }
    MaterialIcon { anchors.centerIn: parent; visible: image.status !== Image.Ready && artwork.fallbackIcon !== ""; name: artwork.fallbackIcon; size: Theme.emptyStateIconSize }
}
