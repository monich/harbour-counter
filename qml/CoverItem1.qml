import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

// The item is sized by loader to fill the entire cover
Item {
    id: root

    property alias model: repeater.model
    property alias count: repeater.count

    signal selectCounter(var modelId)

    function inc(pos) {
        repeater.itemAt(pos).inc()
    }

    function dec(pos) {
        return repeater.itemAt(pos).dec()
    }

    Row {
        id: row

        x: (repeater.visibleCount === 1) ? Math.round((parent.width - width)/2) : Theme.paddingMedium
        height: parent.height
        spacing: Theme.paddingMedium

        Repeater {
            id: repeater

            readonly property int visibleCount: Math.min(repeater.count,2)
            delegate: Item {
                id: counterDelegate

                height: row.height
                width: (repeater.visibleCount === 1) ? Math.round(root.width - 4 * Theme.paddingLarge) : maxWidth

                readonly property real maxWidth: Math.floor((root.width - 2 * Theme.paddingMedium - (repeater.visibleCount - 1) * row.spacing)/repeater.visibleCount)
                readonly property string valueString: model.value

                Label {
                    anchors {
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: model.title
                    width: Math.min(implicitWidth, parent.width)
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: Text.AlignLeft
                    textFormat: Text.PlainText
                }
                Rectangle {
                    id: background

                    width: counterDelegate.width
                    height: width
                    radius: width/2
                    y: Math.round((row.height - height)/2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.rgba(Theme.primaryColor, Counter.opacityHigh)
                    readonly property color color1: Theme.rgba(Theme.primaryColor, Counter.opacityFaint)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Counter.darkOnLight ? background.color1 : background.color }
                        GradientStop { position: 1.0; color: Counter.darkOnLight ? background.color : background.color1 }
                    }
                }
                NumberPanel {
                    anchors.centerIn: background
                    width: background.width * 0.7
                    height: width/2
                    number: model.value
                    interactive: false
                    hasBackground: false
                    color: HarbourUtil.invertedColor(Theme.primaryColor)
                    horizontalMargins: 0
                    count: valueString.length
                }

                function inc() {
                    root.selectCounter(model.modelId)
                    model.value++
                }

                function dec() {
                    root.selectCounter(model.modelId)
                    if (model.value > 0) {
                        model.value--
                        return true
                    } else {
                        return false
                    }
                }
            }
        }
    }
}
