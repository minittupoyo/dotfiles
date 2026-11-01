//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"
import "modules/launcher"
import "modules/wallpaper"

ShellRoot {
    // バーはモニターごとに 1 つ。モニターの増減に追従する。
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // ランチャー (qs ipc call launcher toggle|clipboard)
    Launcher {}

    // 壁紙セレクター (qs ipc call wallpaper toggle で開閉)
    WallpaperSelector {}
}
