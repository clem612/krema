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

void MprisController::updatePlayers()
{
    QDBusReply<QStringList> reply = m_watcher->connection().interface()->registeredServiceNames();
    if (!reply.isValid())
        return;

    QString playingService;
    QString pausedService;
    QString stoppedService;

    for (const QString &service : reply.value()) {
        if (service.startsWith(QLatin1String("org.mpris.MediaPlayer2."))) {
            QDBusInterface iface(service,
                                 QStringLiteral("/org/mpris/MediaPlayer2"),
                                 QStringLiteral("org.freedesktop.DBus.Properties"),
                                 QDBusConnection::sessionBus());
            QDBusReply<QDBusVariant> statusReply =
                iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("PlaybackStatus"));
            if (statusReply.isValid()) {
                QString status = statusReply.value().variant().toString();
                if (status == QLatin1String("Playing")) {
                    playingService = service;
                    break; // Found highest priority
                } else if (status == QLatin1String("Paused") && pausedService.isEmpty()) {
                    pausedService = service;
                } else if (stoppedService.isEmpty()) {
                    stoppedService = service;
                }
            } else if (stoppedService.isEmpty()) {
                stoppedService = service;
            }
        }
    }

    QString newService = playingService.isEmpty() ? (pausedService.isEmpty() ? stoppedService : pausedService) : playingService;

    if (newService != m_currentPlayerService) {
        m_currentPlayerService = newService;
        m_hasPlayer = !m_currentPlayerService.isEmpty();
        Q_EMIT hasPlayerChanged();

        if (m_hasPlayer) {
            fetchPlayerProperties();
        } else {
            m_isPlaying = false;
            m_trackName.clear();
            m_artistName.clear();
            m_albumArtUrl.clear();
            m_canControl = false;
            Q_EMIT playbackStatusChanged();
            Q_EMIT metadataChanged();
            Q_EMIT canControlChanged();
        }
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
    // Ignore signals from other services if they happen to share the path
    if (interface != QLatin1String("org.mpris.MediaPlayer2.Player")) {
        return;
    }

    bool statusChanged = false;
    bool metaChanged = false;
    bool ctrlChanged = false;

    if (changedProps.contains(QLatin1String("PlaybackStatus"))) {
        QString status = changedProps.value(QLatin1String("PlaybackStatus")).toString();
        bool isP = (status == QLatin1String("Playing"));
        if (isP != m_isPlaying) {
            m_isPlaying = isP;
            statusChanged = true;
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

        if (newTrack != m_trackName || newArtist != m_artistName || newArt != m_albumArtUrl) {
            m_trackName = newTrack;
            m_artistName = newArtist;
            m_albumArtUrl = newArt;
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

} // namespace krema
