#include "hyprlandpreviewresponse.h"
#include "hyprlandexportmanager.h"
#include <QDebug>
#include <QQuickTextureFactory>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

namespace krema
{

HyprlandPreviewResponse::HyprlandPreviewResponse(const QString &id, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize);

    auto *mgr = HyprlandExportManager::instance();
    if (!mgr->manager() || !mgr->shm()) {
        QMetaObject::invokeMethod(this, "finished", Qt::QueuedConnection);
        return;
    }

    // Convert address (e.g. 0x5557ae915a60) to uint32_t handle
    bool ok;
    quint64 addr = id.toULongLong(&ok, 16);
    if (!ok) {
        QMetaObject::invokeMethod(this, "finished", Qt::QueuedConnection);
        return;
    }
    uint32_t handle = static_cast<uint32_t>(addr & 0xFFFFFFFF);

    m_frame = hyprland_toplevel_export_manager_v1_capture_toplevel(mgr->manager(), 0, handle);
    if (!m_frame) {
        QMetaObject::invokeMethod(this, "finished", Qt::QueuedConnection);
        return;
    }

    static const struct hyprland_toplevel_export_frame_v1_listener frame_listener =
        {frame_buffer, frame_damage, frame_flags, frame_ready, frame_failed, frame_linux_dmabuf, frame_buffer_done};

    hyprland_toplevel_export_frame_v1_add_listener(m_frame, &frame_listener, this);
}

HyprlandPreviewResponse::~HyprlandPreviewResponse()
{
    if (m_frame) {
        hyprland_toplevel_export_frame_v1_destroy(m_frame);
    }
    if (m_wlBuffer) {
        wl_buffer_destroy(m_wlBuffer);
    }
    if (m_shmData && m_shmData != MAP_FAILED) {
        munmap(m_shmData, m_shmSize);
    }
    if (m_fd >= 0) {
        close(m_fd);
    }
}

QQuickTextureFactory *HyprlandPreviewResponse::textureFactory() const
{
    if (m_image.isNull()) {
        return nullptr;
    }
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

void HyprlandPreviewResponse::frame_buffer(void *data,
                                           struct hyprland_toplevel_export_frame_v1 *frame,
                                           uint32_t format,
                                           uint32_t width,
                                           uint32_t height,
                                           uint32_t stride)
{
    Q_UNUSED(frame);
    auto *self = static_cast<HyprlandPreviewResponse *>(data);
    self->m_format = format;
    self->m_width = width;
    self->m_height = height;
    self->m_stride = stride;
}

void HyprlandPreviewResponse::frame_damage(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t x, uint32_t y, uint32_t width, uint32_t height)
{
    Q_UNUSED(data);
    Q_UNUSED(frame);
    Q_UNUSED(x);
    Q_UNUSED(y);
    Q_UNUSED(width);
    Q_UNUSED(height);
}

void HyprlandPreviewResponse::frame_flags(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t flags)
{
    Q_UNUSED(data);
    Q_UNUSED(frame);
    Q_UNUSED(flags);
}

void HyprlandPreviewResponse::frame_ready(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t tv_sec_hi, uint32_t tv_sec_lo, uint32_t tv_nsec)
{
    Q_UNUSED(frame);
    Q_UNUSED(tv_sec_hi);
    Q_UNUSED(tv_sec_lo);
    Q_UNUSED(tv_nsec);

    auto *self = static_cast<HyprlandPreviewResponse *>(data);

    if (self->m_shmData && self->m_shmData != MAP_FAILED) {
        // We must copy the data into a QImage because m_shmData will be unmapped in destructor
        QImage::Format qfmt = QImage::Format_ARGB32_Premultiplied;
        if (self->m_format == 1) { // WL_SHM_FORMAT_XRGB8888
            qfmt = QImage::Format_RGB32;
        }

        QImage tmp(static_cast<uchar *>(self->m_shmData), self->m_width, self->m_height, self->m_stride, qfmt);
        self->m_image = tmp.copy(); // Deep copy so we can free the mmap
    }

    Q_EMIT self->finished();
}

void HyprlandPreviewResponse::frame_failed(void *data, struct hyprland_toplevel_export_frame_v1 *frame)
{
    Q_UNUSED(frame);
    auto *self = static_cast<HyprlandPreviewResponse *>(data);
    Q_EMIT self->finished();
}

void HyprlandPreviewResponse::frame_linux_dmabuf(void *data, struct hyprland_toplevel_export_frame_v1 *frame, uint32_t format, uint32_t width, uint32_t height)
{
    Q_UNUSED(data);
    Q_UNUSED(frame);
    Q_UNUSED(format);
    Q_UNUSED(width);
    Q_UNUSED(height);
}

#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC 0x0001U
#endif

void HyprlandPreviewResponse::frame_buffer_done(void *data, struct hyprland_toplevel_export_frame_v1 *frame)
{
    Q_UNUSED(frame);
    auto *self = static_cast<HyprlandPreviewResponse *>(data);

    if (self->m_width == 0 || self->m_height == 0) {
        hyprland_toplevel_export_frame_v1_destroy(self->m_frame);
        self->m_frame = nullptr;
        Q_EMIT self->finished();
        return;
    }

    self->m_shmSize = self->m_stride * self->m_height;
    self->m_fd = memfd_create("krema_hyprland_preview", MFD_CLOEXEC);
    if (self->m_fd < 0) {
        Q_EMIT self->finished();
        return;
    }

    if (ftruncate(self->m_fd, self->m_shmSize) < 0) {
        Q_EMIT self->finished();
        return;
    }

    self->m_shmData = mmap(nullptr, self->m_shmSize, PROT_READ | PROT_WRITE, MAP_SHARED, self->m_fd, 0);
    if (self->m_shmData == MAP_FAILED) {
        Q_EMIT self->finished();
        return;
    }

    auto *mgr = HyprlandExportManager::instance();
    struct wl_shm_pool *pool = wl_shm_create_pool(mgr->shm(), self->m_fd, self->m_shmSize);
    self->m_wlBuffer = wl_shm_pool_create_buffer(pool, 0, self->m_width, self->m_height, self->m_stride, self->m_format);
    wl_shm_pool_destroy(pool);

    hyprland_toplevel_export_frame_v1_copy(self->m_frame, self->m_wlBuffer, 1);
}

} // namespace krema
