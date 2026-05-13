// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import com.bhyoo.krema 1.0

/**
 * Main dock container.
 *
 * The root item fills the layer-shell surface. The visible dock panel
 * is a centered rounded rectangle that hugs its content.
 * The panel slides in/out based on DockVisibility.dockVisible.
 */
Item {
    id: root
    anchors.fill: parent

    Accessible.role: Accessible.ToolBar
    Accessible.name: i18n("Krema Dock")

    // --- DEBUG PROTOCOL (Rule 12) ---
    readonly property bool _debugAll: Qt.application.arguments.indexOf("--debug-all") !== -1
    readonly property bool _debugGeom: _debugAll || Qt.application.arguments.indexOf("--debug-geom") !== -1
    readonly property bool _debugHit: _debugAll || Qt.application.arguments.indexOf("--debug-hit") !== -1
    readonly property bool _debugZoom: _debugAll || Qt.application.arguments.indexOf("--debug-zoom") !== -1
    readonly property bool _debugNotif: _debugAll || Qt.application.arguments.indexOf("--debug-notif") !== -1

    // State Tracking: Monitor zoom slider changes
    Connections {
        target: DockSettings
        function onMaxZoomFactorChanged() {
        }
    }

    MouseArea {
        id: dockMouseArea
        Accessible.ignored: true
        
        // --- Thickness Lead Fix (Rule 3) ---
        // Do NOT anchor to dockPanel (parent). Fill the root to cover 
        // the entire Wayland input region. This ensures we catch the mouse
        // even if the visual panel is thin (e.g. 10px).
        anchors.fill: root

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onExited: {
            if (!PreviewController.visible) {
                dockPanel.mouseX = -1
                dockPanel.mouseY = -1
                root._zoomActive = false
            }
            PreviewController.hidePreviewDelayed()
            if (root._dragActive) {
                if (DockModel.isPinned(root._dragSourceIndex)) {
                    DockActions.removeLauncher(root._dragSourceIndex)
                }
                root._dragActive = false
                root._dragPending = false
                root._dragWasActive = false
                root._dragSourceIndex = -1
                root._dragTargetIndex = -1
                DockVisibility.setInteracting(false)
            } else if (root._dragPending) {
                root._dragPending = false
                root._dragWasActive = false
                root._dragSourceIndex = -1
                root._dragTargetIndex = -1
                dragHoldTimer.stop()
            }
            if (!PreviewController.visible) {
                DockVisibility.setHovered(false)
            }
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton && root.hoveredIndex >= 0) {
                root._dragStartX = mouse.x
                root._dragStartY = mouse.y
                root._dragWasActive = false
                dragHoldTimer.restart()
            }
        }

        onReleased: function(mouse) {
            dragHoldTimer.stop()
            if (root._dragActive) {
                if (root._dragTargetIndex >= 0 && root._dragTargetIndex !== root._dragSourceIndex) {
                    let sourceIsPinned = DockModel.isPinned(root._dragSourceIndex);
                    let targetIsPinned = DockModel.isPinned(root._dragTargetIndex);
                    let finalTarget = root._dragTargetIndex;
                    if (sourceIsPinned && !targetIsPinned) {
                        for (let i = dockRepeater.count - 1; i >= 0; i--) {
                            if (DockModel.isPinned(i)) { finalTarget = i; break; }
                        }
                    } else if (!sourceIsPinned && targetIsPinned) {
                        for (let i = 0; i < dockRepeater.count; i++) {
                            if (!DockModel.isPinned(i)) { finalTarget = i; break; }
                        }
                    }
                    if (finalTarget !== root._dragSourceIndex) {
                        let item = dockRepeater.itemAt(root._dragSourceIndex);
                        let name = item ? item.displayName : "";
                        DockActions.moveTask(root._dragSourceIndex, finalTarget);
                        Accessible.announce(i18n("Moved %1 to position %2", name, finalTarget + 1), Accessible.Polite);
                    }
                }
                root._dragActive = false
                root._dragPending = false
                root._dragSourceIndex = -1
                root._dragTargetIndex = -1
                DockVisibility.setInteracting(false)
            } else {
                root._dragPending = false
            }
        }

        onClicked: function(mouse) {
            if (root._dragWasActive) {
                root._dragWasActive = false
                return
            }
            if (root.hoveredIndex < 0) return
            if (mouse.button === Qt.LeftButton) {
                DockActions.activate(root.hoveredIndex)
            } else if (mouse.button === Qt.MiddleButton) {
                DockActions.newInstance(root.hoveredIndex)
            } else if (mouse.button === Qt.RightButton) {
                DockContextMenu.showForTask(root.hoveredIndex)
            }
        }

        onWheel: function(wheel) {
            if (root.hoveredIndex < 0) return
            if (wheel.angleDelta.y > 0) {
                DockActions.cycleWindows(root.hoveredIndex, false)
            } else if (wheel.angleDelta.y < 0) {
                DockActions.cycleWindows(root.hoveredIndex, true)
            }
        }

        onPositionChanged: function(mouse) {
            if (typeof DockContextMenu !== "undefined" && DockContextMenu.visible) return

            // Hit-test diagnostic (active with --debug-hit)
            if (_debugHit) {
                console.log("[GEOM-HIT] Hovering at", mouse.x.toFixed(1), mouse.y.toFixed(1))
            }

            let isVisible = DockVisibility.dockVisible
            let triggerDepth = 2

            let iconSize = DockSettings.iconSize
            let spacing = DockSettings.iconSpacing
            let slotSize = iconSize + spacing
            let totalUnscaled = (dockRepeater.count * slotSize) - spacing
            let centerPos = (DockView.isVertical ? root.height : root.width) / 2
            let unscaledStart = centerPos - (totalUnscaled / 2)

            // --- Interaction Orbit (Rule 3 & 17) ---
            // The orbit is anchored to the visual center of the icons, 
            // ensuring hit-testing matches visual pixels exactly.
            let sample = dockRepeater.itemAt(0)
            let floorUnits = sample ? sample._indicatorSpace : 0
            let unitCenter = floorUnits + (iconSize / 2)
            
            let secondaryAxisCenter = 0
            if (DockView.isVertical) {
                secondaryAxisCenter = (DockView.edge === 2) 
                    ? dockPanel.x + unitCenter 
                    : (dockPanel.x + dockPanel.width - unitCenter)
            } else {
                secondaryAxisCenter = (DockView.edge === 0) 
                    ? dockPanel.y + unitCenter 
                    : (dockPanel.y + dockPanel.height - unitCenter)
            }

            // Dual-Orbit Hysteresis: prevents flickering between unzoomed/zoomed states
            let enterOrbit = (iconSize * 0.5) + 5
            let exitOrbit = enterOrbit // fallback
            if (sample) {
                let visualRadius = (dockRow._maxIconThickness * 0.5) + sample._indicatorSpace
                exitOrbit = visualRadius + 10
            }

            let currentOrbit = root._zoomActive ? exitOrbit : enterOrbit
            let secondaryAxisDist = Math.abs((DockView.isVertical ? mouse.x : mouse.y) - secondaryAxisCenter)
            let isInside = isVisible && (secondaryAxisDist <= currentOrbit)

            if (!isVisible) {
                switch (DockView.edge) {
                    case 0: isInside = (mouse.y <= triggerDepth); break
                    case 1: isInside = (mouse.y >= root.height - triggerDepth); break
                    case 2: isInside = (mouse.x <= triggerDepth); break
                    case 3: isInside = (mouse.x >= root.width - triggerDepth); break
                }
            }

            DockVisibility.setHovered(isInside);

            if (!isInside) {
                if (!PreviewController.visible) {
                    dockPanel.mouseX = -1
                    dockPanel.mouseY = -1
                    root._zoomActive = false
                }
                root.hoveredIndex = -1
                root.hoveredName = ""
                return 
            }

            // 3. ACTIVE ZOOM SIGNAL
            root._zoomActive = true
            dockPanel.mouseX = DockView.isVertical ? mouse.y : mouse.x
            dockPanel.mouseY = DockView.isVertical ? mouse.x : mouse.y

            // 4. PIXEL-PERFECT HIT-TESTING
            let hitIndex = -1;
            let mPos = DockView.isVertical ? mouse.y : mouse.x;

            for (let i = 0; i < dockRepeater.count; i++) {
                let item = dockRepeater.itemAt(i);
                if (!item) continue;

                let unscaledCenter = unscaledStart + (i * slotSize) + (iconSize / 2);
                let zoomedSize = iconSize * item.currentScale;
                let slotStart = unscaledCenter - (zoomedSize / 2);
                let slotEnd = unscaledCenter + (zoomedSize / 2);

                // Primary Axis Filter: Is the mouse within the visual width of this icon?
                if (mPos >= slotStart - 5 && mPos <= slotEnd + 5) {
                    let localPos = item.iconImage.mapFromItem(dockMouseArea, mouse.x, mouse.y);

                    // Secondary Axis Precision: Distance from visual icon center
                    let dx = localPos.x - (item.iconSize / 2)
                    let dy = localPos.y - (item.iconSize / 2)
                    let dist = Math.sqrt(dx*dx + dy*dy)

                    // Trigger hover ONLY if over actual icon pixels
                    if (dist <= (item.iconSize / 2)) {
                        hitIndex = i;
                        break;
                    }
                }
            }

            if (hitIndex >= 0) {
                if (root.hoveredIndex !== hitIndex) {
                    root.hoveredIndex = hitIndex;
                    root.hoveredName = dockRepeater.itemAt(hitIndex).displayName;
                    tooltipTimer.restart();
                }
            } else {
                root.hoveredIndex = -1;
                root.hoveredName = "";
            }

            if (root.keyboardNavigating) {
                root.keyboardNavigating = false
                DockVisibility.setKeyboardActive(false)
            }

            if (root._dragPending && !root._dragActive) {
                let dx = mouse.x - root._dragStartX
                let dy = mouse.y - root._dragStartY
                if (Math.sqrt(dx * dx + dy * dy) > root._dragThreshold) {
                    root._dragActive = true
                    root._dragWasActive = true
                    DockVisibility.setInteracting(true) 
                    tooltipItem.show = false
                    tooltipTimer.stop()
                }
            }

            if (root._dragActive) {
                root._dragCurrentX = mouse.x
                root._dragCurrentY = mouse.y
                root._dragTargetIndex = computeDropIndex(DockView.isVertical ? mouse.y : mouse.x)
            }
        }
    }

    property int hoveredIndex: -1
    property string hoveredName: ""
    property bool keyboardNavigating: false
    property bool _zoomActive: false

    // Kinetic Zoom Physics (Milestone 9)
    // We animate this value to create a 'liquid' exit instead of an instant snap.
    property real _zoomIntensity: _zoomActive ? 1.0 : 0.0
    Behavior on _zoomIntensity {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutBack // Provides a subtle bounce/liquid feel
        }
    }

    focus: true

    function announceLaunch(name) {
        Accessible.announce(i18n("Starting %1", name), Accessible.Assertive)
    }

    function startKeyboardNavigation() {
        keyboardNavigating = true
        tooltipTimer.stop()
        tooltipItem.show = false
        if (dockRepeater.count > 0) {
            if (hoveredIndex < 0) hoveredIndex = 0
            let item = dockRepeater.itemAt(hoveredIndex)
            if (item) {
                dockPanel.mouseX = item.itemCenterX
                dockPanel.mouseY = dockRow.y + item.height / 2
            }
        }
        root.forceActiveFocus()
    }

    Connections {
        target: root.Window.window
        function onActiveChanged() {
            if (root.Window.window && root.Window.window.active
                    && root.keyboardNavigating && !root.activeFocus) {
                root.forceActiveFocus()
            }
        }
    }

    function endKeyboardNavigation() {
        keyboardNavigating = false
        hoveredIndex = -1
        hoveredName = ""
        _zoomActive = false
        dockPanel.mouseX = -1
        dockPanel.mouseY = -1
        DockVisibility.setKeyboardActive(false)
    }

    function navigateItem(delta) {
        keyboardNavigating = true
        let count = dockRepeater.count
        if (count === 0) return
        if (hoveredIndex < 0) {
            hoveredIndex = delta > 0 ? 0 : count - 1
        } else {
            hoveredIndex = Math.max(0, Math.min(count - 1, hoveredIndex + delta))
        }
        hoveredName = dockRepeater.itemAt(hoveredIndex)?.displayName ?? ""
        let item = dockRepeater.itemAt(hoveredIndex)
        if (item) {
            dockPanel.mouseX = item.itemCenterX
            dockPanel.mouseY = dockRow.y + item.height / 2
            let msg = item.displayName + ", " + i18n("%1 of %2", hoveredIndex + 1, count)
            Accessible.announce(msg, Accessible.Polite)
        }
    }

    function announcePreviewThumbnail() {
        let title = PreviewController.focusedThumbnailTitle()
        if (!title) return
        let msg = title + ", " + i18n("%1 of %2",
            PreviewController.focusedThumbnailIndex + 1,
            PreviewController.previewThumbnailCount())
        Accessible.announce(msg, Accessible.Polite)
    }

    Keys.onPressed: function(event) {
        if (!keyboardNavigating) return
        if (PreviewController.previewKeyboardActive) {
            let thumbPrev = DockView.isVertical ? Qt.Key_Up : Qt.Key_Left
            let thumbNext = DockView.isVertical ? Qt.Key_Down : Qt.Key_Right
            let backKey = DockView.isVertical ? (DockView.edge === 2 ? Qt.Key_Left : Qt.Key_Right) : (DockView.edge === 0 ? Qt.Key_Up : Qt.Key_Down)
            switch (event.key) {
            case thumbPrev: PreviewController.navigatePreviewThumbnail(-1); announcePreviewThumbnail(); event.accepted = true; break
            case thumbNext: PreviewController.navigatePreviewThumbnail(1); announcePreviewThumbnail(); event.accepted = true; break
            case Qt.Key_Return: case Qt.Key_Enter: PreviewController.activatePreviewThumbnail(); endKeyboardNavigation(); event.accepted = true; break
            case Qt.Key_Delete: PreviewController.closePreviewThumbnail(); announcePreviewThumbnail(); event.accepted = true; break
            case Qt.Key_Escape: case backKey: PreviewController.endPreviewKeyboardNav(); event.accepted = true; break
            }
            return
        }
        let navPrev = DockView.isVertical ? Qt.Key_Up : Qt.Key_Left
        let navNext = DockView.isVertical ? Qt.Key_Down : Qt.Key_Right
        let previewKey = DockView.isVertical ? (DockView.edge === 2 ? Qt.Key_Right : Qt.Key_Left) : (DockView.edge === 0 ? Qt.Key_Down : Qt.Key_Up)
        switch (event.key) {
        case navPrev: navigateItem(-1); event.accepted = true; break
        case navNext: navigateItem(1); event.accepted = true; break
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: if (hoveredIndex >= 0) { DockActions.activate(hoveredIndex); endKeyboardNavigation(); } event.accepted = true; break
        case Qt.Key_Escape: if (PreviewController.visible) PreviewController.hidePreview(); endKeyboardNavigation(); event.accepted = true; break
        case previewKey:
            if (hoveredIndex >= 0) {
                let idx = DockModel.tasksModel.index(hoveredIndex, 0)
                if (DockModel.tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow)) {
                    let item = dockRepeater.itemAt(hoveredIndex)
                    if (item) {
                        let globalPos = item.mapToGlobal(0, 0)
                        PreviewController.showPreview(hoveredIndex, DockView.isVertical ? globalPos.y : globalPos.x, DockView.isVertical ? item.height : item.width)
                        PreviewController.startPreviewKeyboardNav(); announcePreviewThumbnail();
                    }
                }
            }
            event.accepted = true; break
        case Qt.Key_Menu: if (hoveredIndex >= 0) DockContextMenu.showForTask(hoveredIndex); event.accepted = true; break
        }
    }

    // --- Internal drag state ---
    property bool _dragActive: false
    property int _dragSourceIndex: -1
    property int _dragTargetIndex: -1
    property real _dragCurrentX: 0
    property real _dragCurrentY: 0
    property real _dragStartX: 0
    property real _dragStartY: 0
    property bool _dragPending: false
    property bool _dragWasActive: false
    readonly property real _dragThreshold: 10

    Timer {
        id: dragHoldTimer
        interval: 300
        onTriggered: {
            if (root.hoveredIndex >= 0) {
                root._dragPending = true
                root._dragSourceIndex = root.hoveredIndex
            }
        }
    }

    function computeDropIndex(globalMousePos) {
        let panelRel = globalMousePos - (DockView.isVertical ? dockPanel.y : dockPanel.x)
        let items = []
        for (let i = 0; i < dockRepeater.count; i++) {
            let item = dockRepeater.itemAt(i)
            if (item) items.push({ idx: i, cx: (DockView.isVertical ? item.y + item.height/2 : item.x + item.width/2) + (DockView.isVertical ? dockRow.y : dockRow.x) })
        }
        if (items.length === 0) return -1
        let bestIdx = items[0].idx, bestDist = Math.abs(panelRel - items[0].cx)
        for (let j = 1; j < items.length; j++) {
            let d = Math.abs(panelRel - items[j].cx)
            if (d < bestDist) { bestDist = d; bestIdx = items[j].idx }
        }
        return bestIdx
    }

    function computeExternalDropIndex(dropX) {
        for (let i = 0; i < dockRepeater.count; i++) {
            let item = dockRepeater.itemAt(i)
            if (item && dropX >= dockRow.x + item.x && dropX <= dockRow.x + item.x + item.width) return i
        }
        return -1
    }

    function _tryAutoPreview() {
        if (!DockSettings.previewEnabled || hoveredIndex < 0 || PreviewController.visible || (typeof DockContextMenu !== "undefined" && DockContextMenu.visible)) return
        let idx = DockModel.tasksModel.index(hoveredIndex, 0)
        if (DockModel.tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow)) {
            tooltipItem.show = false; tooltipTimer.stop()
            let item = dockRepeater.itemAt(hoveredIndex)
            if (item) {
                let globalPos = item.mapToGlobal(0, 0)
                PreviewController.showPreview(hoveredIndex, DockView.isVertical ? globalPos.y : globalPos.x, DockView.isVertical ? item.height : item.width)
            }
        }
    }

    function traceHitTest(mX_abs, mY_abs) {
        let mPos = DockView.isVertical ? mY_abs : mX_abs
        let iconSize = DockSettings.iconSize, spacing = DockSettings.iconSpacing, slot = iconSize + spacing
        let totalUnscaled = (dockRepeater.count * slot) - spacing
        let unscaledStart = (DockView.isVertical ? root.height : root.width) / 2 - (totalUnscaled / 2)
        for (let i = 0; i < dockRepeater.count; i++) {
            let item = dockRepeater.itemAt(i)
            if (!item) continue
            let unscaledCenter = unscaledStart + (i * slot) + (iconSize / 2)
            let zoomedSize = iconSize * item.currentScale
            if (mPos >= unscaledCenter - zoomedSize/2 && mPos <= unscaledCenter + zoomedSize/2) {
                let localPos = item.iconImage.mapFromItem(dockMouseArea, mX_abs, mY_abs)
                return `ICON-${i}: Local(${localPos.x.toFixed(1)},${localPos.y.toFixed(1)})`
            }
        }
        return "BETWEEN-ICONS"
    }

    // Projective SDF drop shadow
    ShaderEffect {
        id: dockShadow
        visible: DockSettings.shadowEnabled
        z: dockPanel.z - 1
        property real panelWidth: dockPanel.width
        property real panelHeight: dockPanel.height
        property real cornerRadius: dockPanel.radius
        property real elevation: DockSettings.shadowElevation
        property real lightX: DockSettings.shadowLightX
        property real lightY: DockSettings.shadowLightY
        property real lightZ: DockSettings.shadowLightZ
        property real lightRadius: DockSettings.shadowLightRadius
        property color _shadowColor: DockSettings.shadowColor
        property real shadowR: _shadowColor.r
        property real shadowG: _shadowColor.g
        property real shadowB: _shadowColor.b
        property real shadowA: DockSettings.shadowIntensity
        property real margin: Math.min(64, Math.max((Math.sqrt(lightX*lightX+lightY*lightY)+lightRadius)*elevation/Math.max(lightZ-elevation,1), lightRadius*3)+10)
        
        // --- Shadow Alignment Fix ---
        // The width/height and offsets MUST match the margin property exactly
        // because the shader uses this uniform to define its coordinate space.
        x: dockPanel.x - margin; y: dockPanel.y - margin; width: dockPanel.width + margin * 2; height: dockPanel.height + margin * 2
        
        fragmentShader: "qrc:/qml/shaders/outer_shadow.frag.qsb"
    }

    Item {
        id: blueprintGhost
        visible: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode
        z: dockPanel.z - 1
        width: (DockSettings.edge === 2 || DockSettings.edge === 3) ? 180 : parent.width
        height: (DockSettings.edge === 2 || DockSettings.edge === 3) ? parent.height : 180
        x: DockSettings.edge === 3 ? parent.width - width : 0
        y: DockSettings.edge === 1 ? parent.height - height : 0
        enabled: false
        Rectangle {
            anchors.fill: parent; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
            Canvas {
                anchors.fill: parent; opacity: 0.4
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    ctx.beginPath(); ctx.lineWidth = 0.5; ctx.strokeStyle = "rgba(255, 255, 255, 0.15)"
                    for (let x = (width/2)%10; x <= width; x += 10) { ctx.moveTo(x+0.5, 0); ctx.lineTo(x+0.5, height) }
                    for (let y = (height/2)%10; y <= height; y += 10) { ctx.moveTo(0, y+0.5); ctx.lineTo(width, y+0.5) }
                    ctx.stroke(); ctx.beginPath(); ctx.lineWidth = 1.0; ctx.strokeStyle = "rgba(255, 255, 255, 0.40)"
                    for (let x = (width/2)%50; x <= width; x += 50) { ctx.moveTo(x+0.5, 0); ctx.lineTo(x+0.5, height) }
                    for (let y = (height/2)%50; y <= height; y += 50) { ctx.moveTo(0, y+0.5); ctx.lineTo(width, y+0.5) }
                    ctx.stroke()
                }
            }
        }
    }

    Rectangle {
        id: dockPanel
        visible: opacity > 0.01

        // --- Visual Extent (Rule 17/18) ---
        // The highest physical point of the icons relative to the screen edge.
        // Used to anchor window previews perfectly.
        readonly property real visualIconTop: {
            let sample = dockRepeater.itemAt(0)
            let floorUnits = sample ? sample._indicatorSpace : 0
            
            // Current visual icon height = unzoomedSize * (1.0 + zoomAmount)
            let currentIconHeight = DockSettings.iconSize * (1.0 + (DockSettings.maxZoomFactor - 1.0) * root._zoomIntensity)
            
            return _screenFlooring + floorUnits + currentIconHeight
        }
        property real currentVisualOverflow: {
            let sample = dockRepeater.itemAt(0)
            let floorUnits = sample ? sample._indicatorSpace : 0
            
            // --- Dynamic Overflow (Bug #7 Fix) ---
            // Calculate the actual visual overflow based on the kinetic zoom intensity.
            // This ensures the Wayland surface and Previews track the icons perfectly.
            let maxPotentialZoom = (DockSettings.iconSize * (DockSettings.maxZoomFactor - 1.0))
            let currentZoomOverflow = maxPotentialZoom * root._zoomIntensity
            
            let baseOverflow = Math.max(0, (DockView.isVertical ? dockRow.implicitWidth - width : dockRow.implicitHeight - height))
            
            return currentZoomOverflow + baseOverflow + floorUnits + 16
        }
        onCurrentVisualOverflowChanged: updateWaylandInputRegion()
        
        property real mouseX: -9999
        property real mouseY: -9999
        property bool mouseInside: dockMouseArea.containsMouse && !root._dragActive
        property real _actualContentWidth: Math.max(dockRow.implicitWidth + 32, Kirigami.Units.gridUnit * 6)
        property real _actualContentHeight: Math.max(dockRow.implicitHeight + 32, Kirigami.Units.gridUnit * 6)
        
        width: !DockView.isVertical ? _actualContentWidth : Math.min(DockSettings.panelHeight, dockRow.implicitWidth)
        height: DockView.isVertical ? _actualContentHeight : Math.min(DockSettings.panelHeight, dockRow.implicitHeight)
        radius: Math.min(DockSettings.cornerRadius, Math.min(width, height) / 2)
        color: {
            let style = DockSettings.backgroundStyle
            if (style === 3 || style === 4) return "transparent" // Acrylic or Mica (handled by shaders)
            if (style === 1) return "transparent" // Transparent
            let c = (style === 2 && !DockSettings.useSystemColor) ? Qt.color(DockSettings.tintColor) : DockView.backgroundColor
            return Qt.rgba(c.r, c.g, c.b, DockSettings.backgroundOpacity)
        }
        x: DockView.isVertical ? _panelEdgePos : (parent.width - width) / 2
        y: DockView.isVertical ? (parent.height - height) / 2 : _panelEdgePos
        readonly property real _screenFlooring: DockView.floatingPadding
        property real _panelEdgePos: {
            if (typeof DockVisibility === "undefined") return 0
            let pfb = _screenFlooring
            switch (DockView.edge) {
            case 0: return DockVisibility.dockVisible ? pfb : -(height + 20)
            case 1: return DockVisibility.dockVisible ? (parent.height - height - pfb) : (parent.height + height)
            case 2: return DockVisibility.dockVisible ? pfb : -(width + 20)
            case 3: return DockVisibility.dockVisible ? (parent.width - width - pfb) : (parent.width + width)
            }
            return 0
        }

        function updateWaylandInputRegion() {
            if (typeof DockVisibility !== "undefined") {
                DockVisibility.setPanelRect(dockPanel.x, dockPanel.y, dockPanel.width, dockPanel.height)
                DockVisibility.setZoomOverflowHeight(dockPanel.currentVisualOverflow)
            }
        }

        onXChanged: updateWaylandInputRegion(); onYChanged: updateWaylandInputRegion()
        onWidthChanged: updateWaylandInputRegion(); onHeightChanged: updateWaylandInputRegion()
        
        onVisualIconTopChanged: {
            if (typeof PreviewController !== "undefined") {
                PreviewController.setDockHeight(visualIconTop)
            }
        }

        ShaderEffect {
            id: acrylicShader; anchors.fill: parent; z: 0; visible: DockSettings.backgroundStyle === 3 || DockSettings.backgroundStyle === 4
            property color _activeTint: {
                if (DockSettings.backgroundStyle === 4) return Kirigami.Theme.highlightColor // Mica uses accent
                return (DockSettings.backgroundStyle === 3 && !DockSettings.useSystemColor) ? Qt.color(DockSettings.tintColor) : DockView.backgroundColor
            }
            property real tintR: _activeTint.r; property real tintG: _activeTint.g; property real tintB: _activeTint.b; property real tintOpacity: DockSettings.backgroundStyle === 4 ? 0.3 : DockSettings.backgroundOpacity
            property real noiseStrength: DockSettings.backgroundStyle === 4 ? 0.05 : 0.02
            property real resX: width; property real resY: height; property real cornerRadius: dockPanel.radius
            fragmentShader: "qrc:/qml/shaders/acrylic_overlay.frag.qsb"
        }

        Component.onCompleted: Qt.callLater(function() {
            updateWaylandInputRegion()
            if (DockVisibility) DockVisibility.setContentDimensions(dockRow.implicitWidth, dockRow.implicitHeight)
        })

        Behavior on x { enabled: !dockPanel.mouseInside && DockView.isVertical; NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }
        Behavior on y { enabled: !dockPanel.mouseInside && !DockView.isVertical; NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }
        opacity: DockVisibility.dockVisible ? 1.0 : 0.0; Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration } }

        Item {
            id: dockRow; z: 2; readonly property real baseSpacing: DockSettings.iconSpacing
            // Rule 15 & 16: Content dimensions account for dynamic expansion.
            // [STABILITY]: We use a stable base width to prevent startup "Identity Crisis" gaps.
            readonly property real baseWidth: (dockRepeater.count === 0) ? 0 : (dockRepeater.count * (DockSettings.iconSize + baseSpacing)) - baseSpacing
            readonly property real baseHeight: (dockRepeater.count === 0) ? 0 : (dockRepeater.count * (DockSettings.iconSize + baseSpacing)) - baseSpacing

            implicitWidth: DockView.isVertical ? _maxIconThickness : Math.max(baseWidth, (dockRepeater.count === 0 ? 0 : (dockRepeater.itemAt(dockRepeater.count-1)?.x + dockRepeater.itemAt(dockRepeater.count-1)?.width || 0)))
            implicitHeight: !DockView.isVertical ? _maxIconThickness : Math.max(baseHeight, (dockRepeater.count === 0 ? 0 : (dockRepeater.itemAt(dockRepeater.count-1)?.y + dockRepeater.itemAt(dockRepeater.count-1)?.height || 0)))
            readonly property real _maxIconThickness: {
                let m = 0; for (let i=0; i<dockRepeater.count; i++) { let it = dockRepeater.itemAt(i); if (it) { let t = DockView.isVertical ? it.width : it.height; if (t > m) m = t } }
                return m
            }
            onImplicitWidthChanged: if (DockVisibility) DockVisibility.setContentDimensions(implicitWidth, implicitHeight)
            onImplicitHeightChanged: if (DockVisibility) DockVisibility.setContentDimensions(implicitWidth, implicitHeight)
            x: DockView.isVertical ? ((DockView.edge === 2) ? 0 : (dockPanel.width - implicitWidth)) : (dockPanel.width - implicitWidth) / 2
            y: !DockView.isVertical ? ((DockView.edge === 0) ? 0 : (dockPanel.height - implicitHeight)) : (dockPanel.height - implicitHeight) / 2

            Repeater {
                id: dockRepeater; model: DockModel.tasksModel
                AppIcon {
                    readonly property real virtualCenter: {
                        let slot = iconSize + dockRow.baseSpacing, total = (dockRepeater.count * slot) - dockRow.baseSpacing
                        let start = (DockView.isVertical ? root.height : root.width) / 2 - (total / 2)
                        return start + (index * slot) + (iconSize / 2)
                    }

                    // --- State-Aware Layout (Rule 15) ---
                    // [STABILITY]: Use stable grid when idle to prevent startup gaps.
                    // [INTERACTION]: Use recursive displacement when zooming to push neighbors.
                    x: {
                        if (DockView.isVertical) return (dockRow._maxIconThickness - width) / 2
                        if (index === 0) return 0
                        
                        let slotSize = iconSize + dockRow.baseSpacing
                        if (root._zoomIntensity <= 0) return index * slotSize
                        
                        let p = dockRepeater.itemAt(index-1)
                        return p ? p.x + p.width + (dockRow.baseSpacing * (currentScale + p.currentScale) / 2) : index * slotSize
                    }
                    y: {
                        if (!DockView.isVertical) return (dockRow._maxIconThickness - height) / 2
                        if (index === 0) return 0

                        let slotSize = iconSize + dockRow.baseSpacing
                        if (root._zoomIntensity <= 0) return index * slotSize
                        
                        let p = dockRepeater.itemAt(index-1)
                        return p ? p.y + p.height + (dockRow.baseSpacing * (currentScale + p.currentScale) / 2) : index * slotSize
                    }

                    z: (root.hoveredIndex === index) ? 1 : 0
                    isHovered: (root.hoveredIndex === index)
                    isKeyboardFocused: root.keyboardNavigating && root.hoveredIndex === index
                    iconSize: DockSettings.iconSize
                    maxZoomFactor: 1.0 + (DockSettings.maxZoomFactor - 1.0) * root._zoomIntensity
                    panelMouseX: dockPanel.mouseX
                    panelMouseInside: root._zoomIntensity > 0
                    spacing: DockSettings.iconSpacing
                    itemCenterX: virtualCenter
                    isDragSource: root._dragActive && root._dragSourceIndex === index
                    isExternalDropTarget: externalDropArea.containsDrag && externalDropArea.dropTargetIndex === index
                }
            }
        }

        Item {
            id: pinnedSeparator
            z: 1
            property int _rt: 0
            Connections {
                target: DockModel.tasksModel
                function onLayoutChanged() { pinnedSeparator._rt++ }
                function onRowsInserted() { pinnedSeparator._rt++ }
                function onRowsRemoved() { pinnedSeparator._rt++ }
            }
            property int boundaryIndex: {
                let p = pinnedSeparator._rt
                let lp = -1
                for(let i=0; i<dockRepeater.count; i++){
                    if(DockModel.isPinned(i)) lp=i
                    else break
                }
                return lp
            }
            visible: boundaryIndex >= 0 && boundaryIndex < (dockRepeater.count - 1)
            opacity: DockSettings.separatorOpacity
            property real at: Math.max(1, Math.round(DockSettings.iconSize * 0.05))
            property real al: Math.round(DockSettings.iconSize * 0.7)
            width: Math.round(!DockView.isVertical ? at : al); height: Math.round(DockView.isVertical ? at : al)
            x: { if(!visible) return 0; let i=dockRepeater.itemAt(boundaryIndex), n=dockRepeater.itemAt(boundaryIndex+1); if(!i||!n) return 0; let g=dockRow.baseSpacing*(i.currentScale+n.currentScale)/2; return Math.round(DockView.isVertical ? dockRow.x+(dockRow.width-width)/2 : dockRow.x+i.x+i.width+(g/2)-(width/2)) }
            y: { if(!visible) return 0; let i=dockRepeater.itemAt(boundaryIndex), n=dockRepeater.itemAt(boundaryIndex+1); if(!i||!n) return 0; let g=dockRow.baseSpacing*(i.currentScale+n.currentScale)/2; return Math.round(DockView.isVertical ? dockRow.y+i.y+i.height+(g/2)-(height/2) : dockRow.y+i.y+(i.height-height)/2) }
            Rectangle { anchors.fill: parent; visible: DockSettings.separatorStyle === 0; color: "white"; radius: width/2 }
            Grid {
                anchors.centerIn: parent; visible: DockSettings.separatorStyle === 1; spacing: Math.max(2, Math.round(DockSettings.iconSize * 0.15)); rows: DockView.isVertical ? 1 : 3; columns: DockView.isVertical ? 3 : 1
                Repeater { model: 3; Rectangle { width: Math.max(3, Math.round(DockSettings.iconSize * 0.12)); height: width; color: "white"; radius: width/2 } }
            }
        }

        DropArea {
            id: externalDropArea; anchors.fill: parent; property int dropTargetIndex: -1
            onEntered: function(drag) { drag.accepted = true }
            onPositionChanged: function(drag) { dropTargetIndex = root.computeExternalDropIndex(drag.x) }
            onDropped: function(drop) {
                let urls = []; if(drop.hasUrls) for(let i=0; i<drop.urls.length; i++) urls.push(drop.urls[i])
                if(urls.length === 0) { drop.accepted = false; dropTargetIndex = -1; return }
                if(DockModel.isDesktopFile(urls[0])) DockActions.addLauncher(urls[0])
                else if(dropTargetIndex >= 0) DockActions.openUrlsWithTask(dropTargetIndex, urls)
                drop.accepted = true; dropTargetIndex = -1
            }
            onExited: { dropTargetIndex = -1 }
        }
    }

    Kirigami.Icon {
        id: dragGhost; Accessible.ignored: true; visible: root._dragActive && root._dragSourceIndex >= 0
        width: DockSettings.iconSize; height: DockSettings.iconSize
        source: visible ? DockModel.iconData(root._dragSourceIndex) : ""
        x: root._dragCurrentX - width/2; y: root._dragCurrentY - height/2; opacity: 0.8; z: 200
    }

    Rectangle {
        id: dropIndicator; Accessible.ignored: true; visible: root._dragActive && root._dragTargetIndex >= 0 && root._dragTargetIndex !== root._dragSourceIndex
        width: DockView.isVertical ? DockSettings.iconSize : 2; height: DockView.isVertical ? 2 : DockSettings.iconSize; color: Kirigami.Theme.highlightColor; radius: 1; z: 150
        x: { if(!visible||root._dragTargetIndex<0) return 0; if(DockView.isVertical) return dockPanel.x+dockRow.x; let t=dockRepeater.itemAt(root._dragTargetIndex); if(!t) return 0; let ix=dockPanel.x+dockRow.x+t.x; return root._dragTargetIndex>root._dragSourceIndex ? ix+t.width+DockSettings.iconSpacing/2-1 : ix-DockSettings.iconSpacing/2-1 }
        y: { if(!visible||root._dragTargetIndex<0) return 0; if(!DockView.isVertical) return dockPanel.y+dockRow.y; let t=dockRepeater.itemAt(root._dragTargetIndex); if(!t) return 0; let iy=dockPanel.y+dockRow.y+t.y; return root._dragTargetIndex>root._dragSourceIndex ? iy+t.height+DockSettings.iconSpacing/2-1 : iy-DockSettings.iconSpacing/2-1 }
    }

    Connections {
        target: DockActions
        function onTaskLaunching(index) {
            let it = dockRepeater.itemAt(index); if(!it) return; root.announceLaunch(it.displayName)
            if(it.model.IsWindow) it.manualLaunching = true
        }
    }

    Timer { id: autoPreviewTimer; interval: 200; repeat: true; running: tooltipItem.visible && !PreviewController.visible && (!DockContextMenu || !DockContextMenu.visible); onTriggered: root._tryAutoPreview() }

    Connections {
        target: PreviewController
        function onVisibleChanged() { if(!PreviewController.visible && !dockMouseArea.containsMouse) { dockPanel.mouseX = -1; dockPanel.mouseY = -1; root._zoomActive = false; DockVisibility.setHovered(false) } }
    }

    Timer {
        id: tooltipTimer; interval: DockSettings.previewHoverDelay
        onTriggered: {
            if(root.hoveredIndex < 0 || (DockContextMenu && DockContextMenu.visible)) return
            let idx = DockModel.tasksModel.index(root.hoveredIndex, 0)
            if(DockModel.tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow) && DockSettings.previewEnabled) {
                let it = dockRepeater.itemAt(root.hoveredIndex); if(it) { let gp = it.mapToGlobal(0,0); PreviewController.showPreview(root.hoveredIndex, DockView.isVertical ? gp.y : gp.x, DockView.isVertical ? it.height : it.width) }
            } else { tooltipItem.show = true }
        }
    }

    Rectangle {
        id: tooltipItem; Accessible.ignored: true; property bool show: false; visible: show && root.hoveredName.length > 0; onVisibleChanged: if(!visible) show = false
        x: { if(root.hoveredIndex<0||root.hoveredIndex>=dockRepeater.count) return 0; let it=dockRepeater.itemAt(root.hoveredIndex); if(!it) return 0; let sp=Kirigami.Units.largeSpacing; if(DockView.edge===2) return dockPanel.x+dockPanel.width+sp; if(DockView.edge===3) return dockPanel.x-width-sp; return dockPanel.x+dockRow.x+it.x+it.width/2-width/2 }
        y: { if(root.hoveredIndex<0||root.hoveredIndex>=dockRepeater.count) return 0; let it=dockRepeater.itemAt(root.hoveredIndex); if(!it) return 0; let sp=Kirigami.Units.largeSpacing; if(DockView.edge===0) return dockPanel.y+dockPanel.height+sp; if(DockView.edge===1) return dockPanel.y-height-sp; return dockPanel.y+dockRow.y+it.y+it.height/2-height/2 }
        Kirigami.Theme.colorSet: Kirigami.Theme.Tooltip; Kirigami.Theme.inherit: false; width: tooltipLabel.implicitWidth+Kirigami.Units.largeSpacing*2; height: tooltipLabel.implicitHeight+Kirigami.Units.largeSpacing; radius: Kirigami.Units.smallSpacing; color: Kirigami.Theme.backgroundColor; z: 100
        QQC2.Label { id: tooltipLabel; anchors.centerIn: parent; text: root.hoveredName; Accessible.ignored: true }
        Connections { target: root; function onHoveredIndexChanged() { tooltipItem.show = false; tooltipTimer.stop(); if(root.hoveredIndex < 0) PreviewController.hidePreviewDelayed(); else if(!root.keyboardNavigating) { PreviewController.hidePreviewDelayed(); tooltipTimer.restart() } } }
    }

    Connections {
        target: DockModel.tasksModel
        function onRowsInserted() {
            if(root.hoveredIndex<0 || PreviewController.visible || (DockContextMenu && DockContextMenu.visible)) return
            let idx = DockModel.tasksModel.index(root.hoveredIndex,0); if(DockModel.tasksModel.data(idx, TaskManager.AbstractTasksModel.IsWindow)) { tooltipItem.show=false; let it=dockRepeater.itemAt(root.hoveredIndex); if(it){let gp=it.mapToGlobal(0,0); PreviewController.showPreview(root.hoveredIndex, DockView.isVertical?gp.y:gp.x, DockView.isVertical?it.height:it.width)}}
        }
    }
    
    Loader {
        id: settingsUnifiedLoader
        x: { if(DockSettings.edge===2) return blueprintGhost.width; if(DockSettings.edge===3) return parent.width-blueprintGhost.width-width; return (parent.width-width)/2 }
        y: { if(DockSettings.edge===0) return blueprintGhost.height; if(DockSettings.edge===1) return parent.height-blueprintGhost.height-height; return (parent.height-height)/2 }
        active: SettingsController ? SettingsController.visible : false; visible: active; source: active ? "qrc:/qml/SettingsDialog.qml" : ""
        Connections {
            target: SettingsController || null
            function onVisibleChanged() {
                if(DockVisibility) { if(SettingsController.visible){ DockVisibility.liveEditMode=true; DockVisibility.setInteracting(true) } else { DockVisibility.liveEditMode=false; DockVisibility.setInteracting(false); DockVisibility.setSettingsRect(0,0,0,0) } }
            }
        }
        onXChanged: updateSettingsHitbox(); onYChanged: updateSettingsHitbox(); onWidthChanged: updateSettingsHitbox(); onHeightChanged: updateSettingsHitbox()
        function updateSettingsHitbox() { if(item && active && DockVisibility) DockVisibility.setSettingsRect(x,y,width,height) }
        onLoaded: { if(item && SettingsController) { item.open(SettingsController.module); updateSettingsHitbox() } }
    }
}
