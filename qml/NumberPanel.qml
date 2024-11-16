import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: panel

    opacity: enabled ? 1 : 0
    implicitWidth: row.width
    implicitHeight: Theme.itemSizeHuge

    property int number
    property int minCount: 1
    property alias count: digitsModel.count
    property bool animated: panel.visible
    property color backgroundColor: Theme.primaryColor
    property bool hasBackground: true
    property bool interactive: true
    property color color: HarbourUtil.invertedColor(backgroundColor)
    property alias spacing: row.spacing
    property string digitItem: CounterSettings.digitItem

    signal updateNumber(var newValue)

    property bool _completed
    readonly property real _aspectRatio: height ? width/height : 0

    Component.onCompleted: {
        digitsModel.number = panel.number
        _completed = true
    }

    onNumberChanged: digitsModel.number = panel.number

    ListView {
        id: row

        visible: opacity > 0
        height: parent.height
        width: contentWidth
        anchors.centerIn: parent
        orientation: ListView.Horizontal
        interactive: false
        scale: width && aspectRatio > parent._aspectRatio ? parent.width/width : 1

        readonly property real aspectRatio: height ? width/height : 0

        model: CounterDigitsModel {
            id: digitsModel

            minCount: panel.minCount
            onNumberChanged: panel.updateNumber(number)
        }

        delegate: NumberSpinner {
            property bool completed
            readonly property int digit: model.digit

            height: row.height
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            color: panel.color
            animated: panel.animated && completed && _completed
            interactive: panel.interactive
            hasBackground: panel.hasBackground
            backgroundColor: panel.backgroundColor
            digitItem: panel.digitItem

            Component.onCompleted: {
                setNumber(digit)
                completed = true
            }

            onDigitChanged: {
                if (completed) {
                    setNumber(digit)
                }
            }

            onNumberChanged: {
                if (completed) {
                    model.digit = number
                }
            }
        }
    }

    Behavior on opacity { FadeAnimation { } }
}
