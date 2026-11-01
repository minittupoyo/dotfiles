import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// 壁紙セレクターの中身 (ヘッダー・グリッド・配色プレビュー)。
// ウィンドウ管理 (レイヤー・表示モニター) は WallpaperSelector 側。入力のテストをしやすいよう分離している。
Item {
    id: root

    property alias grid: grid

    signal closeRequested()

    // 開いたとき: 現在の壁紙を選択して、キーボードフォーカスを取る
    function open() {
        const i = Wallpaper.indexOfCurrent();
        grid.currentIndex = i >= 0 ? i : 0;
        grid.forceActiveFocus();
        previewTimer.restart();
        // ウィンドウが非表示の間はグリッドの高さが 0 なので、高さが決まってから位置合わせする
        _needsInitialScroll = true;
        _applyInitialScroll();
    }

    property bool _needsInitialScroll: false

    function _applyInitialScroll() {
        if (!_needsInitialScroll || grid.height <= 0)
            return;
        _needsInitialScroll = false;
        scroller.snap(0);
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }

    function applyCurrent() {
        const item = grid.currentItem;
        if (!item)
            return;
        Wallpaper.apply(item.filePath);
        root.closeRequested();
    }

    // 選択中の行が見える位置まで、スプリングで滑らかにスクロールする (キー操作・hover 共通)。
    // スプリングが動いている間だけ contentY を駆動するので、ホイールやドラッグの操作とは干渉しない。
    function scrollToCurrent() {
        // 高さが未確定 (非表示中) の計算は誤るので、確定後の初期位置合わせに任せる
        if (grid.height <= 0 || grid.count === 0 || grid.currentIndex < 0)
            return;
        const row = Math.floor(grid.currentIndex / grid.cols);
        const top = row * grid.cellHeight;
        const slack = grid.cellHeight * 0.06;    // 拡大したカードがはみ出さない分
        let target = grid.contentY;
        if (top - slack < grid.contentY)
            target = top - slack;
        else if (top + grid.cellHeight + slack > grid.contentY + grid.height)
            target = top + grid.cellHeight + slack - grid.height;
        target = Math.max(0, Math.min(target, grid.contentHeight - grid.height));
        if (Math.abs(target - grid.contentY) < 1)
            return;
        scroller.snap(grid.contentY);
        scroller.target = target;
    }

    SpringValue {
        id: scroller
        spec: Motion.spatialDefault
        epsilon: 0.3
        onValueChanged: if (running) grid.contentY = value
    }

    // 選択が止まってからプレビューを計算する (matugen は重いので連続で呼ばない)
    Timer {
        id: previewTimer
        interval: 250
        onTriggered: {
            if (grid.currentItem)
                Wallpaper.requestPreview(grid.currentItem.filePath);
        }
    }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "壁紙"
                    role: Typography.headlineSmallEmphasized
                }
                Label {
                    text: Wallpaper.count + " 枚"
                    role: Typography.labelLarge
                    color: Colors.m3OnSurfaceVariant
                    Layout.leftMargin: 8
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    size: "s"
                    variant: "standard"
                    icon: "close"
                    onClicked: root.closeRequested()
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true
                keyNavigationEnabled: true
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: false
                model: Wallpaper.files

                readonly property int cols: Math.max(1, Math.floor(width / 280))
                cellWidth: Math.floor(width / cols)
                cellHeight: Math.round(cellWidth * 0.66)

                onCurrentIndexChanged: {
                    previewTimer.restart();
                    if (!root._needsInitialScroll)
                        root.scrollToCurrent();
                }
                onHeightChanged: root._applyInitialScroll()

                Keys.onReturnPressed: root.applyCurrent()
                Keys.onEnterPressed: root.applyCurrent()
                Keys.onEscapePressed: root.closeRequested()
                // GridView 標準では Home / End / PageUp / PageDown が効かない
                Keys.onPressed: event => {
                    const page = Math.max(1, Math.floor(height / cellHeight)) * cols;
                    switch (event.key) {
                    case Qt.Key_Home: currentIndex = 0; break;
                    case Qt.Key_End: currentIndex = count - 1; break;
                    case Qt.Key_PageUp: currentIndex = Math.max(0, currentIndex - page); break;
                    case Qt.Key_PageDown: currentIndex = Math.min(count - 1, currentIndex + page); break;
                    default: return;
                    }
                    event.accepted = true;
                }

                delegate: WallpaperCard {
                    width: grid.cellWidth
                    height: grid.cellHeight
                    selected: GridView.isCurrentItem
                    isCurrent: filePath === Wallpaper.current
                    onMoved: grid.currentIndex = index
                    onClicked: {
                        grid.currentIndex = index;
                        root.applyCurrent();
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: Wallpaper.count === 0
                    text: Wallpaper.dir + " に画像がありません"
                    role: Typography.bodyLarge
                    color: Colors.m3OnSurfaceVariant
                }
            }

            // フッター: 選択中の壁紙の配色プレビュー (適用はしない)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["primary", "secondary", "tertiary", "primary_container", "surface"]
                    Rectangle {
                        id: sw
                        required property string modelData
                        readonly property var pv: grid.currentItem ? Wallpaper.preview(grid.currentItem.filePath) : null
                        width: 32
                        height: 32
                        radius: Shapes.full
                        color: pv ? pv[modelData] : Colors.m3SurfaceContainerHighest
                        border.width: 1
                        border.color: Colors.m3OutlineVariant
                    }
                }
                Label {
                    text: "配色プレビュー"
                    role: Typography.labelMedium
                    color: Colors.m3OnSurfaceVariant
                    Layout.leftMargin: 4
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "矢印で選択  ·  Enter で適用  ·  Esc で閉じる"
                    role: Typography.labelMedium
                    color: Colors.m3OnSurfaceVariant
                }
            }
        }
}
