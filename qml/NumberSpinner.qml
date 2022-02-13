import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Item {
    id: spinner

    implicitWidth: digitWidth + 2 * horizontalMargins
    implicitHeight: digitHeight + 2 * verticalMargins
    width: implicitWidth
    height: implicitHeight

    property real verticalMargins
    property real horizontalMargins
    property bool animated: true
    property bool completed
    property alias hasBackground: background.visible
    property alias backgroundColor: background.color
    property alias cornerRadius: background.radius
    property alias interactive: view.interactive
    property color color: Counter.invertedColor(background.color)
    property font font
    property real digitWidth
    property real digitHeight

    readonly property int number: view.actualNumber

    function setNumber(n) {
        view.currentIndex = (n + 5) % 10
    }

    Component.onCompleted: completed = true

    Sound {
        id: tick

        source: "sounds/roll.wav"
    }

    Rectangle {
        id: background

        anchors.fill: parent
        radius: horizontalMargins/2
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
        width: parent.width
        height: digitHeight
        anchors.centerIn: parent
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
        delegate: Text {
            width: view.width
            height: digitHeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font: spinner.font
            color: spinner.color
            minimumPixelSize: Theme.fontSizeExtraSmall
            fontSizeMode: Text.Fit
            text: modelData
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
