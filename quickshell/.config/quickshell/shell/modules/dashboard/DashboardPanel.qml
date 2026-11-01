import QtQuick
import QtQuick.Layouts
import "../../tokens"

// ダッシュボードの中身: 左にカレンダー、右にシステムモニター。Esc で閉じる。
Item {
    id: root

    signal closeRequested()

    implicitHeight: Math.max(calendar.implicitHeight, stats.implicitHeight)
    focus: true

    function open() {
        calendar.reset();
        forceActiveFocus();
    }

    Keys.onEscapePressed: root.closeRequested()

    RowLayout {
        anchors.fill: parent
        spacing: 16

        CalendarCard {
            id: calendar
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.fillWidth: true
        }
        StatsCard {
            id: stats
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.fillWidth: true
        }
    }
}
