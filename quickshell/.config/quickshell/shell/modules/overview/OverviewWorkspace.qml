import QtQuick
import "../../components"
import "../../tokens"

// オーバービューの 1 枚のカード (1 つのワークスペース)。中のウィンドウは、パネル側の別レイヤーが重ねて描く
// (ドラッグでカードの外へ出せるように)。選択中は色が付いて、角が大きくなる (形状モーフィング)。
Item {
    id: card

    required property var ws           // HyprlandWorkspace
    property bool selected: false
    property bool dropTarget: false    // ウィンドウをドラッグして、ここに乗っている
    property real screenW: 300
    property real screenH: 170
    property int windowCount: 0

    signal clicked()

    width: screenW + 16
    height: screenH + 16 + 28

    SpringValue {
        id: sel
        target: card.selected ? 1 : 0
        spec: Motion.spatialFast
        epsilon: 0.002
    }

    Rectangle {
        anchors.fill: parent
        radius: Shapes.large + 6 * sel.value
        color: card.dropTarget ? Colors.m3PrimaryContainer
             : card.selected ? Colors.m3SecondaryContainer : Colors.m3SurfaceContainerHigh
        border.width: card.dropTarget ? 2 : 0
        border.color: Colors.m3Primary
    }
    StateLayer {
        anchors.fill: parent
        radius: Shapes.large
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    // 画面の枠 (中にウィンドウが重なる)
    Rectangle {
        x: 8
        y: 8
        width: card.screenW
        height: card.screenH
        radius: Shapes.medium + 4 * sel.value
        color: Colors.m3SurfaceContainerLowest

        Label {
            anchors.centerIn: parent
            visible: card.windowCount === 0
            text: card.ws.id
            role: Typography.headlineLarge
            color: Colors.m3OutlineVariant
        }
    }

    Label {
        x: 12
        y: card.screenH + 16
        width: card.width - 24
        height: 28
        verticalAlignment: Text.AlignVCenter
        text: card.ws.id + (card.windowCount > 0 ? "  ·  " + card.windowCount : "")
        role: Typography.labelLarge
        color: card.selected ? Colors.m3OnSecondaryContainer : Colors.m3OnSurfaceVariant
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
