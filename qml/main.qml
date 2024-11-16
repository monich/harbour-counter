import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

ApplicationWindow {
    id: appWindow

    allowedOrientations: Orientation.Portrait

    Component.onCompleted: CounterListModel.saveFile = "counters.json"

    initialPage: MainPage { id: mainPage }
    cover: Component {
        CoverPage {
            onSelectCounter: mainPage.selectCounter(modelId)
            onPlayPlusSound: mainPage.playPlusSound()
            onPlayMinusSound: mainPage.playMinusSound()
        }
    }

    Connections {
        target: HarbourSystemTime
        onPreNotify: Date.timeZoneUpdated()
        onNotify: CounterListModel.timeChanged()
    }

    Binding {
        target: Counter
        property: "darkOnLight"
        value: "colorScheme" in Theme && Theme.colorScheme === Theme.DarkOnLight
    }
}
