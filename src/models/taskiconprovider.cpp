// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "taskiconprovider.h"

#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QPainter>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>
#include <cmath>

namespace krema
{

TaskIconProvider::TaskIconProvider(bool normalizationEnabled)
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
    , m_normalizationEnabled(normalizationEnabled)
{
}

QPixmap TaskIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    const int queryIdx = id.indexOf(QLatin1Char('?'));
    QString iconName = (queryIdx >= 0) ? id.left(queryIdx) : id;
    QString originalId = iconName;

    if (iconName.endsWith(QLatin1String(".desktop"))) {
        iconName.chop(8);
    }

    const int width = requestedSize.width() > 0 ? requestedSize.width() : 48;
    const int height = requestedSize.height() > 0 ? requestedSize.height() : 48;
    const int targetSize = std::max(width, height);

    QIcon icon;

    // 1. Strict Theme Check (prevents fake valid icons)
    if (QIcon::hasThemeIcon(iconName)) {
        icon = QIcon::fromTheme(iconName);
    }

    // 2. Desktop File Extraction
    if (icon.isNull()) {
        QString desktopFile = originalId.endsWith(QLatin1String(".desktop")) ? originalId : originalId + QLatin1String(".desktop");
        QStringList paths = QStandardPaths::locateAll(QStandardPaths::ApplicationsLocation, desktopFile);

        if (!paths.isEmpty()) {
            QSettings settings(paths.first(), QSettings::IniFormat);
            settings.beginGroup(QStringLiteral("Desktop Entry"));
            QString realIconName = settings.value(QStringLiteral("Icon")).toString();

            if (!realIconName.isEmpty()) {
                if (QIcon::hasThemeIcon(realIconName)) {
                    icon = QIcon::fromTheme(realIconName);
                } else {
                    icon = QIcon(realIconName);
                }
            }
        }
    }

    // 3. Steam Resolver
    if (icon.isNull()) {
        if (originalId.startsWith(QLatin1String("steam_app_"))) {
            icon = resolveSteamIcon(originalId.mid(10));
        } else if (originalId.startsWith(QLatin1String("steam_icon_"))) {
            icon = resolveSteamIcon(originalId.mid(11));
        }
    }

    // 🚨 THE FIX: No more gear fallback! Defer to QML RAM icon if we fail.
    if (icon.isNull()) {
        qDebug() << "[krema.icons] Deferring to QML RAM icon for:" << originalId;
        return QPixmap();
    }

    QPixmap result;

    if (!m_normalizationEnabled) {
        result = icon.pixmap(QSize(targetSize, targetSize), 1.0);
    } else {
        auto info = analyzeIcon(originalId, icon);
        const bool hasSignificantPadding = info.contentRatio < 0.95;
        const qreal effectiveRatio = hasSignificantPadding ? info.contentRatio * std::sqrt(info.fillRatio) : info.contentRatio;

        if (effectiveRatio >= kMinContentRatio) {
            const qreal shrinkFactor = (info.contentRatio > kEdgeToEdgeFill) ? kEdgeToEdgeFill / info.contentRatio : 1.0;
            result = shrinkPixmap(icon, targetSize, shrinkFactor);
        } else {
            result = normalizePixmap(icon, targetSize, info);
        }
    }

    // If normalization failed to render, defer to QML
    if (result.isNull()) {
        return QPixmap();
    }

    if (m_iconScale < 1.0) {
        int shrunkSize = static_cast<int>(std::round(targetSize * m_iconScale));
        QImage scaled = result.toImage().scaled(shrunkSize, shrunkSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        result = QPixmap(targetSize, targetSize);
        result.fill(Qt::transparent);
        QPainter painter(&result);
        painter.drawImage((targetSize - scaled.width()) / 2, (targetSize - scaled.height()) / 2, scaled);
        painter.end();
    }

    if (size) {
        *size = result.size();
    }
    return result;
}

void TaskIconProvider::setNormalizationEnabled(bool enabled)
{
    m_normalizationEnabled = enabled;
}

void TaskIconProvider::setIconScale(qreal scale)
{
    m_iconScale = std::clamp(scale, 0.5, 1.0);
}

void TaskIconProvider::clearCache()
{
    m_cache.clear();
}

QRect TaskIconProvider::findContentBounds(const QImage &image, int threshold)
{
    const int w = image.width();
    const int h = image.height();

    if (w == 0 || h == 0) {
        return {};
    }

    int top = h, bottom = -1, left = w, right = -1;

    for (int y = 0; y < h; ++y) {
        const auto *scanline = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < w; ++x) {
            if (qAlpha(scanline[x]) > threshold) {
                if (y < top)
                    top = y;
                if (y > bottom)
                    bottom = y;
                if (x < left)
                    left = x;
                if (x > right)
                    right = x;
            }
        }
    }

