import QtQuick 2.0
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
    }
}
