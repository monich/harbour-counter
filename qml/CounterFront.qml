import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "constants.js" as Constants

Item {
    id: panel

    property int value
    property alias title: titleLabel.text
    property alias hasLink: linkIcon.visible
    property bool active

    signal flip()
    signal hapticFeedback()
    signal playPlusSound()
    signal playMinusSound()
    signal updateCounter(var value)
    signal switchToLinked()

    readonly property bool mediaKeysActive: active && CounterSettings.volumeKeysEnabled
    readonly property var permissions: Qt.createQmlObject(Counter.permissionsQml, panel, "Permissions")
    readonly property var volumeUp: Qt.createQmlObject(Counter.mediaKeyQml, panel, "VolumeKey")
    readonly property var volumeDown: Qt.createQmlObject(Counter.mediaKeyQml, panel, "VolumeKey")

    Binding { target: permissions; property: "enabled"; value: mediaKeysActive }
    Binding { target: volumeUp; property: "enabled"; value: mediaKeysActive }
    Binding { target: volumeUp;  property: "key"; value: Qt.Key_VolumeUp }
    Binding { target: volumeDown; property: "enabled"; value: mediaKeysActive }
    Binding { target: volumeDown;  property: "key"; value: Qt.Key_VolumeDown }

    Connections {
        target: volumeUp
        ignoreUnknownSignals: true
        onPressed: plus(false)
        onRepeat: plus(false)
    }

    Connections {
        target: volumeDown
        ignoreUnknownSignals: true
        onPressed: minus(false)
        onRepeat: minus(false)
    }

    Rectangle {
        id: panelBorder

        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        border {
            color: Theme.rgba(Theme.highlightColor, Counter.opacityLow)
            width: Constants.thinBorder
        }
        radius: Constants.cornerRadius
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

    NumberPanel {
        id: spinners

        x: Theme.paddingLarge
        y: Math.max(titleLabel.y + titleLabel.height + Theme.paddingLarge, Math.floor((plusButton.y - height)/2))
        width: parent.width - 2 * x
        spacing: Theme.paddingMedium
        // Disable animation if change is triggered by cover action:
        animated: active && Qt.application.active
        minCount: 3
        number: value
        onUpdateNumber: panel.updateCounter(newValue)
    }

    RoundButton {
        id: plusButton

        anchors.centerIn: parent
        buttonSize: parent.width/2
        imageSource: "images/plus.svg"
        onClicked: plus(CounterSettings.vibraEnabled)
    }

    RoundButton {
        readonly property real y1: plusButton.y + plusButton.height + Math.round(height/2)
        readonly property real y2: Math.round((plusButton.y + plusButton.height + parent.height - height)/2)
        y: Math.min(y1, y2)
        anchors.horizontalCenter: parent.horizontalCenter
        buttonSize: Math.round(panel.width/3)
        imageSource: "images/minus.svg"
        onClicked: minus(CounterSettings.vibraEnabled)
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
        panel.playPlusSound()
        if (feedback) {
            panel.hapticFeedback()
        }
    }

    function minus(feedback) {
        if (value > 0) {
            panel.updateCounter(value - 1)
            panel.playMinusSound()
            if (feedback) {
                panel.hapticFeedback()
            }
        }
    }
}
