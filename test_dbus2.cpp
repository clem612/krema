#include <QCoreApplication>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDebug>
#include <QVariantMap>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QDBusInterface iface("org.mpris.MediaPlayer2.ryotunes", "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", QDBusConnection::sessionBus());
    QDBusReply<QDBusVariant> metaReply = iface.call("Get", "org.mpris.MediaPlayer2.Player", "Metadata");
    if (metaReply.isValid()) {
        QVariant v = metaReply.value().variant();
        QDBusArgument arg = v.value<QDBusArgument>();
        QVariantMap meta = qdbus_cast<QVariantMap>(arg);

        QVariant titleVar = meta.value("xesam:title");
        qDebug() << "Title Type:" << titleVar.typeName() << "Value:" << titleVar.toString();

        if (titleVar.userType() == qMetaTypeId<QDBusVariant>()) {
            qDebug() << "Unwrapped QDBusVariant title:" << titleVar.value<QDBusVariant>().variant().toString();
        }
    }
    return 0;
}
