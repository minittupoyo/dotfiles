import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../tokens"

RowLayout {
    id: root

    spacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Label {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        role: Typography.titleMedium
        Layout.leftMargin: 12
    }
    Label {
        text: Qt.locale("ja_JP").toString(clock.date, "M月d日(ddd)")
        role: Typography.labelLarge
        color: Colors.m3OnSurfaceVariant
        Layout.rightMargin: 12
    }
}
