NAME = counter
PREFIX = harbour

TARGET = $${PREFIX}-$${NAME}
CONFIG += sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp mlite5 glib-2.0 gobject-2.0
QT += qml quick dbus
LIBS += -ldl

QMAKE_CXXFLAGS += -Wno-unused-parameter
QMAKE_CFLAGS += -Wno-unused-parameter

TARGET_DATA_DIR = /usr/share/$${TARGET}
TRANSLATIONS_PATH = $${TARGET_DATA_DIR}/translations

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
    qml/*.js \
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
    $${HARBOUR_LIB_INCLUDE}/HarbourBase45.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourDebug.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSystemTime.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourUtil.h

SOURCES += \
    $${HARBOUR_LIB_SRC}/HarbourBase45.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystemTime.cpp \
    $${HARBOUR_LIB_SRC}/HarbourUtil.cpp

HARBOUR_QML_COMPONENTS = \
    $${HARBOUR_LIB_QML}/HarbourHighlightIcon.qml \
    $${HARBOUR_LIB_QML}/HarbourPressEffect.qml

OTHER_FILES += $${HARBOUR_QML_COMPONENTS}

qml_components.files = $${HARBOUR_QML_COMPONENTS}
qml_components.path = $${TARGET_DATA_DIR}/qml/harbour
INSTALLS += qml_components

# App

HEADERS += \
    src/Counter.h \
    src/CounterDefs.h \
    src/CounterDigitsModel.h \
    src/CounterFavoritesModel.h \
    src/CounterLinkModel.h \
    src/CounterListModel.h \
    src/CounterSampleModel.h \
    src/CounterSettings.h

SOURCES += \
    src/Counter.cpp \
    src/CounterDigitsModel.cpp \
    src/CounterFavoritesModel.cpp \
    src/CounterLinkModel.cpp \
    src/CounterListModel.cpp \
    src/CounterSettings.cpp \
    src/main.cpp

# Icons

ICON_SIZES = 86 108 128 172 256
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
  $${_PRO_FILE_PWD_}/src

defineTest(addTrFile) {
    rel = translations/harbour-$${1}
    OTHER_FILES += $${rel}.ts
    export(OTHER_FILES)

    in = $${_PRO_FILE_PWD_}/$$rel
    out = $${OUT_PWD}/translations/$${PREFIX}-$$1

    s = $$replace(1,-,_)
    lupdate_target = lupdate_$$s
    qm_target = qm_$$s

    $${lupdate_target}.commands = lupdate -noobsolete -locations none $${TRANSLATION_SOURCES} -ts \"$${in}.ts\" && \
        mkdir -p \"$${OUT_PWD}/translations\" &&  [ \"$${in}.ts\" != \"$${out}.ts\" ] && \
        cp -af \"$${in}.ts\" \"$${out}.ts\" || :

    $${qm_target}.path = $$TRANSLATIONS_PATH
    $${qm_target}.depends = $${lupdate_target}
    $${qm_target}.commands = lrelease -idbased \"$${out}.ts\" && \
        $(INSTALL_FILE) \"$${out}.qm\" $(INSTALL_ROOT)$${TRANSLATIONS_PATH}/

    QMAKE_EXTRA_TARGETS += $${lupdate_target} $${qm_target}
    INSTALLS += $${qm_target}

    export($${lupdate_target}.commands)
    export($${qm_target}.path)
    export($${qm_target}.depends)
    export($${qm_target}.commands)
    export(QMAKE_EXTRA_TARGETS)
    export(INSTALLS)
}

LANGUAGES = fr hu pl ru sv zh_CN

addTrFile($${NAME})
for(l, LANGUAGES) {
    addTrFile($${NAME}-$$l)
}
