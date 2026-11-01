pragma Singleton

import QtQuick
import Quickshell

// 電源操作 (スリープ・再起動・シャットダウン)。systemctl は logind 経由で、アクティブなセッションなら sudo 不要。
// dryRun のときは実行せずログに出す (テスト用)。
Singleton {
    property bool dryRun: false

    readonly property var commands: ({
        suspend: ["systemctl", "suspend"],
        reboot: ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    })

    function run(action) {
        const cmd = commands[action];
        if (!cmd)
            return false;
        if (dryRun) {
            console.log("Power(dryRun): would run:", cmd.join(" "));
            return true;
        }
        Quickshell.execDetached(cmd);
        return true;
    }
}
