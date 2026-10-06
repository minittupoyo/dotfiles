import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Item {
    id: service
    property var screen: Quickshell.screens[0] ?? null
    property var history: []
    property var toastIds: []
    readonly property var notifications: server.trackedNotifications.values
    readonly property var toasts: notifications.filter(n => toastIds.includes(n.id)).slice(-3)
    property string generation: String(Date.now())
    signal centerRequested()
    function record(n) {
        if (n.transient) return;
        const item = {key: generation + ":" + n.id, id: n.id, app: n.appName, summary: n.summary,
            body: n.body, timestamp: Date.now()};
        history = [item, ...history.filter(entry => entry.key !== item.key && !(n.lastGeneration && entry.id === n.id && entry.app === n.appName && entry.summary === n.summary))].slice(0, Theme.notificationHistoryLimit);
        historyWriter.restart();
    }
    function removeToast(id) { toastIds = toastIds.filter(value => value !== id); }
    function clearHistory() { history = []; notifications.slice().forEach(n => n.dismiss()); historyWriter.restart(); }
    function activeNotification(entry) { return entry.key.startsWith(generation + ":") ? notifications.find(n => n.id === entry.id) : null; }
    FileView {
        id: historyFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/material-shell/notifications.json"
        atomicWrites: true
        preload: true
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                if (Array.isArray(saved)) service.history = saved.filter(entry =>
                    typeof entry.key === "string" && typeof entry.summary === "string" && typeof entry.body === "string" && typeof entry.app === "string" && Number.isFinite(entry.timestamp)).slice(0, Theme.notificationHistoryLimit);
                service.notifications.forEach(n => service.record(n));
            } catch (error) { console.warn("Notification history could not be loaded"); }
        }
    }
    Timer { id: historyWriter; interval: 250; onTriggered: historyFile.setText(JSON.stringify(service.history)) }
    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            service.record(n);
            if (!Settings.values.dnd && !n.lastGeneration) service.toastIds = [...service.toastIds.filter(id => id !== n.id), n.id];
        }
    }
    Instantiator {
        model: service.notifications
        delegate: QtObject {
            required property var modelData
            property Timer expiry: Timer {
                interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : Theme.notificationDuration
                running: modelData.expireTimeout !== 0 && modelData.urgency !== NotificationUrgency.Critical
                onTriggered: { service.removeToast(modelData.id); modelData.expire(); }
            }
            property Connections events: Connections {
                target: modelData
                function onClosed(reason) { service.removeToast(modelData.id); }
                function onSummaryChanged() { service.record(modelData); if (expiry.running) expiry.restart(); }
                function onBodyChanged() { service.record(modelData); if (expiry.running) expiry.restart(); }
                function onExpireTimeoutChanged() { expiry.running = modelData.expireTimeout !== 0 && modelData.urgency !== NotificationUrgency.Critical; if (expiry.running) expiry.restart(); }
            }
        }
    }
    Connections { target: Settings; function onValuesChanged() { if (Settings.values.dnd) service.toastIds = []; } }
    PanelWindow {
        screen: service.screen
        visible: service.toasts.length > 0 && !Settings.values.dnd
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + Theme.space16; right: Theme.space16 }
        implicitWidth: Theme.notificationWidth
        implicitHeight: cards.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "material-shell-notifications"
        ColumnLayout {
            id: cards
            width: parent.width
            spacing: Theme.space8
            Repeater {
                model: service.toasts
                NotificationCard { required property var modelData; notification: modelData; Layout.fillWidth: true }
            }
        }
    }
}
