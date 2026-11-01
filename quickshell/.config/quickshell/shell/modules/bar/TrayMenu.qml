import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../tokens"

// トレイ項目のコンテキストメニュー (M3 スタイル)。
// SystemTrayItem.display() はネイティブのメニューで、UseQApplication が必要かつ見た目も Qt 標準になるので、
// QsMenuOpener + PopupWindow で自前に描く。サブメニューは同じウィンドウ内で階層を辿る。
PopupWindow {
    id: popup

    required property var anchorItem    // 位置の基準 (トレイのボタン)
    required property var menuHandle    // SystemTrayItem.menu

    // 開いているサブメニューの階層 (QsMenuEntry)。空ならトップ
    property var stack: []
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : menuHandle

    // 影が切れないよう、面の周りに透明な余白を持つ
    readonly property real margin: 12

    function toggle() {
        visible = !visible;
    }

    onVisibleChanged: if (!visible) stack = []

    anchor.item: anchorItem
    // 面の右端をボタンの右端に揃え、ボタンの 8px 下から下向きに出す (画面右端でも収まる)
    anchor.rect: Qt.rect(anchorItem.width + margin, anchorItem.height + 8 - margin, 1, 1)
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide

    grabFocus: true
    color: "transparent"
    implicitWidth: Math.max(220, col.implicitWidth + 16) + 2 * margin
    implicitHeight: col.implicitHeight + 16 + 2 * margin

    QsMenuOpener {
        id: opener
        menu: popup.current
    }

    Surface {
        x: popup.margin
        y: popup.margin
        width: popup.width - 2 * popup.margin
        height: popup.height - 2 * popup.margin
        level: 3
        radius: Shapes.large

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            // サブメニューの中にいるときは「戻る」
            BaseButton {
                id: backBtn
                visible: popup.stack.length > 0
                variant: "standard"
                implicitHeight: 40
                Layout.fillWidth: true
                onClicked: popup.stack = popup.stack.slice(0, -1)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 12
                    Icon { name: "arrow_back"; size: 20; color: backBtn.contentColor }
                    Label { text: "戻る"; role: Typography.labelLarge; color: Colors.m3OnSurface; Layout.fillWidth: true }
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: row

                    required property var modelData    // QsMenuEntry

                    Layout.fillWidth: true
                    implicitHeight: modelData.isSeparator ? 9 : 40
                    // 項目の内容に合わせてメニューの幅が決まるようにする (左右余白 12 + 12)
                    implicitWidth: modelData.isSeparator ? 0 : line.implicitWidth + 24

                    // 区切り線
                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        height: 1
                        color: Colors.m3OutlineVariant
                    }

                    BaseButton {
                        id: btn
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        variant: "standard"
                        enabled: row.modelData.enabled
                        onClicked: {
                            if (row.modelData.hasChildren) {
                                popup.stack = popup.stack.concat([row.modelData]);
                            } else {
                                row.modelData.triggered();
                                popup.visible = false;
                            }
                        }

                        RowLayout {
                            id: line
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // チェック状態 / アイコン (どちらも無ければ左に余白だけ)
                            Item {
                                implicitWidth: 20
                                implicitHeight: 20
                                visible: row.modelData.icon !== "" || row.modelData.checkState === Qt.Checked
                                Icon {
                                    anchors.centerIn: parent
                                    visible: row.modelData.checkState === Qt.Checked
                                    name: "check"
                                    size: 20
                                    color: btn.contentColor
                                }
                                Image {
                                    anchors.centerIn: parent
                                    visible: row.modelData.icon !== "" && row.modelData.checkState !== Qt.Checked
                                    width: 20
                                    height: 20
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    source: row.modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }
                            Label {
                                text: row.modelData.text.replace(/_/g, "")    // DBusMenu のニーモニック (_X) を除く
                                role: Typography.labelLarge
                                color: btn.enabled ? Colors.m3OnSurface : btn.contentColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Icon {
                                visible: row.modelData.hasChildren
                                name: "chevron_right"
                                size: 20
                                color: btn.contentColor
                            }
                        }
                    }
                }
            }
        }
    }
}
