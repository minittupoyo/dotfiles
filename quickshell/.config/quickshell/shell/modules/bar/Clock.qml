import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

RowLayout {
    id: root

    spacing: 8

    SystemClock {
        id: clock
        precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Label {
        text: Qt.formatDateTime(clock.date, (Settings.clock24h ? "HH:mm" : "h:mm") + (Settings.clockSeconds ? ":ss" : "") + (Settings.clock24h ? "" : " AP"))
        role: Typography.titleMedium
        Layout.leftMargin: 12
        Layout.rightMargin: Settings.clockDate ? 0 : 12
    }
    Label {
        text: Qt.locale("ja_JP").toString(clock.date, "M月d日(ddd)")
        role: Typography.labelLarge
        color: Colors.m3OnSurfaceVariant
        visible: Settings.clockDate
        Layout.rightMargin: 12
    }
}
