import QtQuick
import Quickshell.Services.Mpris
QtObject {
    property var players: Mpris.players.values
    property string selectedName: ""
    readonly property var player: players.find(p => p.dbusName === selectedName) ?? players.find(p => p.isPlaying) ?? players[0] ?? null
    function select(name) { selectedName = name; }
    onPlayersChanged: { if (selectedName && !players.some(p => p.dbusName === selectedName)) selectedName = ""; }
}