    if (bottom < 0) {
        return {};
    }

    return QRect(left, top, right - left + 1, bottom - top + 1);
}

IconNormalizationInfo TaskIconProvider::analyzeIcon(const QString &iconName, const QIcon &icon)
{
    auto it = m_cache.constFind(iconName);
    if (it != m_cache.constEnd()) {
        return it.value();
    }

    // Determine probe size: use the largest available raster, or 256 for SVG
    const auto sizes = icon.availableSizes();
    int probeSize = 0;
    if (sizes.isEmpty()) {
        probeSize = 256; // Fallback for SVGs
    } else {
        for (const auto &s : sizes) {
            probeSize = std::max({probeSize, s.width(), s.height()});
        }
    }
    // For SVG icons, availableSizes() is empty; 256 is a good probe size

    QImage probeImage = icon.pixmap(QSize(probeSize, probeSize), 1.0).toImage();
    if (probeImage.isNull() || probeImage.format() != QImage::Format_ARGB32_Premultiplied) {
        probeImage = probeImage.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    }

    QRect bounds = findContentBounds(probeImage, kAlphaThreshold);

    IconNormalizationInfo info;
    info.probeSize = probeSize;

    if (bounds.isEmpty()) {
        // Fully transparent icon — treat as no padding
        info.contentRatio = 1.0;
        info.fillRatio = 1.0;
        info.contentBounds = QRect(0, 0, probeSize, probeSize);
    } else {
        int contentDim = std::max(bounds.width(), bounds.height());
        info.contentRatio = static_cast<qreal>(contentDim) / probeSize;
        info.contentBounds = bounds;

        // Count non-transparent pixels within content bounds to measure shape fill.
        // Square icon fills ~100% of bbox, circle fills ~π/4 ≈ 78.5%.
        int contentPixels = 0;
        for (int y = bounds.top(); y <= bounds.bottom(); ++y) {
            const auto *scanline = reinterpret_cast<const QRgb *>(probeImage.constScanLine(y));
            for (int x = bounds.left(); x <= bounds.right(); ++x) {
                if (qAlpha(scanline[x]) > kAlphaThreshold) {
                    ++contentPixels;
                }
            }
        }
        const qreal bboxArea = static_cast<qreal>(bounds.width()) * bounds.height();
        info.fillRatio = (bboxArea > 0) ? contentPixels / bboxArea : 1.0;
    }

    m_cache.insert(iconName, info);
    return info;
}

