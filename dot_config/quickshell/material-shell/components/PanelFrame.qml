import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

PanelWindow {
    id: frame
    property int panelWidth: Theme.launcherWidth
    property int panelHeight: Theme.launcherMaxHeight
    property bool attachedToBar: false
    property bool opened: false
    property bool exiting: false
    property bool animateClose: true
    property real offsetScale: opened ? 0 : 1
    default property alias panelContent: content.data
    signal dismissed()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: opened || exiting
    onOpenedChanged: exiting = !opened && animateClose
    onOffsetScaleChanged: if (!opened && offsetScale >= 1) exiting = false
    WlrLayershell.namespace: "material-shell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible && opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Behavior on offsetScale {
        enabled: !Theme.reducedMotion
        NumberAnimation { duration: Theme.panelMotionDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: frame.attachedToBar ? "transparent" : Theme.scrim
        opacity: frame.attachedToBar ? 1 : 1 - frame.offsetScale
        MouseArea { anchors.fill: parent; enabled: frame.opened; onClicked: frame.dismissed() }
        Rectangle {
            id: panel
            x: Math.max(Theme.panelScreenMargin, Math.min((parent.width - width) / 2, parent.width - width - Theme.panelScreenMargin))
            y: frame.attachedToBar ? Theme.barHeight - (height + Theme.space4) * frame.offsetScale : (parent.height - height) / 2
            width: Math.min(frame.panelWidth, Math.max(1, frame.width - Theme.panelScreenMargin * 2))
            height: Math.min(frame.panelHeight, Math.max(1, frame.height - (frame.attachedToBar ? Theme.barHeight : 0) - Theme.panelScreenMargin * 2))
            radius: Theme.panelRadius
            color: frame.attachedToBar ? Theme.surfaceContainer : Theme.panelBackground
            opacity: frame.attachedToBar ? 1 - frame.offsetScale : 1
            Rectangle {
                visible: frame.attachedToBar
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Theme.panelRadius
                color: parent.color
            }
            // Consume clicks on the surface without intercepting child controls.
            MouseArea { anchors.fill: parent; enabled: frame.opened }
            Item {
                id: content
                focus: frame.opened
                Keys.onEscapePressed: frame.dismissed()
                anchors.fill: parent
                anchors.margins: Theme.panelPadding
            }
        }
    }
}
