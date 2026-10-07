import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: section
    property string title: ""
    property string description: ""
    property string icon: ""
    property alias spacing: content.spacing
    default property alias sectionContent: content.data
    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + Theme.sectionPadding * 2
    radius: Theme.sectionRadius
    color: Theme.surfaceContainerHigh
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.sectionPadding
        spacing: Theme.space12
        RowLayout {
            visible: section.title !== ""
            Layout.fillWidth: true
            spacing: Theme.space8
            MaterialIcon { visible: section.icon !== ""; name: section.icon; color: Theme.primary }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.space4
                Text { Layout.fillWidth: true; text: section.title; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleMediumSize; font.weight: Font.Medium; wrapMode: Text.Wrap }
                Text { visible: section.description !== ""; Layout.fillWidth: true; text: section.description; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; wrapMode: Text.Wrap }
            }
        }
    }
}
