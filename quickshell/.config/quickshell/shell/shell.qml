//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"
import "modules/dashboard"
import "modules/launcher"
import "modules/lock"
import "modules/media"
import "modules/notifications"
import "modules/osd"
import "modules/overview"
import "modules/power"
import "modules/settings"
import "modules/screenshot"
import "modules/switcher"
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

    // Alt+Tab のウィンドウ切り替え (Hyprland のサブマップから IPC で操作される)
    Switcher {}

    // スクリーンショットのメニュー (Print キー。qs ipc call screenshot toggle でも開く)
    ScreenshotMenu {}

    // ダッシュボード (バー中央の島のクリック。qs ipc call dashboard toggle でも開く)
    Dashboard {}

    // ワークスペースのオーバービュー (SUPER+Tab。qs ipc call overview toggle でも開く)
    Overview {}

    // 電源メニュー (SUPER+M。qs ipc call power toggle でも開く)
    PowerMenu {}

    // ロック画面 (qs ipc call lock lock / SUPER+L / アイドル 15 分)
    LockScreen {}

    // 壁紙セレクター (qs ipc call wallpaper toggle で開閉)
    WallpaperSelector {}

    // 設定画面 (クイック設定の歯車 / SUPER+comma。qs ipc call settings toggle でも開く)
    SettingsWindow {}
}
