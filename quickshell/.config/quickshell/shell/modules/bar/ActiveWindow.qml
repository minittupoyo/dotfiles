import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../components"
import "../../tokens"

// フォーカス中のウィンドウのタイトル。このモニター上のウィンドウのときだけ表示する。
Label {
    id: root

    required property var monitor    // HyprlandMonitor

    readonly property var toplevel: Hyprland.activeToplevel

    text: toplevel && toplevel.monitor && monitor && toplevel.monitor.name === monitor.name ? toplevel.title : ""
    visible: text !== ""
    role: Typography.labelLarge
    color: Colors.m3OnSurfaceVariant
    elide: Text.ElideRight
    Layout.maximumWidth: 320
    Layout.leftMargin: 8
    Layout.rightMargin: 12
}
