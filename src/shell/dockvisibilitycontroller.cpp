// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "dockvisibilitycontroller.h"
#include "krema.h"
#include "utils/inputregion.h"
#include <QLoggingCategory>
#include <QQuickView>
#include <QScreen>
#include <QWindow>
#include <taskmanager/abstracttasksmodel.h>
#include <taskmanager/activityinfo.h>
#include <taskmanager/regionfiltermode.h>
#include <taskmanager/tasksmodel.h>
#include <taskmanager/virtualdesktopinfo.h>

Q_LOGGING_CATEGORY(lcVisibility, "krema.shell.visibility")

namespace krema
{

DockVisibilityController::DockVisibilityController(DockPlatform *platform,
                                                   TaskManager::TasksModel *tasksModel,
                                                   TaskManager::VirtualDesktopInfo *virtualDesktopInfo,
                                                   TaskManager::ActivityInfo *activityInfo,
                                                   QWindow *dockWindow,
                                                   QObject *parent)
    : QObject(parent)
    , m_platform(platform)
    , m_tasksModel(tasksModel)
    , m_virtualDesktopInfo(virtualDesktopInfo)
    , m_activityInfo(activityInfo)
    , m_dockWindow(dockWindow)
{
    m_overlapModel = new TaskManager::TasksModel(this);
    m_overlapModel->classBegin();
    m_overlapModel->setGroupMode(TaskManager::TasksModel::GroupDisabled);
    m_overlapModel->setFilterByRegion(RegionFilterMode::Intersect);
    m_overlapModel->setFilterMinimized(true);
    m_overlapModel->setFilterHidden(true);
    m_overlapModel->setFilterByVirtualDesktop(true);
    m_overlapModel->setFilterByActivity(true);
    if (m_virtualDesktopInfo) {
        m_overlapModel->setVirtualDesktop(m_virtualDesktopInfo->currentDesktop());
        connect(m_virtualDesktopInfo, &TaskManager::VirtualDesktopInfo::currentDesktopChanged, this, [this]() {
            m_overlapModel->setVirtualDesktop(m_virtualDesktopInfo->currentDesktop());
            m_evaluateTimer.start();
        });
    }
    if (m_activityInfo) {
        m_overlapModel->setActivity(m_activityInfo->currentActivity());
        connect(m_activityInfo, &TaskManager::ActivityInfo::currentActivityChanged, this, [this]() {
            m_overlapModel->setActivity(m_activityInfo->currentActivity());
            m_evaluateTimer.start();
        });
    }
    m_overlapModel->componentComplete();

    m_showTimer.setSingleShot(true);
    m_showTimer.setInterval(200);
    connect(&m_showTimer, &QTimer::timeout, this, [this]() {
        setVisible(true);
    });

    m_hideTimer.setSingleShot(true);
    m_hideTimer.setInterval(400);
    connect(&m_hideTimer, &QTimer::timeout, this, [this]() {
        evaluateVisibility();
    });

    m_evaluateTimer.setSingleShot(true);
    m_evaluateTimer.setInterval(300);
    connect(&m_evaluateTimer, &QTimer::timeout, this, &DockVisibilityController::evaluateVisibility);

    connectModelSignals();
}

DockVisibilityController::~DockVisibilityController() = default;

bool DockVisibilityController::isDockVisible() const
{
    return m_visible;
}
int DockVisibilityController::mode() const
{
    return static_cast<int>(m_mode);
}

void DockVisibilityController::setMode(int mode)
{
    setMode(static_cast<DockPlatform::VisibilityMode>(mode));
}

void DockVisibilityController::setMode(DockPlatform::VisibilityMode mode)
{
    if (m_mode == mode)
        return;
    m_mode = mode;
    m_platform->setVisibilityMode(mode);
    m_showTimer.stop();
    m_hideTimer.stop();
    m_evaluateTimer.stop();
    evaluateVisibility();
    Q_EMIT modeChanged();
}

void DockVisibilityController::toggleVisibility()
{
    if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible)
        return;
    m_showTimer.stop();
    m_hideTimer.stop();
    setVisible(!m_visible);
}

void DockVisibilityController::setHovered(bool hovered)
{
    if (m_hovered == hovered)
        return;
    m_hovered = hovered;
    if (m_interactingCount == 0 || hovered)
        applyInputRegion();
    if (hovered) {
        m_hideTimer.stop();
        if (!m_visible)
            m_showTimer.start();
    } else {
        m_showTimer.stop();
        if (m_interactingCount > 0)
            return;
        if (m_mode != DockPlatform::VisibilityMode::AlwaysVisible)
            m_hideTimer.start();
    }
}

