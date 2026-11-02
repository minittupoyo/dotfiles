pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// シェルの設定。1 つの settings.json (~/.local/state/quickshell/) に保存して、次回も使う。
// 各サービス・モジュールは Settings.xxx を読む。変更は set(key, value) か、プロパティへの代入 + save()。
// 読み込み時は、既知のキーで型が合うものだけ取り込む (壊れたファイル・古いキーは無視)。
Singleton {
    id: root

    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/settings.json"

    // ---- 外観 ----
    property bool darkMode: true
    property string scheme: "scheme-expressive"    // matugen のスキーム
    property string wallpaperDir: ""               // 空なら既定 (~/Pictures/Wallpapers)

    // ---- バー ----
    property bool clock24h: true
    property bool clockSeconds: false
    property bool clockDate: true
    property bool barTray: true
    property bool barActiveWindow: true

    // ---- 通知 ----
    property int notifTimeout: 6                   // 秒。通知側が時間を指定しないときの表示時間

    // ---- ロック・電源 ----
    property int lockMinutes: 15                   // アイドルでロックするまでの分。0 ならロックしない
    property int dpmsMinutes: 0                    // ロック中に画面を消すまでの分。0 なら消さない

    // ---- ランチャー ----
    property int clipboardResults: 50              // クリップボード履歴の表示件数

    // ---- スクリーンショット ----
    property bool screenshotSave: true             // false ならクリップボードにだけコピー
    property int screenshotDelay: 0                // 撮影までの秒 (0 / 3 / 5)
    property bool screenshotMigrated: false        // 旧 screenshot.json を取り込み済みか

    readonly property var keys: [
        "darkMode", "scheme", "wallpaperDir",
        "clock24h", "clockSeconds", "clockDate", "barTray", "barActiveWindow",
        "notifTimeout", "lockMinutes", "dpmsMinutes", "clipboardResults",
        "screenshotSave", "screenshotDelay", "screenshotMigrated"
    ]

    // 初期値 (起動時に現在の値を控える。ファイルの読み込みは非同期なので、その前に済む)
    property var defaults: ({})

    function set(key, value) {
        if (keys.indexOf(key) < 0 || root[key] === value)
            return;
        root[key] = value;
        save();
    }

    function resetAll() {
        for (const k of keys)
            if (k !== "screenshotMigrated")
                root[k] = defaults[k];
        save();
    }

    function save() {
        saveTimer.restart();
    }

    function _write() {
        const o = {};
        for (const k of keys)
            o[k] = root[k];
        file.setText(JSON.stringify(o, null, 2) + "\n");
    }

    // スライダーなどの連続変更をまとめて書く
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: root._write()
    }

    Component.onCompleted: {
        const d = {};
        for (const k of keys)
            d[k] = root[k];
        defaults = d;
    }

    FileView {
        id: file
        path: root.stateFile
        printErrors: false    // 初回は設定ファイルが無いのが正常
        onLoaded: {
            try {
                const j = JSON.parse(text());
                for (const k of root.keys)
                    if (typeof j[k] === typeof root.defaults[k])
                        root[k] = j[k];
            } catch (e) {
                console.warn("Settings: bad settings file, using defaults:", e);
            }
            root._migrate();
        }
        onLoadFailed: root._migrate()    // 初回 (設定ファイルなし)
    }

    // 旧 screenshot.json (保存するか・ディレイ) を一度だけ取り込む
    function _migrate() {
        if (!screenshotMigrated)
            legacy.path = stateDir + "/screenshot.json";
    }
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"

    FileView {
        id: legacy
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                if (typeof j.saveToFile === "boolean")
                    root.screenshotSave = j.saveToFile;
                if ([0, 3, 5].indexOf(j.delay) >= 0)
                    root.screenshotDelay = j.delay;
            } catch (e) {
                console.warn("Settings: bad legacy screenshot.json:", e);
            }
            root.screenshotMigrated = true;
            root.save();
        }
        onLoadFailed: {
            root.screenshotMigrated = true;
            root.save();
        }
    }
}
