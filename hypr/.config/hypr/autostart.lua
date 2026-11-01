hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("awww-daemon")
    -- quickshell は shell.qml が存在するようになってから起動する
    hl.exec_cmd("sh -c '[ -f \"$HOME/.config/quickshell/shell/shell.qml\" ] && exec qs -p \"$HOME/.config/quickshell/shell\"'")
end)
