.pragma library

var configRoot = "/apps/" + appName() + "/"

var configKeySounds = configRoot + "sounds"
var configDefaultSounds = false

var configKeyVibra = configRoot + "vibra"
var configDefaultVibra = true

var configKeyUseVolumeKeys = configRoot + "useVolumeKeys"
var configDefaultUseVolumeKeys = true

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
