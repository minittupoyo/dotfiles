import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "配色"

        SettingRow {
            title: "ダークモード"
            description: "オフにするとライトの配色になります。壁紙から配色を作り直します"
            Switch {
                checked: Settings.darkMode
                onToggled: {
                    Settings.set("darkMode", !checked);
                    Wallpaper.reapply();
                }
            }
        }
        SettingRow {
            title: "配色のスキーム"
            description: "matugen のスキーム。Expressive が M3 Expressive の既定です"
            stacked: true
            ChoiceChips {
                Layout.fillWidth: true
                options: [
                    { label: "Expressive", value: "scheme-expressive" },
                    { label: "Tonal Spot", value: "scheme-tonal-spot" },
                    { label: "Vibrant", value: "scheme-vibrant" },
                    { label: "Fidelity", value: "scheme-fidelity" },
                    { label: "Content", value: "scheme-content" },
                    { label: "Fruit Salad", value: "scheme-fruit-salad" },
                    { label: "Rainbow", value: "scheme-rainbow" },
                    { label: "Neutral", value: "scheme-neutral" },
                    { label: "Monochrome", value: "scheme-monochrome" }
                ]
                current: Settings.scheme
                onPicked: v => {
                    Settings.set("scheme", v);
                    Wallpaper.reapply();
                }
            }
        }
    }

    SettingGroup {
        Layout.fillWidth: true
        title: "壁紙"

        SettingRow {
            title: "壁紙のディレクトリ"
            description: wallpaperField.invalid ? "ディレクトリが見つかりません" : "Enter で決定。空にすると ~/Pictures/Wallpapers に戻ります (" + Wallpaper.count + " 枚)"
            stacked: true

            TextField {
                id: wallpaperField
                Layout.fillWidth: true
                text: Settings.wallpaperDir
                placeholder: "~/Pictures/Wallpapers"
                onTextChanged: invalid = false
                onAccepted: t => {
                    let path = t.trim();
                    if (path.startsWith("~/"))
                        path = Quickshell.env("HOME") + path.slice(1);
                    if (path === "") {
                        Settings.set("wallpaperDir", "");
                    } else {
                        dirCheck.path = path;
                        dirCheck.running = true;
                    }
                }

                Process {
                    id: dirCheck
                    property string path
                    command: ["test", "-d", path]
                    onExited: code => {
                        if (code === 0)
                            Settings.set("wallpaperDir", path);
                        else
                            wallpaperField.invalid = true;
                    }
                }
            }
        }
    }
}
