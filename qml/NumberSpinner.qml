import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: spinner

    property bool animated: true
    property alias hasBackground: background.visible
    property alias backgroundColor: background.color
    property alias cornerRadius: background.radius
    property alias interactive: view.interactive
    property color color: HarbourUtil.invertedColor(background.color)
    property string digitItem

    readonly property int number: view.actualNumber

    readonly property int _defaultWidth: Math.ceil(height * 3 / 5)

    implicitWidth: (hasBackground || !view.currentItem || !view.currentItem.item) ? _defaultWidth :  view.currentItem.item.implicitWidth

    function setNumber(n) {
        view.currentIndex = (n + 5) % 10
    }

    Sound {
        id: tick

        source: "sounds/roll.wav"
    }

    Rectangle {
        id: background

        anchors.fill: parent
        radius: Theme.paddingMedium
        color: Theme.primaryColor
        readonly property color color1: Theme.rgba(color, Counter.opacityFaint)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Counter.darkOnLight ? background.color1 : background.color }
            GradientStop { position: 1.0; color: Counter.darkOnLight ? background.color : background.color1 }
        }
    }

    PathView {
        id: view

        clip: true
        anchors.fill: parent
        snapMode: PathView.SnapOneItem
        maximumFlickVelocity: Theme.maximumFlickVelocity
        highlightMoveDuration: animated ? 250 : 0
        model: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        pathItemCount: model.length
        offset: 5 // initial value (zero)
        path: Path {
            id: path

            startX: view.width/2
            startY: - 4 * view.height - view.height / 2

            PathLine {
                x: path.startX
                y: path.startY + view.pathItemCount * view.height
            }
        }
        delegate: Loader {
            id: numberLoader

            Binding {
                target: numberLoader.item
                property: "tight"
                value: !hasBackground
            }

            Binding {
                target: numberLoader.item
                property: "text"
                value: modelData
            }

            Binding {
                target: numberLoader.item
                property: "color"
                value: spinner.color
            }

            height: parent.height
            source: digitItem
        }
        onCurrentIndexChanged: {
            if (moving) {
                tick.play()
            } else {
                updateActualNumber()
            }
        }
        onMovingChanged: if (!moving) view.updateActualNumber()
        function updateActualNumber() { actualNumber = (currentIndex + 5) % 10 }
        property int actualNumber
    }
}
