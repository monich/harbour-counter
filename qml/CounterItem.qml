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
            id: frontPanel

            anchors.fill: parent
            visible: rotation.angle < 90 || rotation.angle > 270
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
            visible: !frontPanel.visible
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
