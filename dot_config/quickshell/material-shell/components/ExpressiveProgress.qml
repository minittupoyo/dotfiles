import QtQuick
import ".."
Item {
    id: progress
    property real value: 0
    property bool interactive: false
    signal adjusted(real value)
    property bool keyboardFocus: false
    property bool wavy: true
    readonly property real fraction: Math.max(0, Math.min(1, value))
    property bool animationEnabled: true
    readonly property bool animationRunning: animationEnabled && visible && enabled && wavy && !Theme.reducedMotion && fraction > 0 && fraction < 1
    property real phase: 0
    property real displayedFraction: fraction
    property real amplitudeScale: fraction >= Theme.progressAmplitudeStart && fraction <= Theme.progressAmplitudeEnd ? 1 : 0
    readonly property real activeWidth: width * Math.max(0, Math.min(1, displayedFraction))
    Behavior on displayedFraction {
        enabled: progress.animationEnabled && progress.visible && !Theme.reducedMotion
        SpringAnimation { spring: Theme.progressSpring; damping: Theme.progressDamping; epsilon: Theme.progressEpsilon }
    }
    Behavior on amplitudeScale {
        enabled: progress.animationEnabled && progress.visible && !Theme.reducedMotion
        NumberAnimation { duration: Theme.progressAmplitudeDuration; easing.type: Easing.OutCubic }
    }
    FrameAnimation {
        running: progress.animationRunning
        onTriggered: progress.phase = (progress.phase + frameTime * Theme.progressWaveSpeed / Theme.progressWavelength) % 1
    }
    implicitHeight: Theme.progressTrackHeight + (wavy ? Theme.progressAmplitude * 2 : 0)
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: interactive && enabled
    Accessible.role: interactive ? Accessible.Slider : Accessible.ProgressBar
    Accessible.name: Math.round(fraction * 100) + "%"
    function adjust(next) { if (interactive && enabled) adjusted(Math.max(0, Math.min(1, next))); }
    Keys.onLeftPressed: { keyboardFocus = true; adjust(value - 0.05); }
    Keys.onRightPressed: { keyboardFocus = true; adjust(value + 0.05); }
    Keys.onPressed: event => {
        if (!interactive || !enabled) return;
        if (event.key === Qt.Key_Home) { keyboardFocus = true; adjust(0); event.accepted = true; }
        else if (event.key === Qt.Key_End) { keyboardFocus = true; adjust(1); event.accepted = true; }
    }
    Rectangle {
        x: Math.min(progress.width, progress.activeWidth + Theme.progressGap)
        width: Math.max(0, progress.width - x)
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.progressTrackHeight; radius: height / 2
        color: Theme.secondaryContainer
    }
    Rectangle {
        visible: !progress.wavy && progress.fraction > 0
        width: progress.activeWidth; height: Theme.progressTrackHeight
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2; color: Theme.primary
    }
    Canvas {
        id: wave
        anchors.fill: parent
        visible: progress.wavy && progress.fraction > 0
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections { target: progress; function onDisplayedFractionChanged() { wave.requestPaint(); } function onPhaseChanged() { wave.requestPaint(); } function onAmplitudeScaleChanged() { wave.requestPaint(); } function onWavyChanged() { wave.requestPaint(); } }
        Connections { target: Theme; function onPrimaryChanged() { wave.requestPaint(); } }
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const stroke = Math.min(Theme.progressTrackHeight, progress.activeWidth);
            if (stroke <= 0) return;
            ctx.strokeStyle = Theme.primary.toString(); ctx.lineWidth = stroke; ctx.lineCap = "round";
            ctx.beginPath();
            const start = stroke / 2; const end = Math.max(start, progress.activeWidth - stroke / 2);
            const amplitude = Theme.progressAmplitude * progress.amplitudeScale;
            function waveY(x) { return height / 2 + Math.sin((x - Theme.progressTrackHeight / 2) * Math.PI * 2 / Theme.progressWavelength + progress.phase * Math.PI * 2) * amplitude; }
            if (end === start) {
                ctx.fillStyle = Theme.primary.toString();
                ctx.beginPath(); ctx.arc(start, height / 2, stroke / 2, 0, Math.PI * 2); ctx.fill(); return;
            }
            for (let x = start; x <= end; x += 1) {
                const y = waveY(x);
                if (x === start) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.lineTo(end, waveY(end));
            ctx.stroke();
        }
    }
    Rectangle {
        x: parent.width - width
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.progressStopSize; height: width; radius: width / 2
        color: Theme.primary
        visible: x > progress.activeWidth + Theme.progressGap
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: progress.interactive && progress.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        function setPosition(x) { progress.adjust(x / Math.max(1, width)); }
        onPressed: mouse => { progress.keyboardFocus = false; progress.focus = false; setPosition(mouse.x); }
        onPositionChanged: mouse => { if (pressed) setPosition(mouse.x); }
    }
    Rectangle {
        objectName: "progressFocusIndicator"
        visible: progress.interactive && progress.activeFocus && progress.keyboardFocus
        anchors.fill: parent
        radius: Theme.space4
        color: "transparent"
        border.width: 1
        border.color: Theme.primary
    }
}
