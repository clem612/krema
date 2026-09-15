// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "backgroundstyle.h"

#include <KColorScheme>
#include <KWindowEffects>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace krema
{

void applyBackgroundToWindow(QWindow *window, BackgroundStyleType type, const QRegion &region)
{
    if (!window) {
        return;
    }

    if (qEnvironmentVariableIsSet("HYPRLAND_INSTANCE_SIGNATURE")) {
        return;
    }

    // Always remove previous effects first
    removeBackgroundFromWindow(window);

    // PanelInherit: compositor handles blur + contrast. QML provides Header color with opacity.
    // All other styles: no compositor effects — QML handles the background directly.
    switch (type) {
    case BackgroundStyleType::PanelInherit:
        if (KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind)) {
            KWindowEffects::enableBlurBehind(window, true, region);
            KWindowEffects::enableBackgroundContrast(window, true, 1.0, 1.0, 1.0, region);
        }
        break;

    case BackgroundStyleType::Acrylic:
    case BackgroundStyleType::Mica:
        if (KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind)) {
            KWindowEffects::enableBlurBehind(window, true, region);
        }
        break;

    case BackgroundStyleType::Tinted:
    case BackgroundStyleType::Transparent:
        // No compositor effects — QML handles the background directly.
        break;
    }
}

void removeBackgroundFromWindow(QWindow *window)
{
    if (!window) {
        return;
    }

    if (qEnvironmentVariableIsSet("HYPRLAND_INSTANCE_SIGNATURE")) {
        return;
    }
    KWindowEffects::enableBlurBehind(window, false);
    KWindowEffects::enableBackgroundContrast(window, false);
}

QColor getWallpaperColor(bool useAccentColor)
{
    // Check Ryoku shell first (matugen)
    QString ryokuPath = QDir::homePath() + QStringLiteral("/.cache/ryoku/colors.json");
    if (QFile::exists(ryokuPath)) {
        QFile file(ryokuPath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            QJsonObject obj = doc.object();
            if (useAccentColor && obj.contains(QStringLiteral("primary"))) {
                return QColor(obj[QStringLiteral("primary")].toString());
            } else if (obj.contains(QStringLiteral("surfaceContainer"))) {
                return QColor(obj[QStringLiteral("surfaceContainer")].toString());
            } else if (obj.contains(QStringLiteral("background"))) {
                return QColor(obj[QStringLiteral("background")].toString());
            }
        }
    }

    // Check pywal
    QString walPath = QDir::homePath() + QStringLiteral("/.cache/wal/colors.json");
    if (QFile::exists(walPath)) {
        QFile file(walPath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            QJsonObject obj = doc.object();
            if (useAccentColor && obj.contains(QStringLiteral("colors")) && obj[QStringLiteral("colors")].isObject()) {
                QJsonObject colors = obj[QStringLiteral("colors")].toObject();
                if (colors.contains(QStringLiteral("color2"))) {
                    return QColor(colors[QStringLiteral("color2")].toString());
                }
            }
            if (obj.contains(QStringLiteral("special")) && obj[QStringLiteral("special")].isObject()) {
                QJsonObject special = obj[QStringLiteral("special")].toObject();
                if (special.contains(QStringLiteral("background"))) {
                    return QColor(special[QStringLiteral("background")].toString());
                }
            }
        }
    }
    return QColor();
}

QColor
computeBackgroundColor(BackgroundStyleType type, const QString &tintColorHex, qreal opacity, bool useAccentColor, bool useSystemColor, bool useWallpaperColor)
{
    if (type == BackgroundStyleType::Transparent) {
        return Qt::transparent;
    }

    QColor color;
    if (useWallpaperColor) {
        color = getWallpaperColor(useAccentColor);
    }

    if (color.isValid()) {
        color.setAlphaF(static_cast<float>(opacity));
        return color;
    }

    switch (type) {
    case BackgroundStyleType::PanelInherit:
    case BackgroundStyleType::Acrylic:
    case BackgroundStyleType::Mica: {
        if (useAccentColor) {
            KColorScheme scheme(QPalette::Normal, KColorScheme::Selection);
            color = scheme.background(KColorScheme::NormalBackground).color();
        }
        if (!useAccentColor || !color.isValid()) {
            KColorScheme scheme(QPalette::Normal, KColorScheme::Header);
            color = scheme.background(KColorScheme::NormalBackground).color();
        }
        break;
    }

    case BackgroundStyleType::Tinted: {
        if (useSystemColor) {
            // System color mode: same as PanelInherit/Acrylic (Header or Selection)
            if (useAccentColor) {
                KColorScheme scheme(QPalette::Normal, KColorScheme::Selection);
                color = scheme.background(KColorScheme::NormalBackground).color();
            }
            if (!useAccentColor || !color.isValid()) {
                KColorScheme scheme(QPalette::Normal, KColorScheme::Header);
                color = scheme.background(KColorScheme::NormalBackground).color();
            }
        } else {
            color = QColor::fromString(tintColorHex);
            if (!color.isValid()) {
                KColorScheme scheme(QPalette::Normal, KColorScheme::Header);
                color = scheme.background(KColorScheme::NormalBackground).color();
            }
        }
        break;
    }

    default:
        break;
    }

    color.setAlphaF(static_cast<float>(opacity));
    return color;
}

bool styleUsesBlur(BackgroundStyleType type)
{
    return type == BackgroundStyleType::PanelInherit || type == BackgroundStyleType::Acrylic || type == BackgroundStyleType::Mica;
}

bool isStyleAvailable(BackgroundStyleType /* type */)
{
    return true;
}

} // namespace krema
