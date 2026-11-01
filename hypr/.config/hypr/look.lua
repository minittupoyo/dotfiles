-- 見た目。配色は matugen が生成する colors.lua (無ければフォールバック)。
local ok, c = pcall(require, "colors")
if not ok then
    c = { active_border = "rgba(cfbcffee)", inactive_border = "rgba(49454f88)", shadow = 0xee000000 }
end

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border   = c.active_border,
            inactive_border = c.inactive_border,
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout = "dwindle",
    },
    decoration = {
        rounding       = 16,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 8, render_power = 3, color = c.shadow },
        blur   = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        -- ロック用クライアント(qs)が落ちても、ロック画面を維持して再接続を待つ
        allow_session_lock_restore = true,
        -- ロック中に消した画面を、キー入力・マウス操作で戻す
        key_press_enables_dpms  = true,
        mouse_move_enables_dpms = true,
    },
})

-- M3 Expressive のスプリング。quickshell の tokens/Motion.qml と同じ値。
-- Hyprland の damping は係数なので、減衰比 ζ から c = 2*ζ*sqrt(stiffness) (mass=1) で換算している。
-- Spatial = 位置・大きさ (オーバーシュートあり) / Effects = 色・不透明度 (オーバーシュートなし)
hl.curve("spatialFast",    { type = "spring", mass = 1, stiffness = 800,  damping = 33.94 })  -- ζ0.6
hl.curve("spatialDefault", { type = "spring", mass = 1, stiffness = 380,  damping = 31.19 })  -- ζ0.8
hl.curve("spatialSlow",    { type = "spring", mass = 1, stiffness = 200,  damping = 22.63 })  -- ζ0.8
hl.curve("effectsFast",    { type = "spring", mass = 1, stiffness = 3800, damping = 123.29 }) -- ζ1.0
hl.curve("effectsDefault", { type = "spring", mass = 1, stiffness = 1600, damping = 80.0 })   -- ζ1.0
hl.curve("effectsSlow",    { type = "spring", mass = 1, stiffness = 800,  damping = 56.57 })  -- ζ1.0

hl.animation({ leaf = "global",     enabled = true, speed = 1, spring = "effectsDefault" })
hl.animation({ leaf = "windows",    enabled = true, speed = 1, spring = "spatialDefault" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 1, spring = "spatialDefault", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, spring = "effectsFast",    style = "popin 87%" })
hl.animation({ leaf = "border",     enabled = true, speed = 1, spring = "effectsDefault" })
hl.animation({ leaf = "layers",     enabled = true, speed = 1, spring = "spatialFast" })
hl.animation({ leaf = "layersIn",   enabled = true, speed = 1, spring = "effectsDefault", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 1, spring = "effectsFast",    style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "spatialDefault", style = "slide" })
