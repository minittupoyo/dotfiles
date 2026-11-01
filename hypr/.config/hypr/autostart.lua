hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("fcitx5 -d")
    -- クリップボード履歴 (cliphist)。テキストと画像を別々に監視する
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("awww-daemon")
    -- デーモンの待ち受け開始を待ってから、最後の壁紙を復元する
    hl.exec_cmd("sh -c 'for i in $(seq 50); do awww query >/dev/null 2>&1 && break; sleep 0.1; done; awww restore'")
    -- quickshell は shell.qml が存在するようになってから起動する
    hl.exec_cmd("sh -c '[ -f \"$HOME/.config/quickshell/shell/shell.qml\" ] && exec qs -p \"$HOME/.config/quickshell/shell\"'")
end)
