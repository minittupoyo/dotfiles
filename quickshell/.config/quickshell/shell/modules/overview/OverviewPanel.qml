import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../components"
import "../../tokens"

// オーバービューの中身: フォーカス中のモニターに割り当てられたワークスペースを横に並べる。
// 操作: ← → か 1〜 で選ぶ、Enter で移動、Esc で閉じる。カードのクリックで移動、ウィンドウをクリックでそこへ、
// ウィンドウを別のカードへドラッグで、そのワークスペースへ移す。
Item {
    id: root

    signal closeRequested()

    focus: true
    implicitHeight: row.height

    property var monitor: null            // HyprlandMonitor (開いた時点のフォーカス中)
    property var clients: []              // このモニターのウィンドウ
    property int current: 0               // 選択中のカードの位置
    property int dropIndex: -1            // ドラッグ中のウィンドウが乗っているカードの位置

    readonly property int gap: 12
    readonly property var workspaces: {
        if (!monitor)
            return [];
        return Hyprland.workspaces.values
            .filter(w => w.monitor && w.monitor.name === monitor.name && w.id > 0)
            .sort((a, b) => a.id - b.id);
    }
    readonly property int count: Math.max(1, workspaces.length)

    // モニターの論理サイズ (スケールを考慮)
    readonly property real monW: monitor ? monitor.width / Math.max(0.1, monitor.scale) : 2560
    readonly property real monH: monitor ? monitor.height / Math.max(0.1, monitor.scale) : 1440
    readonly property real cardW: (width - (count - 1) * gap) / count
    readonly property real screenW: cardW - 16
    readonly property real screenH: screenW * monH / monW

    function wsIndex(id) {
        return workspaces.findIndex(w => w.id === id);
    }
    function countOn(id) {
        return clients.filter(c => c.ws === id).length;
    }

    function open() {
        monitor = Hyprland.focusedMonitor;
        const i = monitor ? wsIndex(monitor.activeWorkspace ? monitor.activeWorkspace.id : -1) : 0;
        current = Math.max(0, i);
        forceActiveFocus();
        clientsProc.running = true;
    }

    function go(i) {
        const w = workspaces[i];
        if (!w)
            return;
        closeRequested();
        w.activate();
    }

    function focusWindow(c) {
        closeRequested();
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "address:' + c.address + '" })']);
    }

    function moveWindow(c, i) {
        const w = workspaces[i];
        if (!w || w.id === c.ws)
            return;
        Quickshell.execDetached(["hyprctl", "dispatch",
            'hl.dsp.window.move({ window = "address:' + c.address + '", workspace = ' + w.id + ', follow = false })']);
        // 画面上はすぐ移す (Hyprland 側は少し遅れて追いつく)
        clients = clients.map(x => x.address === c.address ? Object.assign({}, x, { ws: w.id }) : x);
    }

    function _build(list) {
        const mon = monitor;
        if (!mon)
            return [];
        const byAddr = {};
        for (const t of Hyprland.toplevels.values) {
            const a = ("" + (t.lastIpcObject && t.lastIpcObject.address ? t.lastIpcObject.address : t.address)).replace(/^0x/, "").toLowerCase();
            byAddr[a] = t;
        }
        return list
            .filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id > 0 && c.monitor === mon.id)
            .map(c => ({
                address: c.address,
                appClass: c.class,
                title: c.title,
                ws: c.workspace.id,
                x: c.at[0] - mon.x,
                y: c.at[1] - mon.y,
                w: c.size[0],
                h: c.size[1],
                toplevel: byAddr[("" + c.address).replace(/^0x/, "").toLowerCase()] || null
            }));
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clients = root._build(JSON.parse(text));
                } catch (e) {
                    console.warn("Overview: bad clients json", e);
                }
            }
        }
    }

    Keys.onEscapePressed: closeRequested()
    Keys.onLeftPressed: current = Math.max(0, current - 1)
    Keys.onRightPressed: current = Math.min(workspaces.length - 1, current + 1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            go(current);
            event.accepted = true;
            return;
        }
        const i = event.key - Qt.Key_1;
        if (i >= 0 && i < workspaces.length) {
            go(i);
            event.accepted = true;
        }
    }

    // カード
    Row {
        id: row
        spacing: root.gap

        Repeater {
            model: root.workspaces

            OverviewWorkspace {
                required property var modelData
                required property int index
                ws: modelData
                screenW: root.screenW
                screenH: root.screenH
                selected: root.current === index
                dropTarget: root.dropIndex === index
                windowCount: root.countOn(modelData.id)
                onClicked: root.go(index)
            }
        }
    }

    // ウィンドウ (カードより手前。ドラッグでカードの外へ出せる)
    Item {
        anchors.fill: parent

        Repeater {
            model: ScriptModel {
                values: root.clients
                objectProp: "address"
            }

            OverviewWindow {
                id: w
                required property var modelData
                client: modelData

                readonly property int idx: root.wsIndex(modelData.ws)
                visible: idx >= 0

                homeX: idx * (root.cardW + root.gap) + 8 + modelData.x / root.monW * root.screenW
                homeY: 8 + modelData.y / root.monH * root.screenH
                homeW: Math.max(8, modelData.w / root.monW * root.screenW)
                homeH: Math.max(8, modelData.h / root.monH * root.screenH)

                function cardAt(cx) {
                    const i = Math.floor(cx / (root.cardW + root.gap));
                    return i >= 0 && i < root.workspaces.length ? i : -1;
                }
                onDragMoved: (cx, cy) => root.dropIndex = cardAt(cx)
                onDropped: (cx, cy) => {
                    const i = cardAt(cx);
                    root.dropIndex = -1;
                    if (i >= 0)
                        root.moveWindow(modelData, i);
                }
                onClicked: root.focusWindow(modelData)
            }
        }
    }
}
