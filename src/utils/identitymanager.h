// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <QString>
#include <QStringList>
#include <QUrl>

namespace krema
{

/**
 * Centralized utility for application identity resolution.
 *
 * Standardizes disparate application identifiers (AppIDs, desktop files, URLs)
 * to ensure consistent behavior across the dock, notifications, and icon providers.
 *
 * Resolves the "Identity Crisis" where Wayland app_ids (e.g. "dolphin")
 * mismatch with their .desktop file names (e.g. "org.kde.dolphin.desktop").
 */
class IdentityManager
{
public:
    /**
     * Normalizes an AppID or desktop file name.
     * Examples:
     *   "org.kde.dolphin.desktop" -> "org.kde.dolphin"
     *   "dolphin" -> "org.kde.dolphin" (via KDE Bridge)
     */
    static QString normalizeAppId(const QString &appId);

    /**
     * Extracts and normalizes the AppID from a launcher URL.
     */
    static QString appIdFromUrl(const QUrl &url);

    /**
     * Returns a prioritized list of potential icon names for an identifier.
     */
    static QStringList iconCandidates(const QString &appId, const QUrl &launcherUrl = QUrl(), const QString &displayRole = QString());

private:
    static QString applyKdeBridge(const QString &id);
    static QString stripDesktopSuffix(const QString &id);
};

} // namespace krema
