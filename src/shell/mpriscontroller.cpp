#include <QDBusArgument>
#include <QDBusVariant>
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "mpriscontroller.h"
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>

namespace krema
{

MprisController::MprisController(QObject *parent)
    : QObject(parent)
{
    m_positionTimer = new QTimer(this);
    m_positionTimer->setInterval(1000);
    connect(m_positionTimer, &QTimer::timeout, this, &MprisController::updatePosition);

    m_watcher = new QDBusServiceWatcher(this);
    m_watcher->setConnection(QDBusConnection::sessionBus());
    m_watcher->setWatchMode(QDBusServiceWatcher::WatchForOwnerChange);

    connect(m_watcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &MprisController::onServiceOwnerChanged);

    // Initial fetch
    updatePlayers();

    // Connect to PropertiesChanged on the session bus for MPRIS
    QDBusConnection::sessionBus().connect(QString(),
                                          QStringLiteral("/org/mpris/MediaPlayer2"),
                                          QStringLiteral("org.freedesktop.DBus.Properties"),
                                          QStringLiteral("PropertiesChanged"),
                                          this,
                                          SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));
}

int MprisController::playerPriority(const QString &service)
{
    // Priority 0 = Music (preferred), Priority 1 = Browser/video (deprioritized)
    static const QStringList browserPatterns = {
        QStringLiteral("chromium"),
        QStringLiteral("chrome"),
        QStringLiteral("firefox"),
        QStringLiteral("brave"),
        QStringLiteral("vivaldi"),
        QStringLiteral("edge"),
        QStringLiteral("opera"),
        QStringLiteral("webkit"),
        QStringLiteral("plasma-browser-integration"),
    };
    const QString lower = service.toLower();
    for (const auto &pat : browserPatterns) {
        if (lower.contains(pat))
            return 1;
    }
    return 0;
}

QString MprisController::playerDisplayName(const QString &service)
{
    // "org.mpris.MediaPlayer2.spotify" → "Spotify"
    // "org.mpris.MediaPlayer2.firefox.instance_12345" → "Firefox"
    if (service.isEmpty())
        return QString();
    QString name = service.mid(QStringLiteral("org.mpris.MediaPlayer2.").length());
    // Strip instance suffixes like ".instance12345" or ".instanceXXX"
    int dotPos = name.indexOf(QLatin1Char('.'));
    if (dotPos > 0)
        name = name.left(dotPos);
    // Capitalize first letter
    if (!name.isEmpty())
        name[0] = name[0].toUpper();
    return name;
}

