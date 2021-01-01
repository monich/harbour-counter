import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias source: image.source

    width: Theme.coverSizeSmall.width/2
    height: Theme.itemSizeSmall

    Image {
        id: image

        anchors.centerIn: parent
        sourceSize.height: Theme.iconSizeSmall
    }
}
