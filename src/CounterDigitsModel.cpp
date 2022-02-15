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

#include "CounterDigitsModel.h"

#include "HarbourDebug.h"

// ==========================================================================
// CounterDigitsModel::Private
// ==========================================================================

class CounterDigitsModel::Private {
public:
    enum { MAX_SIGNIFICANT_DIGITS = 10 };

    Private();

    int calculateSignificantDigits();
    void removeExtraLeadingZeros(int aCount);

public:
    uint iNumber;
    uint iSignificantDigits;
    uint iCount;
    QString iNumberString;
};

CounterDigitsModel::Private::Private() :
    iNumber(0),
    iSignificantDigits(1),
    iCount(1),
    iNumberString("0")
{
}

int CounterDigitsModel::Private::calculateSignificantDigits()
{
    int z = 0;
    const int len = iNumberString.length();

    while (z + 1 < len && iNumberString.at(z) == QChar('0')) z++;
    return len - z;
}

void CounterDigitsModel::Private::removeExtraLeadingZeros(int aCount)
{
    while (iNumberString.length() > aCount && iNumberString.at(0) == QChar('0')) {
        iNumberString = iNumberString.right(iNumberString.length() - 1);
    }
}

// ==========================================================================
// CounterDigitsModel
// ==========================================================================

#define SUPER QAbstractListModel

CounterDigitsModel::CounterDigitsModel(QObject* aParent) :
    SUPER(aParent),
    iPrivate(new Private)
{
}

CounterDigitsModel::~CounterDigitsModel()
{
    delete iPrivate;
}

Qt::ItemFlags CounterDigitsModel::flags(const QModelIndex& aIndex) const
{
    return SUPER::flags(aIndex) | Qt::ItemIsEditable;
}

QHash<int,QByteArray> CounterDigitsModel::roleNames() const
{
    QHash<int,QByteArray> roles;

    roles.insert(Qt::DisplayRole, "digit");
    return roles;
}

int CounterDigitsModel::rowCount(const QModelIndex& aParent) const
{
    return iPrivate->iCount;
}

QVariant CounterDigitsModel::data(const QModelIndex& aIndex, int aRole) const
{
    const uint row = aIndex.row();

    if (row < iPrivate->iCount && aRole == Qt::DisplayRole) {
        return QVariant((uint)(iPrivate->iNumberString.at(row).unicode() - '0'));
    }
    return QVariant();
}

bool CounterDigitsModel::setData(const QModelIndex& aIndex, const QVariant& aValue, int aRole)
{
    const uint row = aIndex.row();

    if (row < iPrivate->iCount &&
        row < Private::MAX_SIGNIFICANT_DIGITS &&
        aRole == Qt::DisplayRole) {
        bool ok;
        uint digit = aValue.toUInt(&ok);

        if (ok && digit < 10) {
            const QChar c('0' + digit);
            if (iPrivate->iNumberString.at(row) != c) {
                const uint prevSignificantDigits = iPrivate->iSignificantDigits;
                const QString prevNumberString(iPrivate->iNumberString);

                iPrivate->iNumberString[row] = c;
                HDEBUG(row << c << prevNumberString << "=>" << iPrivate->iNumberString);
                iPrivate->iNumber = iPrivate->iNumberString.toUInt();
                iPrivate->iSignificantDigits = iPrivate->calculateSignificantDigits();

                const QVector<int> roles(1, Qt::DisplayRole);
                Q_EMIT dataChanged(aIndex, aIndex, roles);
                Q_EMIT numberChanged();
                if (iPrivate->iSignificantDigits != prevSignificantDigits) {
                    Q_EMIT significantDigitsChanged();
                }
            }
            return true;
        }
    }
    return false;
}

uint CounterDigitsModel::getNumber() const
{
    return iPrivate->iNumber;
}

void CounterDigitsModel::setNumber(uint aValue)
{
    if (iPrivate->iNumber != aValue) {
        const uint prevSignificantDigits = iPrivate->iSignificantDigits;
        const QString prevNumberString(iPrivate->iNumberString);
        const QString newNumberString(QString::number(aValue).rightJustified(iPrivate->iCount, '0'));

        iPrivate->iNumber = aValue;
        iPrivate->iNumberString = newNumberString;
        iPrivate->iSignificantDigits = iPrivate->calculateSignificantDigits();
        HDEBUG(prevNumberString << "=>" << newNumberString);

        const QVector<int> roles(1, Qt::DisplayRole);
        const uint newOff = newNumberString.length() - iPrivate->iCount;
        const uint prevOff = prevNumberString.length() - iPrivate->iCount;
        for (uint i = 0; i < iPrivate->iCount; i++) {
            if (newNumberString.at(newOff + i) != prevNumberString.at(prevOff + i)) {
                const QModelIndex modelIndex(index(i));
                Q_EMIT dataChanged(modelIndex, modelIndex, roles);
            }
        }

        Q_EMIT numberChanged();
        if (iPrivate->iSignificantDigits != prevSignificantDigits) {
            Q_EMIT significantDigitsChanged();
        }
    }
}

uint CounterDigitsModel::getCount() const
{
    return iPrivate->iCount;
}

void CounterDigitsModel::setCount(uint aCount)
{
    if (aCount != iPrivate->iCount) {
        if (aCount > iPrivate->iCount) {
            const uint prevCount = iPrivate->iCount;
            beginInsertRows(QModelIndex(), 0, aCount - prevCount - 1);
            iPrivate->iNumberString = iPrivate->iNumberString.rightJustified(aCount, '0');
            iPrivate->iCount = aCount;
            endInsertRows();
            // Make sure other delegates get updated. It doesn't seem to
            // be necessary but without they keep showing old values
            Q_EMIT dataChanged(index(aCount - prevCount), index(aCount - 1),
                QVector<int>(1, Qt::DisplayRole));
        } else {
            const uint prevSignificantDigits = iPrivate->iSignificantDigits;
            const uint prevNumber = iPrivate->iNumber;

            beginRemoveRows(QModelIndex(), 0, iPrivate->iCount - aCount - 1);
            iPrivate->iCount = aCount;
            iPrivate->removeExtraLeadingZeros(aCount);
            iPrivate->iNumber = iPrivate->iNumberString.toUInt();
            iPrivate->iSignificantDigits = iPrivate->calculateSignificantDigits();
            endRemoveRows();

            if (iPrivate->iNumber != prevNumber) {
                Q_EMIT numberChanged();
            }
            if (iPrivate->iSignificantDigits != prevSignificantDigits) {
                Q_EMIT significantDigitsChanged();
            }
        }
        HDEBUG(aCount << iPrivate->iNumberString);
        Q_EMIT countChanged();
    }
}

uint CounterDigitsModel::getSignificantDigits() const
{
    return iPrivate->iSignificantDigits;
}
