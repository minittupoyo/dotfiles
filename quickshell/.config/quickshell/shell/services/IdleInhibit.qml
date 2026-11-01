pragma Singleton

import QtQuick
import Quickshell

// スリープ・ロックの抑止。実際の抑止 (IdleInhibitor) は、常に表示されているバーのウィンドウに付ける。
Singleton {
    property bool active: false

    function toggle() {
        active = !active;
    }
}
