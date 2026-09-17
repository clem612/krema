import os
with open('src/shell/mpriscontroller.cpp', 'r') as f:
    c = f.read()

# I want to add some qDebugs to see what is happening, just in case!
new_meta = """
    if (changedProps.contains(QLatin1String("Metadata"))) {
        QVariant metaVar = changedProps.value(QLatin1String("Metadata"));
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
"""

# wait, I already applied this patch in a previous step!
