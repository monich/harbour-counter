import QtQuick 2.0

import "harbour"

// NumberSpinner expects the rendering component to have these properties:
//
// property bool tight
// property string text
// property color color
//
// The component is supposed to adjust its implicitWidth based on its height.

Item {
    property bool tight
    property string text
    property alias color: image.highlightColor

    implicitWidth: Math.ceil(image.width) + 2 * image.x

    HarbourHighlightIcon {
        id: image

        y: Math.ceil(parent.height * 3 / 26)
        x: tight ? Math.ceil(y / 2) : y
        sourceSize.height: Math.ceil(parent.height) - 2 * y
        source: text ? ("images/digit/" + text + ".svg") : ""
    }
}
