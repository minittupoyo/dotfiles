import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: field
    property string placeholder: "アプリを検索"
    property alias text: input.text
    property alias composing: input.inputMethodComposing
    signal navigate(int direction)
    signal submit()
    function focusInput() { input.forceActiveFocus(); }
    implicitHeight: Theme.inputHeight
    radius: Theme.inputRadius
    color: Theme.inputBackground
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space16
        anchors.rightMargin: Theme.space16
        spacing: Theme.space12
        MaterialIcon { name: "search" }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0 && !input.inputMethodComposing
                text: field.placeholder
                color: Theme.surfaceVariantText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.inputSize
                Accessible.ignored: true
            }
            TextInput {
                id: input
                objectName: "searchInput"
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.inputSize
                selectByMouse: true
                clip: true
                selectionColor: Theme.secondaryContainer
                selectedTextColor: Theme.secondaryContainerText
                Accessible.name: field.placeholder
                Keys.onPressed: event => {
                    if (input.inputMethodComposing) return;
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        field.navigate(event.key === Qt.Key_Down ? 1 : -1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        field.submit();
                        event.accepted = true;
                    }
                }
            }
        }
        Rectangle {
            objectName: "clearButton"
            visible: input.text !== ""
            implicitWidth: Theme.buttonHeight
            implicitHeight: Theme.buttonHeight
            radius: Theme.buttonHeight / 2
            color: clear.containsMouse ? Theme.hoverState : "transparent"
            MaterialIcon { anchors.centerIn: parent; name: "close" }
            Accessible.role: Accessible.Button
            Accessible.name: "検索をクリア"
            MouseArea {
                id: clear
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { input.text = ""; input.forceActiveFocus(); }
            }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.space12
        anchors.rightMargin: Theme.space12
        height: input.activeFocus ? 2 : 0
        color: Theme.primary
    }
}
