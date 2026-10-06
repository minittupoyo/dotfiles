import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    property string pendingAction: ""
    property string error: ""
    property bool executing: false
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    property string executorPath: cliDir + "/material-session"
    panelHeight: panel.pendingAction === "" ? Theme.sessionPanelHeight : Theme.sessionConfirmHeight
    readonly property var actions: [{id:"lock",label:"画面をロック",icon:"lock"},
        {id:"suspend",label:"サスペンド",icon:"bedtime"},{id:"logout",label:"ログアウト",icon:"logout"},
        {id:"reboot",label:"再起動",icon:"restart_alt"},{id:"poweroff",label:"電源オフ",icon:"power_settings_new"}]
    readonly property string pendingLabel: actions.find(action => action.id === pendingAction)?.label ?? ""
    onVisibleChanged: if (visible && !executing) { pendingAction = ""; error = ""; }
    function choose(action) {
        if (executing || !actions.some(item => item.id === action)) return;
        pendingAction = action;
        if (action === "lock") execute();
    }
    function execute() {
        if (!pendingAction || executing) return;
        executing = true; error = "";
        executor.command = [executorPath, pendingAction];
        executor.running = true;
    }
    Process {
        id: executor
        stderr: SplitParser { onRead: data => panel.error = data }
        onExited: (code, status) => {
            panel.executing = false;
            if (code === 0) panel.dismissed();
            else panel.error = panel.error || "操作を実行できませんでした";
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { id: header; Layout.fillWidth: true; title: "セッション"; onDismissed: panel.dismissed() }
        Text { visible: panel.pendingAction !== ""; Layout.fillWidth: true; text: panel.pendingLabel + "しますか？"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; wrapMode: Text.Wrap }
        Text { visible: panel.pendingAction !== ""; Layout.fillWidth: true; text: panel.pendingAction === "suspend" ? "画面をロックしてからサスペンドします。" : "未保存の作業を確認してから実行してください。"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap }
        GridLayout {
            id: actionGrid
            visible: panel.pendingAction === ""
            Layout.fillWidth: true
            columns: Math.max(2, Math.min(5, Math.floor((width + Theme.sessionActionSpacing) / (Theme.sessionActionWidth + Theme.sessionActionSpacing))))
            rowSpacing: Theme.sessionActionSpacing
            columnSpacing: Theme.sessionActionSpacing
            Repeater {
                model: panel.actions
                SessionAction {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.label
                    icon: modelData.icon
                    enabled: !panel.executing
                    onClicked: panel.choose(modelData.id)
                }
            }
        }
        Item { Layout.fillHeight: true }
        Text { Layout.fillWidth: true; visible: text !== ""; text: panel.error; color: Theme.error; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap }
        RowLayout {
            visible: panel.pendingAction !== ""
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            ShellButton { text: "キャンセル"; enabled: !panel.executing; onClicked: panel.pendingAction = "" }
            ShellButton { text: panel.executing ? "実行中…" : panel.pendingLabel; emphasized: true; destructive: ["logout", "reboot", "poweroff"].includes(panel.pendingAction); enabled: !panel.executing; onClicked: panel.execute() }
        }
    }
}
