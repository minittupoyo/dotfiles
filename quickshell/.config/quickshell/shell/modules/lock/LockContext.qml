import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../../services"

// ロック画面の入力と認証 (全モニターのロック画面で共有する)。
// PAM のサービスは system-auth (標準の設定。faillock を含むので、連続して失敗すると一時的にロックされる)。
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string error: ""

    function type(text) {
        if (busy)
            return;
        error = "";
        password += text;
    }

    function backspace() {
        if (busy)
            return;
        error = "";
        password = password.slice(0, -1);
    }

    function clear() {
        if (busy)
            return;
        error = "";
        password = "";
    }

    function submit() {
        if (busy || password === "")
            return;
        error = "";
        busy = true;
        if (!pam.start()) {
            busy = false;
            error = "認証を開始できませんでした";
        }
    }

    // ロックが解けたら入力を捨てる (次のロックに残さない)
    Connections {
        target: Lock
        function onLockedChanged() {
            if (!Lock.locked) {
                root.password = "";
                root.error = "";
                root.busy = false;
            }
        }
    }

    PamContext {
        id: pam
        config: "system-auth"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success) {
                Lock.unlock();
            } else if (result === PamResult.Failed) {
                root.error = "パスワードが違います";
            } else if (result === PamResult.MaxTries) {
                root.error = "失敗が続いたため、しばらくロックされています";
            } else {
                root.error = "認証でエラーが起きました";
            }
        }
        onError: err => {
            root.busy = false;
            root.password = "";
            root.error = "認証でエラーが起きました: " + PamError.toString(err);
        }
    }
}
