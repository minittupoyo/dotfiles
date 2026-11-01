import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

// ロック画面。Lock.locked に従って WlSessionLock (ext-session-lock) を掛ける・外す。
// 開始は IPC: qs ipc call lock lock。アイドルが Lock.idleSeconds 続いても掛かる (スリープ抑止中は掛からない)。
// 解除は PAM の認証だけ (IPC に解除は用意しない)。
Scope {
    LockContext {
        id: lockContext
    }

    WlSessionLock {
        locked: Lock.locked

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    IdleMonitor {
        enabled: !Lock.locked
        timeout: Lock.idleSeconds
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Lock.lock()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { Lock.lock(); }
        function status(): string { return Lock.locked ? "locked" : "unlocked"; }
    }
}
