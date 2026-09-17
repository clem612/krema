#include <QGuiApplication>
#include <QWindow>
#include <qpa/qplatformnativeinterface.h>
#include <wayland-client.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QWindow window;
    window.create();
    QPlatformNativeInterface *native = QGuiApplication::platformNativeInterface();
    wl_surface *surface = static_cast<wl_surface *>(native->nativeResourceForWindow(QByteArrayLiteral("surface"), &window));
    return surface != nullptr ? 0 : 1;
}
