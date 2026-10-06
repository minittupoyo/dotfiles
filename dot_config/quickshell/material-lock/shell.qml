import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import "file:///home/mimi/.config/quickshell/material-shell"

ShellRoot {
    id: root
    readonly property bool preview: Quickshell.env("MATERIAL_LOCK_PREVIEW") === "1"
    property string pendingResponse: ""
    property bool hasPendingResponse: false
    property string message: ""
    signal clearInputs()
    function authenticate(response) {
        if (preview) { message = "プレビューでは認証しません"; clearInputs(); return; }
        if (!sessionLock.secure) return;
        if (pam.responseRequired) { pam.respond(response); clearInputs(); return; }
        if (pam.active) return;
        pendingResponse = response;
        hasPendingResponse = true;
        clearInputs();
        if (!pam.start()) { pendingResponse = ""; hasPendingResponse = false; message = "認証を開始できません"; }
    }
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/material-shell/palette.json"
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: Theme.acceptPalette(text())
        onFileChanged: reload()
    }
    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (responseRequired && root.hasPendingResponse) {
                const response = root.pendingResponse;
                root.pendingResponse = ""; root.hasPendingResponse = false;
                respond(response);
            } else if (responseRequired) root.message = message || "認証情報を入力してください";
        }
        onCompleted: result => {
            root.pendingResponse = ""; root.hasPendingResponse = false; root.clearInputs();
            if (result === PamResult.Success && !root.preview) { sessionLock.locked = false; exitTimer.start(); }
            else root.message = "認証できませんでした。もう一度入力してください。";
        }
        onError: error => { root.pendingResponse = ""; root.hasPendingResponse = false; root.message = "認証処理に失敗しました。"; }
    }
    Timer { id: exitTimer; interval: 100; onTriggered: Qt.quit() }
    WlSessionLock {
        id: sessionLock
        locked: false
        WlSessionLockSurface {
            LockContent {
                id: lockContent
                anchors.fill: parent
                user: Quickshell.env("USER")
                message: root.message
                busy: pam.active && !pam.responseRequired
                responseVisible: pam.responseRequired && pam.responseVisible
                onSubmitted: response => root.authenticate(response)
                Connections { target: root; function onClearInputs() { lockContent.clear(); } }
            }
        }
    }
    IpcHandler {
        target: "lock"
        function status(): string { return JSON.stringify({secure: sessionLock.secure, locked: sessionLock.locked, preview: root.preview}); }
        // No IPC unlock endpoint; PAM success is the only unlock path.
    }
    Loader {
        active: root.preview
        sourceComponent: PanelWindow {
            screen: Quickshell.screens[0]
            anchors { top:true; bottom:true; left:true; right:true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "material-lock-preview"
            LockContent { anchors.fill: parent; user: Quickshell.env("USER"); message: "ロック画面のプレビュー" }
        }
    }
    Component.onCompleted: if (!preview) sessionLock.locked = true
}
