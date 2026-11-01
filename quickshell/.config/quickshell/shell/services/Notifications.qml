pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// 通知サーバー (org.freedesktop.Notifications)。
// - history: 受信して保持している通知 (ユーザーが閉じるまで残る)。クイック設定の通知一覧に使う
// - popups: いま画面に出しているポップアップ (時間で消える。履歴には残る)
// - dnd (おやすみモード): ポップアップを出さず、履歴だけ残す。緊急 (critical) は例外
Singleton {
    id: root

    property bool dnd: false
    readonly property int maxHistory: 50
    readonly property int maxPopups: 5    // 同時に出すポップアップの上限。あふれた古いものは履歴にだけ残す

    readonly property var history: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    // PopupEntry の配列 (新しいものが先頭)
    property var popups: []

    function setDnd(on) {
        dnd = on;
    }

    // すべての通知を閉じる
    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function removePopup(entry) {
        popups = popups.filter(e => e !== entry);
        if (!entry.alive)
            entry.destroy();
    }

    Component {
        id: entryComp
        NotificationEntry {}
    }

    NotificationServer {
        id: server

        // 対応していると伝える機能 (ヒント)
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: n => {
            n.tracked = true;
            const entry = entryComp.createObject(root, { n: n });
            // 閉じられたら (アプリ側・ユーザー側どちらでも) 値を控えてから退場させる
            n.closed.connect(() => {
                entry.freeze();
                entry.closing = true;
            });

            if (!root.dnd || entry.critical) {
                root.popups = [entry].concat(root.popups);
                // 上限を超えた古いポップアップ (緊急でないもの) を退場させる
                const shown = root.popups.filter(e => !e.closing);
                for (let i = root.maxPopups; i < shown.length; i++)
                    if (!shown[i].critical)
                        shown[i].hidePopup();
            } else {
                entry.closing = true;    // ポップアップなし。履歴にだけ残る
            }

            // 履歴の上限。古いものから閉じる
            const all = server.trackedNotifications.values;
            if (all.length > root.maxHistory)
                all[0].dismiss();
        }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.setDnd(!root.dnd); }
        function setDnd(on: bool): void { root.setDnd(on); }
        function clear(): void { root.clearAll(); }
        function status(): string { return "dnd=" + root.dnd + " history=" + root.count + " popups=" + root.popups.length + " closing=" + root.popups.filter(e => e.closing).length; }
    }
}
