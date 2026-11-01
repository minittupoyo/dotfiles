import QtQuick
import "../tokens"

// カード。variant: "filled" | "elevated" | "outlined"
Surface {
    id: root

    property string variant: "filled"

    level: variant === "elevated" ? 1 : 0
    radius: Shapes.medium
    color: variant === "elevated" ? Colors.m3SurfaceContainerLow
         : variant === "outlined" ? Colors.m3Surface
         : Colors.m3SurfaceContainerHighest
    borderColor: variant === "outlined" ? Colors.m3OutlineVariant : "transparent"
    borderWidth: variant === "outlined" ? 1 : 0
}
