#pragma once

#include "hyprland-toplevel-export-v1-client-protocol.h"
#include <QObject>
#include <wayland-client.h>

namespace krema
{

class HyprlandExportManager : public QObject
{
    Q_OBJECT
public:
    static HyprlandExportManager *instance();

    struct hyprland_toplevel_export_manager_v1 *manager() const
    {
        return m_manager;
    }
    struct wl_shm *shm() const
    {
        return m_shm;
    }

private:
    HyprlandExportManager();
    ~HyprlandExportManager();

    static void registry_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version);
    static void registry_global_remove(void *data, struct wl_registry *registry, uint32_t name);

    struct wl_registry *m_registry = nullptr;
    struct hyprland_toplevel_export_manager_v1 *m_manager = nullptr;
    struct wl_shm *m_shm = nullptr;
};

} // namespace krema
