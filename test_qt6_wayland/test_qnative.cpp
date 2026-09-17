#include <QGuiApplication>
#include <QNativeInterface/QWaylandWindow>
#include <QWindow>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QWindow window;
    auto *native = window.nativeInterface<QNativeInterface::QWaylandWindow>();
    if (native) {
        struct wl_surface *s = native->surface();
        return 0;
    }
    return 1;
}
