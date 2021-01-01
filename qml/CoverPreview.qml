import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

import "harbour"

Rectangle {
    id: root

    property bool selected
    property string source
    property alias value: sampleModel.value
    readonly property url plusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-plus-dark.svg" :  "cover-plus.svg"))
    readonly property url minusIconSource: Qt.resolvedUrl("images/" + (HarbourTheme.darkOnLight ? "cover-minus-dark.svg" :  "cover-minus.svg"))

    signal clicked()

    width: Theme.coverSizeSmall.width
    height: Theme.coverSizeSmall.height
    color: Theme.rgba(Theme.highlightBackgroundColor, mouseArea.pressed ?
        Theme.highlightBackgroundOpacity : HarbourTheme.opacityFaint)
    radius: Theme.paddingSmall
    border {
        color: Theme.highlightColor
        width: root.selected ? Theme.paddingSmall/2 : 0
    }
    layer.enabled: mouseArea.pressed
    layer.effect: HarbourPressEffect {
        source: root
    }

    Loader {
        id: coverItemLoader

        width: Theme.coverSizeLarge.width
        height: Theme.coverSizeLarge.height
        scale: Theme.coverSizeSmall.width/Theme.coverSizeLarge.width
        anchors.centerIn: parent
        source: Qt.resolvedUrl(root.source)
    }

    CounterSampleModel {
        id: sampleModel
    }

    Binding {
        target: coverItemLoader.item
        property: "model"
        value: sampleModel
    }

    Grid {
        anchors.bottom: parent.bottom
        columns: 2

        ActionButton {
            width: root.width/2
            source: root.minusIconSource
        }

        ActionButton {
            width: root.width/2
            source: root.plusIconSource
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        onClicked: root.clicked()
    }
}
