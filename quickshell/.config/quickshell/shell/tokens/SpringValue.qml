import QtQuick

// スプリングで target に追従する値。M3 Expressive のスプリング (Motion.*) を物理どおりに解く。
//   x'' = -stiffness * (x - target) - 2 * damping * sqrt(stiffness) * x'   (質量 1)
// 1フレームずつ解析解で進めるので、フレーム時間が揺れても安定し、
// 目標が途中で変わっても速度を引き継ぐ (中断に強い)。
//
//   SpringValue { id: s; target: pressed ? 12 : 28; spec: Motion.spatialFast }
//   Rectangle { radius: Math.max(0, s.value) }
//
// spatial 系は damping < 1 でオーバーシュートする。負になってはいけない値 (角丸など) は呼び出し側で clamp する。
QtObject {
    id: root

    property real target: 0
    property var spec: Motion.spatialDefault
    // この距離・速度以下になったら target に収束したとみなして停止する
    property real epsilon: 0.01

    property real value: 0
    readonly property real velocity: _v
    readonly property bool running: _anim.running

    property real _v: 0

    // 今の target に即座に収束させる (アニメーションなし)。target の束縛を壊さない。
    function settle() {
        _anim.stop();
        _v = 0;
        value = target;
    }

    // 値を即座に設定する (アニメーションなし)。target も v に代入するので、target の束縛は外れる
    function snap(v) {
        _anim.stop();
        _v = 0;
        value = v;
        target = v;
    }

    onTargetChanged: {
        if (Math.abs(value - target) > epsilon || Math.abs(_v) > epsilon)
            _anim.start();
    }

    Component.onCompleted: value = target

    function _step(dt) {
        const w = Math.sqrt(spec.stiffness);
        const z = Math.min(spec.damping, 1.0);
        const x0 = value - target;
        const v0 = _v;
        let x, v;
        if (z < 1.0) {
            const wd = w * Math.sqrt(1.0 - z * z);
            const e = Math.exp(-z * w * dt);
            const c = Math.cos(wd * dt);
            const s = Math.sin(wd * dt);
            const b = (v0 + z * w * x0) / wd;
            x = e * (x0 * c + b * s);
            v = e * ((-z * w * x0 + wd * b) * c + (-z * w * b - wd * x0) * s);
        } else {
            const e = Math.exp(-w * dt);
            const a = v0 + w * x0;
            x = e * (x0 + a * dt);
            v = e * (v0 - w * a * dt);
        }
        _v = v;
        value = target + x;
        if (Math.abs(x) < epsilon && Math.abs(v) < epsilon * 10) {
            value = target;
            _v = 0;
            _anim.stop();
        }
    }

    readonly property FrameAnimation _anim: FrameAnimation {
        // 長いフレーム (ブロック時など) で解が飛ばないよう上限を付ける
        onTriggered: root._step(Math.min(frameTime, 0.05))
    }
}
