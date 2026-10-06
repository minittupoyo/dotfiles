import QtQuick
import ".."
Item {
    id: progress
    property real value: 0
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
    Accessible.role: Accessible.ProgressBar
    Accessible.name: Math.round(fraction * 100) + "%"
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
}
