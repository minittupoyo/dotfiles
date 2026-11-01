import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../tokens"

// クイック設定の中身: 上にタブ (概要 / Bluetooth / サウンド / 通知)、下にそのタブの内容。
// 高さは選んだタブの中身に追従する (OverlayWindow が implicitHeight を見る)。
Item {
    id: root

    signal closeRequested()

    readonly property var tabNames: ["概要", "Bluetooth", "サウンド", "通知"]
    property int startTab: 0    // 開いたときのタブ
    property int tab: 0

    readonly property var pages: [overview, bluetooth, sound, notifications]

    implicitHeight: col.implicitHeight
    focus: true

    function open() {
        tab = startTab;
        overview.reset();
        forceActiveFocus();
    }

    Keys.onEscapePressed: closeRequested()

    // タブを替えると、中身が不透明度のスプリングで現れる
    onTabChanged: {
        fade.snap(0);
        fade.target = 1;
    }
    SpringValue {
        id: fade
        value: 1
        target: 1
        spec: Motion.effectsDefault
        epsilon: 0.002
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.tabNames

                Button {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    size: "s"
                    variant: "tonal"
                    text: modelData
                    checkable: true
                    autoToggle: false
                    checked: root.tab === index
                    onClicked: root.tab = index
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: root.pages[root.tab].implicitHeight

            OverviewTab {
                id: overview
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.tab === 0
                opacity: fade.value
                onCloseRequested: root.closeRequested()
                onGotoTab: i => root.tab = i
            }
            BluetoothTab {
                id: bluetooth
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.tab === 1
                opacity: fade.value
            }
            SoundTab {
                id: sound
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.tab === 2
                opacity: fade.value
            }
            NotificationsTab {
                id: notifications
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.tab === 3
                opacity: fade.value
            }
        }
    }
}
