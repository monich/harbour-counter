import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

MouseArea {
    id: button

    implicitWidth: Math.max(preferredWidth, buttonText.width+Theme.paddingMedium)

    property alias text: buttonText.text
    property alias font: buttonText.font
    property real textOffset
    property color color: Theme.primaryColor
    property color highlightColor: Theme.highlightColor
    property color highlightBackgroundColor: Theme.highlightBackgroundColor
    property real preferredWidth: Theme.buttonWidthSmall

    readonly property bool down: pressed && containsMouse
    readonly property bool _showPress: down || pressTimer.running

    onPressedChanged: {
        if (pressed) {
            pressTimer.start()
        }
    }
    onCanceled: pressTimer.stop()

    height: width

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: _showPress ?
                   Theme.rgba(button.highlightBackgroundColor, Theme.highlightBackgroundOpacity) :
                   Theme.rgba(button.color, HarbourTheme.opacityFaint)

        opacity: button.enabled ? 1.0 : HarbourTheme.opacityLow

        Label {
            id: buttonText

            anchors {
                centerIn: parent
                verticalCenterOffset: button.textOffset
            }
            color: _showPress ? button.highlightColor : button.color
        }
    }

    Timer {
        id: pressTimer
        interval: 64
    }
}