QPixmap TaskIconProvider::normalizePixmap(const QIcon &icon, int targetSize, const IconNormalizationInfo &info)
{
    // Adaptive margin: circular icons (low fillRatio) have inherent visual spacing
    // in their transparent corners, so they need less explicit margin.
    // Square (fill≈1.0) → full margin (4%), Circle (fill≈0.785) → minimal margin (1%).
    const qreal margin = (info.fillRatio < 0.95) ? 0.01 : kMinMarginRatio;
    const qreal maxFill = 1.0 - margin * 2;

    const qreal effectiveRatio = info.contentRatio * std::sqrt(info.fillRatio);
    qreal targetFill = std::min(effectiveRatio * kMaxEffectiveScale, maxFill);
    int targetContentPx = static_cast<int>(std::round(targetSize * targetFill));

    // How large we need to load the icon so that its content region is >= targetContentPx
    int requiredLoadSize = static_cast<int>(std::ceil(static_cast<qreal>(targetContentPx) / info.contentRatio));

    // Determine actual load size
    const auto sizes = icon.availableSizes();
    int loadSize = requiredLoadSize;

    if (!sizes.isEmpty()) {
        // Raster icon: find smallest available size >= requiredLoadSize
        int bestSize = 0;
        int largestAvailable = 0;
        for (const auto &s : sizes) {
            int maxDim = std::max(s.width(), s.height());
            if (maxDim >= requiredLoadSize && (bestSize == 0 || maxDim < bestSize)) {
                bestSize = maxDim;
            }
            if (maxDim > largestAvailable) {
                largestAvailable = maxDim;
            }
        }
        loadSize = (bestSize > 0) ? bestSize : largestAvailable;
    }
    // SVG: loadSize = requiredLoadSize (exact render)

    // Load icon at the determined size
    QImage loadedImage = icon.pixmap(QSize(loadSize, loadSize), 1.0).toImage();
    if (loadedImage.isNull()) {
        QPixmap fallback(targetSize, targetSize);
        fallback.fill(Qt::transparent);
        return fallback;
    }
    if (loadedImage.format() != QImage::Format_ARGB32_Premultiplied) {
        loadedImage = loadedImage.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    }

    // Find actual content bounds in the loaded image
    QRect bounds = findContentBounds(loadedImage, kAlphaThreshold);
    if (bounds.isEmpty()) {
        return icon.pixmap(QSize(targetSize, targetSize), 1.0);
    }

    // Expand to square, centered on the content center
    int contentDim = std::max(bounds.width(), bounds.height());
    int cx = bounds.center().x();
    int cy = bounds.center().y();
    int half = contentDim / 2;

    QRect squareBounds(cx - half, cy - half, contentDim, contentDim);

    // Clamp to image bounds
    squareBounds = squareBounds.intersected(loadedImage.rect());

    // Crop the content
    QImage cropped = loadedImage.copy(squareBounds);

    // Scale the cropped content to targetContentPx
    QImage scaled = cropped.scaled(targetContentPx, targetContentPx, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    // Place centered on the target canvas
    QPixmap result(targetSize, targetSize);
    result.fill(Qt::transparent);
    QPainter painter(&result);
    int offsetX = (targetSize - scaled.width()) / 2;
    int offsetY = (targetSize - scaled.height()) / 2;
    painter.drawImage(offsetX, offsetY, scaled);
    painter.end();

    return result;
}

QPixmap TaskIconProvider::shrinkPixmap(const QIcon &icon, int targetSize, qreal shrinkFactor)
{
    QPixmap original = icon.pixmap(QSize(targetSize, targetSize), 1.0);
    if (original.isNull()) {
        original = QPixmap(targetSize, targetSize);
        original.fill(Qt::transparent);
        return original;
    }

    int shrunkSize = static_cast<int>(std::round(targetSize * shrinkFactor));
    QImage scaled = original.toImage().scaled(shrunkSize, shrunkSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    QPixmap result(targetSize, targetSize);
    result.fill(Qt::transparent);
    QPainter painter(&result);
    int offsetX = (targetSize - scaled.width()) / 2;
    int offsetY = (targetSize - scaled.height()) / 2;
    painter.drawImage(offsetX, offsetY, scaled);
    painter.end();

    return result;
}

QIcon TaskIconProvider::resolveSteamIcon(const QString &appId)
{
    QString cachePath = QDir::homePath() + QLatin1String("/.local/share/Steam/appcache/librarycache/") + appId;
    QDir appSubDir(cachePath);

    if (appSubDir.exists()) {
        qDebug() << "[krema.icons] Steam: Searching local cache for high-res assets at" << appSubDir.path();

        QDirIterator subIt(appSubDir.path(), QStringList{QStringLiteral("*.jpg"), QStringLiteral("*.png")}, QDir::Files, QDirIterator::Subdirectories);

        QString logoCandidate;
        QString capsuleCandidate;
        QString largestCandidate;
        qint64 largestSize = 0;

        while (subIt.hasNext()) {
            QString currentPath = subIt.next();
            QFileInfo fileInfo(currentPath);
            QString fileName = fileInfo.fileName().toLower();

            if (fileName.contains(QLatin1String("logo"))) {
                logoCandidate = currentPath;
            } else if (fileName.contains(QLatin1String("capsule"))) {
                capsuleCandidate = currentPath;
            }

            if (fileInfo.size() > largestSize && !fileName.contains(QLatin1String("hero"))) {
                largestSize = fileInfo.size();
                largestCandidate = currentPath;
            }
        }

        // Prioritize the transparent game logo first
        if (!logoCandidate.isEmpty()) {
            qDebug() << "[krema.icons] Steam: Found high-res transparent logo:" << logoCandidate;
            return QIcon(logoCandidate);
        } else if (!capsuleCandidate.isEmpty()) {
            qDebug() << "[krema.icons] Steam: Found high-res capsule poster:" << capsuleCandidate;
            return QIcon(capsuleCandidate);
        } else if (!largestCandidate.isEmpty()) {
            return QIcon(largestCandidate);
        }
    }

    qDebug() << "[krema.icons] Steam: No valid icons found for AppID" << appId;
    return QIcon();
}

} // namespace krema
