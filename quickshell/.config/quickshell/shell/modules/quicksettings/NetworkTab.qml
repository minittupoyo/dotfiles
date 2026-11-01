import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 「ネットワーク」タブ: 各インタフェースの接続状態・IP・ゲートウェイ・リンク速度・送受信の速さ。
// 開いている間だけ Network が 2 秒ごとに詳細を更新する。
Item {
    id: root

    // 表示中か (QuickSettingsPanel が渡す)
    property bool active: false

    implicitHeight: col.implicitHeight

    function rate(bps) {
        const bits = bps * 8;
        if (bits >= 1e9)
            return (bits / 1e9).toFixed(1) + " Gbps";
        if (bits >= 1e6)
            return (bits / 1e6).toFixed(1) + " Mbps";
        if (bits >= 1e3)
            return Math.round(bits / 1e3) + " kbps";
        return Math.round(bits) + " bps";
    }
    function size(b) {
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) {
            b /= 1024;
            i++;
        }
        return (i === 0 ? b : b.toFixed(1)) + " " + u[i];
    }

    Binding {
        target: Network
        property: "detailsActive"
        value: root.active
    }

    component Row2: RowLayout {
        id: r
        property string label
        property string value
        Layout.fillWidth: true
        visible: value !== ""
        Label {
            text: r.label
            role: Typography.labelMedium
            color: Colors.m3OnSurfaceVariant
        }
        Item { Layout.fillWidth: true }
        Label {
            text: r.value
            role: Typography.labelLarge
            color: Colors.m3OnSurface
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        Repeater {
            model: ScriptModel {
                values: Network.links.filter(l => l.up || !l.virtual)
            }

            Card {
                id: card
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: inner.implicitHeight + 32

                ColumnLayout {
                    id: inner
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Icon {
                            name: card.modelData.virtual ? "vpn_lock" : card.modelData.kind === "wireless" ? "wifi" : "lan"
                            size: 24
                            fill: card.modelData.up ? 1 : 0
                            color: card.modelData.up ? Colors.m3Primary : Colors.m3Outline
                        }
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            role: Typography.titleSmall
                            color: Colors.m3OnSurface
                        }
                        Label {
                            text: card.modelData.up ? "接続中" : "切断"
                            role: Typography.labelLarge
                            color: card.modelData.up ? Colors.m3Primary : Colors.m3Outline
                        }
                    }

                    Row2 { label: "IPv4"; value: card.modelData.ip }
                    Row2 { label: "ゲートウェイ"; value: card.modelData.gateway }
                    Row2 { label: "MAC"; value: card.modelData.mac }
                    Row2 { label: "リンク速度"; value: card.modelData.speed > 0 ? card.modelData.speed + " Mbps" : "" }
                    Row2 {
                        label: "受信"
                        visible: card.modelData.up
                        value: root.rate(card.modelData.rxRate) + "  (" + root.size(card.modelData.rxTotal) + ")"
                    }
                    Row2 {
                        label: "送信"
                        visible: card.modelData.up
                        value: root.rate(card.modelData.txRate) + "  (" + root.size(card.modelData.txTotal) + ")"
                    }
                }
            }
        }

        Label {
            visible: Network.links.length === 0
            Layout.leftMargin: 12
            text: "ネットワーク情報を取得中…"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
