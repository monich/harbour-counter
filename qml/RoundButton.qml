import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "harbour"

MouseArea {
    id: button

    property alias imageSource: image.source
    property color color: Theme.primaryColor
    property color highlightColor: Theme.highlightColor
    property color highlightBackgroundColor: Theme.highlightBackgroundColor
    property real buttonSize: Theme.buttonWidthSmall

    readonly property bool down: pressed && containsMouse
    readonly property bool _showPress: down || pressTimer.running

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    height: width

    onPressed: pressTimer.restart()

    onCanceled: pressTimer.stop()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: _showPress ?
                   Theme.rgba(button.highlightBackgroundColor, Theme.highlightBackgroundOpacity) :
                   Theme.rgba(button.color, HarbourTheme.opacityFaint)

        opacity: button.enabled ? 1.0 : HarbourTheme.opacityLow

        HarbourHighlightIcon {
            id: image

            readonly property real imageSize: Math.round(buttonSize/4)
            anchors.centerIn: parent
            sourceSize.width: imageSize
            sourceSize.height: imageSize
            highlightColor: _showPress ? button.highlightColor : button.color
        }
    }

    Timer {
        id: pressTimer
        interval: 64
    }
}
