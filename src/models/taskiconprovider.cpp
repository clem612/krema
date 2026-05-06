// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "taskiconprovider.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
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

// --- Setters and Cache Management ---

void TaskIconProvider::setNormalizationEnabled(bool enabled)
{
    m_normalizationEnabled = enabled;
}

void TaskIconProvider::setIconScale(double scale)
{
    m_iconScale = std::clamp(scale, 0.5, 1.0);
}

void TaskIconProvider::clearCache()
{
    m_cache.clear();
}

// --- Core Request Logic ---

QPixmap TaskIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    using namespace Qt::StringLiterals;

    const int queryIdx = id.indexOf(QLatin1Char('?'));
    QString iconName = (queryIdx >= 0) ? id.left(queryIdx) : id;

    // Clean protocol and extension for consistent caching and lookup
    if (iconName.startsWith(u"file://"_s))
        iconName.remove(0, 7);
    if (iconName.endsWith(u".desktop"_s))
        iconName.chop(8);

    QString originalId = iconName;

    const int width = requestedSize.width() > 0 ? requestedSize.width() : 48;
    const int height = requestedSize.height() > 0 ? requestedSize.height() : 48;
    const int targetSize = std::max(width, height);

    QIcon icon;

    // 1. STAGE 1: Steam Scraper (Top Priority to ignore generic system icons)
    if (iconName.startsWith(u"steam_app_"_s)) {
        icon = resolveSteamIcon(iconName.mid(10));
    } else if (iconName.startsWith(u"steam_icon_"_s)) {
        icon = resolveSteamIcon(iconName.mid(11));
    }

    // 2. STAGE 2: Theme Check
    if (icon.isNull() && QIcon::hasThemeIcon(iconName)) {
        icon = QIcon::fromTheme(iconName);
    }

    // 3. STAGE 3: Desktop File Bridge
    if (icon.isNull()) {
        QString desktopFile = iconName + u".desktop"_s;
        QStringList paths = QStandardPaths::locateAll(QStandardPaths::ApplicationsLocation, desktopFile);
        if (!paths.isEmpty()) {
            QSettings settings(paths.first(), QSettings::IniFormat);
            settings.beginGroup(u"Desktop Entry"_s);
            QString realIcon = settings.value(u"Icon"_s).toString();
            if (!realIcon.isEmpty()) {
                if (realIcon.startsWith(u"steam_app_") || realIcon.startsWith(u"steam_icon_")) {
                    icon = resolveSteamIcon(realIcon.startsWith(u"steam_app_") ? realIcon.mid(10) : realIcon.mid(11));
                } else if (QIcon::hasThemeIcon(realIcon)) {
                    icon = QIcon::fromTheme(realIcon);
                } else {
                    icon = QIcon(realIcon);
                }
            }
        }
    }

    if (icon.isNull()) {
        qDebug() << "[krema.icons] Deferring failure for:" << originalId;
        return QPixmap();
    }

    // Normalization and Processing
    QPixmap result;
    if (!m_normalizationEnabled) {
        result = icon.pixmap(QSize(targetSize, targetSize), 1.0);
    } else {
        auto info = analyzeIcon(originalId, icon);
        const bool hasSignificantPadding = info.contentRatio < 0.95;
        const double effectiveRatio = hasSignificantPadding ? info.contentRatio * std::sqrt(info.fillRatio) : info.contentRatio;

        if (effectiveRatio >= kMinContentRatio) {
            const double shrinkFactor = (info.contentRatio > kEdgeToEdgeFill) ? kEdgeToEdgeFill / info.contentRatio : 1.0;
            result = shrinkPixmap(icon, targetSize, shrinkFactor);
        } else {
            result = normalizePixmap(icon, targetSize, info);
        }
    }

    if (result.isNull())
        return QPixmap();

    // Final Scaling
    if (m_iconScale < 1.0) {
        int shrunkSize = static_cast<int>(std::round(targetSize * m_iconScale));
        QImage scaled = result.toImage().scaled(shrunkSize, shrunkSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        result = QPixmap(targetSize, targetSize);
        result.fill(Qt::transparent);
        QPainter painter(&result);
        painter.drawImage((targetSize - scaled.width()) / 2, (targetSize - scaled.height()) / 2, scaled);
        painter.end();
    }

    if (size)
        *size = result.size();
    return result;
}

