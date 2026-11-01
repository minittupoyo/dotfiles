import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../tokens"

// Alt+Tab の 1 枚のカード: ウィンドウの実際の絵 (サムネイル) + アプリのアイコン + タイトル + ワークスペース。
// 選択中は、少し大きくなり、色が付いて、サムネイルの角が大きくなる (形状モーフィング)。
Item {
    id: card

    required property var modelData    // { address, appClass, title, wsId, monId, toplevel (HyprlandToplevel | null) }
    required property int index
    property bool selected: false

    signal clicked()

    width: 232
    height: 212

    readonly property string appClass: modelData.appClass
    readonly property string title: modelData.title || appClass
    readonly property int wsId: modelData.wsId
    readonly property string monName: {
        const m = Hyprland.monitors.values.find(x => x.id === modelData.monId);
        return m ? m.name : "";
    }

    SpringValue {
        id: sel
        target: card.selected ? 1 : 0
        spec: Motion.spatialFast
        epsilon: 0.002
    }

    scale: 1 + 0.06 * sel.value
    z: card.selected ? 1 : 0

    // 土台
    Rectangle {
        anchors.fill: parent
        radius: Shapes.large + 4 * sel.value
        color: card.selected ? Colors.m3SecondaryContainer : Colors.m3SurfaceContainerHigh
    }
    StateLayer {
        anchors.fill: parent
        radius: Shapes.large
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    // アプリのアイコン (サムネイルが出るまで・取れないときの代わり)
    readonly property string iconSource: {
        const e = DesktopEntries.heuristicLookup(appClass);
        return Quickshell.iconPath(e && e.icon ? e.icon : appClass.toLowerCase(), true);
    }

    // サムネイル
    Item {
        id: thumb
        x: 8
        y: 8
        width: card.width - 16
        height: 140

        Rectangle {
            id: thumbMask
            anchors.fill: parent
            radius: Shapes.medium + 6 * sel.value
            visible: false
            layer.enabled: true
        }
        Rectangle {
            anchors.fill: parent
            radius: thumbMask.radius
            color: Colors.m3SurfaceContainerLowest
        }

        Image {
            anchors.centerIn: parent
            width: 56
            height: 56
            visible: !view.hasContent && source !== ""
            source: card.iconSource
            sourceSize: Qt.size(112, 112)
            asynchronous: true
        }

        // 実際のウィンドウの絵。縦横比を保って、枠に収める
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: thumbMask
            }

            ScreencopyView {
                id: view
                readonly property real ar: sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 9
                anchors.centerIn: parent
                width: ar > parent.width / parent.height ? parent.width : parent.height * ar
                height: ar > parent.width / parent.height ? parent.width / ar : parent.height
                captureSource: card.modelData.toplevel ? card.modelData.toplevel.wayland : null
                constraintSize: Qt.size(480, 320)
                live: true
                visible: hasContent
            }
        }
    }

    // アイコン + タイトル + 場所
    RowLayout {
        x: 12
        y: 156
        width: card.width - 24
        height: 48
        spacing: 10

        Image {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            source: card.iconSource
            sourceSize: Qt.size(56, 56)
            asynchronous: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label {
                Layout.fillWidth: true
                text: card.title
                role: Typography.labelLarge
                color: card.selected ? Colors.m3OnSecondaryContainer : Colors.m3OnSurface
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Label {
                Layout.fillWidth: true
                text: "ワークスペース " + card.wsId + (card.monName !== "" ? "  ·  " + card.monName : "")
                role: Typography.labelSmall
                color: card.selected ? Colors.m3OnSecondaryContainer : Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
