//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"
import "modules/launcher"
import "modules/lock"
import "modules/notifications"
import "modules/osd"
import "modules/quicksettings"
import "modules/wallpaper"

ShellRoot {
    // バーはモニターごとに 1 つ。モニターの増減に追従する。
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // 通知のポップアップ (通知サーバー本体は services/Notifications)
    NotificationPopups {}

    // 音量・マイクのミュートの OSD (Audio の変化に反応する)
    OsdPopup {}

    // クイック設定 (バーのボタン / qs ipc call quicksettings toggle)
    QuickSettings {}

    // ランチャー (qs ipc call launcher toggle|clipboard)
    Launcher {}

    // ロック画面 (qs ipc call lock lock / SUPER+L / アイドル 15 分)
    LockScreen {}

    // 壁紙セレクター (qs ipc call wallpaper toggle で開閉)
    WallpaperSelector {}
}
