import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "constants.js" as Constants
import "harbour"

MouseArea {
    property bool checked
    property bool highlighted: _down
    property bool automaticCheck: true

    readonly property bool _down: pressed && containsMouse
    readonly property bool _showPress: _down || pressTimer.running

    width: Theme.itemSizeMedium
    height: Theme.itemSizeMedium

    onPressed: pressTimer.restart()

    onCanceled: pressTimer.stop()

    onClicked: {
        if (automaticCheck) {
            checked = !checked
        }
    }

    HarbourHighlightIcon {
        readonly property int _size: Math.ceil(Math.min(parent.width, parent.height) * 0.7)

        anchors.centerIn: parent
        width: _size
        height: _size
        sourceSize: Qt.size(_size, _size)
        source: "images/press.svg"
        highlightColor: circle.border.color
        visible: opacity > 0
        opacity: _showPress ? 1 : 0
        Behavior on opacity {
            enabled: !pressTimer.running
            FadeAnimation { }
        }
    }

    // It may sound slightly weird, but primaryColor is used for highlighting
    // and highlightColor as the normal color

    Rectangle {
        id: circle

        readonly property int _size: Math.ceil(Math.min(parent.width, parent.height) * 0.3)

        anchors.centerIn: parent
        width: _size
        height: width
        radius: width/2
        color: Theme.rgba(highlighted ? Theme.primaryColor: Theme.highlightColor,
            checked ? Counter.opacityHigh : Counter.opacityFaint)
        border {
            color: highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor
            width: Constants.thinBorder
        }
    }

    Timer {
        id: pressTimer
        interval: 64
    }
}
