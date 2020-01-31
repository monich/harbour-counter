import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: panel

    property int value
    property alias title: titleLabel.text
    property bool sounds

    signal flip()
    signal updateCounter(var value)

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

    Label {
        id: titleLabel

        anchors {
            top: parent.top
            margins: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(implicitWidth, parent.width - 2 * Theme.paddingLarge)
        truncationMode: TruncationMode.Fade
        horizontalAlignment: Text.AlignLeft
        color: Theme.highlightColor
        textFormat: Text.PlainText
    }

    Text {
        width: parent.width
        anchors.centerIn: spinners
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font {
            pixelSize: spinners.font.pixelSize
            family: spinners.font.family
            bold: spinners.font.bold
            letterSpacing: spinners.font.letterSpacing + Theme.paddingMedium
        }
        text: value
        color: Theme.primaryColor
        visible: opacity > 0
        opacity: spinners.enabled ? 0 : 1
        Behavior on opacity { FadeAnimation { } }
    }

    NumberPanel {
        id: spinners

        y: (parent.height/2 - plus.height/2)/2 - height/2
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 2 * Theme.fontSizeHuge
        horizontalMargins: Theme.paddingLarge
        spacing: Theme.paddingMedium
        sounds: panel.sounds
        // Disable animation if change is triggered by cover action:
        animated: Qt.application.active
        count: 3
        enabled: value < 1000
        number: value
        onUpdateNumber: panel.updateCounter(newValue)
    }

    RoundButton {
        id: plus

        text: "+"
        font: spinners.font
        anchors.centerIn: parent
        preferredWidth: parent.width/2
        onClicked: {
            panel.updateCounter(value + 1)
            if (plusSound.item) {
                plusSound.item.play()
            }
        }

        Loader {
            id: plusSound

            active: model.sounds
            sourceComponent: Component {
                SoundEffect {
                    source: "sounds/plus.wav"
                }
            }
        }
    }

    RoundButton {
        text: "-"
        font: spinners.font
        readonly property real y1: plus.y + plus.height + Math.round(height/2)
        readonly property real y2: Math.round((plus.y + plus.height + parent.height - height)/2)
        y: Math.min(y1, y2)
        preferredWidth: Math.round(panel.width/3)
        textOffset: -Theme.paddingSmall
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            if (value > 0) {
                panel.updateCounter(value - 1)
                if (minusSound.item) {
                    minusSound.item.play()
                }
            }
        }

        Loader {
            id: minusSound

            active: model.sounds
            sourceComponent: Component {
                SoundEffect {
                    source: "sounds/minus.wav"
                }
            }
        }
    }

    IconButton {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: Theme.paddingMedium
        }
        icon.source: "image://theme/icon-m-about"
        onClicked: panel.flip()
    }
}
