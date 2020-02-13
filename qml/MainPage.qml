import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0
import org.nemomobile.configuration 1.0

import "../js/Utils.js" as Utils

Page {
    id: page

    backNavigation: false
    showNavigationIndicator: false

    property bool flipped
    property var remorsePopup

    readonly property int maxCounters: Math.floor(list.width/Theme.itemSizeExtraSmall)
    readonly property bool remorsePopupVisible: remorsePopup ? remorsePopup.visible : false

    ConfigurationValue {
        id: configSounds

        key: Utils.configKeySounds
        defaultValue: Utils.configDefaultSounds
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: menu

            visible: opacity > 0
            opacity: (flipped && !remorsePopupVisible) ? 1 : 0

            Behavior on opacity { FadeAnimation { duration: 500 } }

            onActiveChanged: {
                if (!active) {
                    // Hide disabled and show enabled items when menu is not visible
                    addCounterMenuItem.visible = addCounterMenuItem.enabled
                    removeCounterMenuItem.visible = removeCounterMenuItem.enabled
                }
            }

            MenuItem {
                //: Pulley menu item
                //% "Settings"
                text: qsTrId("counter-menu-settings")
                onClicked: pageStack.push("../settings/SettingsPage.qml", { "title" : text })
            }
            MenuItem {
                id: removeCounterMenuItem

                //: Pulley menu item
                //% "Delete this counter"
                text: qsTrId("counter-menu-delete_counter")
                enabled: list.count > 1
                onEnabledChanged: if (!menu.active) visible = enabled
                onClicked: {
                    var index = list.currentIndex
                    if (!remorsePopup) remorsePopup = remorsePopupComponent.createObject(page)
                    //: Remorse popup text
                    //% "Deleting this counter"
                    remorsePopup.execute(qsTrId("counter-remorse-delete_counter"),
                        function() { CounterListModel.deleteCounter(index) })
                }
            }
            MenuItem {
                id: addCounterMenuItem

                //: Pulley menu item
                //% "New counter"
                text: qsTrId("counter-menu-new_counter")
                enabled: (list.count + 1) <= maxCounters
                onEnabledChanged: if (!menu.active) visible = enabled
                onClicked: scrollAnimation.animateTo(CounterListModel.addCounter())
            }
        }

        Component {
            id: remorsePopupComponent

            RemorsePopup { }
        }

        // Bind coordinates to screen height so that on-screen keyboard
        // doesn't squash the layout
        Row {
            id: switcher

            y : Screen.height - height - Theme.paddingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            visible: list.count > 1

            Repeater {
                model: CounterListModel
                Item {
                    readonly property int modelValue: model.value
                    height: Theme.itemSizeExtraSmall
                    width: Theme.itemSizeExtraSmall
                    Switch {
                        anchors.centerIn: parent
                        automaticCheck: false
                        checked: model.index === list.currentIndex
                        highlighted: down || !model.favorite
                        onClicked: if (!checked) scrollAnimation.animateTo(index)
                    }
                    // Cover action selects the corresponding counter in the list.
                    // Note that these switches always exist, while list delegates
                    // may be destroyed and re-created on demand. That's why the
                    // value is tracked here rather than in the list.
                    onModelValueChanged: list.positionViewAtIndex(model.index, ListView.Center)
                }
            }
        }

        NumberAnimation {
            id: scrollAnimation

            target: list
            property: "contentX"
            duration: 500
            easing.type: Easing.InOutQuad
            alwaysRunToEnd: true

            function animateTo(index) {
                from = list.contentX
                to = list.originX + index * list.width
                start()
            }
        }

        Connections {
            target: list.model
            onStateLoaded: list.positionViewAtIndex(target.currentIndex, ListView.Center)
        }

        SilicaListView {
            id: list

            x: Theme.paddingSmall
            y: Theme.paddingSmall
            width: parent.width - 2 * x
            height: (switcher.visible ? switcher.y : Screen.height) - Theme.paddingSmall
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            flickDeceleration: maximumFlickVelocity
            interactive: !scrollAnimation.running
            clip: !currentItem || !currentItem.flipping
            model: CounterListModel
            delegate: CounterItem {
                width: list.width
                height: list.height
                flipped: page.flipped
                value: model.value
                favorite: model.favorite
                currentItem: ListView.isCurrentItem
                canChangeFavorite: list.count > 1
                title: model.title
                sounds: configSounds.value
                changeTime: model.changeTime
                resetTime: model.resetTime
                onFlip: page.flipped = !page.flipped
                onUpdateCounter: model.value = value
                onUpdateTitle: model.title = value
                onToggleFavorite: model.favorite = !model.favorite
                onResetCounter: CounterListModel.resetCounter(model.index)
            }
            onCurrentIndexChanged: {
                model.currentIndex = currentIndex
                if (remorsePopupVisible) remorsePopup.cancel()
            }
        }
    }
}
