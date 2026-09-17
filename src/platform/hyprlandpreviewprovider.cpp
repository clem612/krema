#include "hyprlandpreviewprovider.h"
#include "hyprlandpreviewresponse.h"

namespace krema
{

HyprlandPreviewProvider::HyprlandPreviewProvider()
{
}

QQuickImageResponse *HyprlandPreviewProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    return new HyprlandPreviewResponse(id, requestedSize);
}

} // namespace krema
