import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

// The item is sized by loader to fill the entire cover
Item {
    id: root

    property alias model: repeater.model
    property alias count: repeater.count
    property int borderWidth
    property color counterBackgroundColor: Theme.rgba(Theme.highlightDimmerColor, Counter.opacityLow)
    property color counterBackgroundBorderColor: Theme.rgba(Theme.primaryColor, Counter.opacityLow)

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
        height: parent.height - Theme.itemSizeSmall
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
                    id: label

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

                Item {
                    width: parent.width
                    anchors {
                        top: label.bottom
                        bottom: counterDelegate.bottom
                    }

                    Rectangle {
                        width: counterDelegate.width
                        height: Theme.fontSizeHuge * 2
                        radius: Theme.paddingLarge
                        anchors.centerIn: parent
                        color: counterBackgroundColor
                        border {
                            width: borderWidth
                            color: counterBackgroundBorderColor
                        }

                        NumberPanel {
                            anchors {
                                fill: parent
                                margins: (repeater.visibleCount === 1) ? Theme.paddingLarge : Theme.paddingMedium
                            }
                            number: model.value
                            interactive: false
                            hasBackground: false
                            color: Theme.primaryColor
                            horizontalMargins: 0
                            count: valueString.length
                        }
                    }
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
