NAME = counter
PREFIX = harbour

TARGET = $${PREFIX}-$${NAME}
CONFIG += sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp glib-2.0 gobject-2.0
QT += qml quick dbus
LIBS += -ldl

QMAKE_CXXFLAGS += -Wno-unused-parameter -Wno-psabi
QMAKE_CFLAGS += -Wno-unused-parameter

TARGET_DATA_DIR = /usr/share/$${TARGET}

app_settings {
    # This path is hardcoded in jolla-settings
    TRANSLATIONS_PATH = /usr/share/translations
} else {
    TRANSLATIONS_PATH = $${TARGET_DATA_DIR}/translations
}

CONFIG(debug, debug|release) {
    DEFINES += DEBUG HARBOUR_DEBUG
}

# Directories

HARBOUR_LIB_DIR = $${_PRO_FILE_PWD_}/harbour-lib
LIBGLIBUTIL_DIR = $${_PRO_FILE_PWD_}/libglibutil

OTHER_FILES += \
    LICENSE \
    README.md \
    rpm/*.spec \
    *.desktop \
    js/*.js \
    settings/*.qml \
    qml/*.qml \
    qml/images/*.svg \
    qml/sounds/*.wav \
    icons/*.svg \
    translations/*.ts

# libglibutil

LIBGLIBUTIL_SRC = $${LIBGLIBUTIL_DIR}/src
LIBGLIBUTIL_INCLUDE = $${LIBGLIBUTIL_DIR}/include

INCLUDEPATH += \
    $${LIBGLIBUTIL_INCLUDE}

HEADERS += \
    $${LIBGLIBUTIL_INCLUDE}/*.h

SOURCES += \
    $${LIBGLIBUTIL_SRC}/gutil_log.c \
    $${LIBGLIBUTIL_SRC}/gutil_timenotify.c

# harbour-lib

HARBOUR_LIB_INCLUDE = $${HARBOUR_LIB_DIR}/include
HARBOUR_LIB_SRC = $${HARBOUR_LIB_DIR}/src
HARBOUR_LIB_QML = $${HARBOUR_LIB_DIR}/qml

INCLUDEPATH += \
    $${HARBOUR_LIB_INCLUDE}

HEADERS += \
    $${HARBOUR_LIB_INCLUDE}/HarbourDebug.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourJson.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourPluginLoader.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSystemTime.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourTheme.h \
    $${HARBOUR_LIB_SRC}/HarbourSystem.h

SOURCES += \
    $${HARBOUR_LIB_SRC}/HarbourJson.cpp \
    $${HARBOUR_LIB_SRC}/HarbourPluginLoader.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystemTime.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystem.cpp \
    $${HARBOUR_LIB_SRC}/HarbourTheme.cpp

HARBOUR_QML_COMPONENTS = \
    $${HARBOUR_LIB_QML}/HarbourFitLabel.qml

OTHER_FILES += $${HARBOUR_QML_COMPONENTS}

qml_components.files = $${HARBOUR_QML_COMPONENTS}
qml_components.path = $${TARGET_DATA_DIR}/qml/harbour
INSTALLS += qml_components

# App

HEADERS += \
    src/CounterDefs.h \
    src/CounterFavoritesModel.h \
    src/CounterListModel.h \
    src/CounterMediaPlugin.h \
    src/CounterPolicyPlugin.h

SOURCES += \
    src/main.cpp \
    src/CounterFavoritesModel.cpp \
    src/CounterListModel.cpp \
    src/CounterMediaPlugin.cpp \
    src/CounterPolicyPlugin.cpp

app_js.files = js/*.js
app_js.path = /usr/share/$${TARGET}/js/
INSTALLS += app_js

# Settings

settings_qml.files = settings/*.qml
settings_qml.path = /usr/share/$${TARGET}/settings/
INSTALLS += settings_qml

# Icons

ICON_SIZES = 86 108 128 256
for(s, ICON_SIZES) {
    icon_target = icon_$${s}
    icon_dir = icons/$${s}x$${s}
    $${icon_target}.files = $${icon_dir}/$${TARGET}.png
    $${icon_target}.path = /usr/share/icons/hicolor/$${s}x$${s}/apps
    INSTALLS += $${icon_target}
}

# Translations
TRANSLATION_SOURCES = \
  $${_PRO_FILE_PWD_}/qml \
  $${_PRO_FILE_PWD_}/settings \
  $${_PRO_FILE_PWD_}/src

defineTest(addTrFile) {
    in = $${_PRO_FILE_PWD_}/translations/harbour-$$1
    out = $${OUT_PWD}/translations/$${PREFIX}-$$1

    s = $$replace(1,-,_)
    lupdate_target = lupdate_$$s
    lrelease_target = lrelease_$$s

    $${lupdate_target}.commands = lupdate -noobsolete -locations none $${TRANSLATION_SOURCES} -ts \"$${in}.ts\" && \
        mkdir -p \"$${OUT_PWD}/translations\" &&  [ \"$${in}.ts\" != \"$${out}.ts\" ] && \
        cp -af \"$${in}.ts\" \"$${out}.ts\" || :

    $${lrelease_target}.target = $${out}.qm
    $${lrelease_target}.depends = $${lupdate_target}
    $${lrelease_target}.commands = lrelease -idbased \"$${out}.ts\"

    QMAKE_EXTRA_TARGETS += $${lrelease_target} $${lupdate_target}
    PRE_TARGETDEPS += $${out}.qm
    qm.files += $${out}.qm

    export($${lupdate_target}.commands)
    export($${lrelease_target}.target)
    export($${lrelease_target}.depends)
    export($${lrelease_target}.commands)
    export(QMAKE_EXTRA_TARGETS)
    export(PRE_TARGETDEPS)
    export(qm.files)
}

LANGUAGES = fr hu pl ru sv zh_CN

addTrFile($${NAME})
for(l, LANGUAGES) {
    addTrFile($${NAME}-$$l)
}

qm.path = $$TRANSLATIONS_PATH
qm.CONFIG += no_check_exist
INSTALLS += qm

OTHER_FILES += LICENSE
