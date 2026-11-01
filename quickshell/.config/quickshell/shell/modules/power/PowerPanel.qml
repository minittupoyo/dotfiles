import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// 電源メニューの中身: ロック / スリープ / ログアウト / 再起動 / シャットダウン。
// 操作: ← → か 1〜5 で選ぶ、Enter で決定、Esc で閉じる (確認中は取り消し)。
// ログアウト・再起動・シャットダウンは、同じパネルの中で確認する (初期位置はキャンセル)。
Item {
    id: root

    signal closeRequested()

    implicitHeight: col.implicitHeight
    focus: true

    readonly property var items: [
        { action: "lock", icon: "lock", label: "ロック", confirm: false },
        { action: "suspend", icon: "bedtime", label: "スリープ", confirm: false },
        { action: "logout", icon: "logout", label: "ログアウト", confirm: true },
        { action: "reboot", icon: "restart_alt", label: "再起動", confirm: true },
        { action: "poweroff", icon: "power_settings_new", label: "シャットダウン", confirm: true }
    ]

    property int current: 0          // 選択中の項目
    property string confirming: ""   // 確認中の項目 (action)。"" なら通常表示
    property int confirmIndex: 0     // 確認中の選択: 0 = キャンセル / 1 = 実行

    readonly property var confirmItem: {
        for (const it of items)
            if (it.action === confirming)
                return it;
        return null;
    }

    function open() {
        current = 0;
        confirming = "";
        forceActiveFocus();
    }

    function run(action) {
        closeRequested();
        if (action === "lock")
            Lock.lock();
        else
            Power.run(action);
    }

    function choose(i) {
        const it = items[i];
        current = i;
        if (it.confirm) {
            confirming = it.action;
            confirmIndex = 0;
        } else {
            run(it.action);
        }
    }

    function cancel() {
        confirming = "";
    }

    Keys.onEscapePressed: confirming !== "" ? cancel() : closeRequested()
    Keys.onLeftPressed: {
        if (confirming !== "")
            confirmIndex = 0;
        else
            current = Math.max(0, current - 1);
    }
    Keys.onRightPressed: {
        if (confirming !== "")
            confirmIndex = 1;
        else
            current = Math.min(items.length - 1, current + 1);
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (confirming === "")
                choose(current);
            else if (confirmIndex === 1)
                run(confirming);
            else
                cancel();
            event.accepted = true;
            return;
        }
        const i = event.key - Qt.Key_1;
        if (confirming === "" && i >= 0 && i < items.length) {
            choose(i);
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 20

        // 項目
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: root.confirming === ""
            spacing: 12

            Repeater {
                model: root.items

                ColumnLayout {
                    required property var modelData
                    required property int index
                    Layout.preferredWidth: 104
                    spacing: 10

                    IconButton {
                        Layout.alignment: Qt.AlignHCenter
                        size: "l"
                        variant: "tonal"
                        checkable: true
                        autoToggle: false
                        checked: root.current === index
                        icon: modelData.icon
                        onClicked: root.choose(index)
                        onHoveredChanged: if (hovered) root.current = index
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        role: Typography.labelLarge
                        color: root.current === index ? Colors.m3OnSurface : Colors.m3OnSurfaceVariant
                    }
                }
            }
        }

        // 確認
        Rectangle {
            Layout.fillWidth: true
            visible: root.confirming !== ""
            implicitHeight: 120
            radius: Shapes.large
            color: Colors.m3ErrorContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.confirmItem ? root.confirmItem.label + "しますか？" : ""
                    role: Typography.titleMedium
                    color: Colors.m3OnErrorContainer
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Button {
                        size: "m"
                        variant: "tonal"
                        checkable: true
                        autoToggle: false
                        checked: root.confirmIndex === 0
                        text: "キャンセル"
                        onClicked: root.cancel()
                        onHoveredChanged: if (hovered) root.confirmIndex = 0
                    }
                    Button {
                        size: "m"
                        variant: "filled"
                        checkable: true
                        autoToggle: false
                        checked: root.confirmIndex === 1
                        icon: root.confirmItem ? root.confirmItem.icon : ""
                        text: root.confirmItem ? root.confirmItem.label : ""
                        onClicked: root.run(root.confirming)
                        onHoveredChanged: if (hovered) root.confirmIndex = 1
                    }
                }
            }
        }
    }
}
