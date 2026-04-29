// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "dockmodel.h"

#include <taskmanager/abstracttasksmodel.h>
#include <taskmanager/tasksmodel.h>

#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QLoggingCategory>
#include <QScreen>

#include <algorithm>

#include "taskiconprovider.h"

Q_LOGGING_CATEGORY(lcModel, "krema.model")

namespace krema
{
namespace
{

QString stripDesktopSuffix(const QString &id)
{
    static const QLatin1String suffix(".desktop");
    if (id.endsWith(suffix)) {
        return id.left(id.size() - suffix.size());
    }
    return id;
}

QString lastSegment(const QString &id)
{
    const int dot = id.lastIndexOf(QLatin1Char('.'));
    return (dot >= 0) ? id.mid(dot + 1) : id;
}

QString desktopNameFromUrl(const QUrl &url)
{
    if (!url.isValid()) {
        return {};
    }

    if (url.scheme() == QLatin1String("applications")) {
        return stripDesktopSuffix(url.path());
    }

    if (url.isLocalFile()) {
        const QString local = url.toLocalFile();
        if (local.endsWith(QLatin1String(".desktop"))) {
            return stripDesktopSuffix(QFileInfo(local).baseName());
        }
    }

    return {};
}

QStringList iconCandidates(const QModelIndex &idx)
{
    QStringList candidates;

    const QString appId = idx.data(TaskManager::AbstractTasksModel::AppId).toString();
    const QString stripped = stripDesktopSuffix(appId);
    const QString segment = lastSegment(stripped);
    const QString display = idx.data(Qt::DisplayRole).toString().trimmed();
    const QString launcherName = desktopNameFromUrl(idx.data(TaskManager::AbstractTasksModel::LauncherUrlWithoutIcon).toUrl());

    auto addCandidate = [&candidates](const QString &value) {
        if (value.isEmpty()) {
            return;
        }
        if (!candidates.contains(value)) {
            candidates.push_back(value);
        }
        const QString lowered = value.toLower();
        if (!lowered.isEmpty() && !candidates.contains(lowered)) {
            candidates.push_back(lowered);
        }
    };

    addCandidate(appId);
    addCandidate(stripped);
    addCandidate(segment);
    addCandidate(launcherName);
    addCandidate(display);

    if (stripped.startsWith(QLatin1String("steam_app_"))) {
        QString steamThemeName = stripped;
        steamThemeName.replace(QLatin1String("steam_app_"), QLatin1String("steam_icon_"));
        addCandidate(steamThemeName);
        addCandidate(QStringLiteral("steam"));
    }

    return candidates;
}

} // namespace

DockModel::DockModel(QObject *parent)
    : QObject(parent)
    , m_tasksModel(std::make_unique<TaskManager::TasksModel>(this))
    , m_virtualDesktopInfo(std::make_shared<TaskManager::VirtualDesktopInfo>(this))
    , m_activityInfo(std::make_shared<TaskManager::ActivityInfo>(this))
{
    // TasksModel implements QQmlParserStatus. When created from C++ (not QML),
    // classBegin/componentComplete are not called by the QML engine.
    // We must call them manually to trigger internal model initialization.
    //
    // CRITICAL: Mirror QML's initialization order:
    //   1. classBegin()
    //   2. All properties set (including virtualDesktop, activity, screenGeometry)
    //   3. componentComplete() — activates internal source models
    //
    // Setting virtualDesktop/activity/screenGeometry AFTER componentComplete()
    // causes the Wayland window backend to miss running windows.
    m_tasksModel->classBegin();

    // Configure for dock-style behavior:
    // - Group windows by application (pinned + running merged)
    // - Manual sort for drag reordering
    // - Hide activated launchers (avoid duplicates: pinned + running)
    m_tasksModel->setGroupMode(TaskManager::TasksModel::GroupApplications);
    m_tasksModel->setSortMode(TaskManager::TasksModel::SortManual);
    m_tasksModel->setHideActivatedLaunchers(true);
    m_tasksModel->setSeparateLaunchers(true);
    m_tasksModel->setLaunchInPlace(true);
    m_tasksModel->setGroupInline(false);
    m_tasksModel->setTaskReorderingEnabled(true);

    // VirtualDesktopInfo and ActivityInfo are required for the Wayland
    // window backend to properly detect running windows on KDE Plasma.
    // These MUST be set BEFORE componentComplete() — mirrors QML property binding order.
    m_tasksModel->setVirtualDesktop(m_virtualDesktopInfo->currentDesktop());
    m_tasksModel->setActivity(m_activityInfo->currentActivity());

    // Screen geometry — Plasma Task Manager always sets this.
    if (auto *screen = QGuiApplication::primaryScreen()) {
        m_tasksModel->setScreenGeometry(screen->geometry());
    }

    // Show all windows regardless of desktop/screen/activity.
    // Filtering can be enabled later (M8: multi-monitor + virtual desktop).
    m_tasksModel->setFilterByVirtualDesktop(false);
    m_tasksModel->setFilterByScreen(false);
    m_tasksModel->setFilterByActivity(false);
    m_tasksModel->setFilterHidden(false);

    // NOW activate internal source models (launcher model, window model, etc.)
    // All properties are set, so the backends will correctly discover running windows.
    m_tasksModel->componentComplete();

    // Track desktop/activity changes so the model stays up to date.
    connect(m_virtualDesktopInfo.get(), &TaskManager::VirtualDesktopInfo::currentDesktopChanged, this, [this]() {
        m_tasksModel->setVirtualDesktop(m_virtualDesktopInfo->currentDesktop());
        Q_EMIT currentDesktopChanged();
    });
    connect(m_activityInfo.get(), &TaskManager::ActivityInfo::currentActivityChanged, this, [this]() {
        m_tasksModel->setActivity(m_activityInfo->currentActivity());
    });

    // Debug logging for model row changes
    connect(m_tasksModel.get(), &QAbstractItemModel::rowsInserted, this, [this]() {
        qCDebug(lcModel) << "Model rows after insert:" << m_tasksModel->rowCount();
    });
    connect(m_tasksModel.get(), &QAbstractItemModel::rowsRemoved, this, [this]() {
        qCDebug(lcModel) << "Model rows after remove:" << m_tasksModel->rowCount();
    });
}

DockModel::~DockModel() = default;

TaskManager::TasksModel *DockModel::tasksModel() const
{
    return m_tasksModel.get();
}

TaskManager::VirtualDesktopInfo *DockModel::virtualDesktopInfo() const
{
    return m_virtualDesktopInfo.get();
}

TaskManager::ActivityInfo *DockModel::activityInfo() const
{
    return m_activityInfo.get();
}

QStringList DockModel::pinnedLaunchers() const
{
    return m_tasksModel->launcherList();
}

void DockModel::setPinnedLaunchers(const QStringList &launchers)
{
    m_tasksModel->setLauncherList(launchers);
    Q_EMIT pinnedLaunchersChanged();
}

QVariant DockModel::iconData(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid())
        return {};

