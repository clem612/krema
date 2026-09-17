import os
with open('src/shell/mpriscontroller.cpp', 'r') as f:
    c = f.read()

new_update_players = """void MprisController::updatePlayers()
{
    QDBusReply<QStringList> reply = m_dbusWatcher->connection().interface()->registeredServiceNames();
    if (!reply.isValid()) return;

    QString playingService;
    QString pausedService;
    QString stoppedService;

    for (const QString &service : reply.value()) {
        if (service.startsWith(QLatin1String("org.mpris.MediaPlayer2."))) {
            QDBusInterface iface(service, QStringLiteral("/org/mpris/MediaPlayer2"), QStringLiteral("org.freedesktop.DBus.Properties"), QDBusConnection::sessionBus());
            QDBusReply<QDBusVariant> statusReply = iface.call(QStringLiteral("Get"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("PlaybackStatus"));
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
"""

import re
c = re.sub(r'void MprisController::updatePlayers\(\)\n\{.*?(?=\nvoid MprisController::onServiceOwnerChanged)', new_update_players, c, flags=re.DOTALL)

with open('src/shell/mpriscontroller.cpp', 'w') as f:
    f.write(c)
