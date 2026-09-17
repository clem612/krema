#pragma once

#include <QImage>
#include <QQuickAsyncImageProvider>
#include <QQuickImageResponse>
#include <QString>

namespace krema
{

class HyprlandPreviewProvider : public QQuickAsyncImageProvider
{
public:
    HyprlandPreviewProvider();
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
};

} // namespace krema