void MprisController::updatePlayers()
{
    QDBusReply<QStringList> reply = m_watcher->connection().interface()->registeredServiceNames();
    if (!reply.isValid())
        return;

    // Collect all MPRIS services with their status and metadata
    struct PlayerInfo {
        QString service;
        QString status; // "Playing", "Paused", "Stopped"
        int priority; // 0 = music, 1 = browser
        QString trackName;
        bool hasArt;
    };
    QList<PlayerInfo> players;

    bool hasPBI = false;

    for (const QString &service : reply.value()) {
        if (!service.startsWith(QLatin1String("org.mpris.MediaPlayer2.")))
            continue;

        PlayerInfo info;
        info.service = service;
        info.priority = playerPriority(service);
        info.status = QStringLiteral("Stopped");
        info.hasArt = false;

        QDBusInterface iface(service,
                             QStringLiteral("/org/mpris/MediaPlayer2"),
                             QStringLiteral("org.freedesktop.DBus.Properties"),
                             QDBusConnection::sessionBus());

        QDBusReply<QDBusVariant> statusReply =
            iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("PlaybackStatus"));
        if (statusReply.isValid())
            info.status = statusReply.value().variant().toString();

        QDBusReply<QDBusVariant> metaReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Metadata"));
        if (metaReply.isValid()) {
            QVariantMap meta;
            QVariant metaVar = metaReply.value().variant();
            if (metaVar.userType() == qMetaTypeId<QDBusArgument>()) {
                meta = qdbus_cast<QVariantMap>(metaVar.value<QDBusArgument>());
            } else if (metaVar.userType() == qMetaTypeId<QVariantMap>()) {
                meta = metaVar.toMap();
            }
            info.trackName = meta.value(QLatin1String("xesam:title")).toString().trimmed();
            info.hasArt = !meta.value(QLatin1String("mpris:artUrl")).toString().isEmpty();
        }

        // Ignore ghost players with no media
        if (info.trackName.isEmpty())
            continue;

        if (service.contains(QLatin1String("plasma-browser-integration")))
            hasPBI = true;

        players.append(info);
    }

    // Deduplicate: If plasma-browser-integration is present, native browser MPRIS usually duplicates it.
    // We will remove native browser players if they have no album art (PBI usually provides art)
    // AND they are a browser player.
    if (hasPBI) {
        players.erase(std::remove_if(players.begin(),
                                     players.end(),
                                     [](const PlayerInfo &p) {
                                         return p.priority == 1 && !p.service.contains(QLatin1String("plasma-browser-integration")) && !p.hasArt;
                                     }),
                      players.end());
    }

    // Sort by: priority (music first) → status (Playing > Paused > Stopped) → hasArt (true > false)
    auto statusWeight = [](const QString &s) -> int {
        if (s == QLatin1String("Playing"))
            return 0;
        if (s == QLatin1String("Paused"))
            return 1;
        return 2;
    };
    std::sort(players.begin(), players.end(), [&](const PlayerInfo &a, const PlayerInfo &b) {
        if (a.priority != b.priority)
            return a.priority < b.priority;
        int weightA = statusWeight(a.status);
        int weightB = statusWeight(b.status);
        if (weightA != weightB)
            return weightA < weightB;
        if (a.hasArt != b.hasArt)
            return a.hasArt > b.hasArt; // true (1) > false (0), so we want true first
        return false;
    });

    // Build the sorted service list
    QStringList newList;
    for (const auto &p : players)
        newList.append(p.service);

    bool listChanged = (newList != m_allPlayers);
    m_allPlayers = newList;

    // Select the best player (unless user manually cycled)
    QString bestService = players.isEmpty() ? QString() : players.first().service;
    QString newService = m_currentPlayerService;

    if (m_userCycled) {
        // Keep user's choice if it's still available
        if (!m_allPlayers.contains(m_currentPlayerService)) {
            m_userCycled = false;
            newService = bestService;
        }
    } else {
        newService = bestService;
    }

    if (listChanged)
        Q_EMIT playerListChanged();

    if (newService != m_currentPlayerService) {
        m_currentPlayerService = newService;
        m_currentPlayerUniqueName = QDBusConnection::sessionBus().interface()->serviceOwner(newService);
        m_hasPlayer = !m_currentPlayerService.isEmpty();
        Q_EMIT hasPlayerChanged();
        if (listChanged)
            Q_EMIT playerListChanged();
        if (m_hasPlayer) {
            QDBusConnection::sessionBus().connect(m_currentPlayerService,
                                                  QStringLiteral("/org/mpris/MediaPlayer2"),
                                                  QStringLiteral("org.mpris.MediaPlayer2.Player"),
                                                  QStringLiteral("Seeked"),
                                                  this,
                                                  SLOT(onSeeked(qlonglong)));
            fetchPlayerProperties();
        } else {
            m_isPlaying = false;
            m_trackName.clear();
            m_artistName.clear();
            m_albumArtUrl.clear();
            m_canControl = false;
            m_length = 0;
            m_position = 0;
            m_volume = 1.0;
            m_shuffle = false;
            m_loopStatus = QStringLiteral("None");
            m_positionTimer->stop();
            Q_EMIT playbackStatusChanged();
            Q_EMIT metadataChanged();
            Q_EMIT canControlChanged();
            Q_EMIT positionChanged();
            Q_EMIT volumeChanged();
            Q_EMIT shuffleChanged();
            Q_EMIT loopStatusChanged();
        }
    }
}

