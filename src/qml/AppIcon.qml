// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

/**
 * A single dock item (app icon + indicator).
 *
 * Handles parabolic zoom calculation and displays the application icon
 * with status indicators beneath.
 */
Item {
    id: dockItem

    // Properties set by the Repeater delegate
    required property int index
    required property var model

    // Display name for tooltip (readable by parent)
    readonly property string displayName: model.display || ""

    // Accessible description for screen readers (state summary)
    readonly property string accessibleDescription: {
        let parts = []
        if (DockModel.isPinned(index)) parts.push(i18n("Pinned"))
        if (model.IsActive) parts.push(i18n("Active"))
        if (model.IsMinimized) parts.push(i18n("Minimized"))
        let count = model.ChildCount || 0
        if (count > 1) parts.push(i18n("%1 windows", count))
        if (launching) parts.push(i18n("Starting"))
        if (_isDemandingAttention) parts.push(i18n("Attention requested"))
        if (_badgeCount > 0)
            parts.push(i18n("%1 notifications", _badgeCount))
        return parts.join(", ")
    }

    // Tracks keyboard navigation focus set by main.qml; toggles visual visibility of the focusRing.
    property bool isKeyboardFocused: false

    // Standard button accessibility interface; triggers activation via DockActions.activate(index).
    Accessible.role: Accessible.Button
    Accessible.name: displayName
    Accessible.description: accessibleDescription
    Accessible.focusable: true
    Accessible.focused: isKeyboardFocused
    Accessible.onPressAction: DockActions.activate(index)

    // Backing object for the Unity Launcher API, initialized via DockModel.launcherUrl.
    // Provides app-direct reporting for badge counts and urgency status.
    property QtObject _smartLauncherItem: null

    // Desktop entry name for notification lookup (e.g. "org.kde.dolphin", "slack")
    readonly property string _appId: {
        let _dep = model.display  // reactive dependency on model data
        return DockModel.appId(index)
    }

    // === Inbox (persistent badge) ===
    // Unified badge count calculation with a strict priority hierarchy.
    // 1st: Unity API (Direct app reporting, e.g. unread count in mail apps).
    // 2nd: WatchedNotifications (Passive fd.o watcher for generic notifications).
    readonly property int _badgeCount: {
        let _rev = NotificationTracker.revision  // reactive dependency
        // 1st: SmartLauncherItem (Unity API) — exact count from the app
        if (_smartLauncherItem && _smartLauncherItem.countVisible)
            return _smartLauncherItem.count
        // 2nd: WatchedNotifications — unread notification count
        if (_appId.length > 0) {
            let n = NotificationTracker.unreadCount(_appId)
            if (n > 0) return n
        }
        return 0
    }

    // === Notification (transient attention) ===
    // Implementation of the KDE Plasma Attention Protocol. 
    // Triggers visual animations when an app demands attention via:
    // 1. Window metadata (IsDemandingAttention flag).
    // 2. Unity Launcher API (Urgency flag).
    // 3. Status Notifier Items (NeedsAttention state).
    //
    // API support matrix:
    //   fd.o RegisterWatcher: notification(badge↑→animation) + inbox(badge count) + clear(focus/menu/SNI)
    //   Portal: transparent (routed to fd.o)
    //   SNI: notification(NeedsAttention→animation) + clear(→Active clears fd.o)
    //   SmartLauncher: inbox(count→badge, app-managed) + notification(urgent→animation)
    //   Window: notification(IsDemandingAttention→animation)
    //   Jobs: transparent (exposed via SmartLauncherItem.progress)
    //   DND: suppresses notification animation (badge persists)
    // Attention condition (Plasma-compatible: IsDemandingAttention OR SmartLauncher.urgent OR SNI NeedsAttention)
    readonly property bool _isDemandingAttention: {
        let _rev = NotificationTracker.revision  // reactive dependency
        return (model.IsDemandingAttention ?? false)
            || (_smartLauncherItem !== null && _smartLauncherItem.urgent)
            || (_appId.length > 0 && NotificationTracker.sniNeedsAttention(_appId))
    }

    // Timed attention animation state — triggers on new attention events, auto-clears after duration
    property bool _animationActive: false
    property int _prevBadgeCount: 0

    function _triggerAttention() {
        if (NotificationTracker.dndActive) return
        _animationActive = true
        let dur = DockSettings.attentionAnimationDuration
        if (dur > 0) {
            attentionTimer.interval = dur * 1000
            attentionTimer.restart()
        }
    }

    Timer {
        id: attentionTimer
        onTriggered: dockItem._animationActive = false
    }

    // Attention animation won't run during launch bounce or DND
    readonly property bool _showAttentionAnim:
        _animationActive && !launching && DockSettings.attentionAnimation > 0
        && !NotificationTracker.dndActive

    readonly property int _attentionType: DockSettings.attentionAnimation

    // --- Notification → animation debug logging ---
    on_BadgeCountChanged: {
        console.log("[NOTIF-TRACE] '" + displayName + "' appId=" + _appId
                    + " badgeCount=" + _badgeCount)
        if (_badgeCount > _prevBadgeCount) {
            _triggerAttention()
        }
        _prevBadgeCount = _badgeCount
    }
    on_IsDemandingAttentionChanged: {
        console.log("[NOTIF-TRACE] '" + displayName + "' appId=" + _appId
                    + " isDemandingAttention=" + _isDemandingAttention
                    + " | model.IsDemandingAttention=" + (model.IsDemandingAttention ?? false)
                    + " | smartLauncher.urgent=" + (_smartLauncherItem !== null && _smartLauncherItem.urgent)
                    + " | sniNeedsAttention=" + (_appId.length > 0 ? NotificationTracker.sniNeedsAttention(_appId) : false)
                    + " | badgeCount=" + _badgeCount)
        if (_isDemandingAttention) {
            _triggerAttention()
        }
    }

    // Blink opacity multiplier (animated by type 6)
    property real _blinkOpacity: 1.0
    on_BlinkOpacityChanged: {
        if (_blinkOpacity !== 1.0)
            console.log("[ANIM-TRACE] _blinkOpacity=" + _blinkOpacity.toFixed(3)
                + " → iconOpacity=" + iconImage.opacity.toFixed(3)
                + " for '" + displayName + "'")
    }

    // Dot blink opacity (animated by type 5)
    property real _dotBlinkOpacity: 1.0

    // Launch animation state
    property bool manualLaunching: false
    readonly property bool launching:
        manualLaunching
        || (_isStartup && !_noOpOverride)
        || _waitingForWindow

    // Drag and drop visual feedback (driven from main.qml)
    property bool isDragSource: false
    property bool isExternalDropTarget: false

    // Hover state (driven from main.qml)
    property bool isHovered: false

    // Configuration from DockView
       property int iconSize: 48
       property real maxZoomFactor: 1.6
       property real panelMouseX: -1
       property bool panelMouseInside: false
       property int spacing: 4
       
       // Re-added the property so the parent can pass the perfect math
       property real itemCenterX: 0

       // Gaussian sigma factor
       property real zoomSigmaFactor: 1.2
       readonly property real zoomSigma: iconSize * zoomSigmaFactor

       // Computed zoom factor for this item
       readonly property real zoomFactor: {
           if (!panelMouseInside || panelMouseX < 0) {
               return 1.0
           }

           let distance = Math.abs(panelMouseX - itemCenterX)
           let sigma2 = zoomSigma * zoomSigma
           // Standard Gaussian (2.0 * sigma^2) for smoother wave transition
           return 1.0 + (maxZoomFactor - 1.0) * Math.exp(-(distance * distance) / (2.0 * sigma2))
       }

    // --- KDE state-driven launch tracking ---
    //
    // Launch animation lifecycle:
    //   1. manualLaunching: click → IsStartup handoff bridge (a few ms)
    //   2. _isStartup: KDE startup notification drives bounce (until window or timeout)
    //   3. _waitingForWindow: keeps bounce alive after KDE's 5s timeout for slow apps
    //
    // Bounce stops when any of:
    //   - ChildCount increases (new window created)
    //   - IsActive changes (single-instance app raised its existing window)
    //   - noOpDetectionTimer fires (already-active app, no new window in 2s → no-op)
    //   - launchSafetyTimer fires (IsStartup never arrived within 500ms)
    //   - maxLaunchTimer fires (30s absolute safety net)

    readonly property bool _isStartup: model.IsStartup ?? false
    readonly property bool _isActive: model.IsActive ?? false
    readonly property int _childCount: model.ChildCount || 0

    // Virtual desktop opacity: mode 1 (DimOtherDesktops) dims icons on other desktops
    // DockModel.currentDesktop is a reactive dependency — triggers re-evaluation on desktop switch
    readonly property bool _isOnCurrentDesktop: {
        let _dep = DockModel.currentDesktop
        return DockModel.isOnCurrentDesktop(index)
    }
    opacity: (DockModel.virtualDesktopMode === 1 && !_isOnCurrentDesktop) ? DockSettings.otherDesktopOpacity : 1.0
    Behavior on opacity { NumberAnimation { duration: 150 } }
    property int _prevChildCount: 0

    property bool _noOpOverride: false
    property bool _waitingForWindow: false
    property int _childCountAtLaunch: 0

    property alias iconImage: iconImage

    // --- State change handlers ---

    on_IsStartupChanged: {
        if (_isStartup) {
            // KDE acknowledged the launch → release manualLaunching bridge
            if (manualLaunching) manualLaunching = false
        } else {
            // IsStartup went false (window matched, cancelled, or KDE timeout).
            // If no new window appeared and not already active → slow app,
            // keep bouncing via _waitingForWindow.
            if (!_noOpOverride
                    && _childCount === _childCountAtLaunch
                    && !_isActive) {
                _waitingForWindow = true
                maxLaunchTimer.restart()
            }
        }
    }

    on_IsActiveChanged: {
        if (_isActive && manualLaunching) manualLaunching = false
        if (_isActive && _waitingForWindow) {
            _waitingForWindow = false
            maxLaunchTimer.stop()
        }
        // Clear fd.o watcher badges when window gains focus.
        // SmartLauncher count is app-managed (separate source), so always clear fd.o unconditionally.
        if (_isActive && _appId.length > 0) {
            NotificationTracker.clearUnreadNotifications(_appId)
        }
    }

    on_ChildCountChanged: {
        if (_childCount > _prevChildCount) {
            if (manualLaunching) manualLaunching = false
            _noOpOverride = false
            _waitingForWindow = false
            noOpDetectionTimer.stop()
            maxLaunchTimer.stop()
        }
        _prevChildCount = _childCount
    }

    // Launch Safety Protocol:
    // [0.5s] Fallback if the OS misses the startup signal.
    // [2.0s] No-Op detection (e.g. middle-click didn't open a new window).
    // [30.0s] Absolute ceiling to prevent eternal icon bouncing on crash.
    Timer {
        id: launchSafetyTimer
        interval: 500
        onTriggered: {
            if (dockItem.manualLaunching) dockItem.manualLaunching = false
        }
    }

    // 2s No-Op Detection: Detects middle-click or 'New Instance' attempts on already active apps.
    // If no new window appears within 2s, it stops the launch bounce.
    Timer {
        id: noOpDetectionTimer
        interval: 2000
        onTriggered: {
            if (dockItem._childCount === dockItem._childCountAtLaunch) {
                dockItem._noOpOverride = true
            }
        }
    }

    // 30s Absolute Ceiling: Maximum allowed time for an icon to bounce during startup.
    // Prevents eternal bouncing if an application crashes or fails to open a window.
    Timer {
        id: maxLaunchTimer
        interval: 30000
        onTriggered: {
            dockItem._waitingForWindow = false
        }
    }

    onManualLaunchingChanged: {
        if (manualLaunching) {
            _childCountAtLaunch = _childCount
            _noOpOverride = false
            _waitingForWindow = false
            launchSafetyTimer.restart()
            maxLaunchTimer.stop()

            // Start no-op detection only if app is already active
            if (_isActive) {
                noOpDetectionTimer.restart()
            }
        } else {
            launchSafetyTimer.stop()
        }
    }

    // Animated scale
    property real currentScale: 1.0
    property bool _zoomAnimReady: false

    // Update currentScale when zoomFactor changes
    onZoomFactorChanged: currentScale = zoomFactor

    // When item position shifts due to model reorganization (e.g. hideActivatedLaunchers
    // merges a launcher with its window, causing other delegates to shift), suppress
    // zoom animation to prevent the visual glitch where shifted icons animate their scale.
    // Normal mouse-driven zoom doesn't change itemCenterX, so this only fires during
    // model/layout changes.
     onItemCenterXChanged: {
       if (_zoomAnimReady) {
           _zoomAnimReady = false
           currentScale = zoomFactor
           Qt.callLater(function() { _zoomAnimReady = true })
       }
   }

    // On delegate creation: apply zoom instantly (no animation) to avoid glitch
    // when Repeater recreates delegates due to model changes.
    // Qt.callLater() defers _zoomAnimReady until AFTER Row layout has set the
    // delegate's x position, ensuring itemCenterX and zoomFactor are correct.
    Component.onCompleted: {
        _prevChildCount = _childCount
        currentScale = zoomFactor  // best guess pre-layout
        Qt.callLater(function() {
            currentScale = zoomFactor  // correct value after layout
            _zoomAnimReady = true
        })

        // Create SmartLauncherItem for badge/urgent tracking
        let comp = Qt.createComponent("org.kde.plasma.private.taskmanager", "SmartLauncherItem")
        if (comp && comp.status === Component.Ready) {
            _smartLauncherItem = comp.createObject(dockItem)
            _smartLauncherItem.launcherUrl = Qt.binding(() => DockModel.launcherUrl(dockItem.index))
        }
        if (comp) comp.destroy()

        // Debug: log appId for notification matching verification
        Qt.callLater(function() {
            if (_debugNotif && dockItem._appId.length > 0)
                console.log("[NOTIF-TRACE] DockIcon created: '" + dockItem.displayName + "' appId=" + dockItem._appId)

            if (_debugGeom) {
                console.log(`[GEOM-ICON] '${dockItem.displayName}' | SLOT X:${Math.round(x)} Y:${Math.round(y)} W:${width} H:${height} | ICON X:${Math.round(iconImage.x)} Y:${Math.round(iconImage.y)} W:${iconImage.width} H:${iconImage.height} (Scaled:${Math.round(iconImage.width * currentScale)}x${Math.round(iconImage.height * currentScale)}) | TotalH:${_maxTheoreticalThickness} | Floor:${_dockFloorPadding} | Indic:${_dotHeight}+${_indicatorGap} | Ceil:${_dockCeilingPadding}`);
            }
        })
    }

    // --- ARCHITECTURAL MANDATE: THE INSIDE WORLD ---
    // Rule 1: The Fixed Floor (Grounded by Gravity)
    // Floor padding scales proportionally with icon size (25% ratio, min 4px).
    readonly property real _dockFloorPadding: Math.max(4, Math.round(iconSize * 0.25)) // Panel Edge to Indicators
    
    // The indicator gap is strictly proportional to icon size to prevent large gaps on small icons.
    // As the slider goes from 1.0 down to 0.5, the gap expands symmetrically up to a limit.
    // Baseline is 12.5% of iconSize (6px for 48px icons), with expansion up to +15%.
    readonly property real _indicatorGap: Math.max(2, Math.round(iconSize * 0.125) + Math.round(iconSize * 0.15 * (1.0 - DockSettings.indicatorOffset)))

    // Rule 6: UI Blindness Prevention (Dynamic Proportions)
    // A standard indicator is ~10% of the icon size.
    readonly property real _dotHeight: Math.max(2, Math.round(iconSize * 0.10))
    // Active dash is roughly 35% of the icon width, but at least double the dot height.
    readonly property real _activeDotWidth: Math.max(_dotHeight * 2, Math.round(iconSize * 0.35))

    // The "Floor Unit" is the total space occupied by the grounding elements
    readonly property real _totalFloorUnit: _dockFloorPadding + _dotHeight + _indicatorGap

    // Rule 2: The Illusion of Symmetry (The Empty Gap Rule)
    // Visual symmetry is achieved by ensuring the empty space above the icon
    // is exactly equal to the empty space below the indicators, regardless of gaps.
    readonly property real _dockCeilingPadding: _dockFloorPadding

    // The "Inside World" Slot defines the unzoomed territory (Icon + Floor + Ceiling)
    // The slot expands linearly as components are added, maintaining symmetric padding.
    readonly property real _maxTheoreticalThickness: iconSize + _totalFloorUnit + _dockCeilingPadding

    // Property for indicator positioning (used by main.qml for layout)
    readonly property real _indicatorSpace: _totalFloorUnit

    // Size: The delegate represents the unzoomed "Inside World" territory (The Slot).
    // Rule 8: The slot size is static to ensure a stable layout and hit-test floor.
    width: DockView.isVertical
        ? _maxTheoreticalThickness
        : iconSize
    height: DockView.isVertical
        ? iconSize
        : _maxTheoreticalThickness


    // --- DEBUG PROTOCOL (Rule 12) ---
    readonly property bool _debugAll: Qt.application.arguments.indexOf("--debug-all") !== -1
    readonly property bool _debugGeom: _debugAll || Qt.application.arguments.indexOf("--debug-geom") !== -1
    readonly property bool _debugHit: _debugAll || Qt.application.arguments.indexOf("--debug-hit") !== -1
    readonly property bool _debugZoom: _debugAll || Qt.application.arguments.indexOf("--debug-zoom") !== -1
    readonly property bool _debugNotif: _debugAll || Qt.application.arguments.indexOf("--debug-notif") !== -1

    // Scaled transform: Rule 1 - Grow AWAY from the 'Fixed Floor' (active edge)
    transform: Scale {
        origin.x: {
            switch (DockView.edge) {
            case 2: return _totalFloorUnit // Left: grow right
            case 3: return width - _totalFloorUnit // Right: grow left
            default: return width / 2
            }
        }
        origin.y: {
            switch (DockView.edge) {
            case 0: return _totalFloorUnit // Top: grow down
            case 1: return height - _totalFloorUnit // Bottom: grow up
            default: return height / 2
            }
        }
        xScale: currentScale
        yScale: currentScale
    }

    // Keyboard focus ring
    Rectangle {
        id: focusRing
        anchors.centerIn: iconImage
        width: iconImage.width + Kirigami.Units.smallSpacing * 2
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Kirigami.Theme.focusColor
        border.width: 2
        visible: dockItem.isKeyboardFocused
        Accessible.ignored: true
    }

    // Application icon
    // Rule 1: The Fixed Floor (Grounded by Gravity)
    // The icon sits in the 'Inside World' above the indicators.
    Item {
            id: iconImage
            width: iconSize
            height: iconSize
            
            // --- PIXEL HUGGER (Rule 12 Debug Visual) ---
            // A semi-transparent square that hugs the exact mathematical pixels.
            Rectangle {
                z: -1 // Behind the icon
                anchors.fill: parent
                color: "magenta"
                opacity: 0.4 // 60% transparent
                visible: _debugGeom
                border.color: "magenta"
                border.width: 1
                enabled: false // Don't block mouse
                
                // Real-time dimension label
                QQC2.Label {
                    text: Math.round(parent.width) + "x" + Math.round(parent.height)
                    font.pixelSize: 8; font.bold: true; color: "white"
                    anchors.centerIn: parent; opacity: 0.8
                }
            }
            
            // Declarative Grounding in the 'Inside World'
            x: {
                if (!DockView.isVertical) return (parent.width - width) / 2;
                if (DockView.edge === 2) return _totalFloorUnit; // Left: anchor after grounding unit
                return parent.width - _totalFloorUnit - width; // Right: anchor before grounding unit
            }
            y: {
                if (DockView.isVertical) return (parent.height - height) / 2;
                if (DockView.edge === 0) return _totalFloorUnit; // Top: icon starts after grounding unit
                return parent.height - _totalFloorUnit - height; // Bottom: icon ends before grounding unit
            }

            // --- HOVER GLOW ---
            // A subtle radial glow that follows the icon shape
            Rectangle {
                id: hoverGlow
                anchors.centerIn: parent
                width: parent.width * 1.2
                height: parent.height * 1.2
                radius: width / 2
                
                // Pure white glow, very soft
                color: "white"
                opacity: dockItem.isHovered ? 0.3 : 0.0
                
                // Fast, snappy transition
                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1.5
                }
            }
            
            // Valid if EITHER the C++ image loaded successfully OR Kirigami found the RAM icon
            property bool valid: internalIcon.status === Image.Ready || ramIcon.valid
            
            // Backup: Native RAM Icon (Kirigami perfectly understands KDE's raw QIcon memory object)
            Kirigami.Icon {
                id: ramIcon
                width: 128
                height: 128
                anchors.centerIn: parent
                scale: iconSize / 128
                smooth: true
                visible: internalIcon.status !== Image.Ready
                source: model.decoration 
            }

            // Primary: C++ Normalized Icon (Standard Image natively handles custom image:// URLs)
            Image {
                id: internalIcon
                width: 128
                height: 128
                anchors.centerIn: parent
                scale: iconSize / 128
                smooth: true
                sourceSize.width: 128
                sourceSize.height: 128
                source: dockItem._appId ? ("image://taskicon/" + dockItem._appId) : ""
            }

            // Transforms: launch bounce + attention animations
            transform: [
                Translate { id: bounceTranslate; x: 0; y: 0 },
                Translate { id: attentionBounceT; x: 0; y: 0 },
                Rotation {
                    id: attentionRotateT
                    origin.x: iconSize / 2; origin.y: iconSize / 2
                    angle: 0
                },
                Scale {
                    id: attentionScaleT
                    origin.x: iconSize / 2; origin.y: iconSize / 2
                    xScale: 1.0; yScale: xScale
                }
            ]

            // Highlight for active window / drag source dimming (× blink for type 6)
            opacity: {
                let base
                if (dockItem.isDragSource) base = 0.3
                else if (dockItem.model.IsActive) base = 1.0
                else if (dockItem.model.IsMinimized) base = 0.5
                else base = 0.8
                return base * dockItem._blinkOpacity
            }

            Behavior on opacity {
                // Disable during blink animation — rapid _blinkOpacity changes cause
                // the Behavior to restart every frame, preventing opacity from changing.
                enabled: !blinkAnim.running
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }

            // Fallback placeholder when icon is not available
            Rectangle {
                id: iconPlaceholder
                anchors.centerIn: parent
                width: parent.width * 0.85
                height: parent.height * 0.85
                radius: Kirigami.Units.largeSpacing
                color: Kirigami.Theme.highlightColor
                visible: !iconImage.valid
                Accessible.ignored: true

                QQC2.Label {
                    anchors.centerIn: parent
                    text: {
                        let name = dockItem.model.display || ""
                        return name.length > 0 ? name[0].toUpperCase() : "?"
                    }
                    font.pixelSize: iconSize * 0.4
                    font.bold: true
                    color: Kirigami.Theme.highlightedTextColor
                    Accessible.ignored: true
                }
            }

        }

    // Attention glow effect (type 4) — MultiEffect shadow pulse on iconImage
    MultiEffect {
        id: attentionGlow
        source: iconImage
        anchors.fill: iconImage
        paddingRect: Qt.rect(16, 16, 16, 16)
        visible: dockItem._showAttentionAnim && dockItem._attentionType === 4
        shadowEnabled: true
        shadowColor: Kirigami.Theme.highlightColor
        shadowBlur: 0.7
        shadowScale: 1.12
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowOpacity: 0
        Accessible.ignored: true

        SequentialAnimation on shadowOpacity {
            running: attentionGlow.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.85; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.15; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    // Badge count overlay (unified: SmartLauncher + WatchedNotifications)
    Rectangle {
        id: badge
        visible: dockItem._badgeCount > 0 && DockSettings.badgeDisplayMode !== 2
        anchors.right: iconImage.right
        anchors.top: iconImage.top
        anchors.rightMargin: -width * 0.2
        anchors.topMargin: -height * 0.2
        width: DockSettings.badgeDisplayMode === 1
               ? Math.round(iconSize * 0.18)
               : Math.round(iconSize * 0.38)
        height: width
        radius: width / 2
        color: Kirigami.Theme.highlightColor
        Accessible.ignored: true

        layer.enabled: DockSettings.badgeDisplayMode === 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha("black", 0.4)
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }

        QQC2.Label {
            visible: DockSettings.badgeDisplayMode === 0
            anchors.centerIn: parent
            text: dockItem._badgeCount > 99 ? "99+" : dockItem._badgeCount.toString()
            color: Kirigami.Theme.highlightedTextColor
            font.pixelSize: parent.height * 0.55
            font.bold: true
            fontSizeMode: Text.Fit
            minimumPixelSize: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            width: parent.width - 2
            height: parent.height - 2
        }
    }

    // Progress bar (SmartLauncher task progress)
    Rectangle {
        id: progressBar
        visible: dockItem._smartLauncherItem !== null
                 && dockItem._smartLauncherItem.progressVisible
        anchors.bottom: iconImage.bottom
        anchors.horizontalCenter: iconImage.horizontalCenter
        anchors.bottomMargin: 2
        width: iconImage.width * 0.8
        height: 3
        radius: 1.5
        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.6)
        Accessible.ignored: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (dockItem._smartLauncherItem
                                   ? dockItem._smartLauncherItem.progress / 100.0
                                   : 0)
            radius: parent.radius
            color: Kirigami.Theme.highlightColor

            Behavior on width {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }
        }
    }

    // External drop target highlight (shown when dragging a file over this icon)
    Rectangle {
        anchors.fill: iconImage
        anchors.margins: -Kirigami.Units.smallSpacing
        radius: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing / 2
        color: "transparent"
        border.color: Kirigami.Theme.highlightColor
        border.width: 2
        visible: dockItem.isExternalDropTarget
        opacity: 0.9
    }

    // Launch bounce animation — finishes current cycle gracefully when launching ends
    property bool _finishingBounce: false

    // Bounce property/value depends on edge direction
    readonly property string _bounceProp: DockView.isVertical ? "x" : "y"
    readonly property real _bounceTarget: {
        switch (DockView.edge) {
        case 0: return 8    // Top: bounce down
        case 1: return -8   // Bottom: bounce up
        case 2: return 8    // Left: bounce right
        case 3: return -8   // Right: bounce left
        }
        return -8
    }

    SequentialAnimation {
        id: bounceAnim
        loops: 1

        NumberAnimation {
            target: bounceTranslate; property: dockItem._bounceProp
            to: dockItem._bounceTarget
            duration: dockItem._finishingBounce
                ? Kirigami.Units.longDuration * 0.85
                : Kirigami.Units.longDuration
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: bounceTranslate; property: dockItem._bounceProp
            to: 0
            duration: dockItem._finishingBounce
                ? Kirigami.Units.longDuration * 0.85
                : Kirigami.Units.longDuration
            easing.type: Easing.InQuad
        }

        onFinished: {
            if (dockItem._finishingBounce) {
                dockItem._finishingBounce = false
                bounceTranslate.x = 0
                bounceTranslate.y = 0
            } else if (dockItem.launching) {
                bounceAnim.start()
            } else {
                bounceTranslate.x = 0
                bounceTranslate.y = 0
            }
        }
    }

    onLaunchingChanged: {
        if (launching) {
            _finishingBounce = false
            bounceAnim.start()
        } else if (bounceAnim.running) {
            // Let the current cycle finish at faster speed
            _finishingBounce = true
        }
    }

    // --- Attention animations (6 types) ---

    // Attention bounce target (bigger than launch bounce)
    readonly property real _attentionBounceTarget: {
        switch (DockView.edge) {
        case 0: return 14   // Top: down
        case 1: return -14  // Bottom: up
        case 2: return 14   // Left: right
        case 3: return -14  // Right: left
        }
        return -14
    }

    // Type 1: Bounce
    SequentialAnimation {
        running: dockItem._showAttentionAnim && dockItem._attentionType === 1
        onRunningChanged: console.log("[ANIM-TRACE] bounceAttentionAnim.running=" + running
            + " for '" + dockItem.displayName + "'"
            + " | _attentionType=" + dockItem._attentionType)
        loops: Animation.Infinite
        NumberAnimation {
            target: attentionBounceT; property: dockItem._bounceProp
            to: dockItem._attentionBounceTarget; duration: 300; easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: attentionBounceT; property: dockItem._bounceProp
            to: 0; duration: 300; easing.type: Easing.InBounce
        }
        PauseAnimation { duration: 800 }
    }

    // Type 2: Wiggle
    SequentialAnimation {
        running: dockItem._showAttentionAnim && dockItem._attentionType === 2
        loops: Animation.Infinite
        NumberAnimation { target: attentionRotateT; property: "angle"; to: 5; duration: 80; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: -5; duration: 160; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: 3; duration: 120; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: -3; duration: 120; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: 1; duration: 100; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: -1; duration: 100; easing.type: Easing.InOutSine }
        NumberAnimation { target: attentionRotateT; property: "angle"; to: 0; duration: 80; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2000 }
    }

    // Type 3: Pulse
    SequentialAnimation {
        running: dockItem._showAttentionAnim && dockItem._attentionType === 3
        loops: Animation.Infinite
        NumberAnimation {
            target: attentionScaleT; property: "xScale"
            to: 1.15; duration: 600; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: attentionScaleT; property: "xScale"
            to: 1.0; duration: 600; easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 400 }
    }

    // Type 4: Glow — animation is on MultiEffect (attentionGlow) above

    // Type 5: DotColor — animation on _dotBlinkOpacity
    SequentialAnimation {
        running: dockItem._showAttentionAnim && dockItem._attentionType === 5
        loops: Animation.Infinite
        NumberAnimation {
            target: dockItem; property: "_dotBlinkOpacity"
            to: 0.3; duration: 500; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: dockItem; property: "_dotBlinkOpacity"
            to: 1.0; duration: 500; easing.type: Easing.InOutSine
        }
    }

    // Type 6: Blink — animation on _blinkOpacity
    SequentialAnimation {
        id: blinkAnim
        running: dockItem._showAttentionAnim && dockItem._attentionType === 6
        loops: Animation.Infinite
        onRunningChanged: console.log("[ANIM-TRACE] blinkAnim.running=" + running
            + " for '" + dockItem.displayName + "'"
            + " | _showAttentionAnim=" + dockItem._showAttentionAnim
            + " | _attentionType=" + dockItem._attentionType
            + " (type: " + typeof dockItem._attentionType + ")")
        NumberAnimation {
            target: dockItem; property: "_blinkOpacity"
            to: 0.2; duration: 400; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: dockItem; property: "_blinkOpacity"
            to: 1.0; duration: 400; easing.type: Easing.InOutSine
        }
    }

    // Reset attention properties when animation stops
    on_ShowAttentionAnimChanged: {
        console.log("[NOTIF-TRACE] '" + displayName + "' appId=" + _appId
                    + " showAttentionAnim=" + _showAttentionAnim
                    + " | isDemandingAttention=" + _isDemandingAttention
                    + " | launching=" + launching
                    + " | attentionSetting=" + DockSettings.attentionAnimation)
        if (!_showAttentionAnim) {
            attentionBounceT.x = 0
            attentionBounceT.y = 0
            attentionRotateT.angle = 0
            attentionScaleT.xScale = 1.0
            attentionGlow.shadowOpacity = 0
            _blinkOpacity = 1.0
            _dotBlinkOpacity = 1.0
        }
    }

    // Status indicator dots (Rule 1: Grounded by Gravity)
    // The dots sit in the 'Inside World' Floor.
    Flow {
        id: indicatorRow
        height: _dotHeight // Ensure fixed height for symmetry math
        flow: DockView.isVertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: Kirigami.Units.smallSpacing
        Accessible.ignored: true
        
        // Grounded in the 'Inside World' Floor
        x: {
            if (!DockView.isVertical) return (parent.width - width) / 2;
            if (DockView.edge === 2) return (_dockFloorPadding + (_dotHeight - width) / 2); // Left: Center in grounding zone
            return parent.width - _dockFloorPadding - _dotHeight + (_dotHeight - width) / 2; // Right: Center in grounding zone
        }
        y: {
            if (DockView.isVertical) return (parent.height - height) / 2;
            if (DockView.edge === 0) return (_dockFloorPadding + (_dotHeight - height) / 2); // Top: Center in grounding zone
            return parent.height - _dockFloorPadding - _dotHeight + (_dotHeight - height) / 2; // Bottom: Center in grounding zone
        }

        Repeater {
            // Show dots based on window count (max 3)
            model: {
                if (!dockItem.model.IsWindow) return 0
                let count = dockItem.model.ChildCount || 1
                return Math.min(count, 3)
            }

            Rectangle {
		    // --- THE ACTIVE DASH LOGIC ---
                // If the dock is horizontal, stretch width when active.
                width: DockView.isVertical ? _dotHeight : (dockItem.model.IsActive ? Math.round(iconSize * 0.35) : _dotHeight)
                
                // If the dock is vertical, stretch height when active.
                height: DockView.isVertical ? (dockItem.model.IsActive ? Math.round(iconSize * 0.35) : _dotHeight) : _dotHeight
                
                // Keep the pill shape completely round at the ends
                radius: _dotHeight / 2
                
                // Smoothly animate the stretching effect
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                }
                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                }
                // -----------------------------
                color: (dockItem._showAttentionAnim && dockItem._attentionType === 5)
                       ? Kirigami.Theme.negativeTextColor
                       : Kirigami.Theme.textColor
                opacity: (dockItem._showAttentionAnim && dockItem._attentionType === 5)
                         ? dockItem._dotBlinkOpacity
                         : (dockItem.model.IsMinimized ? 0.4 : 0.8)

                Behavior on color {
                    ColorAnimation { duration: Kirigami.Units.longDuration }
                }
                Behavior on opacity {
                    enabled: !(dockItem._showAttentionAnim && dockItem._attentionType === 5)
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
            }
        }
    }

    // Click handling is done in main.qml's dockMouseArea using
    // hoveredIndex-based hit testing to match the zoomed icon geometry.
}
