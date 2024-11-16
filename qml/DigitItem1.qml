import QtQuick 2.0
import Sailfish.Silica 1.0

// NumberSpinner expects the rendering component to have these properties:
//
// property bool tight
// property string text
// property color color
//
// The component is supposed to adjust its implicitWidth based on its height.

Item {
    property bool tight
    property alias text: text.text
    property alias color: text.color

    implicitWidth: text.paintedWidth ? text.paintedWidth : text.implicitWidth

    Text {
        id: text

        height: parent.height
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font {
            family: Theme.fontFamilyHeading
            weight: Font.Bold
            pixelSize: text.height
        }
        minimumPixelSize: Theme.fontSizeExtraSmall
        fontSizeMode: Text.Fit
    }
}
