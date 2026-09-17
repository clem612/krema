import re

with open('src/shell/mpriscontroller.cpp', 'r') as f:
    c = f.read()

# Setup QTimer in constructor
constructor_replace = """MprisController::MprisController(QObject *parent)
    : QObject(parent)
{
    m_positionTimer = new QTimer(this);
    m_positionTimer->setInterval(1000);
    connect(m_positionTimer, &QTimer::timeout, this, &MprisController::updatePosition);
"""
c = re.sub(r'MprisController::MprisController\(QObject \*parent\)\s*:\s*QObject\(parent\)\s*\{', constructor_replace, c)

# Connect/disconnect signals when player changes
service_change = """
        if (m_hasPlayer) {
            // Reconnect Seeked signal
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
            m_loopStatus = "None";
            m_positionTimer->stop();
            Q_EMIT playbackStatusChanged();
            Q_EMIT metadataChanged();
            Q_EMIT canControlChanged();
            Q_EMIT positionChanged();
            Q_EMIT volumeChanged();
            Q_EMIT shuffleChanged();
            Q_EMIT loopStatusChanged();
        }"""
c = re.sub(r'\s*if \(m_hasPlayer\) \{\s*fetchPlayerProperties\(\);\s*\} else \{.*?\Q_EMIT canControlChanged\(\);\s*\}'.replace(r'\Q', 'Q'), service_change, c, flags=re.DOTALL)

# Handle timer on status change
status_changed = """    if (changedProps.contains(QLatin1String("PlaybackStatus"))) {
        QString status = changedProps.value(QLatin1String("PlaybackStatus")).toString();
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
            }
        }
    }"""
c = re.sub(r'    if \(changedProps\.contains\(QLatin1String\("PlaybackStatus"\)\)\) \{.*?\n    \}', status_changed, c, flags=re.DOTALL)

# Parse length in metadata
meta_length = """        QString newArt = meta.value(QLatin1String("mpris:artUrl")).toString();

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
        }"""
c = re.sub(r'        QString newArt = meta\.value\(QLatin1String\("mpris:artUrl"\)\)\.toString\(\);\n\n        if \(newTrack != m_trackName \|\| newArtist != m_artistName \|\| newArt != m_albumArtUrl\) \{\n            m_trackName = newTrack;\n            m_artistName = newArtist;\n            m_albumArtUrl = newArt;\n            metaChanged = true;\n        \}', meta_length, c, flags=re.DOTALL)

# Handle Volume, Shuffle, LoopStatus in onPropertiesChanged
props_changed_extra = """
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
"""
c = re.sub(r'    if \(statusChanged\)', props_changed_extra + '\n    if (statusChanged)', c)

# Add implementations for fetching extra props, updatePosition, and setters
impls = """
void MprisController::onSeeked(qlonglong position)
{
    m_position = position;
    Q_EMIT positionChanged();
}

void MprisController::updatePosition()
{
    if (m_currentPlayerService.isEmpty()) return;
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
    if (m_currentPlayerService.isEmpty() || m_trackId.isEmpty()) return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.mpris.MediaPlayer2.Player"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("SetPosition"), QDBusObjectPath(m_trackId), position);
}

void MprisController::setVolume(double volume)
{
    if (m_currentPlayerService.isEmpty()) return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("Set"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Volume"), QDBusVariant(volume));
    m_volume = volume;
    Q_EMIT volumeChanged();
}

void MprisController::setShuffle(bool shuffle)
{
    if (m_currentPlayerService.isEmpty()) return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("Set"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("Shuffle"), QDBusVariant(shuffle));
    m_shuffle = shuffle;
    Q_EMIT shuffleChanged();
}

void MprisController::setLoopStatus(const QString &loopStatus)
{
    if (m_currentPlayerService.isEmpty()) return;
    QDBusInterface iface(m_currentPlayerService,
                         QStringLiteral("/org/mpris/MediaPlayer2"),
                         QStringLiteral("org.freedesktop.DBus.Properties"),
                         QDBusConnection::sessionBus());
    iface.call(QDBus::NoBlock, QStringLiteral("Set"), QStringLiteral("org.mpris.MediaPlayer2.Player"), QStringLiteral("LoopStatus"), QDBusVariant(loopStatus));
    m_loopStatus = loopStatus;
    Q_EMIT loopStatusChanged();
}
"""
c = c.replace('} // namespace krema', impls + '\n} // namespace krema')

with open('src/shell/mpriscontroller.cpp', 'w') as f:
    f.write(c)