void MprisController::cyclePlayer(int direction)
{
    if (m_allPlayers.size() <= 1)
        return;

    int idx = m_allPlayers.indexOf(m_currentPlayerService);
    if (idx < 0)
        idx = 0;

    idx = (idx + direction + m_allPlayers.size()) % m_allPlayers.size();

    m_userCycled = true;
    QString newService = m_allPlayers.at(idx);
    if (newService != m_currentPlayerService) {
        m_currentPlayerService = newService;
        m_currentPlayerUniqueName = QDBusConnection::sessionBus().interface()->serviceOwner(newService);
        m_hasPlayer = true;
        Q_EMIT hasPlayerChanged();
        Q_EMIT playerListChanged();
        QDBusConnection::sessionBus().connect(m_currentPlayerService,
                                              QStringLiteral("/org/mpris/MediaPlayer2"),
                                              QStringLiteral("org.mpris.MediaPlayer2.Player"),
                                              QStringLiteral("Seeked"),
                                              this,
                                              SLOT(onSeeked(qlonglong)));
        fetchPlayerProperties();
    }
}

void MprisController::onServiceOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner)
{
    if (serviceName.startsWith(QLatin1String("org.mpris.MediaPlayer2."))) {
        // A player appeared or disappeared
        updatePlayers();
    }
}

void MprisController::onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps)
{
    // Ignore non-Player interfaces
    if (interface != QLatin1String("org.mpris.MediaPlayer2.Player")) {
        return;
    }

    // Identify which service sent this signal via the D-Bus message sender
    QString sender;
    if (calledFromDBus()) {
        sender = message().service();
    }

    // If a non-current player changed status, just re-evaluate player selection
    if (!sender.isEmpty() && sender != m_currentPlayerUniqueName) {
        if (changedProps.contains(QLatin1String("PlaybackStatus"))) {
            updatePlayers();
        }
        return;
    }

    bool statusChanged = false;
    bool metaChanged = false;
    bool ctrlChanged = false;

    if (changedProps.contains(QLatin1String("PlaybackStatus"))) {
        QString status = changedProps.value(QLatin1String("PlaybackStatus")).toString();
        qDebug() << "[MPRIS] Current player status:" << playerDisplayName(m_currentPlayerService) << status;
        bool isP = (status == QLatin1String("Playing"));
        if (isP != m_isPlaying) {
            m_isPlaying = isP;
            statusChanged = true;
            if (m_isPlaying) {
                updatePosition();
                m_positionTimer->start();
            } else {
                m_positionTimer->stop();
                updatePosition();
                // When current player stops/pauses, re-evaluate to find a better player
                updatePlayers();
            }
        }
    }

    if (changedProps.contains(QLatin1String("Metadata"))) {
        QVariant metaVar = changedProps.value(QLatin1String("Metadata"));
        qWarning() << "RECEIVED METADATA, Type:" << metaVar.typeName();
        QVariantMap meta;
        if (metaVar.userType() == qMetaTypeId<QDBusArgument>()) {
            meta = qdbus_cast<QVariantMap>(metaVar.value<QDBusArgument>());
        } else if (metaVar.userType() == qMetaTypeId<QVariantMap>()) {
            meta = metaVar.toMap();
        } else {
            // Unhandled
            qWarning() << "Unhandled Metadata type:" << metaVar.typeName();
        }

        QString newTrack = meta.value(QLatin1String("xesam:title")).toString();

        QString newArtist;
        QVariant artistVar = meta.value(QLatin1String("xesam:artist"));
        if (artistVar.canConvert<QStringList>()) {
            newArtist = artistVar.toStringList().join(QLatin1String(", "));
        } else {
            newArtist = artistVar.toString();
        }

        QString newArt = meta.value(QLatin1String("mpris:artUrl")).toString();

        qint64 newLen = m_length;
        if (meta.contains(QLatin1String("mpris:length"))) {
            newLen = meta.value(QLatin1String("mpris:length")).toLongLong();
        }

        QString newTrackId = m_trackId;
        if (meta.contains(QLatin1String("mpris:trackid"))) {
            newTrackId = meta.value(QLatin1String("mpris:trackid")).toString();
        }

        if (newTrack != m_trackName || newArtist != m_artistName || newArt != m_albumArtUrl || newLen != m_length || newTrackId != m_trackId) {
            m_trackName = newTrack;
            m_artistName = newArtist;
            m_albumArtUrl = newArt;
            m_length = newLen;
            m_trackId = newTrackId;
            metaChanged = true;
        }
    }

    if (changedProps.contains(QLatin1String("CanPlay")) || changedProps.contains(QLatin1String("CanPause"))) {
        bool canP = changedProps.value(QLatin1String("CanPlay")).toBool() || changedProps.value(QLatin1String("CanPause")).toBool();
        if (m_canControl != canP) {
            m_canControl = canP;
            ctrlChanged = true;
        }
    }

    if (changedProps.contains(QLatin1String("Volume"))) {
        m_volume = changedProps.value(QLatin1String("Volume")).toDouble();
        Q_EMIT volumeChanged();
    }
    if (changedProps.contains(QLatin1String("Shuffle"))) {
        m_shuffle = changedProps.value(QLatin1String("Shuffle")).toBool();
        Q_EMIT shuffleChanged();
    }
    if (changedProps.contains(QLatin1String("LoopStatus"))) {
        m_loopStatus = changedProps.value(QLatin1String("LoopStatus")).toString();
        Q_EMIT loopStatusChanged();
    }

    if (statusChanged)
        Q_EMIT playbackStatusChanged();
    if (metaChanged)
        Q_EMIT metadataChanged();
    if (ctrlChanged)
        Q_EMIT canControlChanged();
}

