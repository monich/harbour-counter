import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import harbour.counter 1.0

import "../js/Utils.js" as Utils

Item {
    id: panel

    property int value
    property alias title: titleLabel.text
    property bool sounds
    property bool vibra
    property bool active

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

        y: Math.max(titleLabel.y + titleLabel.height + Theme.paddingLarge, Math.floor((plusButton.y - height)/2))
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
        id: plusButton

        text: "+"
        font: spinners.font
        anchors.centerIn: parent
        preferredWidth: parent.width/2
        onClicked: plus()
    }

    RoundButton {
        text: "-"
        font: spinners.font
        readonly property real y1: plusButton.y + plusButton.height + Math.round(height/2)
        readonly property real y2: Math.round((plusButton.y + plusButton.height + parent.height - height)/2)
        y: Math.min(y1, y2)
        preferredWidth: Math.round(panel.width/3)
        textOffset: -Theme.paddingSmall
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: minus()
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

    function plus() {
        panel.updateCounter(value + 1)
        if (plusSound.item) {
            plusSound.item.play()
        }
        if (buzz.item) {
            buzz.item.play()
        }
    }

    function minus() {
        if (value > 0) {
            panel.updateCounter(value - 1)
            if (minusSound.item) {
                minusSound.item.play()
            }
            if (buzz.item) {
                buzz.item.play()
            }
        }
    }

    Loader {
        id: plusSound

        active: panel.sounds
        sourceComponent: Component {
            SoundEffect {
                source: "sounds/plus.wav"
            }
        }
    }

    Loader {
        id: minusSound

        active: panel.sounds
        sourceComponent: Component {
            SoundEffect {
                source: "sounds/minus.wav"
            }
        }
    }

    Loader {
        id: buzz

        active: panel.vibra
        source: "Buzz.qml"
    }

    ConfigurationValue {
        id: configUseVolumeKeys

        key: Utils.configKeyUseVolumeKeys
        defaultValue: Utils.configDefaultUseVolumeKeys
    }

    MediaKey {
        enabled: panel.active && configUseVolumeKeys.value
        key: Qt.Key_VolumeUp
        onPressed: plus()
        onRepeat: plus()
    }

    MediaKey {
        enabled: panel.active && configUseVolumeKeys.value
        key: Qt.Key_VolumeDown
        onPressed: minus()
        onRepeat: minus()
    }

    Permissions {
        enabled: panel.active && configUseVolumeKeys.value
        autoRelease: true
        applicationClass: "camera"

        Resource {
            id: volumeKeysResource
            type: Resource.ScaleButton
            optional: true
        }
    }
}
