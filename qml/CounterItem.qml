import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: panel

    property alias value: frontPanel.value
    property alias favorite: backPanel.favorite
    property alias canChangeFavorite: backPanel.canChangeFavorite
    property alias changeTime: backPanel.changeTime
    property alias resetTime: backPanel.resetTime
    property alias counterId: backPanel.counterId
    property alias flipped: flipable.flipped
    property string link
    property string title
    property bool flipping
    property bool currentItem

    signal flip()
    signal clearLink()
    signal resetCounter()
    signal toggleFavorite()
    signal switchToLinked()
    signal updateCounter(var value)
    signal updateTitle(var value)

    Flipable {
        id: flipable

        anchors {
            fill: parent
            margins: Theme.paddingMedium
        }

        property bool flipped
        front: CounterFront {
            id: frontPanel

            anchors.fill: parent
            visible: rotation.angle < 90
            active: visible && Qt.application.active && currentItem
            title: panel.title
            hasLink: panel.link.length > 0

            onFlip: panel.flip()
            onUpdateCounter: panel.updateCounter(value)
            onSwitchToLinked: panel.switchToLinked()
        }
        back: CounterBack {
            id: backPanel

            anchors.fill: parent
            visible: rotation.angle >= 90
            title: panel.title
            link: panel.link

            onFlip: panel.flip()
            onUpdateTitle: panel.updateTitle(value)
            onClearLink: panel.clearLink()
            onToggleFavorite: panel.toggleFavorite()
            onReset: {
                panel.flip()
                panel.resetCounter()
            }
        }
        transform: Rotation {
            id: rotation

            origin.x: flipable.width/2
            origin.y: flipable.height/2
            axis {
                x: 0
                y: 1
                z: 0
            }
        }
        states: State {
            name: "back"
            PropertyChanges {
                target: rotation
                angle: 180
            }
            when: flipable.flipped
        }
        transitions: Transition {
            SequentialAnimation {
                ScriptAction { script: flipping = true; }
                NumberAnimation {
                    id: flipAnimation

                    target: rotation
                    property: "angle"
                    duration: currentItem ? 500 : 0
                }
                ScriptAction { script: flipping = false; }
            }
        }
    }
}
