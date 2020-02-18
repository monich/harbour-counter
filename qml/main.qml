import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

ApplicationWindow {
    id: appWindow

    allowedOrientations: Orientation.Portrait

    Component.onCompleted: CounterListModel.saveFile = "counters.json"

    initialPage: Component { MainPage { } }
    cover: Component { CoverPage { } }

    Connections {
        target: HarbourSystemTime
        onPreNotify: Date.timeZoneUpdated()
        onNotify: CounterListModel.timeChanged()
    }
}