    // 1. UNIVERSAL THEME PRIORITY (The "Drag" Logic)
    // Always check if the system theme has a high-res SVG for this app first.
    QString name = iconName(index);
    if (QIcon::hasThemeIcon(name)) {
        return QIcon::fromTheme(name);
    }

    // 2. STEAM-SPECIFIC FALLBACK
    QString id = idx.data(TaskManager::AbstractTasksModel::AppId).toString();
    if (id.startsWith(QLatin1String("steam_app_"))) {
        QString steamIconId = QStringLiteral("steam_icon_") + id.mid(10);
        if (QIcon::hasThemeIcon(steamIconId))
            return QIcon::fromTheme(steamIconId);

        return QIcon::fromTheme(QStringLiteral("steam")); // Clean fallback
    }

    // 3. RAW PIXEL FALLBACK (The "Blurry" Window Pixels)
    // Only use these if the system theme completely failed to find the app.
    const QVariant decoration = idx.data(Qt::DecorationRole);
    if (decoration.isValid() && !decoration.value<QIcon>().isNull()) {
        return decoration;
    }

    // 4. ABSOLUTE FALLBACK
    return QIcon::fromTheme(QStringLiteral("application-x-executable"));
}

QString DockModel::iconName(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return {};
    }

    const QStringList candidates = iconCandidates(idx);
    for (const QString &candidate : candidates) {
        if (QIcon::hasThemeIcon(candidate)) {
            return candidate;
        }
    }

    // Keep drag ghost/icon provider alive with a best-effort identifier.
    return candidates.value(0, QStringLiteral("application-x-executable"));
}

QUrl DockModel::launcherUrl(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return {};
    }
    return idx.data(TaskManager::AbstractTasksModel::LauncherUrlWithoutIcon).toUrl();
}

bool DockModel::isDesktopFile(const QUrl &url) const
{
    if (url.scheme() == QLatin1String("applications")) {
        return true;
    }
    if (url.isLocalFile() && url.toLocalFile().endsWith(QLatin1String(".desktop"))) {
        return true;
    }
    return false;
}

bool DockModel::isPinned(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return false;
    }

    const QUrl url = idx.data(TaskManager::AbstractTasksModel::LauncherUrlWithoutIcon).toUrl();
    return url.isValid() && m_tasksModel->launcherList().contains(url.toString());
}

QVariantList DockModel::windowIds(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return {};
    }
    return idx.data(TaskManager::AbstractTasksModel::WinIdList).toList();
}

int DockModel::childCount(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return 0;
    }
    return m_tasksModel->rowCount(idx);
}

QModelIndex DockModel::taskModelIndex(int index) const
{
    return m_tasksModel->index(index, 0);
}

QString DockModel::appId(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return {};
    }
    return idx.data(TaskManager::AbstractTasksModel::AppId).toString();
}

int DockModel::virtualDesktopMode() const
{
    return m_virtualDesktopMode;
}

void DockModel::setVirtualDesktopMode(int mode)
{
    if (m_virtualDesktopMode == mode) {
        return;
    }
    m_virtualDesktopMode = mode;
    // Mode 2 (CurrentOnly): use TasksModel built-in filter
    m_tasksModel->setFilterByVirtualDesktop(mode == 2);
    Q_EMIT virtualDesktopModeChanged();
}

QVariant DockModel::currentDesktop() const
{
    return m_virtualDesktopInfo->currentDesktop();
}

bool DockModel::isOnCurrentDesktop(int index) const
{
    const QModelIndex idx = m_tasksModel->index(index, 0);
    if (!idx.isValid()) {
        return true;
    }

    // Launchers (no window) are always considered "on current desktop"
    if (!idx.data(TaskManager::AbstractTasksModel::IsWindow).toBool()) {
        return true;
    }

    // Windows on all desktops are always visible
    if (idx.data(TaskManager::AbstractTasksModel::IsOnAllVirtualDesktops).toBool()) {
        return true;
    }

    // Check if any of the task's desktops match the current desktop
    const QVariant currentDesktop = m_virtualDesktopInfo->currentDesktop();
    const QVariantList desktops = idx.data(TaskManager::AbstractTasksModel::VirtualDesktops).toList();
    return desktops.contains(currentDesktop);
}

} // namespace krema
