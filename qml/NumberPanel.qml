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
    property color color: HarbourUtil.invertedColor(backgroundColor)
    property alias spacing: row.spacing
    property alias font: sample.font

    signal updateNumber(var newValue)

    property bool _completed

    Component.onCompleted: {
        digitsModel.number = panel.number
        _completed = true
    }

    onNumberChanged: digitsModel.number = panel.number

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

            model: CounterDigitsModel {
                id: digitsModel

                count: panel.count
                onNumberChanged: panel.updateNumber(number)
            }

            delegate: NumberSpinner {
                property bool _completed
                readonly property int digit: model.digit

                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                digitWidth: Math.ceil(sample.paintedWidth)
                digitHeight: Math.ceil(sample.paintedHeight)
                font: panel.font
                color: panel.color
                animated: panel.animated && panel._completed
                interactive: panel.interactive
                hasBackground: panel.hasBackground
                backgroundColor: panel.backgroundColor
                horizontalMargins: panel.horizontalMargins
                Component.onCompleted: {
                    setNumber(digit)
                    _completed = true
                }
                onDigitChanged: {
                    if (_completed) {
                        setNumber(digit)
                    }
                }
                onNumberChanged: {
                    if (panel._completed) {
                        model.digit = number
                    }
                }
            }
        }
    }

    Behavior on opacity { FadeAnimation { } }
}
