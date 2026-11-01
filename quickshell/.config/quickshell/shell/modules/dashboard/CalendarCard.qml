import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../tokens"

// カレンダー (日曜始まり)。今日は塗りの丸で示し、月は前後に送れる。
Rectangle {
    id: root

    radius: Shapes.extraLarge
    color: Colors.m3SurfaceContainerHigh

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // 表示中の月の 1 日
    property date viewMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

    readonly property bool isCurrentMonth: viewMonth.getFullYear() === clock.date.getFullYear()
        && viewMonth.getMonth() === clock.date.getMonth()

    function shiftMonth(delta) {
        viewMonth = new Date(viewMonth.getFullYear(), viewMonth.getMonth() + delta, 1);
    }
    function reset() {
        viewMonth = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
    }

    // 42 マス (6 週) の日付
    readonly property var cells: {
        const y = viewMonth.getFullYear();
        const m = viewMonth.getMonth();
        const offset = new Date(y, m, 1).getDay();
        const t = clock.date;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - offset + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === m,
                today: d.getFullYear() === t.getFullYear() && d.getMonth() === t.getMonth() && d.getDate() === t.getDate(),
                weekday: d.getDay()
            });
        }
        return out;
    }

    implicitHeight: col.implicitHeight + 40

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: root.viewMonth.getFullYear() + "年" + (root.viewMonth.getMonth() + 1) + "月"
                role: Typography.titleLarge
            }
            Button {
                size: "s"
                variant: "text"
                text: "今日"
                visible: !root.isCurrentMonth
                onClicked: root.reset()
            }
            IconButton {
                size: "s"
                variant: "standard"
                icon: "chevron_left"
                onClicked: root.shiftMonth(-1)
            }
            IconButton {
                size: "s"
                variant: "standard"
                icon: "chevron_right"
                onClicked: root.shiftMonth(1)
            }
        }

        // 曜日
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: ["日", "月", "火", "水", "木", "金", "土"]
                Label {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    role: Typography.labelMedium
                    color: index === 0 || index === 6 ? Colors.m3Tertiary : Colors.m3OnSurfaceVariant
                }
            }
        }

        // 日付
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: root.cells

                Item {
                    id: cell
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 40

                    Rectangle {
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        radius: Shapes.full
                        color: Colors.m3Primary
                        visible: cell.modelData.today
                    }
                    Label {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        role: cell.modelData.today ? Typography.labelLargeEmphasized : Typography.bodyMedium
                        color: cell.modelData.today ? Colors.m3OnPrimary
                             : !cell.modelData.inMonth ? Colors.m3Outline
                             : cell.modelData.weekday === 0 || cell.modelData.weekday === 6 ? Colors.m3Tertiary
                             : Colors.m3OnSurface
                    }
                }
            }
        }
    }
}
