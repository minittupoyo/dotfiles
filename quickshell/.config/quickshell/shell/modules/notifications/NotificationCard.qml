import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 通知のポップアップ 1 枚。出入りはスプリング (右からスライド + フェード)、退場時は高さも畳む。
Item {
    id: root

    required property var modelData    // NotificationEntry
    readonly property var entry: modelData

    width: 380
    // 退場中は高さを畳んで、下のカードが滑らかに詰まるようにする
    height: Math.max(0, card.implicitHeight * collapse.value)
    clip: collapse.value < 0.999

    SpringValue {
        id: enter
        target: root.entry.closing ? 0 : 1
        value: 0
        spec: Motion.spatialDefault
        epsilon: 0.001
    }
    SpringValue {
        id: fade
        target: root.entry.closing ? 0 : 1
        value: 0
        spec: Motion.effectsDefault
        epsilon: 0.001
    }
    SpringValue {
        id: collapse
        target: root.entry.closing ? 0 : 1
        value: 1
        spec: Motion.spatialDefault
        epsilon: 0.001
    }

    // 退場アニメーションが終わったら取り除く (イベントではなく状態で判定する: 取りこぼさない)
    readonly property bool gone: entry.closing && collapse.value < 0.01 && fade.value < 0.01
    onGoneChanged: if (gone) Notifications.removePopup(entry)

    // アイコン: 絶対パス / URL はそのまま、名前ならテーマから
    function iconSource(name) {
        if (!name)
            return "";
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    Surface {
        id: card
        x: (1 - enter.value) * 48
        width: root.width
        implicitHeight: content.implicitHeight + 32
        height: implicitHeight
        opacity: Math.max(0, Math.min(1, fade.value))
        level: 3
        radius: Shapes.extraLarge
        color: root.entry.critical ? Colors.m3ErrorContainer : Elevation.color(3)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.entry.hovered = true
            onExited: root.entry.hovered = false
            onClicked: root.entry.dismiss()
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // 画像 (メッセージアプリの顔写真など) があれば優先、なければアプリのアイコン
                Item {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignTop

                    // 画像は角丸でクリップする
                    Rectangle {
                        id: imgMask
                        anchors.fill: parent
                        radius: Shapes.medium
                        visible: false
                        layer.enabled: true
                    }
                    Image {
                        id: img
                        anchors.fill: parent
                        visible: source !== "" && status === Image.Ready
                        source: root.entry.image
                        sourceSize.width: 88
                        sourceSize.height: 88
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: imgMask
                        }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        visible: !img.visible && source !== ""
                        source: root.iconSource(root.entry.appIcon)
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: !img.visible && root.iconSource(root.entry.appIcon) === ""
                        name: "notifications"
                        size: 28
                        color: root.entry.critical ? Colors.m3OnErrorContainer : Colors.m3OnSurfaceVariant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: root.entry.appName
                        role: Typography.labelMedium
                        color: root.entry.critical ? Colors.m3OnErrorContainer : Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.entry.summary
                        role: Typography.titleSmall
                        color: root.entry.critical ? Colors.m3OnErrorContainer : Colors.m3OnSurface
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    // 本文。通知のマークアップ (<b> <i> <u> <a>) は StyledText で描く (スクリプトは実行されない)。
                    // リンクは開かない (onLinkActivated を使わない)
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.entry.body
                        textFormat: Text.StyledText
                        role: Typography.bodyMedium
                        color: root.entry.critical ? Colors.m3OnErrorContainer : Colors.m3OnSurfaceVariant
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                }
            }

            // アクションボタン (最大 3 つ。"default" は本体クリックに相当するので出さない)
            Flow {
                Layout.fillWidth: true
                spacing: 8
                visible: repeater.count > 0

                Repeater {
                    id: repeater
                    model: root.entry.actions.filter(a => a.identifier !== "default").slice(0, 3)

                    Button {
                        required property var modelData
                        size: "s"
                        variant: "tonal"
                        text: modelData.text
                        onClicked: {
                            // invoke すると通知が閉じてこのボタン自体が作り直されるので、先に必要な参照を取っておく
                            const e = root.entry;
                            const id = modelData.identifier;
                            e.closing = true;
                            e.invoke(id);
                        }
                    }
                }
            }
        }
    }
}
