#include "hyprlandexportmanager.h"
#include <QDebug>
#include <QGuiApplication>
#include <QtGui/qguiapplication_platform.h>

namespace krema
{

HyprlandExportManager *HyprlandExportManager::instance()
{
    static HyprlandExportManager s_instance;
    return &s_instance;
}

HyprlandExportManager::HyprlandExportManager()
{
    auto *waylandApp = qGuiApp->nativeInterface<QNativeInterface::QWaylandApplication>();
    struct wl_display *display = waylandApp ? waylandApp->display() : nullptr;
    if (!display) {
        qWarning() << "Failed to get wl_display from Qt";
        return;
    }

    m_registry = wl_display_get_registry(display);
    static const struct wl_registry_listener registry_listener = {registry_global, registry_global_remove};
    wl_registry_add_listener(m_registry, &registry_listener, this);
    wl_display_roundtrip(display);
}

HyprlandExportManager::~HyprlandExportManager()
{
    if (m_manager) {
        hyprland_toplevel_export_manager_v1_destroy(m_manager);
    }
    if (m_registry) {
        wl_registry_destroy(m_registry);
    }
}

void HyprlandExportManager::registry_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version)
{
    HyprlandExportManager *self = static_cast<HyprlandExportManager *>(data);
    QString iface = QString::fromUtf8(interface);

    if (iface == QStringLiteral("hyprland_toplevel_export_manager_v1")) {
        self->m_manager = static_cast<struct hyprland_toplevel_export_manager_v1 *>(
            wl_registry_bind(registry, name, &hyprland_toplevel_export_manager_v1_interface, 1) // Using V1
        );
    } else if (iface == QStringLiteral("wl_shm")) {
        self->m_shm = static_cast<struct wl_shm *>(wl_registry_bind(registry, name, &wl_shm_interface, 1));
    }
}

void HyprlandExportManager::registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
    Q_UNUSED(data);
    Q_UNUSED(registry);
    Q_UNUSED(name);
}

} // namespace krema
