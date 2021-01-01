import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import harbour.counter 1.0

import "../js/Utils.js" as Utils

CoverBackground {
    id: cover

    readonly property string plusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-plus-dark.svg" :  "cover-plus.svg"))
    readonly property string minusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-minus-dark.svg" :  "cover-minus.svg"))

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

    Row {
        id: row

        x: (repeater.visibleCount === 1) ? Math.round((parent.width - width)/2) : Theme.paddingMedium
        height: parent.height - Theme.itemSizeSmall
        spacing: Theme.paddingMedium

        Repeater {
            id: repeater

            readonly property int visibleCount: Math.min(repeater.count,2)
            model: CounterFavoritesModel { sourceModel: CounterListModel }
            delegate: Item {
                id: counterDelegate

                height: row.height
                width: (repeater.visibleCount === 1) ? Math.round(cover.width - 4 * Theme.paddingLarge) : maxWidth

                readonly property real maxWidth: Math.floor((cover.width - 2 * Theme.paddingMedium - (repeater.visibleCount - 1) * row.spacing)/repeater.visibleCount)
                readonly property string valueString: model.value

                Label {
                    id: label

                    anchors {
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: model.title
                    width: Math.min(implicitWidth, parent.width)
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: Text.AlignLeft
                    textFormat: Text.PlainText
                }

                Item {
                    width: parent.width
                    anchors {
                        top: label.bottom
                        bottom: counterDelegate.bottom
                    }

                    Rectangle {
                        width: counterDelegate.width
                        height: Theme.fontSizeHuge * 2
                        radius: Theme.paddingLarge
                        anchors.centerIn: parent
                        color: Theme.rgba(Theme.highlightDimmerColor, HarbourTheme.opacityLow)

                        NumberPanel {
                            anchors {
                                fill: parent
                                margins: (repeater.visibleCount === 1) ? Theme.paddingLarge : Theme.paddingMedium
                            }
                            number: model.value
                            interactive: false
                            hasBackground: false
                            color: Theme.primaryColor
                            horizontalMargins: 0
                            count: valueString.length
                        }
                    }
                }

                function inc() {
                    model.value++
                    if (plusSound.item) {
                        plusSound.item.play()
                    }
                    if (buzz.item) {
                        buzz.item.play()
                    }
                }

                function dec() {
                    if (model.value > 0) {
                        model.value--
                        if (minusSound.item) {
                            minusSound.item.play()
                        }
                        if (buzz.item) {
                            buzz.item.play()
                        }
                    }
                }
            }
        }
    }

    CoverActionList {
        enabled: repeater.count === 1
        CoverAction {
            iconSource: cover.minusIconSource
            onTriggered: repeater.itemAt(0).dec()
        }
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: repeater.itemAt(0).inc()
        }
    }

    CoverActionList {
        enabled: repeater.count > 1
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: repeater.itemAt(0).inc()
        }
        CoverAction {
            iconSource: cover.plusIconSource
            onTriggered: repeater.itemAt(1).inc()
        }
    }
}
