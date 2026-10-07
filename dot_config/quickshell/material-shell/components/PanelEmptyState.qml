import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: state
    property string icon: ""
    property string title: ""
    property string description: ""
    property string titleObjectName: ""
    property string descriptionObjectName: ""
    implicitHeight: content.implicitHeight + Theme.space32 * 2
    ColumnLayout {
        id: content
        anchors.centerIn: parent
        width: Math.min(state.width, Theme.emptyStateContentWidth)
        spacing: Theme.space12
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: Theme.emptyStateContainerSize; height: width; radius: width / 2
            color: Theme.secondaryContainer
            MaterialIcon { anchors.centerIn: parent; name: state.icon; size: Theme.emptyStateIconSize; color: Theme.secondaryContainerText }
        }
        Text { objectName: state.titleObjectName; Layout.fillWidth: true; text: state.title; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleMediumSize; font.weight: Font.Medium; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
        Text { objectName: state.descriptionObjectName; visible: state.description !== ""; Layout.fillWidth: true; text: state.description; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
    }
}
