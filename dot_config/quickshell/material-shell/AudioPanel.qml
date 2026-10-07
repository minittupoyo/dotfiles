import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

PanelFrame {
    id: panel
    attachedToBar: true
    readonly property var devices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    readonly property var output: Pipewire.defaultAudioSink
    readonly property var input: Pipewire.defaultAudioSource
    PwObjectTracker { objects: panel.visible ? panel.devices : [] }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "オーディオ"; icon: "volume_up"; subtitle: "音声デバイスと音量を調整"; onDismissed: panel.dismissed() }
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentHeight: sections.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: sections
                width: parent.width
                spacing: Theme.space24
                Repeater {
                    model: [true, false]
                    delegate: PanelSection {
                        id: section
                        title: modelData ? "出力" : "マイク入力"
                        icon: modelData ? "volume_up" : "volume_mute"
                        required property bool modelData
                        readonly property var node: modelData ? panel.output : panel.input
                        Layout.fillWidth: true
                        spacing: Theme.space8
                        Text { Layout.fillWidth: true; text: section.node ? (section.node.description || section.node.name) : "利用できるデバイスがありません"; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        RowLayout {
                            Layout.fillWidth: true
                            ShellButton { text: section.node?.audio?.muted ? "ミュート解除" : "ミュート"; icon: section.node?.audio?.muted ? "volume_off" : "volume_up"; emphasized: section.node?.audio?.muted ?? false; enabled: !!section.node?.ready; onClicked: section.node.audio.muted = !section.node.audio.muted }
                            Item { Layout.fillWidth: true }
                            Text { text: section.node?.audio ? Math.round(section.node.audio.volume * 100) + "%" : "—"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        }
                        VolumeSlider { Layout.fillWidth: true; enabled: !!section.node?.ready; value: section.node?.audio?.volume ?? 0; Accessible.name: section.modelData ? "出力音量" : "マイク音量"; onAdjusted: value => section.node.audio.volume = value }
                        Repeater {
                            model: panel.devices.filter(node => node.isSink === section.modelData)
                            delegate: Rectangle {
                                id: device
                                required property var modelData
                                readonly property bool selected: modelData === section.node
                                Layout.fillWidth: true
                                implicitHeight: Theme.listRowHeight
                                radius: Theme.shapeMedium
                                color: selected ? Theme.secondaryContainer : "transparent"
                                activeFocusOnTab: true
                                border.width: activeFocus ? 1 : 0; border.color: Theme.primary
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.description || modelData.name
                                function choose() { if (section.modelData) Pipewire.preferredDefaultAudioSink = modelData; else Pipewire.preferredDefaultAudioSource = modelData; }
                                Keys.onReturnPressed: choose()
                                Keys.onSpacePressed: choose()
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: Theme.space12; spacing: Theme.space12
                                    Text { Layout.fillWidth: true; text: device.modelData.description || device.modelData.name; textFormat: Text.PlainText; elide: Text.ElideRight; color: device.selected ? Theme.secondaryContainerText : Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                                    MaterialIcon { name: "check"; visible: device.selected; color: Theme.secondaryContainerText }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onPressed: device.focus = false; onClicked: device.choose() }
                            }
                        }
                    }
                }
            }
        }
    }
}
