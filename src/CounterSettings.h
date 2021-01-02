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

#ifndef COUNTER_SETTINGS_H
#define COUNTER_SETTINGS_H

#include <QObject>
#include <QString>
#include <QStringList>

class QQmlEngine;
class QJSEngine;

class CounterSettings : public QObject {
    Q_OBJECT
    Q_DISABLE_COPY(CounterSettings)
    Q_PROPERTY(bool soundsEnabled READ soundsEnabled WRITE setSoundsEnabled NOTIFY soundsEnabledChanged)
    Q_PROPERTY(bool vibraEnabled READ vibraEnabled WRITE setVibraEnabled NOTIFY vibraEnabledChanged)
    Q_PROPERTY(bool volumeKeysEnabled READ volumeKeysEnabled WRITE setVolumeKeysEnabled NOTIFY volumeKeysEnabledChanged)
    Q_PROPERTY(int reorderHintCount READ reorderHintCount WRITE setReorderHintCount NOTIFY reorderHintCountChanged)
    Q_PROPERTY(int maxReorderHintCount READ maxReorderHintCount CONSTANT)
    Q_PROPERTY(int coverStyle READ coverStyle WRITE setCoverStyle NOTIFY coverStyleChanged)
    Q_PROPERTY(QString coverItem READ coverItem NOTIFY coverStyleChanged)
    Q_PROPERTY(QStringList coverItems READ coverItems CONSTANT)

public:
    explicit CounterSettings(QObject* aParent = Q_NULLPTR);
    ~CounterSettings();

    // Callback for qmlRegisterSingletonType<CounterSettings>
    static QObject* createSingleton(QQmlEngine* aEngine, QJSEngine* aScript);

    bool soundsEnabled() const;
    void setSoundsEnabled(bool aValue);

    bool vibraEnabled() const;
    void setVibraEnabled(bool aValue);

    bool volumeKeysEnabled() const;
    void setVolumeKeysEnabled(bool aValue);

    int reorderHintCount() const;
    void setReorderHintCount(int aValue);
    static int maxReorderHintCount();

    int coverStyle() const;
    void setCoverStyle(int aValue);
    const QString& coverItem() const;
    const QStringList& coverItems() const;

Q_SIGNALS:
    void soundsEnabledChanged();
    void vibraEnabledChanged();
    void volumeKeysEnabledChanged();
    void reorderHintCountChanged();
    void coverStyleChanged();

private:
    class Private;
    Private* iPrivate;
};

#endif // COUNTER_SETTINGS_H
