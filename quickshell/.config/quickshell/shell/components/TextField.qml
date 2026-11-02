import QtQuick
import "../tokens"

// 1 行のテキスト入力。Enter で accepted(text) を出す。フォーカス中は枠が primary になる。
//   TextField { text: path; placeholder: "~/Pictures"; onAccepted: t => apply(t) }
Item {
    id: root

    property alias text: input.text
    property string placeholder
    property bool invalid: false

    signal accepted(string text)

    implicitWidth: 320
    implicitHeight: 44

    activeFocusOnTab: true
    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: Shapes.small
        color: Colors.m3SurfaceContainerHighest
        border.width: input.activeFocus ? 2 : 1
        border.color: root.invalid ? Colors.m3Error : input.activeFocus ? Colors.m3Primary : Colors.m3Outline
    }

    StateLayer {
        anchors.fill: parent
        radius: Shapes.small
        hovered: hover.hovered
        focused: false
    }
    HoverHandler {
        id: hover
        cursorShape: Qt.IBeamCursor
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Colors.m3OnSurface
        selectionColor: Colors.m3PrimaryContainer
        selectedTextColor: Colors.m3OnPrimaryContainer
        font.family: Typography.family
        font.pixelSize: Typography.bodyLarge.size
        selectByMouse: true
        onAccepted: root.accepted(text)
        Keys.onEscapePressed: event => event.accepted = false

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" && !input.preeditText
            text: root.placeholder
            role: Typography.bodyLarge
            color: Colors.m3OnSurfaceVariant
        }
    }
}
