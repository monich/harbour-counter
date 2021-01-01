import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import harbour.counter 1.0

import "../js/Utils.js" as Utils

CoverBackground {
    id: cover

    readonly property url plusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-plus-dark.svg" :  "cover-plus.svg"))
    readonly property url minusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-minus-dark.svg" :  "cover-minus.svg"))
    readonly property url coverItemUrl: Qt.resolvedUrl((configCover.value >= 0 && configCover.value < Utils.coverItems.length) ?
        Utils.coverItems[configCover.value] : Utils.coverItems[Utils.configDefaultCoverType])
    property alias coverItem: coverItemLoader.item

    Loader {
        id: coverItemLoader

        anchors.fill: cover
        source: coverItemUrl
    }

    Binding {
        target: coverItem
        property: "model"
        value: coverModel
    }

    function inc(pos) {
        coverItem.inc(pos);
        if (plusSound.item) {
            plusSound.item.play()
        }
        if (buzz.item) {
            buzz.item.play()
        }
    }

    function dec(pos) {
        if (coverItem.dec(pos)) {
            if (minusSound.item) {
                minusSound.item.play()
            }
            if (buzz.item) {
                buzz.item.play()
            }
        }
    }

    CounterFavoritesModel {
        id: coverModel

        sourceModel: CounterListModel
    }

    ConfigurationValue {
        id: configSounds

        key: Utils.configKeySounds
        defaultValue: Utils.configDefaultSounds
    }

    ConfigurationValue {
        id: configVibra

        key: Utils.configKeyVibra
        defaultValue: Utils.configDefaultVibra
    }

    ConfigurationValue {
        id: configCover

        key: Utils.configKeyCoverType
        defaultValue: Utils.configDefaultCoverType
    }

    Loader {
        id: buzz

        active: configVibra.value
        source: "Buzz.qml"
    }

    Loader {
        id: plusSound

        active: configSounds.value
        sourceComponent: Component {
            SoundEffect { source: "sounds/plus.wav" }
        }
    }

    Loader {
        id: minusSound

        active: configSounds.value
        sourceComponent: Component {
            SoundEffect { source: "sounds/minus.wav" }
        }
    }

    CoverActionList {
        enabled: coverItem && coverItem.count === 1
        CoverAction {
            iconSource: cover.minusIconSource
            onTriggered: cover.dec(0)
        }
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: cover.inc(0)
        }
    }

    CoverActionList {
        enabled: coverItem && coverItem.count > 1
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: cover.inc(0)
        }
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: cover.inc(1)
        }
    }
}
