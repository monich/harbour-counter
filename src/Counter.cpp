/*
 * Copyright (C) 2022 Jolla Ltd.
 * Copyright (C) 2022 Slava Monich <slava@monich.com>
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
 *      notice, this list of conditions and the following disclaimer in
 *      the documentation and/or other materials provided with the
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

#include "Counter.h"

#include "HarbourBase45.h"

// ==========================================================================
// Counter::Private
// ==========================================================================

class Counter::Private {
public:

    static const char mediaKeyBase45[];
    static const char permissionsBase45[];

    Private() : iDarkOnLight(false) {}

public:
    bool iDarkOnLight;
};

// import Sailfish.Media 1.0; MediaKey{}
const char Counter::Private::mediaKeyBase45[] =
    "YEDS9E5LE+347ECUVD+EDU7DDZ9AVCOCCZ96H46DZ9AVCMDCC$CNRF";

// import org.nemomobile.policy 1.0;Permissions{
//   autoRelease:true;applicationClass:"camera";
//   Resource{type:Resource.ScaleButton;optional:true}}
const char Counter::Private::permissionsBase45[] =
    "YEDS9E5LEN44$KE6*50$C+3ET3EXEDRZCS9EXVD+PC634Y$5JM75$CJ$DZQE EDF/"
    "D+QF8%ED3E: CX CLQEOH76LE+ZCEECP9EOEDIEC EDC.DPVDZQEWF7GPCF$DVKEX"
    "E4XIAVQE6%EKPCERF%FF*ZCXIAVQE6%EKPCO%5GPCTVD3I8MWE-3E5N7X9E ED..D"
    "VUDKWE%$E+%F";

// ==========================================================================
// Counter
// ==========================================================================

Counter::Counter(QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private)
{
}

Counter::~Counter()
{
    delete iPrivate;
}

// Callback for qmlRegisterSingletonType<Counter>
QObject* Counter::createSingleton(QQmlEngine*, QJSEngine*)
{
    return new Counter();
}

bool Counter::darkOnLight() const
{
    return iPrivate->iDarkOnLight;
}

void Counter::setDarkOnLight(bool aDarkOnLight)
{
    if (iPrivate->iDarkOnLight != aDarkOnLight) {
        iPrivate->iDarkOnLight = aDarkOnLight;
        Q_EMIT darkOnLightChanged();
    }
}

QString Counter::mediaKeyQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(Counter::Private::mediaKeyBase45));
}

QString Counter::permissionsQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(Counter::Private::permissionsBase45));
}

QColor Counter::invertedColor(const QColor& aColor)
{
    if (aColor.isValid()) {
        const QRgb rgb = aColor.rgba();
        return QColor(((~(rgb & RGB_MASK)) & RGB_MASK) | (rgb & (~RGB_MASK)));
    } else {
        return aColor;
    }
}
