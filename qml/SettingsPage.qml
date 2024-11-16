import QtQuick 2.0
import QtFeedback 5.0
import Sailfish.Silica 1.0
import harbour.counter 1.0

Page {
    property alias title: pageHeader.title

    Column {
        id: content
        width: parent.width

        PageHeader {
            id: pageHeader
            //: Application title
            //% "Counter"
            title: qsTrId("counter-app_name")
        }

        TextSwitch {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            //: Text switch label
            //% "Play sounds"
            text: qsTrId("counter-switch-sounds")
            automaticCheck: false
            checked: CounterSettings.soundsEnabled
            onClicked: CounterSettings.soundsEnabled = !CounterSettings.soundsEnabled
        }

        TextSwitch {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            //: Text switch label
            //% "Vibrate"
            text: qsTrId("counter-switch-vibra")
            automaticCheck: false
            checked: CounterSettings.vibraEnabled
            onClicked: {
                CounterSettings.vibraEnabled = !CounterSettings.vibraEnabled
                if (buzz.item) {
                    buzz.item.play()
                }
            }

            Loader {
                id: buzz

                active: CounterSettings.vibraEnabled
                sourceComponent: Component {
                    ThemeEffect { effect: ThemeEffect.Press }
                }
            }
        }

        TextSwitch {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            //: Text switch label
            //% "Use volume keys"
            text: qsTrId("counter-switch-use_volume_keys")
            automaticCheck: false
            checked: CounterSettings.volumeKeysEnabled
            onClicked: CounterSettings.volumeKeysEnabled = !CounterSettings.volumeKeysEnabled
        }

        SectionHeader {
            //: Settings section header
            //% "Style"
            text: qsTrId("counter-section-style")
        }

        Column {
            spacing: Theme.paddingLarge
            x: Theme.horizontalPageMargin
            width: parent.width - x

            Repeater {
                model: CounterSettings.digitItems
                delegate: Row {
                    id: row

                    spacing: Theme.paddingLarge
                    readonly property string _digitItem: modelData
                    readonly property int _digitStyle: model.index

                    Repeater {
                        model: CounterSettings.coverItems
                        delegate: CoverPreview {
                            selected: (CounterSettings.coverStyle === model.index && CounterSettings.digitStyle === row._digitStyle)
                            source: modelData
                            digitItem: row._digitItem
                            value: model.index + 1
                            onClicked: {
                                CounterSettings.coverStyle = model.index
                                CounterSettings.digitStyle = row._digitStyle
                            }
                        }
                    }
                }
            }
        }
    }
}
