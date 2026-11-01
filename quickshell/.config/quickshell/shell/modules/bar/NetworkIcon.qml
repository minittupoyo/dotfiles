import QtQuick
import "../../components"
import "../../services"
import "../../tokens"

// 接続状態のアイコン (有線 / 無線 / 未接続)。
Item {
    implicitWidth: 32
    implicitHeight: 40

    Icon {
        anchors.centerIn: parent
        name: !Network.connected ? "wifi_off" : Network.kind === "wireless" ? "wifi" : "lan"
        size: 24
        color: Network.connected ? Colors.m3OnSurfaceVariant : Colors.m3Error
    }
}
