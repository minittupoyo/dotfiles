//@ pragma IconTheme Adwaita
import Quickshell
import "modules/bar"

ShellRoot {
    // バーはモニターごとに 1 つ。モニターの増減に追従する。
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
