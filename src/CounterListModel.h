/*
 * Copyright (C) 2020-2021 Jolla Ltd.
 * Copyright (C) 2020-2021 Slava Monich <slava@monich.com>
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

#ifndef COUNTER_LIST_MODEL_H
#define COUNTER_LIST_MODEL_H

#include <QAbstractListModel>

#include <QtQml>

class CounterListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString saveFile READ saveFile WRITE setSaveFile NOTIFY saveFileChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(bool updatingLinkedCounter READ updatingLinkedCounter NOTIFY updatingLinkedCounterChanged)
    Q_DISABLE_COPY(CounterListModel)

    class Private;
    class ModelData;

public:
    CounterListModel(QObject* aParent = Q_NULLPTR);

    static int favoriteRole();
    static int modelIdRole();

    QString saveFile() const;
    void setSaveFile(QString aFileName);

    int currentIndex() const;
    void setCurrentIndex(int aIndex);

    bool updatingLinkedCounter() const;

    Q_INVOKABLE int addCounter();
    Q_INVOKABLE void timeChanged();
    Q_INVOKABLE void resetCounter(int aRow);
    Q_INVOKABLE void deleteCounter(int aRow);
    Q_INVOKABLE void moveCounter(int aSrcRow, int aDestRow);
    Q_INVOKABLE int findCounter(QString aModelId);

    // QAbstractItemModel
    Qt::ItemFlags flags(const QModelIndex& aIndex) const Q_DECL_OVERRIDE;
    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex& aParent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex& aIndex, int aRole) const Q_DECL_OVERRIDE;
    bool setData(const QModelIndex& aIndex, const QVariant& aValue, int aRole) Q_DECL_OVERRIDE;

    // Callback for qmlRegisterSingletonType<CounterListModel>
    static QObject* createSingleton(QQmlEngine* aEngine, QJSEngine* aScript);

protected:
    int getValueAt(int aRow);
    void setValueAt(int aRow, int aValue);

Q_SIGNALS:
    void saveFileChanged();
    void currentIndexChanged();
    void updatingLinkedCounterChanged();
    void stateLoaded();

private:
    Private* iPrivate;
};

#endif // COUNTER_LIST_MODEL_H
