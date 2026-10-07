import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root
    Component.onCompleted: {
        Theme.reducedMotion = Quickshell.env("MATERIAL_SHELL_REDUCED_MOTION") === "1";
        Theme.setMode(Settings.values.themeMode || "dark");
    }
    property string activePanel: ""
    property bool trayOverflowOpen: false
    property var trayOverflowScreen: Quickshell.screens[0] ?? null
    readonly property var systemTrayItems: Settings.values.showTray ? SystemTray.items.values : []
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
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
    function closePanels() { launcherOpen = false; wallpaperOpen = false; trayOverflowOpen = false; activePanel = ""; }
    function toggleTrayOverflow(screen) {
        if (trayOverflowOpen) { trayOverflowOpen = false; return; }
        closePanels();
        trayOverflowScreen = screen ?? activeScreen();
        trayOverflowOpen = true;
    }
    function togglePanel(name, screen) {
        if (activePanel === name) { activePanel = ""; return; }
        closePanels(); panelScreen = screen ?? activeScreen(); activePanel = name;
    }
    function openPanel(name) { closePanels(); panelScreen = activeScreen(); activePanel = name; }
    function openControlTab(name, screen) {
        if (name === "display") name = "quick";
        if (root.activePanel !== "control") { root.closePanels(); root.panelScreen = screen ?? root.activeScreen(); root.activePanel = "control"; }
        controlPanel.selectTab(name);
    }
    function toggleControlTab(name, screen) {
        if (name === "display") name = "quick";
        if (root.activePanel === "control" && controlPanel.tab === name) { root.activePanel = ""; return; }
        root.openControlTab(name, screen);
    }
    ControlPanel {
        id: controlPanel
        opened: root.activePanel === "control"
        screen: root.panelScreen
        sink: root.sink
        brightness: root.stats.brightness
        notificationService: notificationLoader.item
        playerService: mediaService
        captureActive: root.captureActive || captureDispatch.running
        onDismissed: root.activePanel = ""
        onPanelRequested: name => {
            if (name === "wallpaper") root.toggleWallpaper(root.panelScreen);
            else if (name === "media") root.openControlTab("media", root.panelScreen);
            else if (name === "cancel-capture") root.cancelCapture();
            else if (name.startsWith("capture:")) root.capture(name.slice(8));
            else root.openControlTab(name, root.panelScreen);
        }
    }
    SessionMenu { id: sessionPanel; opened: root.activePanel === "session"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    TrayMenu { id: trayMenu; opened: root.activePanel === "tray"; screen: root.panelScreen; onDismissed: root.activePanel = "" }
    TrayOverflow {
        id: trayOverflow
        opened: root.trayOverflowOpen
        screen: root.trayOverflowScreen
        items: root.systemTrayItems.length >= 3 ? root.systemTrayItems.slice(2) : []
        onDismissed: root.trayOverflowOpen = false
        onActivateItem: item => { root.trayOverflowOpen = false; item.activate(); }
        onOpenMenu: item => {
            root.trayOverflowOpen = false;
            root.panelScreen = root.trayOverflowScreen;
            trayMenu.openEntry(item.menu, item.title);
            root.activePanel = "tray";
        }
    }
    MediaService { id: mediaService }
    Loader {
        id: notificationLoader
        active: Quickshell.env("MATERIAL_SHELL_INDEPENDENT") === "1"
        sourceComponent: NotificationService { screen: root.activeScreen() }
    }
    property bool captureActive: false
    property var pendingCaptureCommand: []
    function capture(mode) {
        if (captureActive || captureDispatch.running || !["all", "monitor", "region"].includes(mode)) return;
        const command = [root.cliDir + "/material-screenshot", mode];
        if (mode === "monitor") {
            const output = panelScreen?.name || Hyprland.focusedMonitor?.name || "";
            if (!output) { osd.show("screenshot_monitor", "ディスプレイを特定できません", 0, root.activeScreen()); return; }
            command.push("--output", output);
        }
        controlPanel.message = "";
        captureActive = true;
        pendingCaptureCommand = command;
        closePanels();
        // Let the compositor process the layer-surface hide before grim samples the screen.
        captureHideDelay.restart();
    }
    function cancelCapture() {
        captureHideDelay.stop();
        pendingCaptureCommand = [];
        captureActive = false;
        captureLaunchTimeout.stop();
        captureTimeout.stop();
        controlPanel.message = "撮影をキャンセルしました";
        captureDispatch.command = ["/usr/bin/hyprctl", "eval", "hl.exec_cmd(" + JSON.stringify(root.cliDir + "/material-screenshot cancel") + ")"];
        captureDispatch.running = true;
    }
    Timer {
        id: captureHideDelay
        interval: 120
        onTriggered: {
            if (!root.captureActive || root.pendingCaptureCommand.length === 0) return;
            // Run the capture process outside Quickshell's layer client.
            captureDispatch.command = ["/usr/bin/hyprctl", "eval", "hl.exec_cmd(" + JSON.stringify(root.pendingCaptureCommand.join(" ")) + ")"];
            root.pendingCaptureCommand = [];
            captureLaunchTimeout.restart();
            captureDispatch.running = true;
        }
    }
    Timer {
        id: captureLaunchTimeout
        interval: 3000
        onTriggered: {
            if (root.captureActive && !captureDispatch.running) {
                root.captureActive = false;
                captureTimeout.stop();
                controlPanel.message = "撮影を開始できませんでした";
                osd.show("screenshot_monitor", "撮影を開始できませんでした", 0, root.activeScreen());
            }
        }
    }
    Timer {
        id: captureTimeout
        interval: 60000
        onTriggered: {
            root.cancelCapture();
            controlPanel.message = "時間切れのため撮影を終了しました";
            osd.show("screenshot_monitor", "スクリーンショットを終了しました", 0, root.activeScreen());
        }
    }
    Process {
        id: captureDispatch
        stderr: SplitParser { onRead: data => controlPanel.message = data.trim() }
        onExited: (code, status) => {
            if (code !== 0) {
                root.captureActive = false;
                captureLaunchTimeout.stop();
                captureTimeout.stop();
                osd.show("screenshot_monitor", "撮影を起動できませんでした", 0, root.activeScreen());
            }
        }
    }
    IpcHandler { target: "settings"; function toggle(): void { root.toggleControlTab("settings"); } function open(): void { root.openControlTab("settings"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "control" && controlPanel.tab === "settings",values:Settings.values,error:Settings.error,saving:Settings.saving}); } }
    IpcHandler { target: "control"; function toggle(): void { root.togglePanel("control"); } function open(): void { root.openControlTab("quick"); } function tab(name: string): void { root.openControlTab(name); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "control",tab:controlPanel.tab,radio:controlPanel.radio,error:controlPanel.error}); } }
    IpcHandler { target: "session"; function toggle(): void { root.togglePanel("session"); } function open(): void { root.openPanel("session"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "session",pending:sessionPanel.pendingAction,executing:sessionPanel.executing,error:sessionPanel.error}); } }
    IpcHandler { target: "clipboard"; function toggle(): void { root.toggleControlTab("clipboard"); } function open(): void { root.openControlTab("clipboard"); } function close(): void { root.activePanel = ""; } }
    IpcHandler { target: "notifications"; function toggle(): void { root.toggleControlTab("notifications"); } function open(): void { root.openControlTab("notifications"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({active:!!notificationLoader.item,count:notificationLoader.item?.history.length ?? 0,toasts:notificationLoader.item?.toasts.length ?? 0,dnd:Settings.values.dnd}); } }
    IpcHandler { target: "media"; function toggle(): void { root.toggleControlTab("media"); } function open(): void { root.openControlTab("media"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "control" && controlPanel.tab === "media",players:mediaService.players.length,connected:!!mediaService.player,playing:mediaService.player?.isPlaying ?? false}); } }
    IpcHandler { target: "audio"; function toggle(): void { root.toggleControlTab("audio"); } function open(): void { root.openControlTab("audio"); } function close(): void { root.activePanel = ""; } function status(): string { return JSON.stringify({visible:root.activePanel === "control" && controlPanel.tab === "audio",devices:controlPanel.devices.map(n => ({name:n.description || n.name,isSink:n.isSink})),output:controlPanel.output?.name,input:controlPanel.input?.name}); } }
    IpcHandler {
        target: "capture"
        function toggle(): void { root.toggleControlTab("capture"); }
        function open(): void { root.openControlTab("capture"); }
        function all(): void { root.capture("all"); }
        function monitor(): void { root.capture("monitor"); }
        function region(): void { root.capture("region"); }
        function cancel(): void { root.cancelCapture(); }
        function result(status: string, copied: string, filename: string): void {
            if (status === "started") { root.captureActive = true; captureLaunchTimeout.stop(); captureTimeout.restart(); return; }
            root.captureActive = false;
            captureLaunchTimeout.stop(); captureTimeout.stop();
            if (status === "saved") {
                controlPanel.message = copied === "true" ? "保存しました: " + filename : "保存しましたが、クリップボードへコピーできませんでした: " + filename;
                osd.show("screenshot_monitor", copied === "true" ? "スクリーンショットを保存しました" : "保存しました・コピーできません", 1, root.activeScreen());
            } else if (status === "error") {
                controlPanel.message = "撮影できませんでした";
                osd.show("screenshot_monitor", "撮影できませんでした", 0, root.activeScreen());
            } else if (status === "cancelled") controlPanel.message = "範囲選択をキャンセルしました";
        }
        function status(): string { return JSON.stringify({visible:root.activePanel === "control" && controlPanel.tab === "capture",busy:root.captureActive,launcherRunning:captureDispatch.running}); }
    }
    Process {
        id: settingsLoader
        command: [root.cliDir + "/material-settings", "get"]
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
        function onValuesChanged() { Theme.setMode(Settings.values.themeMode || "dark"); }
        function onSaveRequested(data) { settingsSaver.command = [root.cliDir + "/material-settings", "set", JSON.stringify(data)]; settingsSaver.running = true; }
    }
    Process {
        id: settingsSaver
        stdout: SplitParser { onRead: data => Settings.values = JSON.parse(data) }
        stderr: SplitParser { onRead: data => Settings.error = data }
        onExited: (code, status) => { if (code !== 0 && !Settings.error) Settings.error = "保存できませんでした"; Settings.saving = false; }
    }
    Osd { id: osd }
    property var pendingMediaOsdPlayer: null
    property string lastMediaOsdKey: ""
    property double lastMediaOsdAt: 0
    Connections {
        target: mediaService.player
        function onPostTrackChanged() {
            root.pendingMediaOsdPlayer = mediaService.player;
            mediaOsdDebounce.restart();
        }
    }
    Timer {
        id: mediaOsdDebounce
        interval: Theme.mediaOsdDebounce
        onTriggered: {
            const player = root.pendingMediaOsdPlayer;
            root.pendingMediaOsdPlayer = null;
            if (!player || player !== mediaService.player || !player.isPlaying) return;
            const title = String(player.trackTitle || "").trim();
            const artist = String(player.trackArtist || "").trim();
            if (!title || !artist) return;
            const key = JSON.stringify([player.dbusName, title, artist]);
            const now = Date.now();
            if (key === root.lastMediaOsdKey && now - root.lastMediaOsdAt < Theme.mediaOsdDuration) return;
            root.lastMediaOsdKey = key;
            root.lastMediaOsdAt = now;
            osd.showTrack(player, root.activeScreen());
        }
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
        onMessageRequested: (text, failed) => osd.showMessage(text, failed, root.wallpaperScreen)
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
    IpcHandler {
        target: "theme"
        function status(): string { return JSON.stringify({path: Theme.palettePath, mode: Theme.mode, schemes: Object.keys(Theme.schemes), colors: Theme.palette}); }
    }
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    FileView {
        id: statsFile
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/" + (Quickshell.env("UID") || "1000")) + "/material-shell/stats.json"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const next = JSON.parse(text());
                if (root.stats.brightness != null && next.brightness != null && root.stats.brightness !== next.brightness)
                    osd.show(root.brightnessIcon(next.brightness), "明るさ " + next.brightness + "%", next.brightness / 100, root.activeScreen());
                root.stats = next;
            } catch (error) { console.warn("Invalid stats:", error); }
        }
    }
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
                id: barSurface
                anchors.fill: parent
                color: Theme.surfaceContainer
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) root.openControlTab("quick", bar.screen);
                    }
                }
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
                                id: workspaceButton
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
                                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressed: workspaceButton.focus = false; onClicked: workspaceButton.activate() }
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
                        onClicked: root.toggleControlTab("media", bar.screen)
                        TextMetrics { id: metrics; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; font.weight: Font.Medium; text: mediaService.player?.trackTitle || mediaService.player?.identity || ""; elide: Text.ElideRight; elideWidth: Theme.mediaBarWidth }
                    }
                }
                Chip {
                    anchors.centerIn: parent
                    label: Qt.formatDateTime(clock.date, Settings.values.clock24 ? "yyyy/MM/dd HH:mm" : "yyyy/MM/dd AP h:mm")
                    foreground: Theme.surfaceText
                    hint: Qt.formatDateTime(clock.date, "yyyy年M月d日 dddd")
                }
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.barSidePadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Chip { visible: Settings.values.showNetwork && bar.width > 1500; icon: root.stats.networkIcon; label: root.stats.network; interactive: true; hint: "ネットワーク接続"; onClicked: root.toggleControlTab("network", bar.screen) }
                    Chip {
                        icon: root.volumeIcon(root.sink?.audio?.volume ?? 0, root.sink?.audio?.muted ?? false)
                        label: root.sink?.audio ? (root.sink.audio.muted ? "ミュート" : Math.round(root.sink.audio.volume * 100) + "%") : "—"
                        interactive: true
                        hint: "オーディオ設定・スクロールで音量調整"
                        onClicked: root.toggleControlTab("audio", bar.screen)
                        onScrolled: delta => { if (!root.sink?.audio) return; root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05))); }
                    }
                    Chip {
                        visible: root.stats.battery !== null
                        icon: root.batteryIcon(root.stats.battery?.percentage ?? 0, root.stats.battery?.charging ?? false)
                        label: (root.stats.battery?.percentage ?? 0) + "%"
                        hint: "バッテリー残量"
                        foreground: (root.stats.battery?.percentage ?? 100) < 20 ? Theme.error : Theme.surfaceVariantText
                    }
                    Chip { visible: Settings.values.showCpu && bar.width > 1700; icon: "memory"; label: root.stats.cpu + "%"; hint: "CPU使用率" }
                    Chip { visible: Settings.values.showMemory && bar.width > 1700; icon: "storage"; label: root.stats.memory + "%"; hint: "メモリ使用率" }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; Layout.leftMargin: Theme.space4; Layout.rightMargin: Theme.space4; color: Theme.outlineVariant }
                    Repeater {
                        model: bar.width > 1100 ? (root.systemTrayItems.length >= 3 ? root.systemTrayItems.slice(0, 2) : root.systemTrayItems) : []
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
                            readonly property bool inputMethodTrayItem: String(modelData.id || "").toLowerCase().includes("fcitx") || String(modelData.title || "").toLowerCase().includes("input method")
                            Image { id: trayImage; anchors.centerIn: parent; width: Theme.barIconSize; height: width; sourceSize.width: width; sourceSize.height: height; source: trayButton.inputMethodTrayItem ? "" : trayButton.modelData.icon }
                            MaterialIcon { anchors.centerIn: parent; name: "keyboard"; size: Theme.barIconSize; visible: trayButton.inputMethodTrayItem }
                            MaterialIcon { anchors.centerIn: parent; name: "apps"; size: Theme.barIconSize; visible: !trayButton.inputMethodTrayItem && trayImage.status !== Image.Ready }
                            function showMenu() { if (!modelData.hasMenu) return; const itemRightX = trayButton.mapToItem(barSurface, trayButton.width, 0).x; root.closePanels(); root.panelScreen = bar.screen; trayMenu.openEntry(modelData.menu, modelData.title, itemRightX); root.activePanel = "tray"; }
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
                    Chip {
                        visible: Settings.values.showTray && bar.width > 1100 && root.systemTrayItems.length >= 3
                        icon: "apps"
                        label: "+" + (root.systemTrayItems.length - 2)
                        interactive: true
                        hint: "追加のシステムトレイ項目 " + (root.systemTrayItems.length - 2) + " 件"
                        onClicked: root.toggleTrayOverflow(bar.screen)
                    }
                    Rectangle { visible: Settings.values.showTray && bar.width > 1100 && root.systemTrayItems.length > 0; Layout.preferredWidth: 1; Layout.preferredHeight: 16; Layout.leftMargin: Theme.space4; Layout.rightMargin: Theme.space4; color: Theme.outlineVariant }
                    Chip { icon: Settings.values.dnd ? "notifications_off" : "notifications"; interactive: true; hint: "通知"; onClicked: root.toggleControlTab("notifications", bar.screen) }
                    Chip { visible: bar.width > 1400; icon: "content_paste"; interactive: true; hint: "クリップボード"; onClicked: root.toggleControlTab("clipboard", bar.screen) }
                    Chip { visible: bar.width > 1400; icon: "screenshot_monitor"; interactive: true; hint: "スクリーンショット"; onClicked: root.toggleControlTab("capture", bar.screen) }
                    Chip { visible: bar.width > 1100; icon: "wallpaper"; interactive: true; hint: "壁紙と配色"; onClicked: root.toggleWallpaper(bar.screen) }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; Layout.leftMargin: Theme.space4; Layout.rightMargin: Theme.space4; color: Theme.outlineVariant }
                    Chip { icon: "tune"; interactive: true; hint: "コントロールパネル"; onClicked: root.toggleControlTab("quick", bar.screen) }
                    Chip { icon: "settings"; interactive: true; hint: "設定"; onClicked: root.toggleControlTab("settings", bar.screen) }
                    Chip { icon: "power_settings_new"; interactive: true; hint: "セッションメニュー"; onClicked: root.togglePanel("session", bar.screen) }
                }
            }
        }
    }
}
