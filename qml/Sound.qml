import QtQuick 2.0
import QtMultimedia 5.0
import harbour.counter 1.0

Loader {
    id: loader

    property url source

    active: CounterSettings.soundsEnabled
    sourceComponent: Component {
        SoundEffect { source: loader.source }
    }

    function play() {
        if (item) {
            item.play()
        }
    }
}