void DockVisibilityController::applyInputRegion()
{
    if (!m_dockWindow)
        return;

    InputRegionParams params;
    auto *view = qobject_cast<QQuickView *>(parent());
    params.surfaceWidth = view ? view->width() : m_dockWindow->width();
    params.surfaceHeight = view ? view->height() : m_dockWindow->height();
    params.panelX = m_panelX;
    params.panelY = m_panelY;
    params.panelWidth = m_panelWidth;
    params.panelHeight = m_panelHeight;
    params.zoomOverflowHeight = m_zoomOverflowHeight;
    params.visible = m_visible;
    params.hovered = m_visible ? true : m_hovered;
    params.edge = static_cast<int>(m_platform->edge());

    // 1. Create the base stencil for icons
    QRegion finalHitbox = computeDockInputRegion(params);

    // 2. Add the dynamic settings window hitbox
    if (m_liveEditMode && m_settingsWidth > 0) {
        finalHitbox += QRect(m_settingsX, m_settingsY, m_settingsWidth, m_settingsHeight);
    }

    m_platform->setInputRegion(finalHitbox);
}

void DockVisibilityController::setSettingsRect(qreal x, qreal y, qreal width, qreal height)
{
    m_settingsX = static_cast<int>(x);
    m_settingsY = static_cast<int>(y);
    m_settingsWidth = static_cast<int>(width);
    m_settingsHeight = static_cast<int>(height);
    applyInputRegion();
}

void DockVisibilityController::setLiveEditMode(bool edit)
{
    if (m_liveEditMode == edit)
        return;
    m_liveEditMode = edit;
    updateRegionGeometry();
    Q_EMIT liveEditModeChanged();
}

void DockVisibilityController::evaluateVisibility()
{
    if (m_interactingCount > 0 || m_keyboardActive || m_hovered) {
        setVisible(true);
    }
    if (m_platform) {
        if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible && m_reserveSpace) {
            int edgeIndex = static_cast<int>(m_platform->edge());
            int thickness = 0;

            if (m_reserveMode == 0) { // Panel Mode
                thickness = (edgeIndex == 2 || edgeIndex == 3) ? m_panelWidth : m_panelHeight;
            } else { // Icon Mode
                thickness = (edgeIndex == 2 || edgeIndex == 3) ? m_contentWidth : m_contentHeight;
            }

            if (thickness > 0) {
                m_platform->setExclusiveZone(thickness + m_floatingPadding);
            } else {
                m_platform->setExclusiveZone(0);
            }
        } else {
            m_platform->setExclusiveZone(0);
        }
    }
    if (m_interactingCount > 0 || m_keyboardActive || m_hovered)
        return;
    switch (m_mode) {
    case DockPlatform::VisibilityMode::AlwaysVisible:
        setVisible(true);
        break;
    case DockPlatform::VisibilityMode::AutoHide:
        setVisible(false);
        break;
    case DockPlatform::VisibilityMode::DodgeWindows:
        setVisible(!hasOverlappingWindow(m_dodgeActiveOnly));
        break;
    }
}

void DockVisibilityController::setPanelRect(qreal x, qreal y, qreal width, qreal height)
{
    m_panelX = static_cast<int>(x);
    m_panelY = static_cast<int>(y);
    m_panelWidth = static_cast<int>(width);
    m_panelHeight = static_cast<int>(height);
    if (m_visible) {
        m_panelRefX = m_panelX;
        m_panelRefY = m_panelY;
    }
    applyInputRegion();
    Q_EMIT panelRectChanged();
    updateRegionGeometry();
    m_evaluateTimer.start();
}

void DockVisibilityController::setVisible(bool visible)
{
    if (m_visible == visible)
        return;
    m_visible = visible;
    Q_EMIT dockVisibleChanged();
    updateRegionGeometry();
}

QRect DockVisibilityController::panelRect() const
{
    return {m_panelX, m_panelY, m_panelWidth, m_panelHeight};
}

void DockVisibilityController::setShowDelay(int ms)
{
    m_showTimer.setInterval(ms);
}
void DockVisibilityController::setHideDelay(int ms)
{
    m_hideTimer.setInterval(ms);
}

void DockVisibilityController::setZoomOverflowHeight(int height)
{
    if (m_zoomOverflowHeight == height)
        return;
    m_zoomOverflowHeight = height;
    applyInputRegion();
}

bool DockVisibilityController::liveEditMode() const
{
    return m_liveEditMode;
}
bool DockVisibilityController::isInteracting() const
{
    return m_interactingCount > 0;
}

