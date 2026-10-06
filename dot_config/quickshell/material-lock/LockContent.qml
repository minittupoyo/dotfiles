import Quickshell
import QtQuick
import QtQuick.Layouts
import "file:///home/mimi/.config/quickshell/material-shell"

Rectangle {
    id: content
    property string user: ""
    property string message: ""
    property bool busy: false
    property bool responseVisible: false
    signal submitted(string response)
    function clear() { input.text = ""; }
    color: Theme.surface
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(Theme.launcherWidth - Theme.panelPadding * 2, parent.width - Theme.panelScreenMargin * 2)
        spacing: Theme.space24
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDateTime(clock.date, "HH:mm"); color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize * 3; font.weight: Font.Medium }
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDateTime(clock.date, "M月d日 dddd"); color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        Text { Layout.alignment: Qt.AlignHCenter; text: content.user; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.inputHeight
            radius: Theme.shapeMedium
            color: Theme.inputBackground
            Text { anchors.fill: parent; anchors.margins: Theme.space16; verticalAlignment: Text.AlignVCenter; visible: input.text === "" && !input.inputMethodComposing; text: "パスワード"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.inputSize }
            TextInput {
                id: input
                objectName: "lockInput"
                anchors.fill: parent
                anchors.margins: Theme.space12
                enabled: !content.busy
                focus: true
                echoMode: content.responseVisible ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | (content.responseVisible ? 0 : Qt.ImhHiddenText)
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.inputSize
                verticalAlignment: TextInput.AlignVCenter
                selectionColor: Theme.secondaryContainer
                selectedTextColor: Theme.secondaryContainerText
                clip: true
                Accessible.name: "パスワード"
                onAccepted: if (!input.inputMethodComposing && text.length && !content.busy) content.submitted(text)
                onEnabledChanged: if (enabled) Qt.callLater(() => input.forceActiveFocus())
            }
        }
        Text { Layout.fillWidth: true; visible: text !== ""; text: content.message; textFormat: Text.PlainText; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        ShellButton { Layout.alignment: Qt.AlignHCenter; text: content.busy ? "確認中…" : "ロックを解除"; icon: "lock"; emphasized: true; enabled: !content.busy && input.text.length > 0; onClicked: content.submitted(input.text) }
    }
    // The clock is per surface; it has no lock or authentication state.
    SystemClock { id: clock; precision: SystemClock.Minutes }
}
