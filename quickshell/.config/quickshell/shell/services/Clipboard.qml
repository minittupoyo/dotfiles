pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// クリップボード履歴 (cliphist)。履歴の蓄積は wl-paste --watch cliphist store (Hyprland の自動起動) が行う。
// 画像は cliphist decode でキャッシュにファイル化して、サムネイルに使う。
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string imageDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/shell/clipboard"

    // { id, preview, isImage } の配列。新しい順
    property var entries: []

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    function _parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const m = /^(\d+)\t(.*)$/.exec(line);
            if (!m)
                continue;
            out.push({ id: m[1], preview: m[2], isImage: /^\[\[ binary data /.test(m[2]) });
        }
        entries = out;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _norm(s) {
        return (s || "").normalize("NFKC").toLowerCase();
    }

    // 空白区切りの語がすべて含まれるものを、新しい順に返す
    function search(query, limit) {
        const words = _norm(query).trim().split(/\s+/).filter(w => w !== "");
        const out = [];
        for (const e of entries) {
            const t = _norm(e.preview);
            if (words.every(w => t.indexOf(w) >= 0 || (e.isImage && "image".indexOf(w) >= 0)))
                out.push(e);
            if (out.length >= (limit || 50))
                break;
        }
        return out;
    }

    // 選択した履歴を、もう一度クリップボードにコピーする
    // wl-copy は保持するプロセスが選択内容の持ち主になるので、シェルの再読み込みで道連れにならないよう切り離して起動する
    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
    }

    // ---- 画像のサムネイル ----
    property var _imageReady: ({})
    property int imageVersion: 0
    property var _imageQueue: []
    property string _imageActive: ""

    function imageReady(id) {
        imageVersion;    // 依存を張る
        return _imageReady[id] === true;
    }
    function imageUrl(id) {
        return "file://" + imageDir + "/" + id;
    }

    function ensureImage(id) {
        if (_imageReady[id] === true || _imageQueue.indexOf(id) >= 0 || _imageActive === id)
            return;
        _imageQueue = _imageQueue.concat([id]);
        _nextImage();
    }

    function _nextImage() {
        if (imageProc.running || _imageQueue.length === 0)
            return;
        _imageActive = _imageQueue[0];
        _imageQueue = _imageQueue.slice(1);
        imageProc.command = ["sh", "-c", 'mkdir -p "$1" && cliphist decode "$2" > "$1/$2"', "sh", imageDir, _imageActive];
        imageProc.running = true;
    }

    Process {
        id: imageProc
        onExited: (code, status) => {
            if (code === 0) {
                const r = root._imageReady;
                r[root._imageActive] = true;
                root._imageReady = r;
                root.imageVersion++;
            }
            root._imageActive = "";
            root._nextImage();
        }
    }
}
