// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "identitymanager.h"

#include <KService>
#include <QFileInfo>

namespace krema
{

QString IdentityManager::normalizeAppId(const QString &appId)
{
    if (appId.isEmpty()) {
        return {};
    }

    // 1. Lower-case and strip .desktop
    QString id = stripDesktopSuffix(appId).toLower();

    // 2. Apply hardcoded KDE bridge (fast path for common mismatches)
    QString bridged = applyKdeBridge(id);
    if (bridged != id) {
        return bridged;
    }

    // 3. Robust KService lookup (e.g. "konsole" -> "org.kde.konsole")
    // If the short ID doesn't exist as a service, try prefixing it.
    KService::Ptr service = KService::serviceByStorageId(id);
    if (!service) {
        service = KService::serviceByStorageId(QStringLiteral("org.kde.") + id);
    }

    if (service) {
        return stripDesktopSuffix(service->storageId());
    }

    return id;
}

QString IdentityManager::appIdFromUrl(const QUrl &url)
{
    if (!url.isValid()) {
        return {};
    }

    QString id;
    if (url.scheme() == QLatin1String("applications")) {
        id = url.path();
    } else if (url.isLocalFile()) {
        id = QFileInfo(url.toLocalFile()).completeBaseName();
    }

    return normalizeAppId(id);
}

QStringList IdentityManager::iconCandidates(const QString &appId, const QUrl &launcherUrl, const QString &displayRole)
{
    QStringList candidates;

    auto addCandidate = [&candidates](const QString &value) {
        if (value.isEmpty())
            return;
        if (!candidates.contains(value)) {
            candidates.push_back(value);
        }
        QString lowered = value.toLower();
        if (lowered != value && !candidates.contains(lowered)) {
            candidates.push_back(lowered);
        }
    };

    // 1. Normalized AppID (The Authority)
    QString normalized = normalizeAppId(appId);
    addCandidate(normalized);

    // 2. Raw ID variants
    QString stripped = stripDesktopSuffix(appId);
    addCandidate(stripped);

    // 3. Launcher URL derived name
    if (launcherUrl.isValid()) {
        addCandidate(appIdFromUrl(launcherUrl));
    }

    // 4. Last segment of reverse-DNS names (e.g. "org.kde.dolphin" -> "dolphin")
    int lastDot = normalized.lastIndexOf(QLatin1Char('.'));
    if (lastDot >= 0) {
        addCandidate(normalized.mid(lastDot + 1));
    }

    // 5. Display name (last resort)
    if (!displayRole.isEmpty()) {
        addCandidate(displayRole.trimmed());
    }

    // 6. Hardcoded KDE Bridge redundance (ensure we always have both variants)
    if (normalized == QLatin1String("org.kde.dolphin") || normalized == QLatin1String("dolphin")) {
        addCandidate(QStringLiteral("org.kde.dolphin"));
        addCandidate(QStringLiteral("dolphin"));
    } else if (normalized == QLatin1String("org.kde.systemsettings") || normalized == QLatin1String("systemsettings")) {
        addCandidate(QStringLiteral("org.kde.systemsettings"));
        addCandidate(QStringLiteral("systemsettings"));
    } else if (normalized == QLatin1String("org.kde.konsole") || normalized == QLatin1String("konsole")) {
        addCandidate(QStringLiteral("org.kde.konsole"));
        addCandidate(QStringLiteral("konsole"));
    }

    // 7. Steam-specific mapping
    if (normalized.startsWith(QLatin1String("steam_app_"))) {
        QString steamThemeName = normalized;
        steamThemeName.replace(QLatin1String("steam_app_"), QLatin1String("steam_icon_"));
        addCandidate(steamThemeName);
        addCandidate(QStringLiteral("steam"));
    }

    return candidates;
}

QString IdentityManager::applyKdeBridge(const QString &id)
{
    if (id == QLatin1String("dolphin"))
        return QStringLiteral("org.kde.dolphin");
    if (id == QLatin1String("systemsettings"))
        return QStringLiteral("org.kde.systemsettings");
    if (id == QLatin1String("konsole"))
        return QStringLiteral("org.kde.konsole");
    if (id == QLatin1String("kcalc"))
        return QStringLiteral("org.kde.kcalc");
    if (id == QLatin1String("gwenview"))
        return QStringLiteral("org.kde.gwenview");
    if (id == QLatin1String("okular"))
        return QStringLiteral("org.kde.okular");
    return id;
}

QString IdentityManager::stripDesktopSuffix(const QString &id)
{
    static const QLatin1String suffix(".desktop");
    if (id.endsWith(suffix)) {
        return id.left(id.size() - suffix.size());
    }
    return id;
}

} // namespace krema
