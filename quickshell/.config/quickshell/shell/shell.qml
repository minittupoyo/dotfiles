//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"
import "modules/launcher"
import "modules/notifications"
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

    // クイック設定 (バーのボタン / qs ipc call quicksettings toggle)
    QuickSettings {}

    // ランチャー (qs ipc call launcher toggle|clipboard)
    Launcher {}

    // 壁紙セレクター (qs ipc call wallpaper toggle で開閉)
    WallpaperSelector {}
}
