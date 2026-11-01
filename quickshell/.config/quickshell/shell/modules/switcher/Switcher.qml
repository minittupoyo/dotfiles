import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../services"

// Alt+Tab のウィンドウ切り替え。全モニター・全ワークスペースのウィンドウを、使った順 (MRU) に並べて、
// フォーカス中のモニターに出す。Hyprland 側の設定 (binds.lua) が次の IPC を呼ぶ:
//   qs ipc call switcher next | prev | commit | cancel
// Alt を押している間は Hyprland が「switcher」サブマップに入り、Tab で next、Alt を離すと commit を呼ぶ。
// サブマップの中は、ほかのバインドが効かないので、確定・キャンセル・タイムアウトのどれでも、必ずサブマップを抜ける。
Scope {
    id: root

    property bool shown: false
    property var windows: []           // HyprlandToplevel の配列 (開いた時点のスナップショット)
    property int index: 0
    property string targetScreen: ""   // 開いた時点のフォーカス中モニター

    // 使った順 (新しい順) のウィンドウのアドレス。シェルの起動後にフォーカスされたものだけが入る
    property var mru: []
    // commit が next より先に届いた (一瞬だけ押したとき) ことの記憶
    property bool _pendingCommit: false

    function _addr(t) {
        const a = t ? (t.lastIpcObject && t.lastIpcObject.address ? t.lastIpcObject.address : t.address) : "";
        return ("" + a).replace(/^0x/, "").toLowerCase();
    }

    // 一覧は、開くたびに hyprctl で取り直す (Hyprland.toplevels の lastIpcObject は、起動後に作られたウィンドウで遅れるため)。
    // サムネイル用のハンドル (wayland) だけを Hyprland.toplevels からアドレスで引く。
    function _build(clients) {
        const rank = a => {
            const i = root.mru.indexOf(a);
            return i < 0 ? 1000 : i;
        };
        const byAddr = {};
        for (const t of Hyprland.toplevels.values)
            byAddr[_addr(t)] = t;
        return clients
            .filter(c => c.mapped && !c.hidden && c.class !== "" && c.workspace)
            .map(c => ({
                address: c.address,
                appClass: c.class,
                title: c.title,
                wsId: c.workspace.id,
                monId: c.monitor,
                focusHistory: c.focusHistoryID,
                toplevel: byAddr[("" + c.address).replace(/^0x/, "").toLowerCase()] || null
            }))
            .sort((x, y) => {
                const d = rank(("" + x.address).replace(/^0x/, "").toLowerCase()) - rank(("" + y.address).replace(/^0x/, "").toLowerCase());
                return d !== 0 ? d : x.focusHistory - y.focusHistory;
            });
    }

    // サブマップから出す (Hyprland は、サブマップの間、ほかのバインドを効かせないので、取りこぼさない)
    function _resetSubmap() {
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.submap("reset")']);
    }

    // 開く前 (一覧を取っている間) に届いた next / prev の累積。最初の 1 回も含む
    property int _queued: 0
    property bool _loading: false

    function _finishOpen(list) {
        _loading = false;
        const q = _queued;
        _queued = 0;
        if (list.length === 0) {
            _pendingCommit = false;
            _resetSubmap();
            return;
        }
        const m = Hyprland.focusedMonitor;
        const n = list.length;
        windows = list;
        index = n > 1 ? ((q % n) + n) % n : 0;
        targetScreen = m ? m.name : "";
        shown = true;
        timeout.restart();
        // commit が先に届いていた (一瞬だけ押した) なら、そのまま切り替える
        if (_pendingCommit)
            commit();
    }

    function step(dir) {
        if (!shown) {
            _queued += dir;
            if (!_loading) {
                _loading = true;
                clientsProc.running = true;
            }
            return;
        }
        const n = windows.length;
        if (n > 0)
            index = (index + dir + n) % n;
        timeout.restart();
    }

    function commit() {
        if (_loading) {
            _pendingCommit = true;
            return;
        }
        if (!shown) {
            _pendingCommit = true;
            pendingTimer.restart();
            _resetSubmap();
            return;
        }
        const t = windows[index];
        close();
        if (t && t.address)
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "address:' + t.address + '" })']);
    }

    function cancel() {
        _queued = 0;
        close();
    }

    function close() {
        shown = false;
        _pendingCommit = false;
        timeout.stop();
        _resetSubmap();
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._finishOpen(root._build(JSON.parse(text)));
                } catch (e) {
                    console.warn("Switcher: bad clients json", e);
                    root._loading = false;
                    root._queued = 0;
                    root._resetSubmap();
                }
            }
        }
    }

    // Alt の離したときが検知できなかった場合に、サブマップや画面が残らないための保険
    Timer {
        id: timeout
        interval: 8000
        onTriggered: root.cancel()
    }
    Timer {
        id: pendingTimer
        interval: 500
        onTriggered: root._pendingCommit = false
    }

    // 使った順を記録する
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const a = root._addr(Hyprland.activeToplevel);
            if (a !== "")
                root.mru = [a].concat(root.mru.filter(x => x !== a)).slice(0, 50);
        }
    }

    IpcHandler {
        target: "switcher"
        function next(): void { root.step(1); }
        function prev(): void { root.step(-1); }
        function commit(): void { root.commit(); }
        function cancel(): void { root.cancel(); }
        function status(): string { return "shown=" + root.shown + " index=" + root.index + " windows=" + root.windows.length + " mru=" + root.mru.length + " loading=" + root._loading; }
    }

    SwitcherWindow {
        switcher: root
    }
}
