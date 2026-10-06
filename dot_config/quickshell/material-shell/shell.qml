import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root
    Component.onCompleted: Theme.reducedMotion = Quickshell.env("MATERIAL_SHELL_REDUCED_MOTION") === "1"
    property string activePanel: ""
    property var panelScreen: Quickshell.screens[0] ?? null
    function volumeIcon(volume, muted) {
        if (muted) return "volume_off";
        if (volume <= 0.01) return "volume_mute";
        if (volume <= 0.5) return "volume_down";
        return "volume_up";
    }
    function brightnessIcon(percentage) {
        if (percentage <= 25) return "brightness_low";
        if (percentage <= 70) return "brightness_medium";
        return "brightness_high";
    }
    function batteryIcon(percentage, charging) {
        const level = Math.max(0, Math.min(6, Math.round(percentage / 100 * 6)));
        if (!charging) return "battery_" + level + "_bar";
        if (percentage <= 20) return "battery_charging_20";
        if (percentage <= 30) return "battery_charging_30";
        if (percentage <= 50) return "battery_charging_50";
        if (percentage <= 60) return "battery_charging_60";
        if (percentage <= 80) return "battery_charging_80";
        if (percentage <= 90) return "battery_charging_90";
        return "battery_charging_full";
    }
    function closePanels() { launcherOpen = false; wallpaperOpen = false; activePanel = ""; }
    function togglePanel(name, screen) {
        if (activePanel === name) { activePanel = ""; return; }
        closePanels(); panelScreen = screen ?? activeScreen(); activePanel = name;
    }
    function openPanel(name) { closePanels(); panelScreen = activeScreen(); activePanel = name; }
    SettingsPanel { opened: root.activePanel === "settings"; screen: root.panelScreen; onDismissed: root.activePanel = ""; onWallpaperRequested: root.toggleWallpaper(root.panelScreen); onPanelRequested: name => root.togglePanel(name, root.panelScreen) }
    SessionMenu { id: sessionPanel; opened: root.activePanel === "session"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    ClipboardPanel { opened: root.activePanel === "clipboard"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    TrayMenu { id: trayMenu; opened: root.activePanel === "tray"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    NotificationCenter { opened: root.activePanel === "notifications"; screen: root.panelScreen; service: notificationLoader.item; onDismissed: root.activePanel = "" }
    MediaService { id: mediaService }
    AudioPanel { id: audioPanel; opened: root.activePanel === "audio"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    CapturePanel { id: capturePanel; opened: root.activePanel === "capture"; screen: root.panelScreen; onDismissed: root.activePanel = ""; onCaptureRequested: mode => root.capture(mode) }
    Loader {
        id: notificationLoader
        active: Quickshell.env("MATERIAL_SHELL_INDEPENDENT") === "1"
        sourceComponent: NotificationService { screen: root.activeScreen() }
    }
    function capture(mode) {
        if (captureProcess.running || captureDelay.running || !["all", "region"].includes(mode)) return;
        closePanels();
        captureProcess.command = ["python3", Quickshell.shellDir + "/capture.py", mode];
        capturePanel.message = "";
        captureDelay.start();
    }
    Timer { id: captureDelay; interval: 250; onTriggered: captureProcess.running = true }
    Process {
        id: captureProcess
        stdout: SplitParser { onRead: data => { capturePanel.message = "保存しました: " + data; osd.show("screenshot_monitor", "画像を保存しました", 1, root.activeScreen()); } }
        stderr: SplitParser { onRead: data => capturePanel.message = "撮影できませんでした: " + data }
    }
    IpcHandler { target: "settings"; function toggle(): void { root.togglePanel("settings"); } function open(): void { root.openPanel("settings"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "settings",values:Settings.values,error:Settings.error,saving:Settings.saving}); } }
    IpcHandler { target: "session"; function toggle(): void { root.togglePanel("session"); } function open(): void { root.openPanel("session"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "session",pending:sessionPanel.pendingAction,executing:sessionPanel.executing,error:sessionPanel.error}); } }
    IpcHandler { target: "clipboard"; function toggle(): void { root.togglePanel("clipboard"); } function close(): void { root.activePanel = ""; } }
    IpcHandler { target: "notifications"; function toggle(): void { root.togglePanel("notifications"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({active:!!notificationLoader.item,count:notificationLoader.item?.history.length ?? 0,toasts:notificationLoader.item?.toasts.length ?? 0,dnd:Settings.values.dnd}); } }
    IpcHandler { target: "media"; function toggle(): void { root.togglePanel("media"); } function open(): void { root.openPanel("media"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "media",players:mediaService.players.length,connected:!!mediaService.player,playing:mediaService.player?.isPlaying ?? false}); } }
    IpcHandler { target: "audio"; function toggle(): void { root.togglePanel("audio"); } function open(): void { root.openPanel("audio"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible: audioPanel.visible, devices: audioPanel.devices.map(n => ({name:n.description || n.name,isSink:n.isSink})),output:audioPanel.output?.name,input:audioPanel.input?.name}); } }
    IpcHandler { target: "capture"; function toggle(): void { root.togglePanel("capture"); } function all(): void { root.capture("all"); } function region(): void { root.capture("region"); } }
    Process {
        id: settingsLoader
        command: ["python3", Quickshell.shellDir + "/settings.py", "get"]
        running: true
        stdout: SplitParser { onRead: data => { try { Settings.values = JSON.parse(data); Settings.error = ""; } catch (error) { Settings.error = "設定を読み込めません"; } } }
        stderr: SplitParser { onRead: data => Settings.error = data }
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/material-shell/settings.json"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: { reload(); settingsLoader.running = true; }
    }
    Connections {
        target: Settings
        function onSaveRequested(data) { settingsSaver.command = ["python3", Quickshell.shellDir + "/settings.py", "set", JSON.stringify(data)]; settingsSaver.running = true; }
    }
    Process {
        id: settingsSaver
        stdout: SplitParser { onRead: data => Settings.values = JSON.parse(data) }
        stderr: SplitParser { onRead: data => Settings.error = data }
        onExited: (code, status) => { if (code !== 0 && !Settings.error) Settings.error = "保存できませんでした"; Settings.saving = false; }
    }
    Process {
        id: backgroundServices
        command: ["python3", Quickshell.shellDir + "/services.py"]
        running: Quickshell.env("MATERIAL_SHELL_INDEPENDENT") === "1"
        onExited: servicesRestart.restart()
    }
    Timer { id: servicesRestart; interval: 5000; onTriggered: backgroundServices.running = Quickshell.env("MATERIAL_SHELL_INDEPENDENT") === "1" }
    Osd { id: osd }
    Connections {
        target: mediaService.player
        function onPostTrackChanged() { osd.showTrack(mediaService.player, root.activeScreen()); }
    }
    IpcHandler {
        target: "osd"
        function volume(percentage: int): void { osd.show(root.volumeIcon(percentage / 100, false), "音量 " + percentage + "%", percentage / 100, root.activeScreen()); }
        function brightness(percentage: int): void { osd.show(root.brightnessIcon(percentage), "明るさ " + percentage + "%", percentage / 100, root.activeScreen()); }
        function status(): string { return JSON.stringify({visible:osd.visible,value:osd.value,screen:osd.screen?.name ?? ""}); }
    }
    property real lastVolume: -1
    property var lastMuted: null
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { const volume = root.sink.audio.volume; if (root.lastVolume >= 0 && root.lastVolume !== volume) osd.show(root.volumeIcon(volume, root.sink.audio.muted), "音量 " + Math.round(volume * 100) + "%", volume, root.activeScreen()); root.lastVolume = volume; }
        function onMutedChanged() { const muted = root.sink.audio.muted; if (root.lastMuted !== null && root.lastMuted !== muted) osd.show(root.volumeIcon(root.sink?.audio?.volume ?? 0, muted), muted ? "ミュート" : "ミュート解除", muted ? 0 : root.sink.audio.volume, root.activeScreen()); root.lastMuted = muted; }
    }
    readonly property var audio: root.sink?.audio ?? null
    onAudioChanged: { lastVolume = audio?.volume ?? -1; lastMuted = audio?.muted ?? null; }
    property var stats: ({cpu: 0, memory: 0, network: "確認中", networkIcon: "wifi_off", battery: null})
    property bool wallpaperOpen: false
    property var wallpaperScreen: Quickshell.screens[0] ?? null
    property bool launcherOpen: false
    property var launcherScreen: Quickshell.screens[0] ?? null
    function activeScreen() {
        return Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }
    function toggleLauncher(screen) {
        if (launcherOpen) { launcherOpen = false; return; }
        wallpaperOpen = false; activePanel = "";
        launcherScreen = screen ?? activeScreen();
        launcherOpen = true;
    }
    function toggleWallpaper(screen) {
        if (wallpaperOpen) { wallpaperOpen = false; return; }
        launcherOpen = false; activePanel = "";
        wallpaperScreen = screen ?? activeScreen();
        wallpaperOpen = true;
    }
    WallpaperSelector {
        id: wallpaperSelector
        opened: root.wallpaperOpen
        screen: root.wallpaperScreen
        onDismissed: root.wallpaperOpen = false
    }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggleWallpaper(root.activeScreen()); }
        function open(): void { root.closePanels(); root.wallpaperScreen = root.activeScreen(); root.wallpaperOpen = true; }
        function close(): void { root.wallpaperOpen = false; }
        function search(query: string): void { wallpaperSelector.setQuery(query); }
        function folder(path: string): void { wallpaperSelector.refresh(path); }
        function apply(): void { wallpaperSelector.applySelection(); }
        function status(): string { return wallpaperSelector.status(); }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (!Quickshell.screens.includes(root.panelScreen)) root.activePanel = "";
            if (!Quickshell.screens.includes(root.wallpaperScreen)) root.wallpaperOpen = false;
            if (!Quickshell.screens.includes(root.launcherScreen)) {
                root.launcherOpen = false;
                root.launcherScreen = Quickshell.screens[0] ?? null;
            }
        }
    }
    Launcher {
        id: launcher
        opened: root.launcherOpen
        screen: root.launcherScreen
        onDismissed: root.launcherOpen = false
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher(root.activeScreen()); }
        function open(): void {
            root.closePanels();
            root.launcherScreen = root.activeScreen();
            root.launcherOpen = true;
        }
        function close(): void { root.launcherOpen = false; }
        function search(query: string): void { launcher.setQuery(query); }
        function status(): string { return launcher.status(); }
    }
    FileView {
        id: paletteFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/material-shell/palette.json"
        watchChanges: true
        preload: true
        printErrors: false
        Component.onCompleted: Theme.palettePath = path
        onFileChanged: reload()
        onLoaded: Theme.acceptPalette(text())
    }
    Process {
        // Monitor the independent awww backend and wallpaper palette.
        id: paletteWatcher
        command: ["python3", Quickshell.shellDir + "/palette.py", "--watch"]
        running: true
        onExited: paletteRestart.restart()
    }
    Timer { id: paletteRestart; interval: 5000; onTriggered: paletteWatcher.running = true }
    IpcHandler {
        target: "theme"
        function status(): string { return JSON.stringify({path: Theme.palettePath, colors: Theme.palette}); }
    }
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Process {
        id: sampler
        command: ["python3", Quickshell.shellDir + "/stats.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try { const next = JSON.parse(data); if (root.stats.brightness != null && next.brightness != null && root.stats.brightness !== next.brightness) osd.show(root.brightnessIcon(next.brightness), "明るさ " + next.brightness + "%", next.brightness / 100, root.activeScreen()); root.stats = next; } catch (error) { console.warn("Invalid stats:", error); }
            }
        }
        onExited: restart.restart()
    }
    Timer { id: restart; interval: 5000; onTriggered: sampler.running = true }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            color: "transparent"
            readonly property var monitor: Hyprland.monitorFor(screen)
            Rectangle {
                anchors.fill: parent
                color: Theme.surfaceContainer
                RowLayout {
                    id: left
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.barSidePadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Chip {
                        icon: "apps"
                        horizontalPadding: Theme.launcherIconPadding
                        interactive: true
                        hint: "アプリランチャー"
                        onClicked: root.toggleLauncher(bar.screen)
                    }
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.leftMargin: Theme.separatorPadding
                        Layout.rightMargin: Theme.separatorPadding
                        color: Theme.outlineVariant
                    }
                    RowLayout {
                        spacing: Theme.workspaceSpacing
                        Repeater {
                            model: Settings.values.workspaces
                            Rectangle {
                                required property int index
                                readonly property int workspaceId: index + 1
                                readonly property bool selected: Number(bar.monitor?.activeWorkspace?.id ?? -1) === workspaceId || (bar.screen?.name === Hyprland.focusedMonitor?.name && Number(Hyprland.focusedWorkspace?.id ?? -1) === workspaceId)
                                readonly property bool occupied: Hyprland.workspaces.values.some(w => Number(w.id) === workspaceId)
                                implicitWidth: Theme.controlHeight
                                implicitHeight: Theme.controlHeight
                                radius: area.pressed ? Theme.pressedRadius : selected ? Theme.shapeMedium : Theme.shapeFull
                                Behavior on radius { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
                                color: selected ? Theme.primary : "transparent"
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: area.pressed ? Theme.pressedState : area.containsMouse ? Theme.hoverState : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
                                }
                                border.width: activeFocus ? 1 : 0
                                border.color: Theme.primary
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: "ワークスペース " + workspaceId
                                Accessible.description: selected ? "選択中" : ""
                                function activate() { Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaceId + " })"); }
                                Keys.onReturnPressed: activate()
                                Keys.onSpacePressed: activate()
                                Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
                                Text {
                                    anchors.centerIn: parent
                                    text: workspaceId
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.labelSize
                                    font.weight: Font.DemiBold
                                    color: parent.selected ? Theme.primaryText : parent.occupied ? Theme.surfaceText : Theme.surfaceVariantText
                                }
                                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activate() }
                            }
                        }
                    }
                    Text {
                        visible: Settings.values.showWindowTitle && bar.width > 1350
                        text: Hyprland.activeToplevel?.title ?? "デスクトップ"
                        color: Theme.surfaceVariantText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelSize
                        elide: Text.ElideRight
                        Layout.preferredWidth: Math.min(300, Math.max(0, bar.width / 2 - left.x - 430))
                        Layout.leftMargin: Theme.space16
                    }
                    Chip {
                        id: mediaChip
                        visible: !!mediaService.player && bar.width > 1100
                        icon: "music_note"
                        label: bar.width > 1700 ? metrics.elidedText : ""
                        interactive: true
                        hint: [mediaService.player?.trackTitle || mediaService.player?.identity, mediaService.player?.trackArtist].filter(Boolean).join(" · ")
                        onClicked: root.togglePanel("media", bar.screen)
                        NowPlaying {
                            anchor.item: mediaChip.visible ? mediaChip : left
                            service: mediaService
                            opened: root.activePanel === "media" && root.panelScreen === bar.screen
                            onDismissed: root.activePanel = ""
                        }
                        TextMetrics { id: metrics; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; font.weight: Font.Medium; text: mediaService.player?.trackTitle || mediaService.player?.identity || ""; elide: Text.ElideRight; elideWidth: Theme.mediaBarWidth }
                    }
                }
                Chip {
                    anchors.centerIn: parent
                    icon: "calendar_today"
                    label: Qt.formatDateTime(clock.date, Settings.values.clock24 ? "MM/dd ddd  HH:mm" : "MM/dd ddd  h:mm AP")
                    foreground: Theme.surfaceText
                    hint: Qt.formatDateTime(clock.date, "yyyy年M月d日 dddd")
                }
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.barSidePadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Chip { visible: Settings.values.showCpu && bar.width > 1700; icon: "memory"; label: root.stats.cpu + "%"; hint: "CPU使用率" }
                    Chip { visible: Settings.values.showMemory && bar.width > 1700; icon: "storage"; label: root.stats.memory + "%"; hint: "メモリ使用率" }
                    Rectangle { visible: (Settings.values.showCpu || Settings.values.showMemory) && bar.width > 1700; Layout.preferredWidth: 1; Layout.preferredHeight: 16; color: Theme.outlineVariant }
                    Chip { visible: Settings.values.showNetwork && bar.width > 1500; icon: root.stats.networkIcon; label: root.stats.network; hint: "ネットワーク接続" }
                    Chip {
                        icon: root.volumeIcon(root.sink?.audio?.volume ?? 0, root.sink?.audio?.muted ?? false)
                        label: root.sink?.audio ? (root.sink.audio.muted ? "ミュート" : Math.round(root.sink.audio.volume * 100) + "%") : "—"
                        interactive: true
                        hint: "オーディオ設定・スクロールで音量調整"
                        onClicked: root.togglePanel("audio", bar.screen)
                        onScrolled: delta => { if (!root.sink?.audio) return; root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05))); }
                    }
                    Chip {
                        visible: root.stats.battery !== null
                        icon: root.batteryIcon(root.stats.battery?.percentage ?? 0, root.stats.battery?.charging ?? false)
                        label: (root.stats.battery?.percentage ?? 0) + "%"
                        hint: "バッテリー残量"
                        foreground: (root.stats.battery?.percentage ?? 100) < 20 ? Theme.error : Theme.surfaceVariantText
                    }
                    Chip { visible: bar.width > 1100; icon: "wallpaper"; interactive: true; hint: "壁紙を選択"; onClicked: root.toggleWallpaper(bar.screen) }
                    Repeater {
                        model: Settings.values.showTray && bar.width > 1100 ? SystemTray.items.values : []
                        Rectangle {
                            id: trayButton
                            required property var modelData
                            implicitWidth: Theme.controlHeight
                            implicitHeight: Theme.controlHeight
                            radius: Theme.shapeFull
                            color: trayArea.pressed ? Theme.pressedState : trayArea.containsMouse ? Theme.hoverState : "transparent"
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id
                            Image { id: trayImage; anchors.centerIn: parent; width: Theme.barIconSize; height: width; sourceSize.width: width; sourceSize.height: height; source: trayButton.modelData.icon }
                            MaterialIcon { anchors.centerIn: parent; name: "apps"; size: Theme.barIconSize; visible: trayImage.status !== Image.Ready }
                            function showMenu() { if (!modelData.hasMenu) return; root.closePanels(); root.panelScreen = bar.screen; trayMenu.openEntry(modelData.menu, modelData.title); root.activePanel = "tray"; }
                            Keys.onReturnPressed: { if (modelData.onlyMenu) showMenu(); else modelData.activate(); }
                            Keys.onSpacePressed: showMenu()
                            MouseArea {
                                id: trayArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => { if (mouse.button === Qt.RightButton || trayButton.modelData.onlyMenu) trayButton.showMenu(); else if (mouse.button === Qt.MiddleButton) trayButton.modelData.secondaryActivate(); else trayButton.modelData.activate(); }
                                onWheel: wheel => trayButton.modelData.scroll(wheel.angleDelta.y, false)
                            }
                            BarTooltip { target: trayButton; text: trayButton.modelData.tooltipTitle || trayButton.modelData.title; active: trayArea.containsMouse }
                        }
                    }
                    Chip { icon: Settings.values.dnd ? "notifications_off" : "notifications"; interactive: true; hint: "通知"; onClicked: root.togglePanel("notifications", bar.screen) }
                    Chip { visible: bar.width > 1400; icon: "content_paste"; interactive: true; hint: "クリップボード"; onClicked: root.togglePanel("clipboard", bar.screen) }
                    Chip { visible: bar.width > 1400; icon: "screenshot_monitor"; interactive: true; hint: "スクリーンショット"; onClicked: root.togglePanel("capture", bar.screen) }
                    Chip { icon: "settings"; interactive: true; hint: "設定"; onClicked: root.togglePanel("settings", bar.screen) }
                    Chip { icon: "power_settings_new"; interactive: true; hint: "セッションメニュー"; onClicked: root.togglePanel("session", bar.screen) }
                }
            }
        }
    }
}
