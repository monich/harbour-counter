/*
 * Copyright (C) 2021 Jolla Ltd.
 * Copyright (C) 2021 Slava Monich <slava@monich.com>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer
 *      in the documentation and/or other materials provided with the
 *      distribution.
 *   3. Neither the names of the copyright holders nor the names of its
 *      contributors may be used to endorse or promote products derived
 *      from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation
 * are those of the authors and should not be interpreted as representing
 * any official policies, either expressed or implied.
 */

#include "CounterSettings.h"
#include "CounterDefs.h"

#include "HarbourDebug.h"

#include <MGConfItem>

#define DCONF_KEY(x)                "/apps/" APP_NAME "/" x
#define KEY_SOUNDS                  DCONF_KEY("sounds")
#define KEY_VIBRA                   DCONF_KEY("vibra")
#define KEY_USE_VOLUME_KEYS         DCONF_KEY("useVolumeKeys")
#define KEY_COVER_STYLE             DCONF_KEY("coverStyle")
#define KEY_REORDER_HINT_COUNT      DCONF_KEY("reorderHintCount")

#define DEFAULT_SOUNDS              false
#define DEFAULT_VIBRA               true
#define DEFAULT_USE_VOLUME_KEYS     true
#define DEFAULT_COVER_STYLE         1
#define DEFAULT_REORDER_HINT_COUNT  0
#define MAX_REORDER_HINT_COUNT      4

// ==========================================================================
// CounterSettings::Private
// ==========================================================================

class CounterSettings::Private {
public:
    Private(CounterSettings* aParent);

    int validateCoverStyle(int aStyle) const;
    int validatedCoverStyle() const;

public:
    MGConfItem* iSounds;
    MGConfItem* iVibra;
    MGConfItem* iUseVolumeKeys;
    MGConfItem* iCoverStyle;
    MGConfItem* iReorderHintCount;
    QStringList iCoverItems;
};

CounterSettings::Private::Private(CounterSettings* aParent) :
    iSounds(new MGConfItem(KEY_SOUNDS, aParent)),
    iVibra(new MGConfItem(KEY_VIBRA, aParent)),
    iUseVolumeKeys(new MGConfItem(KEY_USE_VOLUME_KEYS, aParent)),
    iCoverStyle(new MGConfItem(KEY_COVER_STYLE, aParent)),
    iReorderHintCount(new MGConfItem(KEY_REORDER_HINT_COUNT, aParent))
{
    iCoverItems.append(QStringLiteral("CoverItem1.qml"));
    iCoverItems.append(QStringLiteral("CoverItem2.qml"));
    QObject::connect(iSounds, SIGNAL(valueChanged()),
        aParent, SIGNAL(soundsEnabledChanged()));
    QObject::connect(iVibra, SIGNAL(valueChanged()),
        aParent, SIGNAL(vibraEnabledChanged()));
    QObject::connect(iUseVolumeKeys, SIGNAL(valueChanged()),
        aParent, SIGNAL(volumeKeysEnabledChanged()));
    QObject::connect(iCoverStyle, SIGNAL(valueChanged()),
        aParent, SIGNAL(coverStyleChanged()));
    QObject::connect(iReorderHintCount, SIGNAL(valueChanged()),
        aParent, SIGNAL(reorderHintCountChanged()));
}

inline int CounterSettings::Private::validateCoverStyle(int aStyle) const
{
    return (aStyle >= 0 && aStyle < iCoverItems.size()) ?
        aStyle : DEFAULT_COVER_STYLE;
}

inline int CounterSettings::Private::validatedCoverStyle() const
{
    return validateCoverStyle(iCoverStyle->value(DEFAULT_COVER_STYLE).toInt());
}

// ==========================================================================
// CounterSettings
// ==========================================================================

CounterSettings::CounterSettings(QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private(this))
{
}

CounterSettings::~CounterSettings()
{
    delete iPrivate;
}

// Callback for qmlRegisterSingletonType<CounterSettings>
QObject* CounterSettings::createSingleton(QQmlEngine*, QJSEngine*)
{
    return new CounterSettings;
}

bool CounterSettings::soundsEnabled() const
{
    return iPrivate->iSounds->value(DEFAULT_SOUNDS).toBool();
}

void CounterSettings::setSoundsEnabled(bool aValue)
{
    HDEBUG(aValue);
    iPrivate->iSounds->set(aValue);
}

bool CounterSettings::vibraEnabled() const
{
    return iPrivate->iVibra->value(DEFAULT_VIBRA).toBool();
}

void CounterSettings::setVibraEnabled(bool aValue)
{
    HDEBUG(aValue);
    iPrivate->iVibra->set(aValue);
}

bool CounterSettings::volumeKeysEnabled() const
{
    return iPrivate->iUseVolumeKeys->value(DEFAULT_USE_VOLUME_KEYS).toBool();
}

void CounterSettings::setVolumeKeysEnabled(bool aValue)
{
    HDEBUG(aValue);
    iPrivate->iUseVolumeKeys->set(aValue);
}

int CounterSettings::reorderHintCount() const
{
    return iPrivate->iReorderHintCount->value(DEFAULT_REORDER_HINT_COUNT).toInt();
}

void CounterSettings::setReorderHintCount(int aValue)
{
    HDEBUG(aValue);
    iPrivate->iReorderHintCount->set(qMax(aValue, 0));
}

int CounterSettings::maxReorderHintCount()
{
    return MAX_REORDER_HINT_COUNT;
}

int CounterSettings::coverStyle() const
{
    return iPrivate->validatedCoverStyle();
}

void CounterSettings::setCoverStyle(int aValue)
{
    HDEBUG(aValue);
    iPrivate->iCoverStyle->set(iPrivate->validateCoverStyle(aValue));
}

const QString& CounterSettings::coverItem() const
{
    return iPrivate->iCoverItems.at(coverStyle());
}

const QStringList& CounterSettings::coverItems() const
{
    return iPrivate->iCoverItems;
}
