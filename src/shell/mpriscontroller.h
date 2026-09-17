// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <QDBusConnection>
#include <QDBusContext>
#include <QDBusServiceWatcher>
#include <QObject>
#include <QString>
#include <QTimer>

namespace krema
{

class MprisController : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_PROPERTY(bool hasPlayer READ hasPlayer NOTIFY hasPlayerChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStatusChanged)
    Q_PROPERTY(QString trackName READ trackName NOTIFY metadataChanged)
    Q_PROPERTY(QString artistName READ artistName NOTIFY metadataChanged)
    Q_PROPERTY(QString albumArtUrl READ albumArtUrl NOTIFY metadataChanged)
    Q_PROPERTY(bool canControl READ canControl NOTIFY canControlChanged)
    Q_PROPERTY(qint64 length READ length NOTIFY metadataChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(QString loopStatus READ loopStatus WRITE setLoopStatus NOTIFY loopStatusChanged)
    Q_PROPERTY(int playerCount READ playerCount NOTIFY playerListChanged)
    Q_PROPERTY(int currentPlayerIndex READ currentPlayerIndex NOTIFY playerListChanged)
    Q_PROPERTY(QString currentPlayerName READ currentPlayerName NOTIFY playerListChanged)

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
    qint64 length() const
    {
        return m_length;
    }
    qint64 position() const
    {
        return m_position;
    }
    double volume() const
    {
        return m_volume;
    }
    bool shuffle() const
    {
        return m_shuffle;
    }
    QString loopStatus() const
    {
        return m_loopStatus;
    }

    void setPosition(qint64 position);
    void setVolume(double volume);
    void setShuffle(bool shuffle);
    void setLoopStatus(const QString &loopStatus);

    int playerCount() const
    {
        return m_allPlayers.size();
    }
    int currentPlayerIndex() const
    {
        return m_allPlayers.indexOf(m_currentPlayerService);
    }
    QString currentPlayerName() const
    {
        return playerDisplayName(m_currentPlayerService);
    }

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void cyclePlayer(int direction);

Q_SIGNALS:
    void hasPlayerChanged();
    void playbackStatusChanged();
    void metadataChanged();
    void canControlChanged();
    void positionChanged();
    void volumeChanged();
    void shuffleChanged();
    void loopStatusChanged();
    void playerListChanged();

private Q_SLOTS:
    void updatePlayers();
    void onServiceOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner);
    void onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps);
    void onSeeked(qlonglong position);
    void updatePosition();

private:
    void fetchPlayerProperties();
    static int playerPriority(const QString &service);
    static QString playerDisplayName(const QString &service);

    QDBusServiceWatcher *m_watcher = nullptr;
    QStringList m_allPlayers;
    bool m_userCycled = false;

    bool m_hasPlayer = false;
    bool m_isPlaying = false;
    QString m_currentPlayerService;
    QString m_currentPlayerUniqueName;
    QString m_trackName;
    QString m_artistName;
    QString m_albumArtUrl;
    QString m_trackId;
    bool m_canControl = false;
    qint64 m_length = 0;
    qint64 m_position = 0;
    double m_volume = 1.0;
    bool m_shuffle = false;
    QString m_loopStatus = QStringLiteral("None");
    QTimer *m_positionTimer = nullptr;
};

} // namespace krema
