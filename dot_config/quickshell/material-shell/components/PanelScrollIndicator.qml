import QtQuick
import ".."

Item {
    id: indicator
    property var view: null
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
    width: Theme.scrollIndicatorWidth
    visible: !!view && view.contentHeight > view.height + 1
    Accessible.ignored: true
    Rectangle {
        width: parent.width
        height: Math.min(indicator.height, Math.max(Theme.scrollIndicatorMinLength, indicator.height * (indicator.view?.height ?? 0) / Math.max(1, indicator.view?.contentHeight ?? 0)))
        y: (indicator.height - height) * Math.max(0, Math.min(1, ((indicator.view?.contentY ?? 0) - (indicator.view?.originY ?? 0)) / Math.max(1, (indicator.view?.contentHeight ?? 0) - (indicator.view?.height ?? 0))))
        radius: width / 2
        color: Theme.outline
        opacity: indicator.view?.moving ? 1 : 0.5
    }
}
