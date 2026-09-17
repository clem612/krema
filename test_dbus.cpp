#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDebug>
int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    qDebug() << QDBusConnection::sessionBus().interface()->serviceOwner("org.kde.kdeconnect");
    return 0;
}
