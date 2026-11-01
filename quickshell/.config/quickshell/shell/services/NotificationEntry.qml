import QtQuick
import Quickshell.Services.Notifications

// ポップアップ 1 件分の状態。通知 (Notification) は「閉じた」直後に破棄されるので、
// 閉じる前に表示用の値を控えておき (freeze)、退場アニメーションの間はそちらで描画する。
QtObject {
    id: entry

    required property var n    // Notification

    property bool alive: true       // n がまだ有効か
    property bool closing: false    // ポップアップが退場中か
    property bool hovered: false    // ホバー中は自動で消さない
    property var snap: ({})

    readonly property string summary: alive ? n.summary : (snap.summary || "")
    readonly property string body: alive ? n.body : (snap.body || "")
    readonly property string appName: alive ? n.appName : (snap.appName || "")
    readonly property string appIcon: alive ? n.appIcon : (snap.appIcon || "")
    readonly property string image: alive ? n.image : (snap.image || "")
    readonly property int urgency: alive ? n.urgency : (snap.urgency === undefined ? NotificationUrgency.Normal : snap.urgency)
    readonly property bool critical: urgency === NotificationUrgency.Critical
    readonly property bool isTransient: alive ? n.transient : (snap.isTransient === true)
    // 閉じた後も、退場アニメーションの間はボタンの見た目を変えないよう、控えた値を使う
    readonly property var actions: alive ? n.actions.map(a => ({ identifier: a.identifier, text: a.text })) : (snap.actions || [])

    // 破棄される前に呼ぶ
    function freeze() {
        snap = {
            summary: n.summary, body: n.body, appName: n.appName, appIcon: n.appIcon, image: n.image,
            urgency: n.urgency, isTransient: n.transient,
            actions: n.actions.map(a => ({ identifier: a.identifier, text: a.text }))
        };
        alive = false;
    }

    function invoke(identifier) {
        if (!alive)
            return;
        for (const a of n.actions)
            if (a.identifier === identifier) {
                a.invoke();
                return;
            }
    }

    // ユーザーが閉じた (送信元にも「閉じられた」と伝わる)
    function dismiss() {
        if (alive)
            n.dismiss();
        closing = true;
    }

    // ポップアップだけ退場させる (履歴には残す。一時的な通知は時間切れとして閉じる)
    function hidePopup() {
        if (alive && isTransient)
            n.expire();
        closing = true;
    }

    // 表示時間 (ms)。0 なら自動では消えない。通知側の指定があればそれに従う。
    // 注意: Quickshell 0.3.2 の expireTimeout は、ドキュメントでは「秒」だが、実際は通知が送ってきたミリ秒の値のまま
    //       (2000 を送ると 2000 が返る)。将来の版で秒になっても破綻しないよう、100 未満は秒とみなす。
    readonly property int duration: {
        if (critical)
            return 0;
        const t = alive ? n.expireTimeout : 0;
        if (t > 0)
            return Math.round(t < 100 ? t * 1000 : t);
        return urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    readonly property Timer timer: Timer {
        interval: entry.duration
        running: entry.duration > 0 && !entry.closing && !entry.hovered
        repeat: false
        onTriggered: entry.hidePopup()
    }
}
