pragma Singleton

import QtQuick
import Quickshell

// 電源操作 (スリープ・再起動・シャットダウン・ログアウト)。systemctl は logind 経由で、アクティブなセッションなら sudo 不要。
// dryRun のときは実行せずログに出す (テスト用。環境変数 POWER_DRYRUN=1 でも有効)。
Singleton {
    property bool dryRun: Quickshell.env("POWER_DRYRUN") === "1"

    readonly property var commands: ({
        suspend: ["systemctl", "suspend"],
        reboot: ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"],
        // アプリを正常終了させてから抜ける hyprshutdown があればそれ、無ければ Hyprland をそのまま終了する
        logout: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
    })

    Timer {
        id: suspendTimer
        interval: 600
        onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
    }

    function run(action) {
        const cmd = commands[action];
        if (!cmd)
            return false;
        if (dryRun) {
            console.log("Power(dryRun): would run:", cmd.join(" "));
            return true;
        }
        // スリープ前にロックする (復帰したときに画面が見えないように)。ロックが掛かるのを少し待つ
        if (action === "suspend") {
            Lock.lock();
            suspendTimer.start();
            return true;
        }
        Quickshell.execDetached(cmd);
        return true;
    }
}
