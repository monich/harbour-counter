import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "constants.js" as Constants

SilicaFlickable {
    id: panel

    property string title
    property string link
    property date changeTime
    property date resetTime
    property alias counterId: linkModel.sourceId
    property alias favorite: favoriteSwitch.checked
    property alias canChangeFavorite: favoriteSwitch.enabled

    signal flip()
    signal reset()
    signal clearLink()
    signal toggleFavorite()
    signal updateTitle(var value)

    quickScrollEnabled: false

    onTitleChanged: titleField.text = title
    onLinkChanged: showCurrentLink()
    Component.onCompleted: showCurrentLink()

    function showCurrentLink() {
        if (link) {
            linkSwitch.checked = true
            linkSelector.updateValue()
        } else {
            linkSwitch.checked = false
            linkSelector.currentItem = null
        }
    }

    CounterLinkModel {
        id: linkModel

        sourceModel: CounterListModel
        onLayoutChanged: showCurrentLink()
    }

    Rectangle {
        id: panelBorder

        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        border {
            color: Theme.rgba(Theme.highlightColor, Counter.opacityLow)
            width: Constants.thinBorder
        }
        radius: Theme.paddingMedium
    }

    Column {
        id: options

        y: Theme.paddingMedium
        width: parent.width

        TextField {
            id: titleField

            x: Theme.paddingLarge
            width: parent.width - x
            //: Text field label (counter title)
            //% "Label"
            label: qsTrId("counter-title")
            //: Text field placeholder (counter title)
            //% "Short description of this counter"
            placeholderText: qsTrId("counter-title-placeholder")

            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: focus = false
            onActiveFocusChanged: {
                if (!activeFocus) {
                    panel.updateTitle(text)
                    panel.forceActiveFocus()
                }
            }
        }

        TextSwitch {
            id: favoriteSwitch

            x: Theme.paddingLarge
            width: parent.width - x
            //: Text switch label
            //% "Show on cover"
            text: qsTrId("counter-switch-favorite")
            //: Text switch description
            //% "No more than two counters can be shown on cover at the same time."
            description: qsTrId("counter-switch-favorite-description")
            automaticCheck: false
            onClicked: panel.toggleFavorite()
        }

        TextSwitch {
            id: linkSwitch

            x: Theme.paddingLarge
            width: parent.width - x
            enabled: linkModel.count > 0
            opacity: enabled ? 1.0 : 0.0
            //: Text switch label
            //% "Linked counter"
            text: qsTrId("counter-switch-linked")
            //: Text switch description
            //% "Linked counters change synchronously but can be reset independently."
            description: qsTrId("counter-switch-linked-description")
            automaticCheck: false
            onClicked: {
                if (checked) {
                    panel.clearLink()
                    if (checked) {
                        // Could be still checked if no link was selected
                        checked = false
                    }
                } else {
                    linkSelector.currentItem = null
                    checked = true // Force-check it
                }
            }
        }

        ComboBox {
            id: linkSelector

            x: Theme.paddingLarge + Theme.itemSizeExtraSmall
            width: parent.width - x - Theme.paddingLarge
            enabled: linkSwitch.visible && linkSwitch.checked
            opacity: enabled ? 1.0 : 0.0
            //: Combo box label
            //% "Link with"
            label: qsTrId("counter-combo-link_to")
            menu: ContextMenu {
                id: linkMenu

                x: 0
                width: linkSelector.width
                Repeater {
                    model: linkModel
                    MenuItem {
                        text: model.title
                        readonly property string modelId: model.modelId
                        onClicked: model.link = panel.counterId
                    }
                }
            }

            property int ignoreCurrentItemChange

            onCurrentItemChanged: {
                if (!ignoreCurrentItemChange) {
                    // Handle the case when ComboBox decides to update
                    // currentItem to a wrong value (which it sometimes
                    // does after the model has been reset)
                    updateValue()
                }
            }

            function updateValue() {
                var itemFound = null
                var items = linkMenu.children
                if (items) {
                    for (var i=0; i<items.length; i++) {
                        if (items[i].modelId === link) {
                            itemFound = items[i]
                            break;
                        }
                    }
                }
                // Prevent recursion
                ignoreCurrentItemChange++
                currentItem = itemFound
                ignoreCurrentItemChange--
            }

            Behavior on opacity { FadeAnimation { } }
        }
    }

    Button {
        // Hide the button so that it doesn't overlap with the menu
        visible: opacity > 0
        opacity: linkMenu.active ? 0.0 : 1.0
        y: Math.round(Math.max((parent.height - height)/2.0, options.y + options.height + Theme.paddingLarge))
        anchors.horizontalCenter: parent.horizontalCenter
        //: Button label (resets counter to zero)
        //% "Reset"
        text: qsTrId("counter-button-reset")
        onClicked: {
            panel.reset()
            resetSound.play()
        }
        Behavior on opacity { FadeAnimation { } }
        Sound {
            id: resetSound

            source: "sounds/reset.wav"
        }
    }

    Grid {
        id: timestamps

        rows: 2
        anchors {
            left: parent.left
            margins: Theme.paddingLarge
            verticalCenter: okButton.verticalCenter
        }
        Label {
            //: Label text (time and date of the last change)
            //% "Last change:"
            text: qsTrId("counter-label-last_change")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
        Row {
            Item {
                width: Theme.paddingMedium
                height: 1
            }
            Label {
                text: timestamps.dateTimeString(changeTime)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }
        }
        Label {
            //: Label text (time and date of the last reset)
            //% "Reset:"
            text: qsTrId("counter-label-reset")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
        Row {
            Item {
                width: Theme.paddingMedium
                height: 1
            }
            Label {
                text: timestamps.dateTimeString(resetTime)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }
        }

        function dateString(date) {
            return date.toLocaleDateString(Qt.locale(), "dd.MM.yyyy")
        }

        function timeString(time) {
            return time.toLocaleTimeString(Qt.locale(), "hh:mm")
        }

        function dateTimeString(dateTime) {
            return isNaN(dateTime) ? "" : (dateString(dateTime) + " " + timeString(dateTime))
        }
    }

    IconButton {
        id: okButton

        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: Theme.paddingMedium + panelBorder.border.width
        }
        icon.source: "image://theme/icon-m-acknowledge"
        onClicked: panel.flip()
    }
}
