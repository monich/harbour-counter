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

    HarbourHighlightIcon {
        readonly property int size: Math.ceil(2*Math.min(parent.width, parent.height)/3)
        anchors.centerIn: parent
        width: size
        height: size
        sourceSize.width: size
        sourceSize.height: size
        source: "images/press.svg"
        highlightColor: Theme.highlightBackgroundColor
        opacity: down ? 1 : 0
        Behavior on opacity { FadeAnimation { duration: 64 } }
    }

    Rectangle {
        readonly property int size: Math.ceil(Math.min(parent.width, parent.height)/3)
        anchors.centerIn: parent
        width: size
        height: width
        radius: width/2
        color: Theme.rgba(highlighted ? Theme.highlightColor : Theme.primaryColor,
            checked ? HarbourTheme.opacityHigh : HarbourTheme.opacityFaint)
        border {
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            width: 2
        }
    }
}
