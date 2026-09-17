#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QDBusReply<QStringList> reply = QDBusConnection::sessionBus().interface()->registeredServiceNames();
    if (reply.isValid()) {
        for (const QString &name : reply.value()) {
            if (name.startsWith("org.mpris.MediaPlayer2.")) {
                QDBusInterface iface(name, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", QDBusConnection::sessionBus());
                QDBusReply<QDBusVariant> statusReply = iface.call("Get", "org.mpris.MediaPlayer2.Player", "PlaybackStatus");
                if (statusReply.isValid()) {
                    qDebug() << name << "status:" << statusReply.value().variant().toString();
                } else {
                    qDebug() << name << "NO STATUS!";
                }
            }
        }
    }
    return 0;
}
