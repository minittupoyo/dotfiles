local mainMod  = "SUPER"
local terminal = "kitty"
local filemanager = "nautilus"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- quickshell (IPC)。-p で対象インスタンスを固定する
local qs = "qs -p $HOME/.config/quickshell/shell ipc call"
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("sh -c '" .. qs .. " overview toggle'"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("sh -c '" .. qs .. " power toggle'"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("sh -c '" .. qs .. " wallpaper toggle'"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("sh -c '" .. qs .. " launcher toggle'"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("sh -c '" .. qs .. " launcher emoji'"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("sh -c '" .. qs .. " launcher clipboard'"))
hl.bind("Print", hl.dsp.exec_cmd("sh -c '" .. qs .. " screenshot toggle'"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("sh -c '" .. qs .. " lock lock'"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("sh -c '" .. qs .. " quicksettings toggle'"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("sh -c '" .. qs .. " settings toggle'"))

-- ウィンドウ切り替え (Alt+Tab)。Alt+Tab で「switcher」サブマップに入り、Alt を押している間は Tab で次へ、離すと確定する。
-- サブマップの間は、ほかのバインドが効かないので、抜ける操作 (Esc・Alt の離し) は、シェルが落ちていても動くよう、
-- IPC とは別に Lua 側で直接リセットする。シェル側にも 8 秒のタイムアウトがある。
local sw = "qs -p $HOME/.config/quickshell/shell ipc call switcher"
local function swcmd(c) return hl.dsp.exec_cmd("sh -c '" .. sw .. " " .. c .. "'") end
local function swenter(c)
    return function()
        hl.dispatch(swcmd(c))
        hl.dispatch(hl.dsp.submap("switcher"))
    end
end
local function swleave(c)
    return function()
        hl.dispatch(swcmd(c))
        hl.dispatch(hl.dsp.submap("reset"))
    end
end
hl.bind("ALT + Tab", swenter("next"))
hl.bind("ALT + SHIFT + Tab", swenter("prev"))
hl.define_submap("switcher", function()
    hl.bind("ALT + Tab", swcmd("next"))
    hl.bind("ALT + SHIFT + Tab", swcmd("prev"))
    hl.bind("Escape", swleave("cancel"))
    hl.bind("ALT + Escape", swleave("cancel"))
    hl.bind("ALT + SHIFT + Escape", swleave("cancel"))
    -- Alt を離したら確定 (Shift を押したままの場合も)
    hl.bind("Alt_L", swleave("commit"), { release = true })
    hl.bind("Alt_R", swleave("commit"), { release = true })
    hl.bind("SHIFT + Alt_L", swleave("commit"), { release = true })
    hl.bind("SHIFT + Alt_R", swleave("commit"), { release = true })
end)

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- メディアキー
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
