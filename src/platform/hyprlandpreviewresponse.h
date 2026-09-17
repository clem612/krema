#pragma once

#include "hyprland-toplevel-export-v1-client-protocol.h"
#include <QImage>
#include <QQuickImageResponse>
#include <QRunnable>

namespace krema
{

class HyprlandPreviewResponse : public QQuickImageResponse
{
    Q_OBJECT
public:
    HyprlandPreviewResponse(const QString &id, const QSize &requestedSize);
    ~HyprlandPreviewResponse() override;

    QQuickTextureFactory *textureFactory() const override;

private:
    static void frame_buffer(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t format, uint32_t width, uint32_t height, uint32_t stride);
    static void frame_damage(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
    static void frame_flags(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t flags);
    static void frame_ready(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t tv_sec_hi, uint32_t tv_sec_lo, uint32_t tv_nsec);
    static void frame_failed(void *data, struct hyprland_toplevel_export_frame_v1 *frame);
    static void frame_linux_dmabuf(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t format, uint32_t width, uint32_t height);
    static void frame_buffer_done(void *data, struct hyprland_toplevel_export_frame_v1 *frame);

    struct hyprland_toplevel_export_frame_v1 *m_frame = nullptr;
    struct wl_buffer *m_wlBuffer = nullptr;
    void *m_shmData = nullptr;
    size_t m_shmSize = 0;
    int m_fd = -1;

    uint32_t m_width = 0;
    uint32_t m_height = 0;
    uint32_t m_stride = 0;
    uint32_t m_format = 0;

    QImage m_image;
};

} // namespace krema
