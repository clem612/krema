#include "shell/mpriscontroller.h"
#include <QCoreApplication>
#include <QDebug>
#include <QTimer>

using namespace krema;

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    MprisController controller;

    QObject::connect(&controller, &MprisController::metadataChanged, [&]() {
        qDebug() << "TRACK:" << controller.trackName();
        qDebug() << "ARTIST:" << controller.artistName();
        qDebug() << "URL:" << controller.albumArtUrl();
        QCoreApplication::quit();
    });

    QTimer::singleShot(2000, []() {
        qDebug() << "TIMEOUT!";
        QCoreApplication::quit();
    });

    return app.exec();
}
