import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: panel

    property int value
    property alias title: titleLabel.text
    property alias hasLink: linkIcon.visible
    property bool active

    signal flip()
    signal updateCounter(var value)
    signal switchToLinked()

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
            bold: spinners.font.weight
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
        font {
            family: Theme.fontFamilyHeading
            pixelSize: 2 * Theme.fontSizeHuge
            weight: Font.Bold
        }
        horizontalMargins: Theme.paddingLarge
        spacing: Theme.paddingMedium
        // Disable animation if change is triggered by cover action:
        animated: Qt.application.active
        count: 3
        enabled: value < 1000
        number: value
        onUpdateNumber: panel.updateCounter(newValue)
    }

    RoundButton {
        id: plusButton

        anchors.centerIn: parent
        buttonSize: parent.width/2
        imageSource: "images/plus.svg"
        onClicked: plus(true)
    }

    RoundButton {
        readonly property real y1: plusButton.y + plusButton.height + Math.round(height/2)
        readonly property real y2: Math.round((plusButton.y + plusButton.height + parent.height - height)/2)
        y: Math.min(y1, y2)
        anchors.horizontalCenter: parent.horizontalCenter
        buttonSize: Math.round(panel.width/3)
        imageSource: "images/minus.svg"
        onClicked: minus(true)
    }

    IconButton {
        id: linkIcon

        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: Theme.paddingMedium
        }
        icon.source: "image://theme/icon-m-link"
        onClicked: panel.switchToLinked()
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

    function plus(feedback) {
        panel.updateCounter(value + 1)
        if (plusSound.item) {
            plusSound.item.play()
        }
        if (feedback && buzz.item) {
            buzz.item.play()
        }
    }

    function minus(feedback) {
        if (value > 0) {
            panel.updateCounter(value - 1)
            if (minusSound.item) {
                minusSound.item.play()
            }
            if (feedback && buzz.item) {
                buzz.item.play()
            }
        }
    }

    Sound {
        id: plusSound

        source: "sounds/plus.wav"
    }

    Sound {
        id: minusSound

        source: "sounds/minus.wav"
    }

    Loader {
        id: buzz

        active: CounterSettings.vibraEnabled
        source: "Buzz.qml"
    }

    MediaKey {
        enabled: panel.active && CounterSettings.volumeKeysEnabled
        key: Qt.Key_VolumeUp
        onPressed: plus(false)
        onRepeat: plus(false)
    }

    MediaKey {
        enabled: panel.active && CounterSettings.volumeKeysEnabled
        key: Qt.Key_VolumeDown
        onPressed: minus(false)
        onRepeat: minus(false)
    }

    Permissions {
        enabled: panel.active && CounterSettings.volumeKeysEnabled
        autoRelease: true
        applicationClass: "camera"

        Resource {
            id: volumeKeysResource
            type: Resource.ScaleButton
            optional: true
        }
    }
}
