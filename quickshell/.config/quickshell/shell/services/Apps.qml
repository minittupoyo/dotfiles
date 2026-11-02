pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// アプリの検索・順位付け・起動。
// - 検索: 名前・キーワード・一般名・説明にあいまい一致 (部分列)。先頭一致・単語頭・連続一致を高く評価する
// - 順位: 一致度 + 起動回数と最近さ (frecency)。履歴は ~/.local/state/quickshell/launcher.json
// - 起動: ターミナルアプリは terminal 経由で、作業ディレクトリは $HOME で起動する
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string usageFile: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/quickshell/launcher.json"
    property var terminal: ["kitty"]

    readonly property var all: DesktopEntries.applications.values

    // id → { count, last(ms) }
    property var usage: ({})

    // ---- 履歴 ----
    FileView {
        id: usageStore
        path: root.usageFile
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text());
                root.usage = (o && typeof o === "object" && !Array.isArray(o)) ? o : {};
            } catch (e) {
                console.warn("Apps: usage file is corrupted, ignoring:", e);
                root.usage = {};
            }
        }
    }

    function resetUsage() {
        usage = {};
        usageStore.setText("{}");
    }

    function recordLaunch(id) {
        const u = Object.assign({}, usage);
        const prev = u[id] || { count: 0, last: 0 };
        u[id] = { count: prev.count + 1, last: Date.now() };
        usage = u;
        usageStore.setText(JSON.stringify(u));
    }

    // 起動回数と最近さ。30 日で半減に近づく減衰
    function frecency(id) {
        const u = usage[id];
        if (!u)
            return 0;
        const days = (Date.now() - u.last) / 86400000;
        return Math.log(1 + u.count) * 6 * Math.exp(-days / 30);
    }

    // ---- あいまい検索 ----
    function _boundary(t, i) {
        return i === 0 || /[\s\-_.\/]/.test(t[i - 1]);
    }

    // q, t は小文字化済み。一致しなければ -1
    function fuzzy(q, t) {
        if (q === "")
            return 0;
        const idx = t.indexOf(q);
        if (idx >= 0)
            return 100 + (idx === 0 ? 50 : (_boundary(t, idx) ? 25 : 0)) - t.length * 0.2;
        let s = 0, prev = -2, from = 0;
        for (const c of q) {
            const p = t.indexOf(c, from);
            if (p < 0)
                return -1;
            s += 1;
            if (p === prev + 1) s += 4;
            if (_boundary(t, p)) s += 3;
            prev = p;
            from = p + 1;
        }
        return s - t.length * 0.1;
    }

    function _norm(s) {
        return (s || "").normalize("NFKC").toLowerCase();
    }

    // 戻り値: 順位付けされたエントリの配列 (最大 limit 件)
    function search(query, limit) {
        const q = _norm(query).trim();
        const list = [];
        for (const e of all) {
            const fr = frecency(e.id);
            if (q === "") {
                list.push({ entry: e, score: fr });
                continue;
            }
            let best = fuzzy(q, _norm(e.name));
            for (const k of e.keywords || [])
                best = Math.max(best, fuzzy(q, _norm(k)) * 0.7);
            best = Math.max(best, fuzzy(q, _norm(e.genericName)) * 0.5);
            const c = _norm(e.comment);
            if (c.indexOf(q) >= 0)
                best = Math.max(best, 20);
            if (best < 0)
                continue;
            list.push({ entry: e, score: best + fr });
        }
        list.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return list.slice(0, limit || 50).map(x => x.entry);
    }

    // ---- 起動 ----
    // DesktopEntry.execute() は runInTerminal を無視し、作業ディレクトリも qs プロセスのものを引き継ぐので、
    // どちらも自前で指定して execDetached で起動する (execute() と同じく、シェルは介さない)。
    function launch(entry) {
        recordLaunch(entry.id);
        Quickshell.execDetached({
            command: entry.runInTerminal ? terminal.concat(entry.command) : entry.command,
            workingDirectory: entry.workingDirectory || home
        });
    }
}
