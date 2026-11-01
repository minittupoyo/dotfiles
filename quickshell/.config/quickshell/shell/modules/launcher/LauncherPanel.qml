import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// ランチャーの中身: 検索バー + 結果のリスト。
//   mode "apps"      : アプリ (あいまい検索・起動回数順) + 式を入力すると先頭に計算結果
//   mode "clipboard" : クリップボード履歴 (Enter でもう一度コピー)
// 操作: ↑↓ (Ctrl+P/N) で選択、Enter で実行、Tab でモード切替、Esc で閉じる
Item {
    id: root

    property alias input: input    // (テストが IME の確定入力を再現するために使う)
    property alias list: list

    property string startMode: "apps"
    property string mode: "apps"
    property string query: ""

    signal closeRequested()

    readonly property int maxRows: 8
    readonly property int rowHeight: 56

    // 高さは中身に合わせる (OverlayWindow が implicitHeight に追従する)
    implicitHeight: col.implicitHeight

    // hover による選択移動の判定用。開いた直後や、行がカーソルの下をスクロールで通っただけのときに
    // 選択を奪われないよう、ポインタの画面座標が実際に変わったときだけ選択を移す。
    property bool _ptrValid: false
    property real _ptrX: 0
    property real _ptrY: 0
    function pointerMoved(index, gx, gy) {
        if (_ptrValid && (gx !== _ptrX || gy !== _ptrY))
            list.currentIndex = index;
        _ptrX = gx;
        _ptrY = gy;
        _ptrValid = true;
    }

    function open() {
        _ptrValid = false;
        mode = startMode;
        input.text = "";
        query = "";
        if (mode === "clipboard")
            Clipboard.refresh();
        input.forceActiveFocus();
    }

    onStartModeChanged: {
        mode = startMode;
        if (mode === "clipboard")
            Clipboard.refresh();
    }

    function setMode(m) {
        mode = m;
        if (m === "clipboard")
            Clipboard.refresh();
    }

    // 結果。{ kind, title, subtitle, iconName, isImage, payload }
    readonly property var results: {
        const out = [];
        if (mode === "apps") {
            const c = Calc.evaluate(query);
            if (c.ok && c.isExpr)
                out.push({ kind: "calc", title: "= " + c.text, subtitle: query.trim() + "  ·  Enter でコピー", payload: c.text });
            for (const e of Apps.search(query, 30))
                out.push({ kind: "app", title: e.name, subtitle: e.comment || e.genericName || "", iconName: e.icon, payload: e });
        } else {
            for (const e of Clipboard.search(query, 50))
                out.push({ kind: "clip", title: e.isImage ? "画像" : e.preview, subtitle: e.isImage ? e.preview : "", isImage: e.isImage, payload: e });
        }
        return out;
    }

    function activate(item) {
        if (!item)
            return;
        if (item.kind === "calc")
            Quickshell.execDetached(["wl-copy", "--", item.payload]);
        else if (item.kind === "app")
            Apps.launch(item.payload);
        else
            Clipboard.copy(item.payload);
        root.closeRequested();
    }

    function move(delta) {
        if (list.count === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    onResultsChanged: {
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // 検索バー
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Shapes.full
            color: Colors.m3SurfaceContainerHighest

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 8
                spacing: 12

                Icon {
                    name: root.mode === "clipboard" ? "content_paste" : "search"
                    size: 24
                    color: Colors.m3OnSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: input
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colors.m3OnSurface
                        selectionColor: Colors.m3Primary
                        selectedTextColor: Colors.m3OnPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.bodyLarge.size
                        clip: true
                        focus: true
                        onTextChanged: root.query = text

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                                root.move(1);
                            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                                root.move(-1);
                            } else if (event.key === Qt.Key_PageDown) {
                                root.move(root.maxRows);
                            } else if (event.key === Qt.Key_PageUp) {
                                root.move(-root.maxRows);
                            } else if (event.key === Qt.Key_Tab) {
                                root.setMode(root.mode === "apps" ? "clipboard" : "apps");
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activate(root.results[list.currentIndex]);
                            } else if (event.key === Qt.Key_Escape) {
                                root.closeRequested();
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === "" && input.preeditText === ""
                        text: root.mode === "clipboard" ? "クリップボード履歴を検索" : "アプリを検索、または式を入力"
                        role: Typography.bodyLarge
                        color: Colors.m3OnSurfaceVariant
                    }
                }

                // モード切替 (Tab でも切り替わる)
                Button {
                    size: "s"
                    variant: "tonal"
                    text: "アプリ"
                    checkable: true
                    autoToggle: false
                    checked: root.mode === "apps"
                    onClicked: root.setMode("apps")
                }
                Button {
                    size: "s"
                    variant: "tonal"
                    text: "履歴"
                    checkable: true
                    autoToggle: false
                    checked: root.mode === "clipboard"
                    onClicked: root.setMode("clipboard")
                }
            }
        }

        // 結果
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: root.results.length === 0
                ? root.rowHeight
                : Math.min(root.results.length, root.maxRows) * root.rowHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            model: root.results

            delegate: ResultRow {
                width: list.width
                selected: index === list.currentIndex
                onMoved: (gx, gy) => root.pointerMoved(index, gx, gy)
                onActivated: {
                    list.currentIndex = index;
                    root.activate(modelData);
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: root.mode === "clipboard" ? "履歴がありません" : "見つかりません"
                role: Typography.bodyLarge
                color: Colors.m3OnSurfaceVariant
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "↑↓ 選択  ·  Enter 実行  ·  Tab 切替  ·  Esc 閉じる"
            role: Typography.labelMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
