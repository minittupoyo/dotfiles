pragma Singleton

import QtQuick
import Quickshell

// ロック状態の持ち主。実際のセッションロックは modules/lock/LockScreen.qml (WlSessionLock) が
// このシングルトンの locked に従って行う。
//
// テスト用の環境変数 (本番では設定しない):
//   LOCK_TEST_AUTOUNLOCK_MS  ロックされてからこのミリ秒後に自動で解除する (認証を通さない)
//   LOCK_IDLE_SECONDS        アイドルでロックするまでの秒数を上書きする
//   LOCK_DPMS_SECONDS        ロック中に画面を消すまでの秒数 (未設定なら消さない)
Singleton {
    id: root

    property bool locked: false
    // 解除のアニメーション中 (認証は通った。画面を消すのはアニメーションが終わってから)。
    // ロックが解けるとサーフェスが即座に破棄されるので、動かすなら解除の前にやるしかない。
    property bool unlocking: false
    readonly property int unlockMs: 450

    // アイドルでロックするまでの時間 (既定 15 分)
    readonly property int idleSeconds: parseInt(Quickshell.env("LOCK_IDLE_SECONDS")) || 15 * 60
    // ロック中に入力がなくなってから画面を消すまでの秒数。既定は 0 (消さない)。
    // 144Hz の DP-2 が、DPMS オフから戻らないことがあったため (NVIDIA + DP)。有効にするときは環境変数で。
    readonly property int dpmsSeconds: parseInt(Quickshell.env("LOCK_DPMS_SECONDS")) || 0
    readonly property int testAutoUnlockMs: parseInt(Quickshell.env("LOCK_TEST_AUTOUNLOCK_MS")) || 0

    function lock() {
        if (!locked) {
            unlocking = false;
            locked = true;
        }
    }

    // 解除する。アニメーションを見せてから実際に外す
    function unlock() {
        if (!locked || unlocking)
            return;
        unlocking = true;
        unlockTimer.start();
    }

    Timer {
        id: unlockTimer
        interval: root.unlockMs
        onTriggered: {
            root.unlocking = false;
            root.locked = false;
        }
    }

    function setScreens(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"" + (on ? "on" : "off") + "\" })"]);
    }

    // 解除したら画面は必ず点ける
    onLockedChanged: if (!locked) setScreens(true)

    Timer {
        interval: root.testAutoUnlockMs
        running: root.locked && root.testAutoUnlockMs > 0
        onTriggered: {
            console.log("Lock(test): auto unlock after", root.testAutoUnlockMs, "ms");
            root.unlock();
        }
    }
}
