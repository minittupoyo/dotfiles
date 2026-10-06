import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: icon
    property string name: ""
    property int size: Theme.iconSize
    property color color: Theme.surfaceVariantText
    width: size
    height: size
    Accessible.ignored: true
    Image {
        id: image
        anchors.fill: parent
        source: icon.name ? Qt.resolvedUrl("../material-symbols/" + icon.name + ".svg") : ""
        sourceSize.width: icon.size
        sourceSize.height: icon.size
        visible: false
    }
    MultiEffect {
        anchors.fill: image
        source: image
        colorization: 1
        colorizationColor: icon.color
    }
}
