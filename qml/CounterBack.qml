import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: panel

    property string title
    property date changeTime
    property date resetTime
    property alias favorite: favoriteSwitch.checked
    property alias sounds: soundsSwitch.checked
    property alias canChangeFavorite: favoriteSwitch.enabled

    signal flip()
    signal reset()
    signal toggleFavorite()
    signal toggleSounds()
    signal updateTitle(var value)

    onTitleChanged: titleField.text = title

    Rectangle {
        id: panelBorder

        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        border {
            color: Theme.rgba(Theme.highlightColor, HarbourTheme.opacityLow)
            width: 2
        }
        radius: Theme.paddingMedium
    }

    Column {
        id: options

        y: Theme.paddingMedium
        width: parent.width
        spacing: Theme.paddingMedium

        TextField {
            id: titleField

            x: Theme.paddingLarge
            width: parent.width - x
            //: Text field label (counter title)
            //% "Label"
            label: qsTrId("counter-title")
            //: Text field placeholder (counter title)
            //% "Short description of this counter"
            placeholderText: qsTrId("counter-title-placeholder")

            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: focus = false
            onActiveFocusChanged: {
                if (!activeFocus) {
                    panel.updateTitle(text)
                    panel.forceActiveFocus()
                }
            }
        }

        TextSwitch {
            id: favoriteSwitch

            x: Theme.paddingLarge
            width: parent.width - x
            //: Text switch label
            //% "Show on cover"
            text: qsTrId("counter-switch-favorite")
            //: Text switch description
            //% "No more than two counters can be shown on cover at the same time."
            description: qsTrId("counter-switch-favorite-description")
            automaticCheck: false
            onClicked: panel.toggleFavorite()
        }

        TextSwitch {
            id: soundsSwitch

            x: Theme.paddingLarge
            width: parent.width - x
            //: Text switch label
            //% "Play sounds"
            text: qsTrId("counter-switch-sounds")
            automaticCheck: false
            onClicked: panel.toggleSounds()
        }
    }

    Item {
        anchors {
            left: parent.left
            right: parent.right
            top: options.bottom
            bottom: timestamps.top
        }

        Button {
            anchors.centerIn: parent
            //: Button label (resets counter to zeto)
            //% "Reset"
            text: qsTrId("counter-button-reset")
            onClicked: {
                panel.reset()
                if (resetSound.item) {
                    resetSound.item.play()
                }
            }

            Loader {
                id: resetSound

                active: model.sounds
                sourceComponent: Component {
                    SoundEffect {
                        source: "sounds/reset.wav"
                    }
                }
            }
        }
    }

    Grid {
        id: timestamps

        rows: 2
        anchors {
            left: parent.left
            margins: Theme.paddingLarge
            verticalCenter: okButton.verticalCenter
        }
        Label {
            //: Label text (time and date of the last change)
            //% "Last change:"
            text: qsTrId("counter-label-last_change")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
        Row {
            Item {
                width: Theme.paddingMedium
                height: 1
            }
            Label {
                text: changeTime ? timestamps.dateTimeString(changeTime) : " "
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }
        }
        Label {
            //: Label text (time and date of the last reset)
            //% "Reset:"
            text: qsTrId("counter-label-reset")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
        Row {
            Item {
                width: Theme.paddingMedium
                height: 1
            }
            Label {
                text: resetTime ? timestamps.dateTimeString(resetTime) : " "
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }
        }

        function dateString(date) {
            return date.toLocaleDateString(Qt.locale(), "dd.MM.yyyy")
        }

        function timeString(time) {
            return time.toLocaleTimeString(Qt.locale(), "hh:mm")
        }

        function dateTimeString(dateTime) {
            return dateString(dateTime) + " " + timeString(dateTime)
        }
    }

    IconButton {
        id: okButton

        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: Theme.paddingMedium + panelBorder.border.width
        }
        icon.source: "image://theme/icon-m-acknowledge"
        onClicked: panel.flip()
    }
}
