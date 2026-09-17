#include <QGuiApplication>
#include <QNativeInterface/QWaylandWindow>
#include <QWindow>

int main()
{
    QWindow window;
    auto *native = window.nativeInterface<QNativeInterface::QWaylandWindow>();
    return 0;
}
