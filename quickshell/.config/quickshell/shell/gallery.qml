import QtQuick
import Quickshell
import "components"
import "tokens"

// トークンと部品の確認用ギャラリー (開発用)。
//   qs -p ~/dotfiles/quickshell/.config/quickshell/shell/gallery.qml
ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 1500
        implicitHeight: 1000
        color: Colors.m3Surface

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: col.implicitHeight + 48
            clip: true

            Column {
                id: col
                x: 24; y: 24
                width: parent.width - 48
                spacing: 28

                Label { text: "Gallery"; role: Typography.headlineMediumEmphasized }

                // --- Typography ---
                Column {
                    spacing: 2
                    Label { text: "Typography"; role: Typography.titleMedium; color: Colors.m3Primary }
                    Label { text: "Display Small — 日本語もきれいに"; role: Typography.displaySmall }
                    Label { text: "Headline Small Emphasized — Quick brown fox"; role: Typography.headlineSmallEmphasized }
                    Label { text: "Title Large — 壁紙セレクター / Launcher"; role: Typography.titleLarge }
                    Label { text: "Body Medium — The quick brown fox jumps over the lazy dog 0123456789"; role: Typography.bodyMedium }
                    Label { text: "Label Large Emphasized — Button"; role: Typography.labelLargeEmphasized }
                }

                // --- Icons ---
                Row {
                    spacing: 16
                    Label { text: "Icons"; role: Typography.titleMedium; color: Colors.m3Primary; anchors.verticalCenter: parent.verticalCenter }
                    Icon { name: "home"; size: 32 }
                    Icon { name: "home"; size: 32; fill: 1 }
                    Icon { name: "search"; size: 32; weight: 700 }
                    Icon { name: "wallpaper"; size: 32; color: Colors.m3Primary }
                    Icon { name: "settings"; size: 48 }
                }

                // --- Shapes ---
                Row {
                    spacing: 12
                    Repeater {
                        model: [
                            { n: "none", r: Shapes.none }, { n: "xs", r: Shapes.extraSmall }, { n: "sm", r: Shapes.small },
                            { n: "md", r: Shapes.medium }, { n: "lg", r: Shapes.large }, { n: "lgInc", r: Shapes.largeIncreased },
                            { n: "xl", r: Shapes.extraLarge }, { n: "xlInc", r: Shapes.extraLargeIncreased },
                            { n: "xxl", r: Shapes.extraExtraLarge }, { n: "full", r: Shapes.full }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 96; height: 72; radius: modelData.r
                            color: Colors.m3SecondaryContainer
                            Label { anchors.centerIn: parent; text: parent.modelData.n; role: Typography.labelMedium; color: Colors.m3OnSecondaryContainer }
                        }
                    }
                }

                // --- Elevation ---
                Row {
                    spacing: 28
                    Repeater {
                        model: 6
                        Surface {
                            id: surf
                            required property int index
                            level: index
                            width: 120; height: 80; radius: Shapes.large
                            Label { anchors.centerIn: parent; text: "level " + surf.index; role: Typography.labelLarge }
                        }
                    }
                }

                // --- Cards ---
                Row {
                    spacing: 20
                    Repeater {
                        model: ["filled", "elevated", "outlined"]
                        Card {
                            id: card
                            required property string modelData
                            variant: modelData
                            width: 220; height: 110
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Label { text: card.modelData; role: Typography.titleMedium }
                                Label { text: "Card variant"; role: Typography.bodySmall; color: Colors.m3OnSurfaceVariant }
                            }
                        }
                    }
                }

                // --- Buttons ---
                Repeater {
                    model: ["s", "m", "l"]
                    Row {
                        id: rowB
                        required property string modelData
                        spacing: 16
                        Button { size: rowB.modelData; variant: "filled";   text: "Filled";   icon: "add" }
                        Button { size: rowB.modelData; variant: "tonal";    text: "Tonal" }
                        Button { size: rowB.modelData; variant: "outlined"; text: "Outlined" }
                        Button { size: rowB.modelData; variant: "text";     text: "Text" }
                        Button { size: rowB.modelData; variant: "filled";   text: "Toggle"; icon: "favorite"; checkable: true }
                        Button { size: rowB.modelData; variant: "tonal";    text: "Toggle"; checkable: true; checked: true }
                        Button { size: rowB.modelData; variant: "filled";   text: "Disabled"; enabled: false }
                    }
                }

                // --- Icon buttons ---
                Row {
                    spacing: 16
                    IconButton { size: "s"; variant: "filled";   icon: "settings" }
                    IconButton { size: "m"; variant: "tonal";    icon: "favorite"; checkable: true }
                    IconButton { size: "m"; variant: "outlined"; icon: "star";     checkable: true; checked: true }
                    IconButton { size: "s"; variant: "text";     icon: "search" }
                    IconButton { size: "l"; variant: "filled";   icon: "wallpaper"; checkable: true }
                }
            }
        }
    }
}