// --- High-Res Steam Resolver (API + Local Fallback) ---

QIcon TaskIconProvider::resolveSteamIcon(const QString &appId)
{
    using namespace Qt::StringLiterals;
    const QString apiKey = u"0e9627f89777d407a9b30a8e30c00ac9"_s; // <-- Paste your API key here
    QString sgdbDir = QDir::homePath() + u"/.local/share/Steam/steam/games/sgdb/"_s;
    QDir().mkpath(sgdbDir);
    QString sgdbPath = sgdbDir + appId + u".png"_s;

    // 1. Check if we already downloaded it from SGDB
    if (QFile::exists(sgdbPath)) {
        return QIcon(sgdbPath);
    }

    // 2. Fetch from SteamGridDB API (Official Styles Only + Timeouts)
    if (apiKey != u"YOUR_API_KEY_HERE"_s && !apiKey.isEmpty()) {
        QProcess curl;
        QString apiUrl = u"https://www.steamgriddb.com/api/v2/icons/steam/"_s + appId + u"?styles=official"_s;

        curl.start(u"curl"_s, {u"-s"_s, u"--connect-timeout"_s, u"2"_s, u"--max-time"_s, u"3"_s, u"-H"_s, u"Authorization: Bearer "_s + apiKey, apiUrl});

        if (curl.waitForFinished(3500)) {
            QByteArray resp = curl.readAllStandardOutput();
            QJsonDocument jsonDoc = QJsonDocument::fromJson(resp);

            if (!jsonDoc.isNull() && jsonDoc.isObject()) {
                QJsonObject jsonObj = jsonDoc.object();
                if (jsonObj.value(u"success"_s).toBool()) {
                    QJsonArray dataArr = jsonObj.value(u"data"_s).toArray();
                    if (!dataArr.isEmpty()) {
                        QString url = dataArr.first().toObject().value(u"url"_s).toString();
                        if (!url.isEmpty()) {
                            QProcess::execute(u"curl"_s, {u"-sL"_s, url, u"-o"_s, sgdbPath});
                            if (QFile::exists(sgdbPath)) {
                                return QIcon(sgdbPath);
                            }
                        }
                    }
                }
            }
        }
    }

    // 3. Fallback: Local High-Res Scraper (with Aspect Ratio logic to avoid pink specks)
    QString localCache = QDir::homePath() + u"/.local/share/Steam/appcache/librarycache/"_s + appId;
    if (QDir(localCache).exists()) {
        QDirIterator it(localCache, {u"*.png"_s, u"*.jpg"_s}, QDir::Files, QDirIterator::Subdirectories);

        struct Candidate {
            QString path;
            int res;
            double aspectScore;
        };
        QList<Candidate> candidates;

        while (it.hasNext()) {
            QString p = it.next();
            QImageReader reader(p);
            if (reader.canRead()) {
                QSize sz = reader.size();
                double aspect = static_cast<double>(sz.width()) / sz.height();

                // We want square-ish icons or vertical capsules (0.5 to 1.8)
                // We completely IGNORE ultra-wide text logos
                if (aspect > 0.5 && aspect < 1.8 && sz.width() >= 64) {
                    double aspectScore = std::abs(1.0 - aspect);
                    candidates.append({p, sz.width(), aspectScore});
                }
            }
        }

        if (!candidates.isEmpty()) {
            // Sort to prioritize square shapes, then higher resolution
            std::sort(candidates.begin(), candidates.end(), [](const Candidate &a, const Candidate &b) {
                if (std::abs(a.aspectScore - b.aspectScore) < 0.2) {
                    return a.res > b.res;
                }
                return a.aspectScore < b.aspectScore;
            });
            return QIcon(candidates.first().path);
        }
    }

    return QIcon();
}

// --- Normalization Helpers ---

