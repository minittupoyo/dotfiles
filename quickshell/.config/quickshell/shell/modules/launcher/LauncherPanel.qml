import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// ランチャーの中身: 検索バー + 結果のリスト。
//   mode "apps"      : アプリ (あいまい検索・起動回数順) + 式を入力すると先頭に計算結果
//   mode "clipboard" : クリップボード履歴 (Enter でもう一度コピー)
//   mode "emoji"     : 絵文字ピッカー (グリッド。日本語・英語のキーワードで検索、Enter でコピー。空欄では最近使ったもの→標準の順)
// 操作: ↑↓ (Ctrl+P/N) で選択 (絵文字は ←↑↓→)、Enter で実行、Tab でモード切替 (アプリ→履歴→絵文字)、Esc で閉じる
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

    // 絵文字のグリッド
    readonly property int emojiColumns: 8
    readonly property int emojiCell: 64
    readonly property int emojiRows: 5
    readonly property bool isEmoji: mode === "emoji"
    // 絵文字で直接開いた (SUPER+. / launcher emoji) ときは、絵文字だけの専用の見た目にする
    // (モードのボタンと Tab の切り替えなし)。ランチャーから Tab で入ったときは、これまでどおり。
    readonly property bool dedicated: startMode === "emoji"

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

    function pointerMovedGrid(index, gx, gy) {
        if (_ptrValid && (gx !== _ptrX || gy !== _ptrY))
            grid.currentIndex = index;
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
        if (m === "emoji")
            Emoji.ensure();
    }

    function nextMode() {
        setMode(mode === "apps" ? "clipboard" : mode === "clipboard" ? "emoji" : "apps");
    }

    // 絵文字モードの結果 (Emoji の items)
    readonly property var emojiResults: isEmoji && Emoji.ready ? Emoji.search(query, 2000) : []

    // 結果。{ kind, title, subtitle, iconName, isImage, payload }
    readonly property var results: {
        const out = [];
        if (mode === "apps") {
            const c = Calc.evaluate(query);
            if (c.ok && c.isExpr)
                out.push({ kind: "calc", title: "= " + c.text, subtitle: query.trim() + "  ·  Enter でコピー", payload: c.text });
            for (const e of Apps.search(query, 30))
                out.push({ kind: "app", title: e.name, subtitle: e.comment || e.genericName || "", iconName: e.icon, payload: e });
        } else if (mode === "clipboard") {
            for (const e of Clipboard.search(query, Settings.clipboardResults))
                out.push({ kind: "clip", title: e.isImage ? "画像" : e.preview, subtitle: e.isImage ? e.preview : "", isImage: e.isImage, payload: e });
        }
        return out;
    }

    function activate(item) {
        if (!item)
            return;
        if (item.kind === "emoji")
            Emoji.copy(item.e);
        else if (item.kind === "calc")
            Quickshell.execDetached(["wl-copy", "--", item.payload]);
        else if (item.kind === "app")
            Apps.launch(item.payload);
        else
            Clipboard.copy(item.payload);
        root.closeRequested();
    }

    // 絵文字グリッドの選択を動かす (dx: 列、dy: 行)
    function moveGrid(dx, dy) {
        const n = emojiResults.length;
        if (n === 0)
            return;
        const next = grid.currentIndex + dx + dy * emojiColumns;
        grid.currentIndex = Math.max(0, Math.min(n - 1, next));
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }

    function move(delta) {
        if (isEmoji) {
            moveGrid(0, delta > 0 ? 1 : -1);
            return;
        }
        if (list.count === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    onResultsChanged: {
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }
    onEmojiResultsChanged: {
        grid.currentIndex = 0;
        grid.positionViewAtBeginning();
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
                    name: root.mode === "clipboard" ? "content_paste" : root.isEmoji ? "mood" : "search"
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
                            } else if (root.isEmoji && event.key === Qt.Key_Left) {
                                root.moveGrid(-1, 0);
                            } else if (root.isEmoji && event.key === Qt.Key_Right) {
                                root.moveGrid(1, 0);
                            } else if (event.key === Qt.Key_PageDown) {
                                root.isEmoji ? root.moveGrid(0, root.emojiRows) : root.move(root.maxRows);
                            } else if (event.key === Qt.Key_PageUp) {
                                root.isEmoji ? root.moveGrid(0, -root.emojiRows) : root.move(-root.maxRows);
                            } else if (event.key === Qt.Key_Tab) {
                                if (!root.dedicated)
                                    root.nextMode();
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.isEmoji) {
                                    const it = root.emojiResults[grid.currentIndex];
                                    if (it)
                                        root.activate({ kind: "emoji", e: it.e });
                                } else {
                                    root.activate(root.results[list.currentIndex]);
                                }
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
                        text: root.mode === "clipboard" ? "クリップボード履歴を検索" : root.isEmoji ? "絵文字を検索 (例: 笑顔、猫、heart)" : "アプリを検索、または式を入力"
                        role: Typography.bodyLarge
                        color: Colors.m3OnSurfaceVariant
                    }
                }

                // モード切替 (Tab でも切り替わる)
                Button {
                    visible: !root.dedicated
                    size: "s"
                    variant: "tonal"
                    text: "アプリ"
                    checkable: true
                    autoToggle: false
                    checked: root.mode === "apps"
                    onClicked: root.setMode("apps")
                }
                Button {
                    visible: !root.dedicated
                    size: "s"
                    variant: "tonal"
                    text: "履歴"
                    checkable: true
                    autoToggle: false
                    checked: root.mode === "clipboard"
                    onClicked: root.setMode("clipboard")
                }
                Button {
                    visible: !root.dedicated
                    size: "s"
                    variant: "tonal"
                    text: "絵文字"
                    checkable: true
                    autoToggle: false
                    checked: root.isEmoji
                    onClicked: root.setMode("emoji")
                }
            }
        }

        // 絵文字のグリッド
        GridView {
            id: grid
            visible: root.isEmoji
            Layout.fillWidth: true
            Layout.preferredHeight: !root.isEmoji ? 0 : root.emojiResults.length === 0 ? root.rowHeight
                : Math.min(Math.ceil(root.emojiResults.length / root.emojiColumns), root.emojiRows) * root.emojiCell
            cellWidth: Math.floor(width / root.emojiColumns)
            cellHeight: root.emojiCell
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            model: root.isEmoji ? root.emojiResults : []

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                readonly property bool selected: index === grid.currentIndex

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Shapes.large
                    color: Colors.m3SecondaryContainer
                    opacity: cell.selected ? 1 : 0
                }
                StateLayer {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Shapes.large
                    hovered: cellMouse.containsMouse
                    pressed: cellMouse.pressed
                }
                Text {
                    anchors.centerIn: parent
                    text: cell.modelData.e
                    font.family: "Noto Color Emoji"
                    font.pixelSize: 32
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: m => {
                        const p = mapToGlobal(m.x, m.y);
                        root.pointerMovedGrid(cell.index, p.x, p.y);
                    }
                    onClicked: {
                        grid.currentIndex = cell.index;
                        root.activate({ kind: "emoji", e: cell.modelData.e });
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.isEmoji && root.emojiResults.length === 0
                text: Emoji.ready ? "見つかりません" : "絵文字のデータを読み込み中…"
                role: Typography.bodyLarge
                color: Colors.m3OnSurfaceVariant
            }
        }
        // 選択中の絵文字の名前
        Label {
            visible: root.isEmoji && root.emojiResults.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: Emoji.label(root.emojiResults[grid.currentIndex])
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
            elide: Text.ElideRight
        }

        // 結果
        ListView {
            id: list
            visible: !root.isEmoji
            Layout.fillWidth: true
            Layout.preferredHeight: root.isEmoji ? 0 : root.results.length === 0
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
            text: root.dedicated ? "←↑↓→ 選択  ·  Enter コピー  ·  Esc 閉じる"
                : root.isEmoji ? "←↑↓→ 選択  ·  Enter コピー  ·  Tab 切替  ·  Esc 閉じる"
                : "↑↓ 選択  ·  Enter 実行  ·  Tab 切替  ·  Esc 閉じる"
            role: Typography.labelMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
