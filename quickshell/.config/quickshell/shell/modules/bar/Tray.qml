import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../../components"
import "../../tokens"

// システムトレイ。左クリックで activate (メニューだけの項目はメニュー)、右クリックでメニュー。
RowLayout {
    id: root

    spacing: 0
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        BaseButton {
            id: item

            required property var modelData    // SystemTrayItem

            variant: "standard"
            implicitWidth: 32
            implicitHeight: 32

            function showMenu() {
                if (modelData.hasMenu)
                    menu.toggle();
            }

            onClicked: modelData.onlyMenu ? showMenu() : modelData.activate()
            onRightClicked: showMenu()

            TrayMenu {
                id: menu
                anchorItem: item
                menuHandle: item.modelData.menu
            }

            // シンボリックアイコンは黒系の単色なので、テーマ色で塗り直す
            readonly property bool symbolic: String(modelData.icon).indexOf("symbolic") >= 0

            Image {
                id: img
                anchors.centerIn: parent
                // シンボリックは 16px グリッドで設計されているので 16px で描く (20px だとにじむ)
                width: item.symbolic ? 16 : 20
                height: width
                sourceSize.width: width
                sourceSize.height: width
                source: item.modelData.icon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: !item.symbolic
                layer.enabled: item.symbolic
            }

            MultiEffect {
                anchors.fill: img
                source: img
                visible: item.symbolic
                colorization: 1.0
                colorizationColor: item.contentColor
            }
        }
    }
}
