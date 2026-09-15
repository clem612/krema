// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QObject>
#include <QString>

namespace krema
{

class MprisController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasPlayer READ hasPlayer NOTIFY hasPlayerChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStatusChanged)
    Q_PROPERTY(QString trackName READ trackName NOTIFY metadataChanged)
    Q_PROPERTY(QString artistName READ artistName NOTIFY metadataChanged)
    Q_PROPERTY(QString albumArtUrl READ albumArtUrl NOTIFY metadataChanged)
    Q_PROPERTY(bool canControl READ canControl NOTIFY canControlChanged)

public:
    explicit MprisController(QObject *parent = nullptr);
    ~MprisController() override = default;

    bool hasPlayer() const
    {
        return m_hasPlayer;
    }
    bool isPlaying() const
    {
        return m_isPlaying;
    }
    QString trackName() const
    {
        return m_trackName;
    }
    QString artistName() const
    {
        return m_artistName;
    }
    QString albumArtUrl() const
    {
        return m_albumArtUrl;
    }
    bool canControl() const
    {
        return m_canControl;
    }

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();

Q_SIGNALS:
    void hasPlayerChanged();
    void playbackStatusChanged();
    void metadataChanged();
    void canControlChanged();

private Q_SLOTS:
    void updatePlayers();
    void onServiceOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner);
    void onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps);

private:
    void fetchPlayerProperties();

    QDBusServiceWatcher *m_watcher = nullptr;
    QString m_currentPlayerService;

    bool m_hasPlayer = false;
    bool m_isPlaying = false;
    QString m_trackName;
    QString m_artistName;
    QString m_albumArtUrl;
    bool m_canControl = false;
};

} // namespace krema
