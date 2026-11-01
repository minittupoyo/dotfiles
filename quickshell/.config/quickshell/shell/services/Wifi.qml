pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// WiFi (iwd)。実体は scripts の wifi.sh (iwctl)。詳細タブが開いている間 (active) だけ、状態を 2 秒ごと・スキャンを 10 秒ごとに更新する。
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.local/bin/wifi.sh"

    property bool active: false          // WiFi の表示が開いているか (QML 側から立てる)
    property bool available: false       // iwd とデバイスがあるか
    property bool powered: false
    property string state: ""            // connected / disconnected / connecting ...
    property string connectedSsid: ""
    property bool scanning: false
    // [{ name, security, signal (0-4), connected, known }]
    property var networks: []

    // 接続の試行中の SSID と、直近の失敗メッセージ
    property string connecting: ""
    property string error: ""

    function refresh() {
        if (!statusProc.running)
            statusProc.running = true;
    }
    function scan() {
        run(["scan"]);
    }
    function setPower(on) {
        run(["power", on ? "on" : "off"]);
    }
    function connectTo(ssid, pass) {
        error = "";
        connecting = ssid;
        connProc.command = pass ? [script, "connect", ssid, pass] : [script, "connect", ssid];
        connProc.running = true;
    }
    function disconnect() {
        run(["disconnect"]);
    }
    function forget(ssid) {
        run(["forget", ssid]);
    }

    function run(args) {
        Quickshell.execDetached([script].concat(args));
        after.restart();
    }

    function _parse(text) {
        const nets = [];
        let ok = false;
        for (const line of text.trim().split("\n")) {
            const f = line.split("|");
            if (f[0] === "dev") {
                ok = true;
                powered = f[2] === "on";
                state = f[3];
                connectedSsid = f[4];
                scanning = f[5] === "yes";
            } else if (f[0] === "net") {
                nets.push({ name: f[1], security: f[2], signal: Number(f[3]), connected: f[4] === "1", known: f[5] === "1" });
            }
        }
        available = ok;
        networks = nets;
    }

    // 操作のあとに状態を読み直す
    Timer {
        id: after
        interval: 600
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Process {
        id: connProc
        stderr: StdioCollector {
            id: connErr
        }
        onExited: code => {
            if (code !== 0)
                root.error = connErr.text.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").trim() || "接続に失敗しました";
            root.connecting = "";
            root.refresh();
        }
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer {
        interval: 10000
        running: root.active && root.powered
        repeat: true
        triggeredOnStart: true
        onTriggered: root.scan()
    }
}
