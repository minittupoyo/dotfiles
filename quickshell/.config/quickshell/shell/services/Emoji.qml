pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// 絵文字ピッカーのデータ・検索・最近使ったもの。
// データは scripts の emoji-data.py が fcitx5 の辞書から作る ~/.cache/shell/emoji.json (無ければ初回に自動生成。
// fcitx5 の辞書が更新されたら、このファイルを消すと作り直す)。
// items: { e: 絵文字, ja: [日本語のキーワード], en: [英語のキーワード], k: [検索用に正規化した全キーワード] }
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dataFile: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/shell/emoji.json"
    readonly property string recentFile: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/quickshell/emoji-recent.json"
    readonly property int maxRecent: 40

    property var items: []
    property var recent: []           // 最近使った絵文字 (新しい順)
    readonly property bool ready: items.length > 0
    property bool _generated: false   // 作り直しは 1 回だけ試す (失敗して無限に繰り返さない)

    // 検索のための正規化: 全角・半角をそろえ、小文字にし、カタカナをひらがなにする
    function norm(s) {
        return (s || "").normalize("NFKC").toLowerCase().replace(/[ァ-ヶ]/g, c => String.fromCharCode(c.charCodeAt(0) - 0x60));
    }

    // ランチャーが開く前に呼んで、データを読み込んでおく
    function ensure() {
        if (!ready && !_generated && !dataView.loading)
            dataView.reload();
    }

    function label(it) {
        if (!it)
            return "";
        const ja = it.ja.slice(0, 4).join(" · ");
        const en = it.en.slice(0, 3).join(", ");
        return ja && en ? ja + "   " + en : ja || en;
    }

    // 空の検索語: 最近使ったものを先頭に、残りは標準の順。語あり: 空白区切りの語がすべて一致するものを、一致の強さ順に
    function search(query, limit) {
        const words = norm(query).trim().split(/\s+/).filter(w => w !== "");
        if (words.length === 0) {
            const byE = {};
            for (const it of items)
                byE[it.e] = it;
            const out = [];
            const seen = {};
            for (const e of recent) {
                if (byE[e] && !seen[e]) {
                    out.push(byE[e]);
                    seen[e] = true;
                }
            }
            for (const it of items) {
                if (out.length >= limit)
                    break;
                if (!seen[it.e])
                    out.push(it);
            }
            return out;
        }
        const scored = [];
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            let total = 0;
            for (const w of words) {
                let best = it.e === w ? 4 : 0;    // 絵文字そのものを貼り付けた場合
                for (const k of it.k) {
                    if (k === w)
                        best = Math.max(best, 3);
                    else if (k.startsWith(w))
                        best = Math.max(best, 2);
                    else if (k.indexOf(w) >= 0)
                        best = Math.max(best, 1);
                }
                if (best === 0) {
                    total = 0;
                    break;
                }
                total += best;
            }
            if (total > 0)
                scored.push({ it: it, total: total, i: i });
        }
        scored.sort((a, b) => b.total - a.total || a.i - b.i);
        return scored.slice(0, limit).map(s => s.it);
    }

    // クリップボードにコピーして、最近使ったものに入れる
    function copy(e) {
        Quickshell.execDetached(["wl-copy", "--", e]);
        recent = [e].concat(recent.filter(x => x !== e)).slice(0, maxRecent);
        recentView.setText(JSON.stringify(recent) + "\n");
    }

    FileView {
        id: dataView
        path: root.dataFile
        printErrors: false
        property bool loading: false
        onLoaded: {
            try {
                root.items = JSON.parse(text()).map(x => ({ e: x.e, ja: x.ja, en: x.en, k: x.ja.concat(x.en).map(root.norm) }));
            } catch (e) {
                console.warn("Emoji: bad data file", e);
            }
        }
        onLoadFailed: {
            // 初回: 辞書から作る
            if (!root._generated) {
                root._generated = true;
                gen.running = true;
            }
        }
    }

    Process {
        id: gen
        command: [root.home + "/.local/bin/emoji-data.py", root.dataFile]
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code === 0)
                dataView.reload();
            else
                console.warn("Emoji: emoji-data.py failed (", code, ")", gen.stderr.text);
        }
    }

    FileView {
        id: recentView
        path: root.recentFile
        printErrors: false
        onLoaded: {
            try {
                const r = JSON.parse(text());
                if (Array.isArray(r))
                    root.recent = r.filter(x => typeof x === "string").slice(0, root.maxRecent);
            } catch (e) {
                console.warn("Emoji: bad recent file", e);
            }
        }
    }
}