void DockVisibilityController::setInteracting(bool interacting)
{
    if (interacting) {
        ++m_interactingCount;
        m_hideTimer.stop();
        m_evaluateTimer.stop();
        setVisible(true);
    } else {
        m_interactingCount = qMax(0, m_interactingCount - 1);
        if (m_interactingCount == 0 && !m_hovered && m_mode != DockPlatform::VisibilityMode::AlwaysVisible)
            m_hideTimer.start();
    }
    Q_EMIT interactingChanged();
}

void DockVisibilityController::requestEvaluate()
{
    updateRegionGeometry();
    m_evaluateTimer.start();
}

void DockVisibilityController::updateRegionGeometry()
{
    if (m_dockWindow && m_dockWindow->screen()) {
        DockScreenRectParams p;
        p.screenX = m_dockWindow->screen()->geometry().x();
        p.screenY = m_dockWindow->screen()->geometry().y();
        p.screenWidth = m_dockWindow->screen()->geometry().width();
        p.screenHeight = m_dockWindow->screen()->geometry().height();

        auto *view = qobject_cast<QQuickView *>(parent());
        p.surfaceWidth = view ? view->width() : m_dockWindow->width();
        p.surfaceHeight = view ? view->height() : m_dockWindow->height();

        p.panelX = m_panelX;
        p.panelRefY = m_panelRefY;
        p.panelWidth = m_panelWidth;
        p.panelHeight = m_panelHeight;
        p.edge = static_cast<int>(m_platform->edge());

        m_overlapModel->setScreenGeometry(computeDockScreenRect(p));
    }

    applyInputRegion();
}

bool DockVisibilityController::hasOverlappingWindow(bool activeOnly) const
{
    const int count = m_overlapModel->rowCount();
    if (!activeOnly)
        return count > 0;
    for (int i = 0; i < count; ++i) {
        if (m_overlapModel->index(i, 0).data(TaskManager::AbstractTasksModel::IsActive).toBool())
            return true;
    }
    return false;
}

void DockVisibilityController::setDodgeActiveOnly(bool activeOnly)
{
    if (m_dodgeActiveOnly == activeOnly)
        return;
    m_dodgeActiveOnly = activeOnly;
    if (m_mode == DockPlatform::VisibilityMode::DodgeWindows)
        m_evaluateTimer.start();
}

void DockVisibilityController::setReserveSpace(bool reserve)
{
    if (m_reserveSpace == reserve)
        return;
    m_reserveSpace = reserve;
    if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible)
        m_evaluateTimer.start();
}

void DockVisibilityController::setReserveMode(int mode)
{
    if (m_reserveMode == mode)
        return;
    m_reserveMode = mode;
    if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible)
        m_evaluateTimer.start();
}

void DockVisibilityController::setFloatingPadding(int padding)
{
    if (m_floatingPadding == padding)
        return;
    m_floatingPadding = padding;
    if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible)
        m_evaluateTimer.start();
}

void DockVisibilityController::setContentDimensions(qreal width, qreal height)
{
    int w = static_cast<int>(width);
    int h = static_cast<int>(height);
    if (m_contentWidth == w && m_contentHeight == h)
        return;
    m_contentWidth = w;
    m_contentHeight = h;
    if (m_mode == DockPlatform::VisibilityMode::AlwaysVisible)
        m_evaluateTimer.start();
}

void DockVisibilityController::setKeyboardActive(bool active)
{
    if (m_keyboardActive == active)
        return;
    m_keyboardActive = active;
    m_platform->setKeyboardInteractivity(active);
    if (active) {
        m_hideTimer.stop();
        m_evaluateTimer.stop();
        setVisible(true);
    } else if (m_interactingCount == 0 && !m_hovered && m_mode != DockPlatform::VisibilityMode::AlwaysVisible)
        m_hideTimer.start();
}

void DockVisibilityController::connectModelSignals()
{
    connect(m_overlapModel, &QAbstractItemModel::rowsInserted, this, [this]() {
        m_evaluateTimer.start();
    });
    connect(m_overlapModel, &QAbstractItemModel::rowsRemoved, this, [this]() {
        m_evaluateTimer.start();
    });
    connect(m_overlapModel, &QAbstractItemModel::modelReset, this, [this]() {
        m_evaluateTimer.start();
    });
    connect(m_overlapModel, &QAbstractItemModel::dataChanged, this, [this](const QModelIndex &, const QModelIndex &, const QList<int> &) {
        // We no longer filter by specific roles. If ANY property of a window changes
        // (especially its geometry while dragging), we trigger an evaluation.
        m_evaluateTimer.start();
    });
}

} // namespace krema