void MprisController::fetchPlayerProperties()
{
    if (m_currentPlayerService.isEmpty())
        return;

    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());

    if (!iface.isValid())
        return;

    QDBusReply<QDBusVariant> statusReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("PlaybackStatus"));
    if (statusReply.isValid()) {
        m_isPlaying = (statusReply.value().variant().toString() == QLatin1String("Playing"));
        Q_EMIT playbackStatusChanged();
    }

    QDBusReply<QDBusVariant> metaReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Metadata"));
    if (metaReply.isValid()) {
        QVariantMap changedProps;
        changedProps.insert(QStringLiteral("Metadata"), metaReply.value().variant());
        onPropertiesChanged(QStringLiteral("org.mpris.MediaPlayer2.Player"), changedProps, QStringList());
    }

    QDBusReply<QDBusVariant> ctrlReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("CanPause"));
    if (ctrlReply.isValid()) {
        m_canControl = ctrlReply.value().variant().toBool();
        Q_EMIT canControlChanged();
    }

    QDBusReply<QDBusVariant> volReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Volume"));
    if (volReply.isValid()) {
        m_volume = volReply.value().variant().toDouble();
        Q_EMIT volumeChanged();
    }
}

void MprisController::playPause()
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("PlayPause"));
}

void MprisController::next()
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("Next"));
}

void MprisController::previous()
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("Previous"));
}

void MprisController::onSeeked(qlonglong position)
{
    m_position = position;
    Q_EMIT positionChanged();
}

void MprisController::updatePosition()
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    if (iface.isValid()) {
        QDBusReply<QDBusVariant> rep = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Position"));
        if (rep.isValid()) {
            m_position = rep.value().variant().toLongLong();
            Q_EMIT positionChanged();
        }
    }
}

void MprisController::setPosition(qint64 position)
{
    if (m_currentPlayerService.isEmpty() || m_trackId.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("SetPosition"), QDBusObjectPath(m_trackId), position);
}

void MprisController::setVolume(double volume)
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());

    QDBusMessage reply = iface.call(QStringLiteral("Set"),
                                    QStringLiteral("org.mpris.MediaPlayer2.Player"),
                                    QStringLiteral("Volume"),
                                    QVariant::fromValue(QDBusVariant(QVariant(volume))));

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "[MPRIS] Failed to set volume:" << reply.errorMessage();
    } else {
        m_volume = volume;
        Q_EMIT volumeChanged();
    }
}

void MprisController::setShuffle(bool shuffle)
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock,
               QStringLiteral("Set"),
               QStringLiteral("org.mpris.MediaPlayer2.Player"),
               QStringLiteral("Shuffle"),
               QVariant::fromValue(QDBusVariant(QVariant(shuffle))));
    m_shuffle = shuffle;
    Q_EMIT shuffleChanged();
}

void MprisController::setLoopStatus(const QString &loopStatus)
{
    if (m_currentPlayerService.isEmpty())
        return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock,
               QStringLiteral("Set"),
               QStringLiteral("org.mpris.MediaPlayer2.Player"),
               QStringLiteral("LoopStatus"),
               QVariant::fromValue(QDBusVariant(QVariant(loopStatus))));
    m_loopStatus = loopStatus;
    Q_EMIT loopStatusChanged();
}

} // namespace krema
