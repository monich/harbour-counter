import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: panel

    property int value
    property bool favorite
    property bool canChangeFavorite
    property date changeTime
    property date resetTime
    property string counterId
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

    property real _targetAngle

    function completeFlip() {
        flipping = false
        if (!flipped) {
            _targetAngle = 0
        }
    }

    onFlippedChanged: {
        if (!flipped) {
            _targetAngle = 360
        }
    }

    Flipable {
        id: flipable

        anchors {
            fill: parent
            margins: Theme.paddingMedium
        }

        property bool flipped

        front: CounterFront {
            anchors.fill: parent
            active: Qt.application.active && currentItem
            value: panel.value
            title: panel.title
            hasLink: panel.link.length > 0

            onFlip: panel.flip()
            onUpdateCounter: panel.updateCounter(value)
            onSwitchToLinked: panel.switchToLinked()
        }
        back: CounterBack {
            anchors.fill: parent
            title: panel.title
            link: panel.link
            changeTime: panel.changeTime
            resetTime: panel.resetTime
            counterId: panel.counterId
            favorite: panel.favorite
            canChangeFavorite: panel.canChangeFavorite
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

            origin {
                x: flipable.width/2
                y: flipable.height/2
            }
            axis {
                x: 0
                y: 1
                z: 0
            }
        }
        states: [
            State {
                name: "front"
                when: !flipable.flipped
                PropertyChanges {
                    target: rotation
                    angle: _targetAngle
                }
            },
            State {
                name: "back"
                when: flipable.flipped
                PropertyChanges {
                    target: rotation
                    angle: 180
                }
            }
        ]
        transitions: Transition {
            SequentialAnimation {
                ScriptAction { script: flipping = true; }
                NumberAnimation {
                    target: rotation
                    property: "angle"
                    duration: currentItem ? 500 : 0
                }
                ScriptAction { script: panel.completeFlip() }
            }
        }
    }
}
