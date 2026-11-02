import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../tokens"
import "pages"

// 設定の中身: 左にカテゴリのレール、右にそのページ (スクロールできる)。
Item {
    id: root

    signal closeRequested()

    property int startPage: 0
    property int page: 0

    readonly property var pageDefs: [
        { name: "外観", icon: "palette" },
        { name: "バー", icon: "toolbar" },
        { name: "通知", icon: "notifications" },
        { name: "ロック・電源", icon: "lock" },
        { name: "ランチャー", icon: "search" },
        { name: "スクリーンショット", icon: "screenshot_region" },
        { name: "情報", icon: "info" }
    ]

    focus: true
    function open() {
        page = Math.max(0, Math.min(startPage, pageDefs.length - 1));
        forceActiveFocus();
    }
    Keys.onEscapePressed: closeRequested()

    onPageChanged: {
        fade.snap(0);
        fade.target = 1;
        flick.contentY = 0;
    }
    SpringValue {
        id: fade
        value: 1
        target: 1
        spec: Motion.effectsDefault
        epsilon: 0.002
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- レール ----
        ColumnLayout {
            Layout.preferredWidth: 248
            Layout.minimumWidth: 248
            Layout.maximumWidth: 248
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 4

            Label {
                Layout.leftMargin: 12
                Layout.bottomMargin: 12
                text: "設定"
                role: Typography.headlineSmallEmphasized
            }

            Repeater {
                model: root.pageDefs

                ChoiceRow {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.name
                    icon: modelData.icon
                    checked: root.page === index
                    onClicked: root.page = index
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // ---- ページ ----
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            Layout.rightMargin: 24
            contentWidth: width
            contentHeight: pageCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            opacity: fade.value

            ColumnLayout {
                id: pageCol
                width: flick.width
                spacing: 20

                Label {
                    text: root.pageDefs[root.page].name
                    role: Typography.headlineMediumEmphasized
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: [appearance, bar, notifications, power, launcher, screenshot, about][root.page]
                }
            }
        }
    }

    Component { id: appearance; AppearancePage {} }
    Component { id: bar; BarPage {} }
    Component { id: notifications; NotificationsPage {} }
    Component { id: power; PowerPage {} }
    Component { id: launcher; LauncherPage {} }
    Component { id: screenshot; ScreenshotPage {} }
    Component { id: about; AboutPage {} }
}
