import QtQuick
import ".."
Item {
    id: slider
    property real value: 0
    signal adjusted(real value)
    property bool keyboardFocus: false
    implicitHeight: Theme.sliderHeight
    implicitWidth: Theme.launcherWidth / 2
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.38
    Accessible.role: Accessible.Slider
    Accessible.name: "音量 " + Math.round(value * 100) + "%"
    function adjust(next) { if (enabled) adjusted(Math.max(0, Math.min(1, next))); }
    Keys.onLeftPressed: { keyboardFocus = true; adjust(value - 0.05); }
    Keys.onRightPressed: { keyboardFocus = true; adjust(value + 0.05); }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) { keyboardFocus = true; adjust(0); event.accepted = true; }
        else if (event.key === Qt.Key_End) { keyboardFocus = true; adjust(1); event.accepted = true; }
    }
    readonly property real fraction: Math.max(0, Math.min(1, value))
    readonly property real trackStart: Theme.sliderHandleWidth / 2
    readonly property real trackWidth: Math.max(0, width - Theme.sliderHandleWidth)
    readonly property real handleX: trackStart + trackWidth * fraction
    Rectangle {
        objectName: "sliderActiveTrack"
        x: slider.trackStart
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, slider.handleX - x - Theme.sliderHandleWidth / 2 - Theme.sliderGap)
        height: Theme.sliderTrackHeight
        topLeftRadius: height / 2; bottomLeftRadius: height / 2
        topRightRadius: Theme.sliderInsideRadius; bottomRightRadius: Theme.sliderInsideRadius
        color: Theme.primary
    }
    Rectangle {
        objectName: "sliderInactiveTrack"
        x: slider.handleX + Theme.sliderHandleWidth / 2 + Theme.sliderGap
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, slider.trackStart + slider.trackWidth - x)
        height: Theme.sliderTrackHeight
        topLeftRadius: Theme.sliderInsideRadius; bottomLeftRadius: Theme.sliderInsideRadius
        topRightRadius: height / 2; bottomRightRadius: height / 2
        color: Theme.secondaryContainer
    }
    Repeater {
        model: [false, true]
        Rectangle {
            required property bool modelData
            width: Theme.sliderStopSize; height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: modelData ? slider.trackStart + slider.trackWidth - Theme.sliderTrackHeight / 2 - width / 2 : slider.trackStart + Theme.sliderTrackHeight / 2 - width / 2
            visible: modelData ? slider.fraction < 1 && x > slider.handleX + Theme.sliderGap : slider.fraction > 0 && x + width < slider.handleX - Theme.sliderGap
            color: modelData ? Theme.secondaryContainerText : Theme.primaryText
        }
    }
    Rectangle {
        objectName: "sliderHandle"
        x: slider.handleX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: pointer.pressed ? Theme.sliderHandlePressedWidth : Theme.sliderHandleWidth
        height: Theme.sliderHandleHeight; radius: width / 2
        color: Theme.primary
        Behavior on width { enabled: !Theme.reducedMotion; NumberAnimation { duration: Theme.motionDuration } }
    }
    Rectangle {
        objectName: "sliderFocusIndicator"
        visible: slider.activeFocus && slider.keyboardFocus
        x: slider.handleX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.sliderHandleWidth + Theme.space8; height: Theme.sliderHeight
        radius: Theme.space4; color: "transparent"
        border.width: 1; border.color: Theme.primary
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function setPosition(x) { slider.adjust((x - slider.trackStart) / Math.max(1, slider.trackWidth)); }
        onPressed: mouse => { slider.keyboardFocus = false; slider.focus = false; setPosition(mouse.x); }
        onPositionChanged: mouse => { if (pressed) setPosition(mouse.x); }
        onWheel: event => { slider.adjust(slider.value + (event.angleDelta.y > 0 ? 0.05 : -0.05)); event.accepted = true; }
    }
}
