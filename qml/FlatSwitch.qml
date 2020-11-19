import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "harbour"

MouseArea {
    property bool checked
    property bool highlighted: down
    property bool automaticCheck: true
    readonly property bool down: pressed && containsMouse

    width: Theme.itemSizeMedium
    height: Theme.itemSizeMedium

    onClicked: {
        if (automaticCheck) {
            checked = !checked
        }
    }

    // It may sound slightly weird, but primaryColor is used for highlighting
    // and highlightColor as the normal color

    HarbourHighlightIcon {
        readonly property int size: Math.ceil(Math.min(parent.width, parent.height) * 0.7)
        anchors.centerIn: parent
        width: size
        height: size
        sourceSize.width: size
        sourceSize.height: size
        source: "images/press.svg"
        highlightColor: circle.border.color
        opacity: down ? 1 : 0
        Behavior on opacity { FadeAnimation { duration: 64 } }
    }

    Rectangle {
        id: circle

        readonly property int size: Math.ceil(Math.min(parent.width, parent.height) * 0.3)
        anchors.centerIn: parent
        width: size
        height: width
        radius: width/2
        color: Theme.rgba(highlighted ? Theme.primaryColor: Theme.highlightColor,
            checked ? HarbourTheme.opacityHigh : HarbourTheme.opacityFaint)
        border {
            color: highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor
            width: 2
        }
    }
}
