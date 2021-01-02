import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Page {
    id: page

    backNavigation: false
    showNavigationIndicator: false

    property bool flipped
    property var remorsePopup
    property var buzz
    property Item reorderHint

    readonly property int maxCounters: Math.floor(list.width/Theme.itemSizeExtraSmall)
    readonly property bool remorsePopupVisible: remorsePopup ? remorsePopup.visible : false

    Component {
        id: buzzComponent

        Buzz { }
    }

    Component {
        id: hintComponent

        InteractionHintLabel {
            id: hintLabel

            visible: opacity > 0.0
            opacity: (hintTimer.running || hintMouseArea.pressed) ? 1.0 : 0.0
            width: parent.width - 2 * Theme.paddingMedium
            height: Math.max(parent.height/2, width)
            z: parent.z + 1
            radius: Theme.paddingMedium
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Theme.paddingMedium
            }

            // This mouse area serves two purposes - 1) allowing the user
            // to prevent the hint from disappearing by pressing it; and
            // 2) consuming mouse event to stop QtQuick from dying of stack
            // overflow when hint is tapped.
            MouseArea {
                id: hintMouseArea

                anchors.fill: parent
            }

            // 1 sec to fade in, 3 sec to show (= 4000 ms), then 1 sec
            // to fade out unless the user is pressing the hint
            Timer {
                id: hintTimer

                interval: 4000
            }

            Behavior on opacity { FadeAnimation { duration: 1000 } }

            function show() { hintTimer.restart() }
        }
    }

    function considerShowingReorderHint() {
        if (CounterSettings.reorderHintCount < CounterSettings.maxReorderHintCount) {
            if (!reorderHint) {
                reorderHint = hintComponent.createObject(list, {
                    //: Hint text
                    //% "To move this counter to a different position in the list, press and hold the desired position in the switcher below"
                    text: qsTrId("counter-hint-how_to_reorder")
                })
            }
            reorderHint.show()
            CounterSettings.reorderHintCount++
        }
    }

    Connections {
        target: CounterListModel
        onRowsMoved: {
            if (!buzz) buzz = buzzComponent.createObject(page)
            buzz.play()
        }
        onRowsInserted: considerShowingReorderHint()
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
                onClicked: pageStack.push("SettingsPage.qml", { "title" : text })
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

            y : Screen.height - height
            anchors.horizontalCenter: parent.horizontalCenter
            visible: list.count > 1

            Repeater {
                model: CounterListModel
                FlatSwitch {
                    readonly property int modelValue: model.value
                    height: Theme.itemSizeExtraSmall
                    width: Theme.itemSizeExtraSmall
                    automaticCheck: false
                    checked: model.index === list.currentIndex
                    highlighted: model.favorite
                    onClicked: {
                        if (!checked) scrollAnimation.animateTo(index)
                        considerShowingReorderHint()
                    }
                    onPressAndHold: {
                        var newIndex = model.index
                        if (list.currentIndex !== newIndex) {
                            CounterListModel.moveCounter(list.currentIndex, newIndex)
                            list.positionViewAtIndex(newIndex, ListView.Center)
                            // And don't show any more hints:
                            CounterSettings.reorderHintCount = CounterSettings.maxReorderHintCount
                        }
                    }
                    // Cover action selects the corresponding counter in the list.
                    // Note that these switches always exist, while list delegates
                    // may be destroyed and re-created on demand. That's why the
                    // value is tracked here rather than in the list.
                    onModelValueChanged: {
                        if (!CounterListModel.updatingLinkedCounter) {
                            list.positionViewAtIndex(model.index, ListView.Center)
                        }
                    }
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
                duration = Math.min(700, Math.max(350, 175*(Math.abs(to - from)/list.width)))
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
            height: switcher.visible ? switcher.y : (Screen.height - Theme.paddingSmall)
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            flickDeceleration: maximumFlickVelocity
            interactive: !scrollAnimation.running
            quickScrollEnabled: false
            clip: !currentItem || !currentItem.flipping
            model: CounterListModel
            delegate: CounterItem {
                width: list.width
                height: list.height
                flipped: page.flipped
                counterId: model.modelId
                value: model.value
                favorite: model.favorite
                currentItem: ListView.isCurrentItem
                canChangeFavorite: list.count > 1
                title: model.title
                link: model.link
                sounds: CounterSettings.soundsEnabled
                vibra: CounterSettings.vibraEnabled
                changeTime: model.changeTime
                resetTime: model.resetTime
                onFlip: page.flipped = !page.flipped
                onUpdateCounter: model.value = value
                onUpdateTitle: model.title = value
                onClearLink: model.link = ""
                onToggleFavorite: model.favorite = !model.favorite
                onResetCounter: CounterListModel.resetCounter(model.index)
                onSwitchToLinked: {
                    var index = CounterListModel.findCounter(model.link)
                    if (index >= 0) {
                        scrollAnimation.animateTo(index)
                    }
                }
            }
            onCurrentIndexChanged: {
                model.currentIndex = currentIndex
                if (remorsePopupVisible) remorsePopup.cancel()
            }
        }
    }
}
