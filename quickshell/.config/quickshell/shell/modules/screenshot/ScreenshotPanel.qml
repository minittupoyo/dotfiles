import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// スクリーンショットのメニューの中身: 撮り方 (範囲 / ウィンドウ / 画面 / 全画面) と、保存・ディレイの設定。
// 操作: 1〜4 で撮り方を選ぶ、Esc で閉じる。
Item {
    id: root

    signal closeRequested()
    // 選んだら閉じて、メニューが消えてから撮る (スクリプトが待つ)
    signal chosen(string mode)

    implicitHeight: col.implicitHeight
    focus: true

    readonly property var modes: [
        { mode: "region", icon: "crop_free", label: "範囲" },
        { mode: "window", icon: "web_asset", label: "ウィンドウ" },
        { mode: "screen", icon: "desktop_windows", label: "画面" },
        { mode: "all", icon: "select_all", label: "全画面" }
    ]

    function open() {
        forceActiveFocus();
    }

    function choose(mode) {
        root.chosen(mode);
        root.closeRequested();
    }

    Keys.onEscapePressed: closeRequested()
    Keys.onPressed: event => {
        const i = event.key - Qt.Key_1;
        if (i >= 0 && i < root.modes.length) {
            root.choose(root.modes[i].mode);
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        // 撮り方
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.modes

                Button {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    size: "m"
                    variant: "filled"
                    icon: modelData.icon
                    text: modelData.label
                    onClicked: root.choose(modelData.mode)
                }
            }
        }

        // 設定
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                size: "s"
                variant: "tonal"
                icon: "save"
                text: "ファイルに保存"
                checkable: true
                autoToggle: false
                checked: Screenshot.saveToFile
                onClicked: Screenshot.setSaveToFile(!Screenshot.saveToFile)
            }

            Item { Layout.fillWidth: true }

            Icon {
                name: "timer"
                size: 20
                color: Colors.m3OnSurfaceVariant
            }
            Repeater {
                model: Screenshot.delays

                Button {
                    required property int modelData
                    size: "s"
                    variant: "tonal"
                    text: modelData === 0 ? "なし" : modelData + "秒"
                    checkable: true
                    autoToggle: false
                    checked: Screenshot.delay === modelData
                    onClicked: Screenshot.setDelay(modelData)
                }
            }
        }
    }
}
