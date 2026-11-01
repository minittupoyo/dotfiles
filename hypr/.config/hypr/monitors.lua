-- モニター: 共通のフォールバック + 出力ごとの設定。
-- 配置(left/right)と refresh は Hyprland 起動後に hyprctl monitors を見て確定する。
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- 出力ごとのモード (DP-2: 144Hz / DP-3: 75Hz)。位置は左から DP-2, DP-3。
hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-3", mode = "2560x1440@75",  position = "2560x0", scale = 1 })

-- ワークスペースの個別割り当て: DP-2 = 1-5 / DP-3 = 6-10
local assign = {
    ["DP-2"] = { 1, 2, 3, 4, 5 },
    ["DP-3"] = { 6, 7, 8, 9, 10 },
}
for output, list in pairs(assign) do
    for i, ws in ipairs(list) do
        hl.workspace_rule({
            workspace  = tostring(ws),
            monitor    = output,
            default    = (i == 1),
            persistent = true,
        })
    end
end
