pragma Singleton
import QtQuick

QtObject {
    property var values: ({showCpu:true, showMemory:true, showNetwork:true, showWindowTitle:true, showTray:true,
        clock24:true, workspaces:5, dnd:false, osd:true, autoLockMinutes:0, screenOffMinutes:0})
    property string error: ""
    property bool saving: false
    signal saveRequested(var data)
    function save(data) { if (!saving) { saving = true; error = ""; saveRequested(data); } }
}
