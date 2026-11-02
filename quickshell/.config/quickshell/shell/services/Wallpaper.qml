pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// 壁紙の一覧・サムネイル・現在の壁紙・適用・配色プレビュー。
// - 一覧: FolderListModel が壁紙ディレクトリを監視する (追加・削除に追従)
// - サムネイル: scripts の wallpaper-thumbs.sh が ~/.cache に生成 (元画像は直接読まない)
// - 適用: apply-wallpaper.sh (壁紙変更 → matugen → 配色反映) を呼ぶ
// - プレビュー: matugen --dry-run で配色だけ計算する (適用はしない)
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // テスト用に WALLPAPER_DIR で差し替えられる
    readonly property string dir: Quickshell.env("WALLPAPER_DIR") || Settings.wallpaperDir || (home + "/Pictures/Wallpapers")
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/shell/wallpaper-thumbs"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/quickshell/wallpaper"
    readonly property string binDir: home + "/.local/bin"

    readonly property string mode: Settings.darkMode ? "dark" : "light"    // 設定画面で切り替える
    readonly property string scheme: Settings.scheme
    property string current: ""

    readonly property alias files: filesModel
    readonly property int count: filesModel.count

    // ---- 一覧 ----
    FolderListModel {
        id: filesModel
        folder: "file://" + root.dir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.avif"]
        showDirs: false
        caseSensitive: false    // .JPG などの大文字拡張子も拾う
        sortField: FolderListModel.Name
        onCountChanged: root.ensureThumbs()
    }

    function indexOfCurrent() {
        for (let i = 0; i < filesModel.count; i++)
            if (filesModel.get(i, "filePath") === current)
                return i;
        return -1;
    }

    // ---- サムネイル ----
    property var _thumbSet: ({})
    property bool _thumbRerun: false

    function thumbName(fileName, modified) {
        return fileName + "." + Math.floor(modified.getTime() / 1000) + ".jpg";
    }
    function thumbReady(fileName, modified) {
        return _thumbSet[thumbName(fileName, modified)] === true;
    }
    function thumbUrl(fileName, modified) {
        return "file://" + thumbDir + "/" + thumbName(fileName, modified);
    }

    function _rescanThumbs() {
        const s = {};
        for (let i = 0; i < thumbsModel.count; i++)
            s[thumbsModel.get(i, "fileName")] = true;
        _thumbSet = s;
    }

    FolderListModel {
        id: thumbsModel
        folder: "file://" + root.thumbDir
        nameFilters: ["*.jpg"]
        showDirs: false
        onCountChanged: root._rescanThumbs()
    }

    function ensureThumbs() {
        if (thumbProc.running)
            _thumbRerun = true;
        else
            thumbProc.running = true;
    }

    Process {
        id: thumbProc
        command: [root.binDir + "/wallpaper-thumbs.sh", root.dir, root.thumbDir]
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Wallpaper: thumbnail generation exited with", code);
            // 生成先ディレクトリが初回に作られた場合も拾えるよう、監視を張り直す
            const url = "file://" + root.thumbDir;
            thumbsModel.folder = "";
            thumbsModel.folder = url;
            if (root._thumbRerun) {
                root._thumbRerun = false;
                running = true;
            }
        }
    }

    // ---- 現在の壁紙 ----
    FileView {
        path: root.stateFile
        printErrors: false    // 適用前は状態ファイルが無いのが正常
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
    }

    // 状態ファイルがまだ無い場合 (適用前) は awww から取る
    Process {
        id: queryProc
        command: ["awww", "query"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /image: (.+)/.exec(text);
                if (m && root.current === "")
                    root.current = m[1].trim();
            }
        }
    }

    // ---- 適用 ----
    function apply(path) {
        applyProc.command = [binDir + "/apply-wallpaper.sh", path, mode, scheme];
        applyProc.running = true;
        current = path;
    }

    // 今の壁紙のまま、モード・スキームだけ変えて配色を作り直す
    function reapply() {
        if (current !== "")
            apply(current);
    }

    Process {
        id: applyProc
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Wallpaper: apply failed (", code, ")", applyProc.stderr.text);
        }
    }

    // ---- 配色プレビュー (適用はしない) ----
    property var _previews: ({})
    property int previewVersion: 0
    property string _previewWanted: ""
    property string _previewActive: ""

    // 計算済みなら { primary, secondary, ... } (hex 文字列)、まだなら null
    function preview(path) {
        previewVersion;    // 依存を張る (計算が終わると更新される)
        return _previews[path + "|" + mode + "|" + scheme] || null;
    }

    function requestPreview(path) {
        if (!path)
            return;
        _previewWanted = path;
        _startPreview();
    }

    function _startPreview() {
        if (previewProc.running || _previewWanted === "")
            return;
        if (_previews[_previewWanted + "|" + mode + "|" + scheme]) {
            _previewWanted = "";
            return;
        }
        _previewActive = _previewWanted;
        previewProc.command = ["matugen", "-t", scheme, "-m", mode, "--prefer", "saturation",
                               "--dry-run", "-j", "hex", "-q", "image", _previewActive];
        previewProc.running = true;
    }

    Process {
        id: previewProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text);
                    const out = {};
                    for (const k of ["primary", "secondary", "tertiary", "primary_container", "surface"])
                        out[k] = o.colors[k].default.color;
                    const cache = root._previews;
                    cache[root._previewActive + "|" + root.mode + "|" + root.scheme] = out;
                    root._previews = cache;
                    root.previewVersion++;
                } catch (e) {
                    console.warn("Wallpaper: preview parse failed:", e);
                }
            }
        }
        onExited: {
            // 計算中に別の壁紙が選ばれていたら、最新のものを続けて計算する
            if (root._previewWanted === root._previewActive)
                root._previewWanted = "";
            root._startPreview();
        }
    }

    onDirChanged: ensureThumbs()
    Component.onCompleted: ensureThumbs()
}
