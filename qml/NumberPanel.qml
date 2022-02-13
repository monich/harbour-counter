import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: panel

    opacity: enabled ? 1 : 0
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property int number
    property int count: 1
    property real horizontalMargins
    property bool animated: true
    property color backgroundColor: Theme.primaryColor
    property bool hasBackground: true
    property bool interactive: true
    property color color: Counter.invertedColor(backgroundColor)
    property bool completed
    property alias spacing: row.spacing
    property alias font: sample.font

    signal updateNumber(var newValue)

    Component.onCompleted: completed = true
    onNumberChanged: repeater.updateSpinners()

    Text {
        id: sample

        text: "0"
        visible: false
        width: Math.round((panel.width + spacing)/count) - spacing - horizontalMargins
        minimumPixelSize: Theme.fontSizeExtraSmall
        fontSizeMode: Text.Fit
        font {
            family: Theme.fontFamilyHeading
            pixelSize: Theme.fontSizeHuge
            weight: Font.Bold
        }
    }

    Row {
        id: row

        anchors.centerIn: parent

        Repeater {
            id: repeater

            model: panel.count

            property int updatingSpinners

            Component.onCompleted: updateSpinners()
            onCountChanged: updateSpinners()

            function updateSpinners() {
                // Update all items
                repeater.updatingSpinners++
                var k = 1
                for (var i = count - 1; i >= 0; i--) {
                    var item = itemAt(i)
                    if (item && item.completed) {
                        item.setNumber(Math.floor((number % (k * 10))/k))
                    }
                    k *= 10
                }
                repeater.updatingSpinners--
            }

            NumberSpinner {
                anchors.verticalCenter: parent.verticalCenter
                digitWidth: Math.ceil(sample.paintedWidth)
                digitHeight: Math.ceil(sample.paintedHeight)
                font: panel.font
                color: panel.color
                animated: panel.animated && panel.completed
                interactive: panel.interactive
                hasBackground: panel.hasBackground
                backgroundColor: panel.backgroundColor
                horizontalMargins: panel.horizontalMargins
                Component.onCompleted: repeater.updateSpinners()
                onNumberChanged:  {
                    if (!repeater.updatingSpinners) {
                        var n = 0
                        var k = 1
                        for (var i = count - 1; i >= 0; i--) {
                            n += repeater.itemAt(i).number * k
                            k *= 10
                        }
                        if (panel.number != n) {
                            panel.updateNumber(n)
                        }
                    }
                }
            }
        }
    }

    Behavior on opacity { FadeAnimation { } }
}
