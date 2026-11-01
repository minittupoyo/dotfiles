import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../tokens"

// バーの「島」: 丸い面 (surface container) に子要素を縦中央で横に並べる。
Item {
    id: root

    default property alias content: row.data
    property real padding: 8

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: 48
    width: implicitWidth
    height: implicitHeight

    Surface {
        anchors.fill: parent
        radius: Shapes.full
        color: Elevation.color(2)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
    }
}
