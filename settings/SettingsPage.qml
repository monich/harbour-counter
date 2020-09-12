import QtQuick 2.0
import QtFeedback 5.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

import "../js/Utils.js" as Utils

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
            checked: configSounds.value
            onClicked: configSounds.value = !configSounds.value

            ConfigurationValue {
                id: configSounds

                key: Utils.configKeySounds
                defaultValue: Utils.configDefaultSounds
            }
        }

        TextSwitch {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            //: Text switch label
            //% "Vibrate"
            text: qsTrId("counter-switch-vibra")
            automaticCheck: false
            checked: configVibra.value
            onClicked: {
                configVibra.value = !configVibra.value
                if (buzz.item) {
                    buzz.item.play()
                }
            }

            ConfigurationValue {
                id: configVibra

                key: Utils.configKeyVibra
                defaultValue: Utils.configDefaultVibra
            }

            Loader {
                id: buzz

                active: configVibra.value
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
            checked: configUseVolumeKeys.value
            onClicked: configUseVolumeKeys.value = !configUseVolumeKeys.value

            ConfigurationValue {
                id: configUseVolumeKeys

                key: Utils.configKeyUseVolumeKeys
                defaultValue: Utils.configDefaultUseVolumeKeys
            }
        }
    }
}
