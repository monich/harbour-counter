/*
 * Copyright (C) 2020 Jolla Ltd.
 * Copyright (C) 2020 Slava Monich <slava@monich.com>
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

#include "CounterDefs.h"
#include "CounterListModel.h"

#include "HarbourDebug.h"
#include "HarbourJson.h"

#define MODEL_ROLES_(first,role,last) \
    first(ModelId,modelId) \
    role(Value,value) \
    role(Title,title) \
    role(ResetTime,resetTime) \
    role(ChangeTime,changeTime) \
    last(Favorite,favorite)

#define MODEL_ROLES(role) \
    MODEL_ROLES_(role,role,role)

// ==========================================================================
// CounterListModel::ModelData
// ==========================================================================

class CounterListModel::ModelData {
public:
    enum Role {
#define FIRST(X,x) FirstRole = Qt::UserRole, X##Role = FirstRole,
#define ROLE(X,x) X##Role,
#define LAST(X,x) X##Role, LastRole = X##Role
        MODEL_ROLES_(FIRST,ROLE,LAST)
#undef FIRST
#undef ROLE
#undef LAST
    };

#define ROLE(X,x) static const QString RoleName##X;
    MODEL_ROLES(ROLE)
#undef ROLE

    typedef QList<ModelData*> List;

public:
    ModelData(QVariantMap aData);
    ModelData(QString aId, bool aFavorite);

    void set(QVariantMap aData);
    QVariant get(Role aRole) const;
    QVariantMap toVariantMap() const;

    static QDateTime dateTimeValue(QVariantMap aData, QString aKey);
    static QString toString(const QDateTime& aTime);

public:
    static const QString KEY_ID;
    static const QString KEY_VALUE;
    static const QString KEY_FAVORITE;
    static const QString KEY_TITLE;
    static const QString KEY_RESET_TIME;
    static const QString KEY_CHANGE_TIME;

public:
    int iValue;
    bool iFavorite;
    QString iId;
    QString iTitle;
    QDateTime iResetTime;
    QDateTime iChangeTime;
};

#define ROLE(X,x) const QString CounterListModel::ModelData::RoleName##X(#x);
MODEL_ROLES(ROLE)
#undef ROLE

const QString CounterListModel::ModelData::KEY_ID("id");
const QString CounterListModel::ModelData::KEY_VALUE("value");
const QString CounterListModel::ModelData::KEY_FAVORITE("favorite");
const QString CounterListModel::ModelData::KEY_TITLE("title");
const QString CounterListModel::ModelData::KEY_RESET_TIME("resetTime");
const QString CounterListModel::ModelData::KEY_CHANGE_TIME("changeTime");

inline QDateTime CounterListModel::ModelData::dateTimeValue(QVariantMap aData, QString aKey)
{
    const QString str = aData.value(aKey).toString();
    return str.isEmpty() ? QDateTime() : QDateTime::fromString(str, Qt::ISODate);
}

inline QString CounterListModel::ModelData::toString(const QDateTime& aTime)
{
    return aTime.toUTC().toString(Qt::ISODate);
}

CounterListModel::ModelData::ModelData(QString aId, bool aFavorite) :
    iValue(0),
    iFavorite(aFavorite),
    iId(aId),
    //: Default title for a new counter
    //% "Counter"
    iTitle(qtTrId("counter-default_title"))
{
}

CounterListModel::ModelData::ModelData(QVariantMap aData)
{
    set(aData);
}

QVariant CounterListModel::ModelData::get(Role aRole) const
{
    switch (aRole) {
    case ValueRole: return iValue;
    case FavoriteRole: return iFavorite;
    case ModelIdRole: return iId;
    case TitleRole: return iTitle;
    case ResetTimeRole: return iResetTime;
    case ChangeTimeRole: return iChangeTime;
    }
    return QVariant();
}

QVariantMap CounterListModel::ModelData::toVariantMap() const
{
    QVariantMap map;
    map.insert(KEY_VALUE, iValue);
    map.insert(KEY_FAVORITE, iFavorite);
    map.insert(KEY_ID, iId);
    map.insert(KEY_TITLE, iTitle);
    if (iResetTime.isValid()) {
        map.insert(KEY_RESET_TIME, toString(iResetTime));
    }
    if (iChangeTime.isValid()) {
        map.insert(KEY_CHANGE_TIME, toString(iChangeTime));
    }
    return map;
}

void CounterListModel::ModelData::set(QVariantMap aData)
{
    iValue = aData.value(KEY_VALUE).toInt();
    iFavorite = aData.value(KEY_FAVORITE).toBool();
    iId = aData.value(KEY_ID).toString();
    iTitle = aData.value(KEY_TITLE).toString();
    iResetTime = dateTimeValue(aData, KEY_RESET_TIME);
    iChangeTime = dateTimeValue(aData, KEY_CHANGE_TIME);
}

// ==========================================================================
// CounterListModel::Private
// ==========================================================================

class CounterListModel::Private : public QObject {
    Q_OBJECT
    Q_DISABLE_COPY(Private)

public:
    Private(QObject* aParent);
    ~Private();

    int rowCount() const;
    int favoriteCount() const;
    QString newId() const;
    void setCount(int aCount);
    void setSaveFile(QString aFileName);
    void save() const;
    void newCounter();
    int oneFavoriteOff(int aIndexToIgnore);
    int oneFavoriteOn(int aIndexToIgnore);
    ModelData* find(QString aId) const;
    ModelData* dataAt(int aIndex) const;

private:
    void writeState() const;

private Q_SLOTS:
    void onHoldoffTimerExpired();
    void onSaveTimerExpired();

public:
    static const int MaxFavorites = 2;
    static const QString COUNTERS;
    static const QString CURRENT_INDEX;

public:
    ModelData::List iData;
    int iCurrentIndex;
    int iSavingSuspended;
    QString iSaveFile;
    QString iSaveFilePath;
    QTimer* iSaveTimer;
    QTimer* iHoldoffTimer;
};

const QString CounterListModel::Private::COUNTERS("counters");
const QString CounterListModel::Private::CURRENT_INDEX("currentIndex");

CounterListModel::Private::Private(QObject* aParent) :
    QObject(aParent),
    iCurrentIndex(0),
    iSavingSuspended(0),
    iSaveTimer(new QTimer(this)),
    iHoldoffTimer(new QTimer(this))
{
    newCounter();
    // Current state is saved at least every 10 seconds
    iSaveTimer->setInterval(10000);
    iSaveTimer->setSingleShot(true);
    connect(iSaveTimer, SIGNAL(timeout()), SLOT(onSaveTimerExpired()));
    // And not more often than every second
    iHoldoffTimer->setInterval(1000);
    iHoldoffTimer->setSingleShot(true);
    connect(iHoldoffTimer, SIGNAL(timeout()), SLOT(onHoldoffTimerExpired()));
}

CounterListModel::Private::~Private()
{
    if (iSaveTimer->isActive()) {
        // There are unsaved changes
        writeState();
    }
    qDeleteAll(iData);
}

inline int CounterListModel::Private::rowCount() const
{
    return iData.count();
}

int CounterListModel::Private::favoriteCount() const
{
    const int n = iData.count();
    int count = 0;
    for (int i = 0; i < n; i++) {
        if (iData.at(i)->iFavorite) {
            count++;
        }
    }
    return count;
}

QString CounterListModel::Private::newId() const
{
    int i = 0;
    QString id;
    do { id.sprintf("%03d", i++); } while (find(id));
    return id;
}

CounterListModel::ModelData* CounterListModel::Private::find(QString aId) const
{
    const int n = iData.count();
    for (int i = 0; i < n; i++) {
        ModelData* data = iData.at(i);
        if (data->iId == aId) {
            return data;
        }
    }
    return NULL;
}

CounterListModel::ModelData* CounterListModel::Private::dataAt(int aIndex) const
{
    if (aIndex >= 0 && aIndex < iData.count()) {
        return iData.at(aIndex);
    } else {
        return NULL;
    }
}

void CounterListModel::Private::newCounter()
{
    iData.append(new ModelData(newId(), iData.isEmpty()));
}

int CounterListModel::Private::oneFavoriteOff(int aIndexToIgnore)
{
    for (int i = iData.count() - 1; i >= 0; i--) {
        if (i != aIndexToIgnore) {
            ModelData* data = iData.at(i);
            if (data->iFavorite) {
                data->iFavorite = false;
                return i;
            }
        }
    }
    return -1;
}

int CounterListModel::Private::oneFavoriteOn(int aIndexToIgnore)
{
    const int n = iData.count();
    for (int i = 0; i < n; i++) {
        if (i != aIndexToIgnore) {
            ModelData* data = iData.at(i);
            if (!data->iFavorite) {
                data->iFavorite = true;
                return i;
            }
        }
    }
    return -1;
}

void CounterListModel::Private::setCount(int aCount)
{
    while (iData.count() > aCount) {
        delete iData.last();
        iData.removeLast();
    }
}

void CounterListModel::Private::setSaveFile(QString aFileName)
{
    iSaveFile = aFileName;
    if (aFileName.isEmpty()) {
        iSaveFilePath.clear();
        setCount(1);
        if (iCurrentIndex != 0) {
            iCurrentIndex = 0;
        }
    } else {
        iSaveFilePath = QStandardPaths::writableLocation(
            QStandardPaths::GenericDataLocation) +
            QStringLiteral("/" APP_NAME "/") + aFileName;
        QVariantMap data;
        HDEBUG("Loading" << qPrintable(iSaveFilePath));
        if (HarbourJson::load(iSaveFilePath, data)) {
            QVariantList counters = data.value(COUNTERS).toList();
            const int n = counters.count();
            if (n > 0) {
                int i;
                const int k = qMin(n, iData.count());
                for (i = 0; i < k; i++) {
                    iData.at(i)->set(counters.at(i).toMap());
                }
                while (i < n) {
                    iData.append(new ModelData(counters.at(i++).toMap()));
                }
                while (iData.count() > n) {
                    delete iData.last();
                    iData.removeLast();
                }
            } else {
                setCount(1);
            }
            bool ok = false;
            const int currentIndex = data.value(CURRENT_INDEX).toInt(&ok);
            if (ok && currentIndex >= 0 && currentIndex < iData.count() &&
                iCurrentIndex != currentIndex) {
                iCurrentIndex = currentIndex;
                HDEBUG("currentIndex" << currentIndex);
            } else if (iCurrentIndex < 0 || iCurrentIndex >= iData.count()) {
                iCurrentIndex = 0;
            }
        }
    }
}

void CounterListModel::Private::save() const
{
    if (!iSaveFilePath.isEmpty() && !iSavingSuspended) {
        if (!iHoldoffTimer->isActive()) {
            // Idle state, write the file right away
            iSaveTimer->stop();
            writeState();
        } else {
            // Make sure it eventually gets saved even if changes will
            // keep happening in quick succession
            if (!iSaveTimer->isActive()) {
                iSaveTimer->start();
            }
        }
        // Restart hold off timer
        iHoldoffTimer->start();
    }
}

void CounterListModel::Private::onHoldoffTimerExpired()
{
    if (iSaveTimer->isActive()) {
        iSaveTimer->stop();
        writeState();
    }
}

void CounterListModel::Private::onSaveTimerExpired()
{
    iHoldoffTimer->start();
    writeState();
}

void CounterListModel::Private::writeState() const
{
    HDEBUG("Writing" << qPrintable(iSaveFilePath));
    QVariantList counters;
    const int n = iData.count();
    for (int i = 0; i < n; i++) {
        counters.append(iData.at(i)->toVariantMap());
    }
    QVariantMap data;
    data.insert(COUNTERS, counters);
    data.insert(CURRENT_INDEX, iCurrentIndex);
    HarbourJson::save(iSaveFilePath, data);
}

// ==========================================================================
// CounterListModel
// ==========================================================================

#define SUPER QAbstractListModel

CounterListModel::CounterListModel(QObject* aParent) :
    SUPER(aParent),
    iPrivate(new Private(this))
{
}

// Callback for qmlRegisterSingletonType<CounterListModel>
QObject* CounterListModel::createSingleton(QQmlEngine* aEngine, QJSEngine* aScript)
{
    return new CounterListModel;
}

int CounterListModel::favoriteRole()
{
    return ModelData::FavoriteRole;
}

QString CounterListModel::saveFile() const
{
    return iPrivate->iSaveFile;
}

void CounterListModel::setSaveFile(QString aFileName)
{
    if (iPrivate->iSaveFile != aFileName) {
        HDEBUG(qPrintable(aFileName));
        iPrivate->iSavingSuspended++; // Suspend saves
        beginResetModel();
        iPrivate->setSaveFile(aFileName);
        const int currentIndex = iPrivate->iCurrentIndex;
        endResetModel(); // This may change the current index
        iPrivate->iSavingSuspended--; // Resume saves
        if (!iPrivate->favoriteCount()) {
            // At least one favorite is required
            const int on = iPrivate->oneFavoriteOn(-1);
            if (on >= 0) {
                HDEBUG(on << "favorite true");
                QVector<int> roles;
                roles.append(ModelData::FavoriteRole);
                const QModelIndex idx(index(on));
                Q_EMIT dataChanged(idx, idx, roles);
            }
        }
        if (iPrivate->iCurrentIndex != currentIndex) {
            // Fix the damage caused by model reset
            iPrivate->iCurrentIndex = currentIndex;
            Q_EMIT currentIndexChanged();
        }
        Q_EMIT saveFileChanged();
        Q_EMIT stateLoaded();
    }
}

int CounterListModel::currentIndex() const
{
    return iPrivate->iCurrentIndex;
}

void CounterListModel::setCurrentIndex(int aIndex)
{
    if (iPrivate->iCurrentIndex != aIndex) {
        iPrivate->iCurrentIndex = aIndex;
        HDEBUG(aIndex);
        Q_EMIT currentIndexChanged();
        iPrivate->save();
    }
}

int CounterListModel::addCounter()
{
    const int pos = iPrivate->iData.count();
    beginInsertRows(QModelIndex(), pos, pos);
    iPrivate->newCounter();
    HDEBUG(pos << iPrivate->dataAt(pos)->iId);
    iPrivate->save();
    endInsertRows();
    return pos;
}

void CounterListModel::resetCounter(int aRow)
{
    ModelData* data = iPrivate->dataAt(aRow);
    if (data) {
        QVector<int> roles;
        HDEBUG(aRow);
        roles.reserve(3);
        roles.append(ModelData::ResetTimeRole);
        data->iResetTime = QDateTime::currentDateTime();
        if (data->iChangeTime.isValid()) {
            data->iChangeTime = QDateTime();
            roles.append(ModelData::ChangeTimeRole);
        }
        if (data->iValue) {
            data->iValue = 0;
            roles.append(ModelData::ValueRole);
        }
        const QModelIndex modelIndex(index(aRow));
        Q_EMIT dataChanged(modelIndex, modelIndex, roles);
        iPrivate->save();
    }
}

void CounterListModel::deleteCounter(int aRow)
{
    if (iPrivate->rowCount() && aRow >= 0 && aRow <= iPrivate->rowCount()) {
        HDEBUG(aRow);
        beginRemoveRows(QModelIndex(), aRow, aRow);
        delete iPrivate->iData.takeAt(aRow);
        endRemoveRows();
        if (!iPrivate->favoriteCount()) {
            // Looks like we have just deleted the last favorite
            const int on = iPrivate->oneFavoriteOn(-1);
            if (on >= 0) {
                HDEBUG(on << "favorite true");
                QVector<int> roles;
                roles.append(ModelData::FavoriteRole);
                const QModelIndex idx(index(on));
                Q_EMIT dataChanged(idx, idx, roles);
            }
        }
    }
}

Qt::ItemFlags CounterListModel::flags(const QModelIndex& aIndex) const
{
    return SUPER::flags(aIndex) | Qt::ItemIsEditable;
}

QHash<int,QByteArray> CounterListModel::roleNames() const
{
    QHash<int,QByteArray> roles;
#define ROLE(X,x) roles.insert(ModelData::X##Role, #x);
MODEL_ROLES(ROLE)
#undef ROLE
    return roles;
}

int CounterListModel::rowCount(const QModelIndex& aParent) const
{
    return iPrivate->rowCount();
}

QVariant CounterListModel::data(const QModelIndex& aIndex, int aRole) const
{
    ModelData* data = iPrivate->dataAt(aIndex.row());
    return data ? data->get((ModelData::Role)aRole) : QVariant();
}

bool CounterListModel::setData(const QModelIndex& aIndex, const QVariant& aValue, int aRole)
{
    const int row = aIndex.row();
    ModelData* data = iPrivate->dataAt(row);
    if (data) {
        QVector<int> roles;
        switch ((ModelData::Role)aRole) {
        case ModelData::ValueRole:
            {
                bool ok;
                const int value = aValue.toInt(&ok);
                if (ok) {
                    if (data->iValue != value) {
                        HDEBUG(row << "value" << value);
                        data->iValue = value;
                        data->iChangeTime = QDateTime::currentDateTime();
                        roles.reserve(2);
                        roles.append(aRole);
                        roles.append(ModelData::ChangeTimeRole);
                        Q_EMIT dataChanged(aIndex, aIndex, roles);
                        iPrivate->save();
                    }
                    return true;
                }
            }
            break;
        case ModelData::FavoriteRole:
            {
                const bool favorite = aValue.toBool();
                if (data->iFavorite != favorite) {
                    if (favorite || iPrivate->rowCount() > 1) {
                        HDEBUG(row << "favorite" << favorite);
                        data->iFavorite = favorite;
                        roles.append(aRole);
                        Q_EMIT dataChanged(aIndex, aIndex, roles);
                        const int nfavorites = iPrivate->favoriteCount();
                        if (favorite) {
                            if (nfavorites > Private::MaxFavorites) {
                                // Too many favorites, need to turn one off
                                const int off = iPrivate->oneFavoriteOff(row);
                                if (off >= 0) {
                                    HDEBUG(off << "favorite false");
                                    const QModelIndex idx(index(off));
                                    Q_EMIT dataChanged(idx, idx, roles);
                                }
                            }
                        } else if (!nfavorites) {
                            // No favorites left, need to turn one on
                            const int on = iPrivate->oneFavoriteOn(row);
                            if (on >= 0) {
                                HDEBUG(on << "favorite true");
                                const QModelIndex idx(index(on));
                                Q_EMIT dataChanged(idx, idx, roles);
                            }
                        }
                        iPrivate->save();
                    } else {
                        HDEBUG(row << "favorite" << favorite << " - nope");
                    }
                }
            }
            return true;
        case ModelData::TitleRole:
            {
                const QString title = aValue.toString();
                if (data->iTitle != title) {
                    data->iTitle = title;
                    roles.append(aRole);
                    HDEBUG(row << "title" << title);
                    Q_EMIT dataChanged(aIndex, aIndex, roles);
                    iPrivate->save();
                }
            }
            return true;
        // No default to make sure that we get "warning: enumeration value
        // not handled in switch" if we forget to handle a real role.
        case ModelData::ResetTimeRole:
        case ModelData::ChangeTimeRole:
        case ModelData::ModelIdRole:
            HDEBUG(row << aRole << aValue << "nope");
            break;
        }
    }
    return false;
}

bool CounterListModel::moveRows(const QModelIndex &aSrcParent, int aSrcRow,
    int aCount, const QModelIndex &aDestParent, int aDestRow)
{
    const int size = iPrivate->rowCount();
    if (aSrcParent == aDestParent &&
        aSrcRow != aDestRow &&
        aSrcRow >= 0 && aSrcRow < size &&
        aDestRow >= 0 && aDestRow < size) {
        HDEBUG(aSrcRow << "->" << aDestRow);
        beginMoveRows(aSrcParent, aSrcRow, aSrcRow, aDestParent,
           (aDestRow < aSrcRow) ? aDestRow : (aDestRow + 1));
        iPrivate->iData.move(aSrcRow, aDestRow);
        iPrivate->save();
        endMoveRows();
        return true;
    } else {
        return false;
    }
}

#include "CounterListModel.moc"
