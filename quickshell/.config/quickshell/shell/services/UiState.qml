pragma Singleton

import QtQuick
import Quickshell

// モジュールをまたぐ UI の状態・合図。
Singleton {
    // クイック設定の開閉の合図 (バーのボタンから送り、QuickSettings が受ける)
    signal quickSettingsToggle()
    // クイック設定が開いているか (通知のポップアップが重ならないよう隠すのに使う)
    property bool quickSettingsOpen: false

    function toggleQuickSettings() {
        quickSettingsToggle();
    }
}
