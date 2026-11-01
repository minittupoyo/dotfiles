//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"
import "modules/dashboard"
import "modules/launcher"
import "modules/lock"
import "modules/media"
import "modules/notifications"
import "modules/osd"
import "modules/screenshot"
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

    // メディア画面 (クイック設定のメディアカードから。qs ipc call media toggle でも開く)
    MediaScreen {}

    // 音量・マイクのミュートの OSD (Audio の変化に反応する)
    OsdPopup {}

    // クイック設定 (バーのボタン / qs ipc call quicksettings toggle)
    QuickSettings {}

    // ランチャー (qs ipc call launcher toggle|clipboard)
    Launcher {}

    // スクリーンショットのメニュー (Print キー。qs ipc call screenshot toggle でも開く)
    ScreenshotMenu {}

    // ダッシュボード (バー中央の島のクリック。qs ipc call dashboard toggle でも開く)
    Dashboard {}

    // ロック画面 (qs ipc call lock lock / SUPER+L / アイドル 15 分)
    LockScreen {}

    // 壁紙セレクター (qs ipc call wallpaper toggle で開閉)
    WallpaperSelector {}
}
