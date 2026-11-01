pragma Singleton

import QtQuick
import Quickshell

// ロック状態の持ち主。実際のセッションロックは modules/lock/LockScreen.qml (WlSessionLock) が
// このシングルトンの locked に従って行う。
//
// テスト用の環境変数 (本番では設定しない):
//   LOCK_TEST_AUTOUNLOCK_MS  ロックされてからこのミリ秒後に自動で解除する (認証を通さない)
//   LOCK_IDLE_SECONDS        アイドルでロックするまでの秒数を上書きする
Singleton {
    id: root

    property bool locked: false

    // アイドルでロックするまでの時間 (既定 15 分)
    readonly property int idleSeconds: parseInt(Quickshell.env("LOCK_IDLE_SECONDS")) || 15 * 60
    readonly property int testAutoUnlockMs: parseInt(Quickshell.env("LOCK_TEST_AUTOUNLOCK_MS")) || 0

    function lock() {
        if (!locked)
            locked = true;
    }

    function unlock() {
        locked = false;
    }

    Timer {
        interval: root.testAutoUnlockMs
        running: root.locked && root.testAutoUnlockMs > 0
        onTriggered: {
            console.log("Lock(test): auto unlock after", root.testAutoUnlockMs, "ms");
            root.unlock();
        }
    }
}
