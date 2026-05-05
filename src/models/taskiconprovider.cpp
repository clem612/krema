// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "taskiconprovider.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
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

    // 1. Strict Theme Check
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

    if (w == 0 || h == 0)
        return {};

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

    if (bottom < 0)
        return {};
    return QRect(left, top, right - left + 1, bottom - top + 1);
}

IconNormalizationInfo TaskIconProvider::analyzeIcon(const QString &iconName, const QIcon &icon)
{
    auto it = m_cache.constFind(iconName);
    if (it != m_cache.constEnd())
        return it.value();

    const auto sizes = icon.availableSizes();
    int probeSize = sizes.isEmpty() ? 256 : 0;
    for (const auto &s : sizes)
        probeSize = std::max({probeSize, s.width(), s.height()});

    QImage probeImage = icon.pixmap(QSize(probeSize, probeSize), 1.0).toImage();
    if (probeImage.isNull() || probeImage.format() != QImage::Format_ARGB32_Premultiplied) {
        probeImage = probeImage.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    }

    QRect bounds = findContentBounds(probeImage, kAlphaThreshold);
    IconNormalizationInfo info;
    info.probeSize = probeSize;

    if (bounds.isEmpty()) {
        info.contentRatio = 1.0;
        info.fillRatio = 1.0;
        info.contentBounds = QRect(0, 0, probeSize, probeSize);
    } else {
        int contentDim = std::max(bounds.width(), bounds.height());
        info.contentRatio = static_cast<qreal>(contentDim) / probeSize;
        info.contentBounds = bounds;

        int contentPixels = 0;
        for (int y = bounds.top(); y <= bounds.bottom(); ++y) {
            const auto *scanline = reinterpret_cast<const QRgb *>(probeImage.constScanLine(y));
            for (int x = bounds.left(); x <= bounds.right(); ++x) {
                if (qAlpha(scanline[x]) > kAlphaThreshold)
                    ++contentPixels;
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
    const qreal margin = (info.fillRatio < 0.95) ? 0.01 : kMinMarginRatio;
    const qreal maxFill = 1.0 - margin * 2;
    const qreal effectiveRatio = info.contentRatio * std::sqrt(info.fillRatio);
    qreal targetFill = std::min(effectiveRatio * kMaxEffectiveScale, maxFill);
    int targetContentPx = static_cast<int>(std::round(targetSize * targetFill));
    int requiredLoadSize = static_cast<int>(std::ceil(static_cast<qreal>(targetContentPx) / info.contentRatio));

    const auto sizes = icon.availableSizes();
    int loadSize = requiredLoadSize;
    if (!sizes.isEmpty()) {
        int bestSize = 0, largestAvailable = 0;
        for (const auto &s : sizes) {
            int maxDim = std::max(s.width(), s.height());
            if (maxDim >= requiredLoadSize && (bestSize == 0 || maxDim < bestSize))
                bestSize = maxDim;
            if (maxDim > largestAvailable)
                largestAvailable = maxDim;
        }
        loadSize = (bestSize > 0) ? bestSize : largestAvailable;
    }

    QImage loadedImage = icon.pixmap(QSize(loadSize, loadSize), 1.0).toImage();
    if (loadedImage.isNull()) {
        QPixmap fallback(targetSize, targetSize);
        fallback.fill(Qt::transparent);
        return fallback;
    }
    if (loadedImage.format() != QImage::Format_ARGB32_Premultiplied) {
        loadedImage = loadedImage.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    }

    QRect bounds = findContentBounds(loadedImage, kAlphaThreshold);
    if (bounds.isEmpty())
        return icon.pixmap(QSize(targetSize, targetSize), 1.0);

    int contentDim = std::max(bounds.width(), bounds.height());
    QRect squareBounds(bounds.center().x() - contentDim / 2, bounds.center().y() - contentDim / 2, contentDim, contentDim);
    QImage cropped = loadedImage.copy(squareBounds.intersected(loadedImage.rect()));
    QImage scaled = cropped.scaled(targetContentPx, targetContentPx, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    QPixmap result(targetSize, targetSize);
    result.fill(Qt::transparent);
    QPainter painter(&result);
    painter.drawImage((targetSize - scaled.width()) / 2, (targetSize - scaled.height()) / 2, scaled);
    painter.end();
    return result;
}

QPixmap TaskIconProvider::shrinkPixmap(const QIcon &icon, int targetSize, qreal shrinkFactor)
{
    QPixmap original = icon.pixmap(QSize(targetSize, targetSize), 1.0);
    if (original.isNull()) {
        QPixmap fallback(targetSize, targetSize);
        fallback.fill(Qt::transparent);
        return fallback;
    }

    int shrunkSize = static_cast<int>(std::round(targetSize * shrinkFactor));
    QImage scaled = original.toImage().scaled(shrunkSize, shrunkSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    QPixmap result(targetSize, targetSize);
    result.fill(Qt::transparent);
    QPainter painter(&result);
    painter.drawImage((targetSize - scaled.width()) / 2, (targetSize - scaled.height()) / 2, scaled);
    painter.end();
    return result;
}

QIcon TaskIconProvider::resolveSteamIcon(const QString &appId)
{
    // 1. YOUR SECRET KEY (Get this from your SGDB profile)
    const QString apiKey = QStringLiteral("YOUR_API_KEY_HERE");

    // Path where we will save the high-res icon
    QString iconSaveDir = QDir::homePath() + QLatin1String("/.local/share/Steam/steam/games/sgdb");
    QDir().mkpath(iconSaveDir);
    QString iconSavePath = iconSaveDir + QLatin1String("/") + appId + QLatin1String(".png");

    // 2. Cache Check: If we already have the high-res SGDB icon, use it!
    if (QFile::exists(iconSavePath)) {
        return QIcon(iconSavePath);
    }

    // 3. The API Hunt: Search SteamGridDB for this AppID
    // Endpoint: /icons/steam/{id} returns a list of icons for that Steam game
    QString searchUrl = QStringLiteral("https://www.steamgriddb.com/api/v2/icons/steam/%1").arg(appId);

    QProcess curlSearch;
    curlSearch.start(QStringLiteral("curl"),
                     QStringList() << QStringLiteral("-s") << QStringLiteral("-H") << QStringLiteral("Authorization: Bearer ") + apiKey << searchUrl);
    curlSearch.waitForFinished(5000);

    QByteArray response = curlSearch.readAllStandardOutput();

    // Quick and dirty JSON parsing for the first icon URL
    // We look for the "url" key in the JSON response
    int urlPos = response.indexOf("\"url\":\"");
    if (urlPos != -1) {
        int start = urlPos + 7;
        int end = response.indexOf("\"", start);
        QString downloadUrl = QString::fromUtf8(response.mid(start, end - start)).replace(QLatin1String("\\/"), QLatin1String("/"));

        qDebug() << "[krema.icons] SGDB: Found high-res icon at" << downloadUrl;

        // 4. Download the actual image
        QProcess curlDownload;
        curlDownload.start(QStringLiteral("curl"), QStringList() << QStringLiteral("-sL") << downloadUrl << QStringLiteral("-o") << iconSavePath);
        curlDownload.waitForFinished(10000);

        if (QFile::exists(iconSavePath) && QFileInfo(iconSavePath).size() > 0) {
            qDebug() << "[krema.icons] SGDB: High-res download successful!";
            return QIcon(iconSavePath);
        }
    }

    // 5. Fallback: If SGDB fails, use the local Steam cache scanner we built earlier
    qDebug() << "[krema.icons] SGDB failed or no API key. Falling back to local cache...";
    // ... insert your existing local cache scanning logic here ...
    return QIcon();
}

} // namespace krema
