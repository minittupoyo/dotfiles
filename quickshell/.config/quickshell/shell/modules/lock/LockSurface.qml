import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 1 つのモニターのロック画面。壁紙をぼかして敷き、中央に時計とパスワード欄を置く。
// キー入力は共有の LockContext に流す (どのモニターが入力フォーカスを持っても同じ状態になる)。
Rectangle {
    id: root

    required property LockContext context

    color: Colors.m3Surface

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ---- 背景 (壁紙をぼかす。ぼかすので縮小して読む) ----
    Image {
        id: wall
        anchors.fill: parent
        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(1280, 720)
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colors.m3Scrim, 0.45)
    }

    // ---- 入力 ----
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: event => {
            const ctx = root.context;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                ctx.submit();
            } else if (event.key === Qt.Key_Backspace) {
                ctx.backspace();
            } else if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                ctx.clear();
            } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && !(event.modifiers & Qt.ControlModifier)) {
                ctx.type(event.text);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    // ---- 時計とカード ----
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                role: Typography.displayLarge
                color: Colors.m3OnSurface
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.locale("ja_JP").toString(clock.date, "M月d日(dddd)")
                role: Typography.titleLarge
                color: Colors.m3OnSurfaceVariant
            }
        }

        Surface {
            id: card
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            Layout.preferredHeight: 156
            level: 2
            radius: Shapes.extraLarge

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Icon {
                        name: "account_circle"
                        size: 24
                        color: Colors.m3OnSurfaceVariant
                    }
                    Label {
                        text: Quickshell.env("USER")
                        role: Typography.titleMedium
                        color: Colors.m3OnSurfaceVariant
                    }
                }

                // パスワード欄 (入力済みの文字数だけ点を出す)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Shapes.full
                    color: Colors.m3SurfaceContainerHighest
                    border.width: 2
                    border.color: root.context.error !== "" ? Colors.m3Error : (keys.activeFocus ? Colors.m3Primary : "transparent")

                    Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        size: 24
                        color: Colors.m3OnSurfaceVariant
                    }

                    Row {
                        id: dots
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: Math.min(root.context.password.length, 16)
                            Rectangle {
                                width: 10
                                height: 10
                                radius: Shapes.full
                                color: Colors.m3OnSurface
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: root.context.password === ""
                        text: root.context.busy ? "確認中…" : "パスワード"
                        role: Typography.bodyLarge
                        color: Colors.m3OnSurfaceVariant
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.context.error
                    role: Typography.bodyMedium
                    color: Colors.m3Error
                }
            }
        }
    }
}
