.pragma library

var configRoot = "/apps/" + appName() + "/"

var configKeySounds = configRoot + "sounds"
var configDefaultSounds = false

var configKeyVibra = configRoot + "vibra"
var configDefaultVibra = true

var configKeyUseVolumeKeys = configRoot + "useVolumeKeys"
var configDefaultUseVolumeKeys = true

var configKeyCoverType = configRoot + "coverType"
var configDefaultCoverType = 1
var coverItems = ["CoverItem1.qml", "CoverItem2.qml"]

var configKeyReorderHintCount = configRoot + "reorderHintCount"
var maxReorderHintCount = 4

// Deduce package name from the path
function appName() {
    var parts = Qt.resolvedUrl("dummy").split('/')
    if (parts.length > 2) {
        var name = parts[parts.length-3]
        if (name.indexOf("-counter") >= 0) {
            return name
        }
    }
    return "harbour-counter"
}
