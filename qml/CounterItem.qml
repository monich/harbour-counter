import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: panel

    property alias value: frontPanel.value
    property alias favorite: backPanel.favorite
    property alias canChangeFavorite: backPanel.canChangeFavorite
    property alias changeTime: backPanel.changeTime
    property alias resetTime: backPanel.resetTime
    property alias flipped: flipable.flipped
    property string title
    property bool sounds
    property bool flipping
    property bool currentItem

    signal flip()
    signal resetCounter()
    signal toggleFavorite()
    signal updateCounter(var value)
    signal updateTitle(var value)

    Component.onCompleted: {
        frontPanel.flip.connect(flip)
        frontPanel.updateCounter.connect(updateCounter)
        backPanel.flip.connect(flip)
        backPanel.updateTitle.connect(updateTitle)
        backPanel.toggleFavorite.connect(toggleFavorite)
    }

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
            sounds: panel.sounds
            title: panel.title
        }
        back: CounterBack {
            id: backPanel

            anchors.fill: parent
            visible: rotation.angle >= 90
            sounds: panel.sounds
            title: panel.title
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
