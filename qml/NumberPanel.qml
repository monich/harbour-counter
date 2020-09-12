import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Row {
    id: panel

    opacity: enabled ? 1 : 0

    property int number
    property int count: 1
    property real horizontalMargins
    property bool animated: true
    property color backgroundColor: Theme.primaryColor
    property bool hasBackground: true
    property bool interactive: true
    property bool sounds
    property alias color: sample.color
    property alias font: sample.font
    property bool completed

    signal updateNumber(var newValue)

    Component.onCompleted: completed = true
    onNumberChanged: repeater.updateSpinners()

    Text {
        id: sample

        font {
            family: Theme.fontFamilyHeading
            pixelSize: Theme.fontSizeHuge
            bold: true
        }
        visible: false
        color: HarbourTheme.invertedColor(backgroundColor)
    }

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
            font: sample.font
            color: sample.color
            animated: panel.animated && panel.completed
            interactive: panel.interactive
            hasBackground: panel.hasBackground
            backgroundColor: panel.backgroundColor
            sounds: panel.sounds
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

    Behavior on opacity { FadeAnimation { } }
}
