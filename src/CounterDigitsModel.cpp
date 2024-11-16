/*
 * Copyright (C) 2022-2024 Slava Monich <slava@monich.com>
 * Copyright (C) 2022 Jolla Ltd.
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer
 *     in the documentation and/or other materials provided with the
 *     distribution.
 *
 *  3. Neither the names of the copyright holders nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
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

class CounterDigitsModel::Private
{
public:
    Private();

    bool setDigit(CounterDigitsModel*, const QModelIndex&, const QVariant&);
    void setNumber(CounterDigitsModel*, uint);
    void setMinCount(CounterDigitsModel*, uint);
    void updateModel(CounterDigitsModel*);

public:
    uint iNumber;
    uint iMinCount;
    QString iNumberString;
};

CounterDigitsModel::Private::Private() :
    iNumber(0),
    iMinCount(1),
    iNumberString("0")
{}

bool
CounterDigitsModel::Private::setDigit(
    CounterDigitsModel* aModel,
    const QModelIndex& aIndex,
    const QVariant& aValue)
{
    const int row = aIndex.row();

    if (row < iNumberString.length()) {
        bool ok;
        uint digit = aValue.toUInt(&ok);

        if (ok && digit < 10) {
            const QChar c('0' + digit);

            if (iNumberString.at(row) != c) {
                QString str(iNumberString);

                str[row] = c;
                // Remove extra leading zeros
                while (str.length() > 1 && str.at(0) == QChar('0')) {
                    str = str.right(str.length() - 1);
                }
                HDEBUG(row << c << iNumber << "=>" << str.toUInt());
                iNumber = str.toUInt();
                updateModel(aModel);
                Q_EMIT aModel->numberChanged();
            }
            return true;
        }
    }
    return false;
}

void
CounterDigitsModel::Private::setNumber(
    CounterDigitsModel* aModel,
    uint aValue)
{
    if (iNumber != aValue) {
        HDEBUG(iNumber << "=>" << aValue);
        iNumber = aValue;
        updateModel(aModel);
        Q_EMIT aModel->numberChanged();
    }
}

void
CounterDigitsModel::Private::setMinCount(
    CounterDigitsModel* aModel,
    uint aMinCount)
{
    if (aMinCount != iMinCount) {
        HDEBUG(aMinCount);
        iMinCount = aMinCount;
        updateModel(aModel);
        Q_EMIT aModel->minCountChanged();
    }
}

void
CounterDigitsModel::Private::updateModel(
    CounterDigitsModel* aModel)
{
    const QString newString(QString::number(iNumber).rightJustified(iMinCount, '0'));

    if (iNumberString != newString) {
        const QString prevString(iNumberString);
        const QVector<int> roles(1, Qt::DisplayRole);
        const uint prevCount = prevString.length();
        const uint newCount = newString.length();

        HDEBUG(iMinCount << iNumberString << "=>" << newString);
        if (newCount > prevCount) {
            const QVector<int> roles(1, Qt::DisplayRole);
            const uint off = newCount - prevCount;

            aModel->beginInsertRows(QModelIndex(), 0, off - 1);
            iNumberString = newString;
            aModel->endInsertRows();

            for (uint i = 0; i < prevCount; i++) {
                if (newString.at(off + i) != prevString.at(i)) {
                    const QModelIndex modelIndex(aModel->index(off + i));
                    Q_EMIT aModel->dataChanged(modelIndex, modelIndex, roles);
                }
            }

            Q_EMIT aModel->countChanged();
        } else if (newCount < prevCount) {
            const QVector<int> roles(1, Qt::DisplayRole);
            const uint off = prevCount - newCount;

            aModel->beginRemoveRows(QModelIndex(), 0, off - 1);
            iNumberString = newString;
            aModel->endRemoveRows();

            for (uint i = 0; i < newCount; i++) {
                if (newString.at(i) != prevString.at(off + i)) {
                    const QModelIndex modelIndex(aModel->index(i));
                    Q_EMIT aModel->dataChanged(modelIndex, modelIndex, roles);
                }
            }

            Q_EMIT aModel->countChanged();
        } else {
            iNumberString = newString;
            for (uint i = 0; i < newCount; i++) {
                if (newString.at(i) != prevString.at(i)) {
                    const QModelIndex modelIndex(aModel->index(i));
                    Q_EMIT aModel->dataChanged(modelIndex, modelIndex, roles);
                }
            }
        }
    }
}

// ==========================================================================
// CounterDigitsModel
// ==========================================================================

CounterDigitsModel::CounterDigitsModel(
    QObject* aParent) :
    QAbstractListModel(aParent),
    iPrivate(new Private)
{}

CounterDigitsModel::~CounterDigitsModel()
{
    delete iPrivate;
}

Qt::ItemFlags
CounterDigitsModel::flags(
    const QModelIndex& aIndex) const
{
    return QAbstractListModel::flags(aIndex) | Qt::ItemIsEditable;
}

QHash<int,QByteArray>
CounterDigitsModel::roleNames() const
{
    QHash<int,QByteArray> roles;

    roles.insert(Qt::DisplayRole, "digit");
    return roles;
}

int
CounterDigitsModel::rowCount(
    const QModelIndex&) const
{
    return iPrivate->iNumberString.length();
}

QVariant
CounterDigitsModel::data(
    const QModelIndex& aIndex,
    int aRole) const
{
    const uint row = aIndex.row();
    const uint count = iPrivate->iNumberString.length();

    if (row < count && aRole == Qt::DisplayRole) {
        return QVariant((uint)(iPrivate->iNumberString.at(row).unicode() - '0'));
    }
    return QVariant();
}

bool
CounterDigitsModel::setData(
    const QModelIndex& aIndex,
    const QVariant& aValue,
    int aRole)
{
    return aRole == Qt::DisplayRole &&
        iPrivate->setDigit(this, aIndex, aValue);
}

uint
CounterDigitsModel::getNumber() const
{
    return iPrivate->iNumber;
}

void
CounterDigitsModel::setNumber(
    uint aValue)
{
    iPrivate->setNumber(this, aValue);
}

uint
CounterDigitsModel::getMinCount() const
{
    return iPrivate->iMinCount;
}

void
CounterDigitsModel::setMinCount(
    uint aMinCount)
{
    iPrivate->setMinCount(this, aMinCount);
}