QRect TaskIconProvider::findContentBounds(const QImage &image, int threshold)
{
    const int w = image.width(), h = image.height();
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
    return (bottom < 0) ? QRect() : QRect(left, top, right - left + 1, bottom - top + 1);
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
    if (probeImage.isNull() || probeImage.format() != QImage::Format_ARGB32_Premultiplied)
        probeImage = probeImage.convertToFormat(QImage::Format_ARGB32_Premultiplied);

    QRect bounds = findContentBounds(probeImage, kAlphaThreshold);
    IconNormalizationInfo info;
    info.probeSize = probeSize;

    if (bounds.isEmpty()) {
        info.contentRatio = 1.0;
        info.fillRatio = 1.0;
        info.contentBounds = QRect(0, 0, probeSize, probeSize);
    } else {
        int contentDim = std::max(bounds.width(), bounds.height());
        info.contentRatio = static_cast<double>(contentDim) / probeSize;
        info.contentBounds = bounds;
        int pixels = 0;
        for (int y = bounds.top(); y <= bounds.bottom(); ++y) {
            const auto *scanline = reinterpret_cast<const QRgb *>(probeImage.constScanLine(y));
            for (int x = bounds.left(); x <= bounds.right(); ++x) {
                if (qAlpha(scanline[x]) > kAlphaThreshold)
                    ++pixels;
            }
        }
        double bboxArea = static_cast<double>(bounds.width()) * bounds.height();
        info.fillRatio = (bboxArea > 0) ? pixels / bboxArea : 1.0;
    }
    m_cache.insert(iconName, info);
    return info;
}

QPixmap TaskIconProvider::normalizePixmap(const QIcon &icon, int targetSize, const IconNormalizationInfo &info)
{
    const double margin = (info.fillRatio < 0.95) ? 0.01 : kMinMarginRatio;
    const double maxFill = 1.0 - margin * 2;
    const double effectiveRatio = info.contentRatio * std::sqrt(info.fillRatio);
    double targetFill = std::min(effectiveRatio * kMaxEffectiveScale, maxFill);
    int targetContentPx = static_cast<int>(std::round(targetSize * targetFill));
    int loadSize = static_cast<int>(std::ceil(static_cast<double>(targetContentPx) / info.contentRatio));

    QImage img = icon.pixmap(QSize(loadSize, loadSize), 1.0).toImage();
    if (img.isNull()) {
        QPixmap f(targetSize, targetSize);
        f.fill(Qt::transparent);
        return f;
    }
    if (img.format() != QImage::Format_ARGB32_Premultiplied)
        img = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);

    QRect bounds = findContentBounds(img, kAlphaThreshold);
    if (bounds.isEmpty())
        return icon.pixmap(QSize(targetSize, targetSize), 1.0);

    int contentDim = std::max(bounds.width(), bounds.height());
    QRect sq(bounds.center().x() - contentDim / 2, bounds.center().y() - contentDim / 2, contentDim, contentDim);
    QImage scaled = img.copy(sq.intersected(img.rect())).scaled(targetContentPx, targetContentPx, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    QPixmap res(targetSize, targetSize);
    res.fill(Qt::transparent);
    QPainter p(&res);
    p.drawImage((targetSize - scaled.width()) / 2, (targetSize - scaled.height()) / 2, scaled);
    p.end();
    return res;
}

QPixmap TaskIconProvider::shrinkPixmap(const QIcon &icon, int targetSize, double shrinkFactor)
{
    QPixmap orig = icon.pixmap(QSize(targetSize, targetSize), 1.0);
    if (orig.isNull()) {
        QPixmap f(targetSize, targetSize);
        f.fill(Qt::transparent);
        return f;
    }
    int s = static_cast<int>(std::round(targetSize * shrinkFactor));
    QImage scaled = orig.toImage().scaled(s, s, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    QPixmap res(targetSize, targetSize);
    res.fill(Qt::transparent);
    QPainter p(&res);
    p.drawImage((targetSize - s) / 2, (targetSize - s) / 2, scaled);
    p.end();
    return res;
}

} // namespace krema
