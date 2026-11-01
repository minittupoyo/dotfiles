import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// システムモニター: CPU / メモリ / GPU / VRAM のゲージと、ドライブの温度・GPU の電力。
Rectangle {
    id: root

    radius: Shapes.extraLarge
    color: Colors.m3SurfaceContainerHigh

    implicitHeight: col.implicitHeight + 40

    function fmt1(v) {
        return v.toFixed(1);
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 2
            columnSpacing: 32
            rowSpacing: 12

            ColumnLayout {
                spacing: 4
                Gauge {
                    Layout.alignment: Qt.AlignHCenter
                    value: SystemStats.cpuUsage
                    text: Math.round(SystemStats.cpuUsage * 100) + "%"
                    subtitle: SystemStats.cpuTemp > 0 ? Math.round(SystemStats.cpuTemp) + " ℃" : ""
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "CPU"
                    role: Typography.titleSmall
                    color: Colors.m3OnSurfaceVariant
                }
            }
            ColumnLayout {
                spacing: 4
                Gauge {
                    Layout.alignment: Qt.AlignHCenter
                    value: SystemStats.memFraction
                    text: Math.round(SystemStats.memFraction * 100) + "%"
                    subtitle: root.fmt1(SystemStats.memUsed) + " / " + Math.round(SystemStats.memTotal) + " GB"
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "メモリ"
                    role: Typography.titleSmall
                    color: Colors.m3OnSurfaceVariant
                }
            }
            ColumnLayout {
                visible: SystemStats.hasGpu
                spacing: 4
                Gauge {
                    Layout.alignment: Qt.AlignHCenter
                    value: SystemStats.gpuUsage
                    text: Math.round(SystemStats.gpuUsage * 100) + "%"
                    subtitle: Math.round(SystemStats.gpuTemp) + " ℃"
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "GPU"
                    role: Typography.titleSmall
                    color: Colors.m3OnSurfaceVariant
                }
            }
            ColumnLayout {
                visible: SystemStats.hasGpu
                spacing: 4
                Gauge {
                    Layout.alignment: Qt.AlignHCenter
                    value: SystemStats.vramFraction
                    text: Math.round(SystemStats.vramFraction * 100) + "%"
                    subtitle: root.fmt1(SystemStats.vramUsed) + " / " + Math.round(SystemStats.vramTotal) + " GB"
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "VRAM"
                    role: Typography.titleSmall
                    color: Colors.m3OnSurfaceVariant
                }
            }
        }

        // 補足の数値
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { icon: "memory", text: "GPU 電力 " + Math.round(SystemStats.gpuPower) + " / " + Math.round(SystemStats.gpuPowerLimit) + " W", show: SystemStats.hasGpu },
                    { icon: "hard_drive", text: "NVMe " + Math.round(SystemStats.nvmeTemp) + " ℃", show: SystemStats.nvmeTemp > 0 }
                ]
                Rectangle {
                    required property var modelData
                    visible: modelData.show
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 40
                    radius: Shapes.full
                    color: Colors.m3SecondaryContainer
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: parent.parent.modelData.icon
                            size: 20
                            color: Colors.m3OnSecondaryContainer
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.modelData.text
                            role: Typography.labelLarge
                            color: Colors.m3OnSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
