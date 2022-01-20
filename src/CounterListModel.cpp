/*
 * Copyright (C) 2020-2022 Jolla Ltd.
 * Copyright (C) 2020-2022 Slava Monich <slava@monich.com>
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

#include "CounterDefs.h"
#include "CounterListModel.h"

#include "HarbourDebug.h"

#include <QDir>
#include <QFile>
#include <QFileSystemWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <QCryptographicHash>

#define MODEL_ROLES_(first,role,last) \
    first(ModelId,modelId) \
    role(Link,link) \
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

    typedef QList<ModelData*> List;

public:
    ModelData(QVariantMap aData);
    ModelData(QString aId, QString aTitle, bool aFavorite);
    ~ModelData();

    void clearLink();
    void set(QVariantMap aData);
    QVariant get(Role aRole) const;
    QVariantMap toVariantMap() const;

    static QDateTime dateTimeValue(QVariantMap aData, QString aKey);
    static QString toString(const QDateTime& aTime);

public:
    static const QString KEY_ID;
    static const QString KEY_LINK;
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
    ModelData* iLink;
};

const QString CounterListModel::ModelData::KEY_ID("id");
const QString CounterListModel::ModelData::KEY_LINK("link");
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

CounterListModel::ModelData::ModelData(QString aId, QString aTitle, bool aFavorite) :
    iValue(0),
    iFavorite(aFavorite),
    iId(aId),
    iTitle(aTitle),
    iLink(Q_NULLPTR)
{
}

CounterListModel::ModelData::ModelData(QVariantMap aData) :
    iLink(Q_NULLPTR)
{
    set(aData);
}

CounterListModel::ModelData::~ModelData()
{
    clearLink();
}

void CounterListModel::ModelData::clearLink()
{
    if (iLink) {
        iLink->iLink = Q_NULLPTR;
        iLink = Q_NULLPTR;
    }
}

QVariant CounterListModel::ModelData::get(Role aRole) const
{
    switch (aRole) {
    case ValueRole: return iValue;
    case FavoriteRole: return iFavorite;
    case ModelIdRole: return iId;
    case LinkRole: return iLink ? iLink->iId : QString();
    case TitleRole: return iTitle;
    case ResetTimeRole: return iResetTime.toLocalTime();
    case ChangeTimeRole: return iChangeTime.toLocalTime();
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
    if (iLink) {
        map.insert(KEY_LINK, iLink->iId);
    }
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
    clearLink();
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
    Private(CounterListModel* aParent);
    ~Private();

    CounterListModel* parentModel();
    int rowCount() const;
    int indexOf(ModelData* aData) const;
    int favoriteCount() const;
    QString newId() const;
    QString newTitle() const;
    void setCount(int aCount);
    void setSaveFile(QString aFileName);
    void save();
    void newCounter();
    int oneFavoriteOff(int aIndexToIgnore);
    int oneFavoriteOn(int aIndexToIgnore);
    int findId(QString aId) const;
    ModelData* findTitle(QString aId) const;
    ModelData* dataAt(int aIndex) const;

private:
    void readState();
    void applyState(const QVariantMap data);
    void writeState();

private Q_SLOTS:
    void flushChanges();
    void onSaveTimerExpired();
    void onSaveFileChanged(QString aPath);
    void onSaveDirectoryChanged(QString aPath);

public:
    static const int MaxFavorites = 2;
    static const QString COUNTERS;
    static const QString CURRENT_INDEX;

public:
    ModelData::List iData;
    int iCurrentIndex;
    int iSavingSuspended;
    int iUpdatingLinkedCounter;
    int iIgnoreSaveFileChange;
    QCryptographicHash::Algorithm iHashAlgorithm;
    QFileSystemWatcher* iSaveFileWatcher;
    QByteArray iSaveFileHash;
    QString iSaveFile;
    QString iSaveFilePath;
    QTimer* iSaveTimer;
    QTimer* iHoldoffTimer;
    QDir iDataDir;
};

const QString CounterListModel::Private::COUNTERS("counters");
const QString CounterListModel::Private::CURRENT_INDEX("currentIndex");

CounterListModel::Private::Private(CounterListModel* aParent) :
    QObject(aParent),
    iCurrentIndex(0),
    iSavingSuspended(0),
    iUpdatingLinkedCounter(0),
    iIgnoreSaveFileChange(0),
    iHashAlgorithm(QCryptographicHash::Md5),
    iSaveFileWatcher(new QFileSystemWatcher(this)),
    iSaveTimer(new QTimer(this)),
    iHoldoffTimer(new QTimer(this)),
    iDataDir(QStandardPaths::writableLocation
        (QStandardPaths::GenericDataLocation) +
            QStringLiteral("/" APP_NAME "/"))
{
    // There's always at least one counter
    newCounter();
    // Current state is saved at least every 10 seconds
    iSaveTimer->setInterval(10000);
    iSaveTimer->setSingleShot(true);
    connect(iSaveTimer, SIGNAL(timeout()), SLOT(onSaveTimerExpired()));
    // And not more often than every second
    iHoldoffTimer->setInterval(1000);
    iHoldoffTimer->setSingleShot(true);
    connect(iHoldoffTimer, SIGNAL(timeout()), SLOT(flushChanges()));
    // Connect the watcher (will add the paths when file name is set)
    connect(iSaveFileWatcher, SIGNAL(fileChanged(QString)),
        SLOT(onSaveFileChanged(QString)));
    connect(iSaveFileWatcher, SIGNAL(directoryChanged(QString)),
        SLOT(onSaveDirectoryChanged(QString)));
}

CounterListModel::Private::~Private()
{
    flushChanges();
    qDeleteAll(iData);
}

inline CounterListModel* CounterListModel::Private::parentModel()
{
    return qobject_cast<CounterListModel*>(parent());
}

inline int CounterListModel::Private::rowCount() const
{
    return iData.count();
}

inline int CounterListModel::Private::indexOf(ModelData* aData) const
{
    return iData.indexOf(aData);
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
    do { id.sprintf("%03d", i++); } while (findId(id) >= 0);
    return id;
}

QString CounterListModel::Private::newTitle() const
{
    //: Default title for the first counter
    //% "Counter"
    QString title(qtTrId("counter-default_title"));
    if (findTitle(title)) {
        int i = 2;
        //: Default title for a new counter
        //% "Counter %1"
        do { title = qtTrId("counter-default_title_n").arg(i++); }
        while (findTitle(title));
    }
    return title;
}

int CounterListModel::Private::findId(QString aId) const
{
    if (!aId.isEmpty()) {
        const int n = iData.count();
        for (int i = 0; i < n; i++) {
            const ModelData* data = iData.at(i);
            if (data->iId == aId) {
                return i;
            }
        }
    }
    return -1;
}

CounterListModel::ModelData* CounterListModel::Private::findTitle(QString aTitle) const
{
    const int n = iData.count();
    for (int i = 0; i < n; i++) {
        ModelData* data = iData.at(i);
        if (data->iTitle == aTitle) {
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
    iData.append(new ModelData(newId(), newTitle(), iData.isEmpty()));
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
    flushChanges();
    iSaveFile = aFileName;
    // Reset the watcher (normally there's nothing to reset)
    const QStringList watchedFiles(iSaveFileWatcher->files());
    if (!watchedFiles.isEmpty()) {
        iSaveFileWatcher->removePaths(watchedFiles);
    }
    const QStringList watchedDirs(iSaveFileWatcher->directories());
    if (!watchedDirs.isEmpty()) {
        iSaveFileWatcher->removePaths(watchedDirs);
    }
    if (aFileName.isEmpty()) {
        // This shouldn't normally happen
        iSaveFilePath.clear();
        setCount(1);
        iCurrentIndex = 0;
        iSaveFileHash = QByteArray();
    } else {
        // But this should
        iDataDir.mkpath(QStringLiteral("."));
        iSaveFileWatcher->addPath(iDataDir.absolutePath());
        iSaveFilePath = iDataDir.absoluteFilePath(aFileName);
        readState();
    }
}

void CounterListModel::Private::readState()
{
    QFile f(iSaveFilePath);
    if (f.open(QIODevice::ReadOnly)) {
        QByteArray fileData(f.readAll());
        QByteArray hash(QCryptographicHash::hash(fileData, iHashAlgorithm));
        if (iSaveFileHash != hash) {
            HDEBUG("Loading" << qPrintable(iSaveFilePath));
            iSaveFileWatcher->addPath(iSaveFilePath);
            iSaveFileHash = hash;
            QJsonDocument doc(QJsonDocument::fromJson(fileData).object());
            applyState(doc.toVariant().toMap());
        } else {
            HDEBUG(qPrintable(iSaveFilePath) << "is unchanged");
        }
    }
}

void CounterListModel::Private::applyState(const QVariantMap aData)
{
    iSavingSuspended++; // Suspend saves
    CounterListModel* model = parentModel();
    model->beginResetModel();

    QVariantList counters = aData.value(COUNTERS).toList();
    const int n = counters.count();
    if (n > 0) {
        int i;
        const int k = qMin(n, iData.count());
        QHash<ModelData*,QString> linkMap;
        for (i = 0; i < k; i++) {
            const QVariantMap entry(counters.at(i).toMap());
            const QString link(entry.value(ModelData::KEY_LINK).toString());
            ModelData* data = iData.at(i);
            data->set(entry);
            if (!link.isEmpty()) linkMap.insert(data, link);
        }
        while (i < n) {
            const QVariantMap entry(counters.at(i++).toMap());
            const QString link(entry.value(ModelData::KEY_LINK).toString());
            ModelData* data = new ModelData(entry);
            iData.append(data);
            if (!link.isEmpty()) linkMap.insert(data, link);
        }
        setCount(n);
        // Restore links
        for (i = 0; i < n; i++) {
            ModelData* data = iData.at(i);
            if (!data->iLink) {
                const QString link(linkMap.value(data));
                const int linked = findId(link);
                if (linked >= 0 && linked != i) {
                    data->iLink = iData.at(linked);
                    data->iLink->iLink = data;
                    HDEBUG("link" << link << "<=>" << data->iId);
                }
            }
        }
    } else {
        setCount(1);
    }
    bool ok = false;
    const int currentIndex = aData.value(CURRENT_INDEX).toInt(&ok);
    if (ok && currentIndex >= 0 && currentIndex < iData.count() &&
        iCurrentIndex != currentIndex) {
        iCurrentIndex = currentIndex;
        HDEBUG("currentIndex" << currentIndex);
    } else if (iCurrentIndex < 0 || iCurrentIndex >= iData.count()) {
        iCurrentIndex = 0;
    }

    const int loadedIndex = iCurrentIndex;
    model->endResetModel(); // This may change the current index
    iSavingSuspended--; // Resume saves

    if (!favoriteCount()) {
        // At least one favorite is required
        const int on = oneFavoriteOn(-1);
        if (on >= 0) {
            HDEBUG(on << "favorite true");
            QVector<int> roles;
            roles.append(ModelData::FavoriteRole);
            const QModelIndex idx(model->index(on));
            Q_EMIT model->dataChanged(idx, idx, roles);
        }
    }
    if (iCurrentIndex != loadedIndex) {
        // Fix the damage caused by model reset
        iCurrentIndex = loadedIndex;
        Q_EMIT model->currentIndexChanged();
    }
    Q_EMIT model->stateLoaded();
}

void CounterListModel::Private::save()
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

void CounterListModel::Private::flushChanges()
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

void CounterListModel::Private::writeState()
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

    // Write the file and update the hash
    QFileInfo file(iSaveFilePath);
    QDir dir(file.dir());
    if (dir.mkpath(dir.absolutePath())) {
        QFile f(file.absoluteFilePath());
        if (f.open(QIODevice::WriteOnly)) {
            QByteArray fileData(QJsonDocument::fromVariant(data).toJson());
            if (f.write(fileData) == fileData.size()) {
                iSaveFileHash = QCryptographicHash::hash(fileData, iHashAlgorithm);
                iIgnoreSaveFileChange++;
            } else {
                HWARN("Error writing" << iSaveFilePath << f.errorString());
            }
        } else {
            HWARN("Error opening" << iSaveFilePath << f.errorString());
        }
    } else {
        HWARN("Failed to create" << dir.absolutePath());
    }
}

void CounterListModel::Private::onSaveDirectoryChanged(QString aPath)
{
    HDEBUG(qPrintable(aPath));
    if (QFile::exists(iSaveFilePath)) {
        if (!iSaveFileWatcher->files().contains(iSaveFilePath)) {
            HDEBUG("Watching" << qPrintable(iSaveFilePath));
            iSaveFileWatcher->addPath(iSaveFilePath);
        }
    }
}

void CounterListModel::Private::onSaveFileChanged(QString aPath)
{
    if (iIgnoreSaveFileChange) {
        iIgnoreSaveFileChange--;
        HDEBUG("Saved" << qPrintable(aPath));
    } else {
        HDEBUG(qPrintable(aPath));
        readState();
    }
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

int CounterListModel::modelIdRole()
{
    return ModelData::ModelIdRole;
}

QString CounterListModel::saveFile() const
{
    return iPrivate->iSaveFile;
}

void CounterListModel::setSaveFile(QString aFileName)
{
    if (iPrivate->iSaveFile != aFileName) {
        HDEBUG(qPrintable(aFileName));
        iPrivate->setSaveFile(aFileName);
        Q_EMIT saveFileChanged();
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

bool CounterListModel::updatingLinkedCounter() const
{
    HASSERT(iPrivate->iUpdatingLinkedCounter >= 0);
    return iPrivate->iUpdatingLinkedCounter > 0;
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
        QModelIndex unlinkIndex;

        // Remove the row deom the model
        beginRemoveRows(QModelIndex(), aRow, aRow);
        ModelData* data = iPrivate->iData.takeAt(aRow);
        if (data->iLink) {
            HDEBUG("clearing link" << data->iLink->iId << "=>" << data->iId);
            unlinkIndex = index(iPrivate->indexOf(data->iLink));
            // Link will be cleared when we delete ModelData
        }
        delete data;
        endRemoveRows();

        if (unlinkIndex.isValid()) {
            // Signal link change
            QVector<int> roles;
            roles.append(ModelData::LinkRole);
            Q_EMIT dataChanged(unlinkIndex, unlinkIndex, roles);
        }

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

        // Save the model
        iPrivate->save();
    }
}

int CounterListModel::findCounter(QString aLink)
{
    return iPrivate->findId(aLink);
}

void CounterListModel::timeChanged()
{
    const int n = iPrivate->rowCount();
    if (n > 0) {
        QVector<int> roles;
        roles.reserve(2);
        for (int i = 0; i < n; i++) {
            ModelData* data = iPrivate->dataAt(i);
            roles.resize(0);
            if (data->iResetTime.isValid()) {
                roles.append(ModelData::ResetTimeRole);
            }
            if (data->iChangeTime.isValid()) {
                roles.append(ModelData::ChangeTimeRole);
            }
            if (!roles.isEmpty()) {
                HDEBUG(i << roles);
                const QModelIndex idx(index(i));
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
        switch ((ModelData::Role)aRole) {
        case ModelData::ValueRole:
            {
                bool ok;
                const int value = aValue.toInt(&ok);
                if (ok && value >= 0) {
                    setValueAt(row, value);
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
                        QVector<int> roles;
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
                const QString title(aValue.toString());
                if (data->iTitle != title) {
                    data->iTitle = title;
                    QVector<int> roles;
                    roles.append(aRole);
                    HDEBUG(row << "title" << title);
                    Q_EMIT dataChanged(aIndex, aIndex, roles);
                    iPrivate->save();
                }
            }
            return true;
        case ModelData::LinkRole:
            {
                const QString link(aValue.toString());
                if (link != data->iId) {
                    QVector<int> roles;
                    roles.append(aRole);
                    if (link.isEmpty()) {
                        // Clearing the link
                        if (data->iLink) {
                            HDEBUG(row << "clearing link" << data->iId << "=>" << link);
                            int unlinkPos = iPrivate->indexOf(data->iLink);
                            data->clearLink();
                            const QModelIndex unlinkIdx(index(unlinkPos));
                            Q_EMIT dataChanged(unlinkIdx, unlinkIdx, roles);
                            Q_EMIT dataChanged(aIndex, aIndex, roles);
                            iPrivate->save();
                        }
                    } else {
                        const int linkPos = iPrivate->findId(link);
                        if (linkPos >= 0) {
                            ModelData* linkData = iPrivate->dataAt(linkPos);
                            if (linkData != data->iLink) {
                                // New (and valid) link
                                ModelData* unlinkData = linkData->iLink;
                                linkData->iLink = data;
                                data->iLink = linkData;
                                HDEBUG(row << "link" << data->iId << "<=>" << link);
                                if (unlinkData) {
                                    unlinkData->iLink = Q_NULLPTR;
                                    int unlinkPos = iPrivate->indexOf(unlinkData);
                                    const QModelIndex unlinkIdx(index(unlinkPos));
                                    Q_EMIT dataChanged(unlinkIdx, unlinkIdx, roles);
                                }
                                const QModelIndex linkIdx(index(linkPos));
                                Q_EMIT dataChanged(linkIdx, linkIdx, roles);
                                Q_EMIT dataChanged(aIndex, aIndex, roles);
                                iPrivate->save();
                            }
                        } else {
                            // Invalid link was passed in
                            HWARN(row << "invalid link" << link);
                        }
                    }
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

void CounterListModel::moveCounter(int aSrcRow, int aDestRow)
{
    const int size = iPrivate->rowCount();
    if (aSrcRow != aDestRow &&
        aSrcRow >= 0 && aSrcRow < size &&
        aDestRow >= 0 && aDestRow < size) {
        HDEBUG(aSrcRow << "->" << aDestRow);
        beginMoveRows(QModelIndex(), aSrcRow, aSrcRow, QModelIndex(),
           (aDestRow < aSrcRow) ? aDestRow : (aDestRow + 1));
        iPrivate->iData.move(aSrcRow, aDestRow);
        iPrivate->save();
        endMoveRows();
    }
}

int CounterListModel::getValueAt(int aRow)
{
    ModelData* data = iPrivate->dataAt(aRow);
    return data ? data->iValue : 0;
}

void CounterListModel::setValueAt(int aRow, int aValue)
{
    ModelData* data = iPrivate->dataAt(aRow);
    if (data && data->iValue != aValue) {
        const int change = aValue - data->iValue;
        HDEBUG(aRow << "value" << data->iValue << "->" << aValue);
        data->iValue = aValue;
        data->iChangeTime = QDateTime::currentDateTime();
        QVector<int> roles;
        roles.reserve(2);
        roles.append(ModelData::ValueRole);
        roles.append(ModelData::ChangeTimeRole);

        // Update the linked counter if there is one
        ModelData* data2 = data->iLink;
        if (data2) {
            const int value2 = qMax(data2->iValue + change, 0);
            if (data2->iValue != value2) {
                const int row2 = iPrivate->findId(data2->iId);
                HDEBUG(row2 << "value" << data2->iValue << "->" << value2);
                if (!(iPrivate->iUpdatingLinkedCounter)++) {
                    Q_EMIT updatingLinkedCounterChanged();
                }
                data2->iValue = value2;
                data2->iChangeTime = data->iChangeTime;
                const QModelIndex index2(index(row2));
                Q_EMIT dataChanged(index2, index2, roles);
                if (!--(iPrivate->iUpdatingLinkedCounter)) {
                    Q_EMIT updatingLinkedCounterChanged();
                }
            }
        }

        const QModelIndex modelIndex(index(aRow));
        Q_EMIT dataChanged(modelIndex, modelIndex, roles);
        iPrivate->save();
    }
}

#include "CounterListModel.moc"
