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

    // C++ singletons: DockView, DockModel, DockActions, DockContextMenu, DockVisibility, DockSettings, PreviewController

    // Hovered item tracking (for custom tooltip and click targeting)
    property int hoveredIndex: -1
    property string hoveredName: ""

    // Keyboard navigation state
    property bool keyboardNavigating: false

    focus: true

    function announceLaunch(name) {
        Accessible.announce(i18n("Starting %1", name), Accessible.Assertive)
    }

    function startKeyboardNavigation() {
        keyboardNavigating = true
        // Suppress tooltip and preview auto-triggers during keyboard nav
        tooltipTimer.stop()
        tooltipItem.show = false
        if (dockRepeater.count > 0) {
            if (hoveredIndex < 0)
                hoveredIndex = 0
            // Set zoom position to the focused item's center
            let item = dockRepeater.itemAt(hoveredIndex)
            if (item) {
                dockPanel.mouseX = item.itemCenterX
                dockPanel.mouseY = dockRow.y + item.height / 2
                _zoomActive = true
            }
        }
        root.forceActiveFocus()
    }

    // Retry forceActiveFocus when the window becomes active from compositor.
    // Layer-shell keyboard interactivity is async (Wayland round-trip),
    // so forceActiveFocus() may fail if called before the window is active.
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

        // Reuse zoom logic: set panelMouseX to the focused item's center
        let item = dockRepeater.itemAt(hoveredIndex)
        if (item) {
            dockPanel.mouseX = item.itemCenterX
            dockPanel.mouseY = dockRow.y + item.height / 2
            _zoomActive = true

            // Announce to screen reader
            let msg = item.displayName
            if (item.accessibleDescription)
                msg += ", " + item.accessibleDescription
            msg += ", " + i18n("%1 of %2", hoveredIndex + 1, count)
            Accessible.announce(msg, Accessible.Polite)
        }
    }

    // Announce preview thumbnail navigation (called after C++ state changes)
    function announcePreviewThumbnail() {
        let title = PreviewController.focusedThumbnailTitle()
        if (!title) return
        let msg = title
        if (PreviewController.focusedThumbnailIsActive())
            msg += ", " + i18n("Active")
        if (PreviewController.focusedThumbnailIsMinimized())
            msg += ", " + i18n("Minimized")
        msg += ", " + i18n("%1 of %2",
            PreviewController.focusedThumbnailIndex + 1,
            PreviewController.previewThumbnailCount())
        Accessible.announce(msg, Accessible.Polite)
    }

    Keys.onPressed: function(event) {
        if (!keyboardNavigating) return

        // Preview keyboard mode: route keys to PreviewController
        if (PreviewController.previewKeyboardActive) {
            // Thumbnail navigation follows dock axis (Left/Right for horizontal, Up/Down for vertical)
            let thumbPrev = DockView.isVertical ? Qt.Key_Up : Qt.Key_Left
            let thumbNext = DockView.isVertical ? Qt.Key_Down : Qt.Key_Right
            // Return to dock: key toward the dock edge
            let backKey = DockView.isVertical
                ? (DockView.edge === 2 ? Qt.Key_Left : Qt.Key_Right)
                : (DockView.edge === 0 ? Qt.Key_Up : Qt.Key_Down)

            switch (event.key) {
            case thumbPrev:
                PreviewController.navigatePreviewThumbnail(-1)
                announcePreviewThumbnail()
                event.accepted = true
                break
            case thumbNext:
                PreviewController.navigatePreviewThumbnail(1)
                announcePreviewThumbnail()
                event.accepted = true
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                PreviewController.activatePreviewThumbnail()
                endKeyboardNavigation()
                event.accepted = true
                break
            case Qt.Key_Delete:
                PreviewController.closePreviewThumbnail()
                announcePreviewThumbnail()
                event.accepted = true
                break
            case Qt.Key_Escape:
            case backKey:
                // Return to dock navigation (keep preview visible)
                PreviewController.endPreviewKeyboardNav()
                event.accepted = true
                break
            }
            return
        }

        // Normal dock navigation — keys depend on orientation
        let navPrev = DockView.isVertical ? Qt.Key_Up : Qt.Key_Left
        let navNext = DockView.isVertical ? Qt.Key_Down : Qt.Key_Right
        // Preview open key: perpendicular to dock axis, away from edge
        let previewKey = DockView.isVertical
            ? (DockView.edge === 2 ? Qt.Key_Right : Qt.Key_Left)   // Left→Right, Right→Left
            : (DockView.edge === 0 ? Qt.Key_Down : Qt.Key_Up)      // Top→Down, Bottom→Up (was Key_Down for bottom)

        switch (event.key) {
        case navPrev:
            navigateItem(-1)
            event.accepted = true
            break
        case navNext:
            navigateItem(1)
            event.accepted = true
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            if (hoveredIndex >= 0) {
                DockActions.activate(hoveredIndex)
                endKeyboardNavigation()
            }
            event.accepted = true
            break
        case Qt.Key_Escape:
            // If preview is visible, hide it first
            if (PreviewController.visible) {
                PreviewController.hidePreview()
            }
            endKeyboardNavigation()
            event.accepted = true
            break
        case previewKey:
            // Open preview for the focused item (if it has windows)
            if (hoveredIndex >= 0) {
                let idx = DockModel.tasksModel.index(hoveredIndex, 0)
                let isWindow = DockModel.tasksModel.data(
                    idx, TaskManager.AbstractTasksModel.IsWindow)
                if (isWindow) {
                    let item = dockRepeater.itemAt(hoveredIndex)
                    if (item) {
                        let globalPos = item.mapToGlobal(0, 0)
                        let pos = DockView.isVertical ? globalPos.y : globalPos.x
                        let ext = DockView.isVertical ? item.height : item.width
                        PreviewController.showPreview(hoveredIndex, pos, ext)
                        PreviewController.startPreviewKeyboardNav()
                        announcePreviewThumbnail()
                    }
                }
            }
            event.accepted = true
            break
        case Qt.Key_Menu:
            if (hoveredIndex >= 0) {
                DockContextMenu.showForTask(hoveredIndex)
            }
            event.accepted = true
            break
        }
    }

    // Hysteresis flag: once zoom activates (mouse on an icon), it stays active
    // until the mouse leaves the panel zone entirely. This prevents rapid zoom
    // on/off flickering when moving between icons through tiny gaps.
    property bool _zoomActive: false

    // --- Internal drag state ---
    property bool _dragActive: false
    property int _dragSourceIndex: -1
    property int _dragTargetIndex: -1
    property real _dragCurrentX: 0
    property real _dragCurrentY: 0
    property real _dragStartX: 0
    property real _dragStartY: 0
    property bool _dragPending: false      // press-hold started but not yet moved enough
    property bool _dragWasActive: false     // was drag active during this press cycle (suppress click)
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

    // Compute the target index where the dragged item would be inserted.
    // Compares mouse X with each icon's center X (including the source so
    // that dropping near the original position keeps the item in place).
    function computeDropIndex(globalMousePos) {
        if (DockView.isVertical) {
            let panelRelY = globalMousePos - dockPanel.y
            let items = []
            for (let i = 0; i < dockRepeater.count; i++) {
                let item = dockRepeater.itemAt(i)
                if (!item) continue
                items.push({ idx: i, cx: item.y + item.height / 2 + dockRow.y })
            }
            if (items.length === 0) return -1
            let bestIdx = items[0].idx
            let bestDist = Math.abs(panelRelY - items[0].cx)
            for (let j = 1; j < items.length; j++) {
                let d = Math.abs(panelRelY - items[j].cx)
                if (d < bestDist) { bestDist = d; bestIdx = items[j].idx }
            }
            return bestIdx
        } else {
            let panelRelX = globalMousePos - dockPanel.x
            let items = []
            for (let i = 0; i < dockRepeater.count; i++) {
                let item = dockRepeater.itemAt(i)
                if (!item) continue
                items.push({ idx: i, cx: item.x + item.width / 2 + dockRow.x })
            }
            if (items.length === 0) return -1
            let bestIdx = items[0].idx
            let bestDist = Math.abs(panelRelX - items[0].cx)
            for (let j = 1; j < items.length; j++) {
                let d = Math.abs(panelRelX - items[j].cx)
                if (d < bestDist) { bestDist = d; bestIdx = items[j].idx }
            }
            return bestIdx
        }
    }

    // Compute which icon is under an external drop cursor (unscaled hit test).
    function computeExternalDropIndex(dropX) {
        for (let i = 0; i < dockRepeater.count; i++) {
            let item = dockRepeater.itemAt(i)
            if (!item) continue
            let itemLeft = dockRow.x + item.x
            let itemRight = itemLeft + item.width
            if (dropX >= itemLeft && dropX <= itemRight) return i
        }
        return -1
    }

    function isDesktopFileUrl(url) {
        let str = url.toString()
        return str.endsWith(".desktop") || str.startsWith("applications:")
    }

    function _tryAutoPreview() {
        if (!DockSettings.previewEnabled) return
        if (hoveredIndex < 0 || PreviewController.visible) return
        let idx = DockModel.tasksModel.index(hoveredIndex, 0)
        let isWindow = DockModel.tasksModel.data(
            idx, TaskManager.AbstractTasksModel.IsWindow)
        if (isWindow) {
            tooltipItem.show = false
            tooltipTimer.stop()
            let item = dockRepeater.itemAt(hoveredIndex)
            if (item) {
                let globalPos = item.mapToGlobal(0, 0)
                let pos = DockView.isVertical ? globalPos.y : globalPos.x
                let ext = DockView.isVertical ? item.height : item.width
                PreviewController.showPreview(hoveredIndex, pos, ext)
            }
        }
    }

    // Throttling property to stop the terminal spam
    function updateHoveredItem() {
        if (dockPanel.mouseX === -9999) {
            hoveredIndex = -1; hoveredName = ""; _zoomActive = false;
            return;
        }

        let mPos = DockView.isVertical ? dockMouseArea.mouseY : dockMouseArea.mouseX;
        let bestIndex = -1;

        // Find exactly where the first icon starts visually on the screen
        let firstItem = dockRepeater.itemAt(0);
        if (!firstItem) return;
        
        let startPos = firstItem.mapToItem(dockMouseArea, 0, 0);
        let currentEdge = DockView.isVertical ? startPos.y : startPos.x;

        // Build the timeline using your idea: the actual, current zoomed sizes
        for (let i = 0; i < dockRepeater.count; i++) {
            let item = dockRepeater.itemAt(i);
            if (!item) continue;

            // item.width/height is already mathematically bound to the zoom factor!
            let itemSize = DockView.isVertical ? item.height : item.width;
            
            // Push the boundary forward by the exact size of this zoomed icon
            currentEdge += itemSize;

            // If the mouse hasn't crossed this swollen boundary yet, this is our icon
            if (mPos <= currentEdge) {
                bestIndex = i;
                break;
            }
            
            // Add the spacing before checking the next icon's territory
            currentEdge += DockSettings.iconSpacing;
        }

        // Catch-all for the far edges
        if (bestIndex === -1 && dockRepeater.count > 0) {
            bestIndex = dockRepeater.count - 1;
        }

        if (bestIndex >= 0) {
            _zoomActive = true;
            if (hoveredIndex !== bestIndex) {
                hoveredIndex = bestIndex;
                hoveredName = dockRepeater.itemAt(bestIndex).displayName;
                tooltipTimer.restart();
            }
        } else {
            hoveredIndex = -1; hoveredName = ""; _zoomActive = false;
        }
    }

    MouseArea {
        id: dockMouseArea
        Accessible.ignored: true
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        // Track hover state for visibility controller
        onEntered: DockVisibility.setHovered(true)
        onExited: {
            // Keep zoom state when preview is visible (dock→preview mouse transition)
            if (!PreviewController.visible) {
                dockPanel.mouseX = -1
                dockPanel.mouseY = -1
                root._zoomActive = false
            }
            root.hoveredIndex = -1
            root.hoveredName = ""
            // Hide preview with delay (allows mouse to move to preview surface)
            PreviewController.hidePreviewDelayed()
            // Drag-out: if an active drag leaves the dock, unpin the launcher
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
            // preview visible이면 dock hover 상태 유지 (입력 영역 축소 방지)
            if (!PreviewController.visible) {
                DockVisibility.setHovered(false)
            }
        }

        // Start drag hold timer on left-button press
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
                // Execute reorder with Auto-Sort
                if (root._dragTargetIndex >= 0 && root._dragTargetIndex !== root._dragSourceIndex) {
                    let sourceIsPinned = DockModel.isPinned(root._dragSourceIndex);
                    let targetIsPinned = DockModel.isPinned(root._dragTargetIndex);
                    let finalTarget = root._dragTargetIndex;
                        
                    // Enforce the boundary
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
                // Reset drag state
                root._dragActive = false
                root._dragPending = false
                root._dragSourceIndex = -1
                root._dragTargetIndex = -1
                DockVisibility.setInteracting(false)
            } else {
                root._dragPending = false
            }
        }

        // Click handling: uses hoveredIndex from scaled hit testing
        // so clicks work correctly on zoomed icons
        onClicked: function(mouse) {
            // Suppress click if drag was active during this press cycle
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

        // Mouse wheel: cycle through child windows of the hovered app
        onWheel: function(wheel) {
            if (root.hoveredIndex < 0) return
            if (wheel.angleDelta.y > 0) {
                DockActions.cycleWindows(root.hoveredIndex, false)
            } else if (wheel.angleDelta.y < 0) {
                DockActions.cycleWindows(root.hoveredIndex, true)
            }
        }

        // Track mouse position for parabolic zoom + drag handling
	onPositionChanged: function(mouse) {
           // 1. Calculate our dynamic reach
           let maxIconHeight = DockSettings.iconSize * DockSettings.maxZoomFactor
           let dynamicBuffer = 10 + (30 * Math.max(0, DockSettings.maxZoomFactor - 1.0))
           let totalReach = maxIconHeight + dynamicBuffer
           
           let isOutside = false

           // 2. Check boundaries based on the current Edge
           // Edge 0: Top | Edge 1: Bottom | Edge 2: Left | Edge 3: Right
           if (DockView.edge === 0) {        // TOP
               isOutside = mouse.y > totalReach
           } else if (DockView.edge === 1) { // BOTTOM
               isOutside = mouse.y < (dockMouseArea.height - totalReach)
           } else if (DockView.edge === 2) { // LEFT
               isOutside = mouse.x > totalReach
           } else if (DockView.edge === 3) { // RIGHT
               isOutside = mouse.x < (dockMouseArea.width - totalReach)
           }

           // 3. The "Reset" Logic
           if (isOutside) {
               if (!PreviewController.visible) {
                   dockPanel.mouseX = -1
                   dockPanel.mouseY = -1
                   root._zoomActive = false
               }
               root.hoveredIndex = -1
               root.hoveredName = ""
               debugHitbox.visible = false
               DockVisibility.setHovered(false)
               return 
           } else {
               DockVisibility.setHovered(true)
           } // --- END UNIVERSAL FIREWALL ---

           if (root.keyboardNavigating) {
               root.keyboardNavigating = false
               DockVisibility.setKeyboardActive(false)
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
                   return 
               }

               let safeReach = DockSettings.iconSize * DockSettings.maxZoomFactor + 20
               let inZone = false
               
	       if (DockView.isVertical) {
                     let panelNear = dockPanel.x
                     let panelFar = dockPanel.x + dockPanel.width
                     inZone = (DockView.edge === 2)
                         ? (mouse.x >= panelNear - 20 && mouse.x <= panelNear + safeReach)
                         : (mouse.x >= panelFar - safeReach && mouse.x <= panelFar + 20)
                     if (inZone) {
                         // USE ABSOLUTE COORDINATES (Swap for vertical alignment)
                         dockPanel.mouseX = mouse.y 
                         dockPanel.mouseY = mouse.x 
                     }
                 } else {
                     let panelTop = dockPanel.y
                     let panelBottom = dockPanel.y + dockPanel.height
                     inZone = (DockView.edge === 0)
                         ? (mouse.y >= panelTop - 20 && mouse.y <= panelTop + safeReach)
                         : (mouse.y >= panelBottom - safeReach && mouse.y <= panelBottom + 20)
                     if (inZone) {
                         // USE ABSOLUTE COORDINATES
                         dockPanel.mouseX = mouse.x 
                         dockPanel.mouseY = mouse.y 
                     }
                 }

                 if (!inZone) {
                     dockPanel.mouseX = -9999
                     dockPanel.mouseY = -9999
                 }
               
               root.updateHoveredItem()
        }
    }

    // --- DEBUG HITBOX LAYER ---
    Rectangle {
        id: debugHitbox
        parent: dockMouseArea
        color: "#55ff0000" // Transparent Red
        border.color: "red"
        border.width: 2
        visible: false // Change to 'true' to see the box!
        
        // This box will jump to the current hovered icon's boundaries
        x: 0; y: 0; width: 0; height: 0 
    }

    // Projective SDF drop shadow via ShaderEffect.
    // Each pixel projects a ray from the light source through the ground plane
    // to determine shadow intensity — no blur/offset needed.
    // Shadow renders within available surface space; overflow clips naturally at screen edges.
    ShaderEffect {
        id: dockShadow
        visible: DockSettings.shadowEnabled
        z: dockPanel.z - 1
        Accessible.ignored: true

        // Shader uniforms (names must match outer_shadow.frag UBO fields)
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
        property real margin: _margin

        // Compute shadow margin: how far the shadow can extend beyond the panel
        // Takes the larger of physical projection margin and Gaussian 3-sigma spread
        property real _margin: {
            let denom = Math.max(lightZ - elevation, 1)
            let lightDist = Math.sqrt(lightX * lightX + lightY * lightY)
            let physicalMargin = (lightDist + lightRadius) * elevation / denom
            // Gaussian decays to ~0.1% at 3*sigma
            let softnessMargin = lightRadius * 3.0
	    return Math.min(Math.max(physicalMargin, softnessMargin) + 10, 64)
        }

        // Centered on panel, expanded by margin on each side
        x: dockPanel.x - _margin
        y: dockPanel.y - _margin
        width: dockPanel.width + _margin * 2
        height: dockPanel.height + _margin * 2

        fragmentShader: "qrc:/qml/shaders/outer_shadow.frag.qsb"
    }

    // --- INDEPENDENT GHOST BLUEPRINT ---
       Item {
           id: blueprintGhost
           // Safe binding: checks if DockVisibility exists before reading it
           visible: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode
           z: dockPanel.z - 1
           
              // Multi-directional dimensions and snapping
	      property real screenW: Screen.width
              property real screenH: Screen.height
              property bool isVert: DockSettings.edge === 2 || DockSettings.edge === 3
              
	      width: isVert ? 180 : parent.width
              height: isVert ? parent.height : 180
              
              x: DockSettings.edge === 3 ? parent.width - width : 0
              y: DockSettings.edge === 1 ? parent.height - height : 0

           enabled: false
           clip: false

           Rectangle {
                id: blueprintBg
                anchors.fill: parent
		color: "transparent"
                radius: 0
                border.color: Qt.rgba(1, 1, 1, 0.3)
                border.width: 1
                clip: true 

		Canvas {
                   id: blueprintCanvas
                   anchors.fill: parent
                   opacity: 0.4
                   
                   // Synchronize the internal drawing buffer with the actual size
                   onWidthChanged: { canvasSize = Qt.size(width, height); requestPaint() }
                   onHeightChanged: { canvasSize = Qt.size(width, height); requestPaint() }
                   
                   onPaint: {
                       var ctx = getContext("2d");
                       
                       // 1. Clear the canvas completely so it's 100% transparent glass
                       ctx.clearRect(0, 0, width, height);

                       // 2. Define the Blueprint Proportions
                       let minorSize = 10; // Small background squares
                       let majorSize = 50; // Large framing squares
                       let centerX = width / 2;
                       let centerY = height / 2;

                       // ==========================================
                       // LAYER 1: THE MINOR GRID (Faint & Thin)
                       // ==========================================
                       ctx.beginPath();
                       ctx.lineWidth = 0.5;
                       ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
                       
                       for (let x = centerX % minorSize; x <= width; x += minorSize) {
                           ctx.moveTo(Math.floor(x) + 0.5, 0);
                           ctx.lineTo(Math.floor(x) + 0.5, height);
                       }
                       for (let y = centerY % minorSize; y <= height; y += minorSize) {
                           ctx.moveTo(0, Math.floor(y) + 0.5);
                           ctx.lineTo(width, Math.floor(y) + 0.5);
                       }
                       ctx.stroke();

                       // ==========================================
                       // LAYER 2: THE MAJOR GRID (Bolder & Wider)
                       // ==========================================
                       ctx.beginPath();
                       ctx.lineWidth = 1.0;
                       ctx.strokeStyle = "rgba(255, 255, 255, 0.40)";
                       
                       for (let x = centerX % majorSize; x <= width; x += majorSize) {
                           ctx.moveTo(Math.floor(x) + 0.5, 0);
                           ctx.lineTo(Math.floor(x) + 0.5, height);
                       }
                       for (let y = centerY % majorSize; y <= height; y += majorSize) {
                           ctx.moveTo(0, Math.floor(y) + 0.5);
                           ctx.lineTo(width, Math.floor(y) + 0.5);
                       }
                       ctx.stroke();
                   } 
	   }
   }
   }
        // The visible dock panel (positioned per edge, fits content)
        Rectangle {
            id: dockPanel
           visible: opacity > 0.01

	   // --- THE SPAM-FREE ULTIMATE DEBUGGER ---
           Timer {
               id: ultimateDebugger
               interval: 100
               repeat: true
               // ONLY run if the terminal command includes our custom flag
               running: Qt.application.arguments.indexOf("--debug-geom") !== -1
               property string lastState: ""

	       onTriggered: {
                  if (hoveredIndex === -1) {
                      if (lastState !== "IDLE") {
                          console.log("\x1b[90m[DEBUG] Dock Idle (No Hover)\x1b[0m");
                          lastState = "IDLE";
                      }
                      return;
                  }

                  let item = dockRepeater.itemAt(hoveredIndex);
                  if (!item) return;

                  let pX = Math.round(dockPanel.x);
                  let pY = Math.round(dockPanel.y);
                  let pW = Math.round(dockPanel.width);
                  let pH = Math.round(dockPanel.height);

                  let iX = Math.round(item.x);
                  let iW = Math.round(item.width);
                  
                  // Exposing the Fight: Target vs Actual
                  let zTarget = item.zoomFactor.toFixed(2);
                  let zActual = item.currentScale.toFixed(2);
                  
                  let mX = Math.round(item.panelMouseX);
                  let cX = Math.round(item.itemCenterX);

                  // Add zActual to the state string so it prints every time the animation changes
                  let currentState = `${hoveredIndex}-${pW}-${pX}-${iW}-${iX}-${zTarget}-${zActual}-${mX}-${cX}`;

                  if (currentState !== lastState) {
                      console.log(`\x1b[36m[PANEL]\x1b[0m Pos:(${pX}, ${pY}) Size:${pW}x${pH}  >>>  \x1b[32m[ICON ${hoveredIndex}]\x1b[0m Mouse:${mX} Center:${cX} | Target Zoom:${zTarget}x \x1b[33mActual Zoom:${zActual}x\x1b[0m`);
                      lastState = currentState;
                  }
              }
           }

           // Create a local alias for Edit Mode that won't crash on startup
           property bool isEditMode: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode

	   // For Vertical Docks: Width is Thickness (Slider), Height is Length (Instant Sync)
	   width: {
              if (!DockView.isVertical) return _actualContentWidth;
              // THE CEILING: Cap panel thickness so it never exceeds icons + padding
              return Math.min(DockSettings.panelHeight, dockRow.animatedContentWidth + 12);
          }

          height: {
              if (DockView.isVertical) return _actualContentHeight;
              // THE CEILING: Cap panel thickness so it never exceeds icons + padding
              return Math.min(DockSettings.panelHeight, dockRow.animatedContentHeight + 12);
          }
           
           // CORNERS
           radius: DockSettings.cornerRadius

	   // BASE PANEL COLOR
            color: {
                let style = DockSettings.backgroundStyle;
                let c = DockView.backgroundColor; // Default to Adaptive

                // Style 2 is Acrylic. The base panel MUST be transparent so the shader can do its job.
                if (style === 2) {
                    return "transparent";
                }
                
                // Style 1 is Solid Color.
                if (style === 1) {
                    // Check if the user toggled the "Use System Accent Color" override
                    c = DockSettings.useSystemColor ? DockView.backgroundColor : Qt.color(DockSettings.tintColor);
                }
                
                // For Style 0 (Adaptive) and Style 1 (Solid), apply the universal opacity slider
                return Qt.rgba(c.r, c.g, c.b, DockSettings.backgroundOpacity);
            }

           // POSITIONING: Grow Upwards
           x: DockView.isVertical ? _panelEdgePos : (parent.width - width) / 2
           y: DockView.isVertical ? (parent.height - height) / 2 : _panelEdgePos

           property real _panelEdgePos: {
              let fp = DockView.floatingPadding
              let sp = Kirigami.Units.largeSpacing
              
              // This is the new setting you created!
              let peekSize = DockSettings.hidePeekSize 
              
              if (typeof DockVisibility === "undefined") return 0;

              switch (DockView.edge) {
              case 0: // Top
                  return DockVisibility.dockVisible ? fp : -(height - peekSize)
              case 1: // Bottom
                  return DockVisibility.dockVisible ? (parent.height - height - fp) : (parent.height + height)
              case 2: // Left
                  return DockVisibility.dockVisible ? fp : -(width - peekSize)
              case 3: // Right
                  return DockVisibility.dockVisible ? (parent.width - width - fp) : (parent.width - peekSize)
              }
              return 0
          }


        // Shader handles rounded corners via SDF mask — no clip wrapper needed.
	// Acrylic overlay: tint + noise via GPU shader
        ShaderEffect {
            id: acrylicShader
            anchors.fill: parent
            z: 0
            // UPDATE: 2 is our new Acrylic index!
            visible: DockSettings.backgroundStyle === 2

            // Define the base color and universally inject the custom opacity
            property color _activeTint: {
                let c = DockView.backgroundColor;
                
                // If Solid (1) or Acrylic (2) AND custom color is enabled
                if (DockSettings.backgroundStyle > 0 && !DockSettings.useSystemColor) {
                    c = Qt.color(DockSettings.tintColor);
                }
                
                // Return the color with our universal opacity slider applied
                return Qt.rgba(c.r, c.g, c.b, DockSettings.backgroundOpacity);
            }

            property real tintR: _activeTint.r
            property real tintG: _activeTint.g
            property real tintB: _activeTint.b
            
            // We can just grab the alpha directly from _activeTint now!
            property real tintOpacity: _activeTint.a
            
            property real noiseStrength: 0.02
            property real resX: width
           property real resY: height
           property real cornerRadius: dockPanel.radius
           fragmentShader: "qrc:/qml/shaders/acrylic_overlay.frag.qsb"
       }

        // Delay enabling animations until after initial layout to avoid startup flicker
        property bool animationsReady: false
        Component.onCompleted: Qt.callLater(function() { animationsReady = true })

        /*Behavior on width {
            enabled: dockPanel.animationsReady
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        } */

        /*Behavior on height {
            enabled: dockPanel.animationsReady && DockView.isVertical
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }*/

        Behavior on x {
            enabled: dockPanel.animationsReady && DockView.isVertical
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on y {
            enabled: dockPanel.animationsReady && !DockView.isVertical
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        // Fade animation
	opacity: DockVisibility.dockVisible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.longDuration }
        }

	// Mouse position relative to the root surface, -9999 when outside
           property real mouseX: -9999
           property real mouseY: -9999
           // Zoom activates when mouse hits an icon (_zoomActive=true) and stays
           // active until mouse leaves the panel zone (mouseX !== -9999). 
           // Zoom is disabled during drag so all icons return to base scale.
           property bool mouseInside: mouseX !== -9999 && root._zoomActive && !root._dragActive

	// This calculates the size of ONLY the icons + padding
	property real _actualContentWidth: Math.max(dockRow.implicitWidth + Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 6)
        property real _actualContentHeight: Math.max(dockRow.animatedContentHeight + 6, Kirigami.Units.gridUnit * 6)

	    // This function calculates the "Ghost" area for the OS
	    function updateWaylandInputRegion() {
    if (typeof DockVisibility === "undefined") return;
    
    // Tell OS where the blur goes
    DockVisibility.setPanelRect(dockPanel.x, dockPanel.y, dockPanel.width, dockPanel.height);
    
    // Tell OS where the mouse works (2.5x icon size)
    let maxReach = DockSettings.iconSize * 2.5;
    
    // Even though the C++ function name says "Height," the backend 
    // uses this number as the "depth" away from the screen edge.
    DockVisibility.setZoomOverflowHeight(maxReach);
}

// Trigger the update AND our debug print whenever the panel moves
                onXChanged: { updateWaylandInputRegion(); printGeometry(); }
                onYChanged: { updateWaylandInputRegion(); printGeometry(); }
                onWidthChanged: { updateWaylandInputRegion(); printGeometry(); }
                onHeightChanged: { updateWaylandInputRegion(); printGeometry(); }

        function printGeometry() {
        }

	    // Main icon layout (Flow switches between horizontal/vertical)
            Flow {
                id: dockRow
		z: 2
                flow: DockView.isVertical ? Flow.TopToBottom : Flow.LeftToRight

		spacing: DockSettings.iconSpacing

                // GRAVITY: Align items to the bottom/right edge of the Flow container
                layoutDirection: Qt.LeftToRight

                // Animate content extent to sync centering with panel size animation.
                property real animatedContentWidth: implicitWidth
                property real animatedContentHeight: implicitHeight
                
                Behavior on animatedContentWidth {
                    enabled: dockPanel.animationsReady && !DockView.isVertical
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on animatedContentHeight {
                    enabled: dockPanel.animationsReady && DockView.isVertical
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
                
		// DYNAMIC GROUNDING (Supports all 4 Edges)
                 x: {
                     if (DockView.isVertical) {
                         // If Left-aligned (Edge 2), stick to left with 6px gap
                         if (DockView.edge === 2) return 6;
                         // If Right-aligned (Edge 3), stick to right
                         if (DockView.edge === 3) return dockPanel.width - animatedContentWidth - 6;
                     }
                     // If horizontal, center the row
                     return (dockPanel.width - animatedContentWidth) / 2;
                 }
                 y: {
                     if (!DockView.isVertical) {
                         // If Bottom-aligned (Edge 1), stick to bottom with 6px gap
                         if (DockView.edge === 1) return dockPanel.height - animatedContentHeight - 6;
                         // If Top-aligned (Edge 0), stick to top with 6px gap
                         if (DockView.edge === 0) return 6;
                     }
                     // If vertical, center the row vertically
                     return (dockPanel.height - animatedContentHeight) / 2;
                 }

            // Animate existing items displaced by add/remove within the Flow.
            // Disabled during hover zoom (mouseInside) to avoid lagging sibling
            // repositioning — zoom needs immediate response.
            move: Transition {
                enabled: dockPanel.animationsReady && !dockPanel.mouseInside
                NumberAnimation {
                    properties: "x,y"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Repeater {
                id: dockRepeater
                model: DockModel.tasksModel

                AppIcon {
                    // index and model are injected by Repeater into
                    // AppIcon's own required properties

                    z: (root.hoveredIndex === index) ? 1 : 0
                    isKeyboardFocused: root.keyboardNavigating && root.hoveredIndex === index
                    iconSize: DockSettings.iconSize
                    maxZoomFactor: DockSettings.maxZoomFactor
		    // --- STRICT ABSOLUTE MATH ---
                         panelMouseX: DockView.isVertical ? dockMouseArea.mouseY : dockMouseArea.mouseX
                         panelMouseInside: dockPanel.mouseInside
                         spacing: DockSettings.iconSpacing

			 // THE GOLDEN JITTER FIX:
                             itemCenterX: {
                                 let slot = iconSize + spacing;
                                 let totalUnscaled = (dockRepeater.count * slot) - spacing;
                                 let center = DockView.isVertical ? root.height / 2 : root.width / 2;
                                 let unscaledIconCenter = (index * slot) + (iconSize / 2) - (totalUnscaled / 2);
                                 return center + unscaledIconCenter;
                             }

                    // Drag and drop visual feedback
                    isDragSource: root._dragActive && root._dragSourceIndex === index
                    isExternalDropTarget: externalDropArea.containsDrag
                                          && externalDropArea.dropTargetIndex === index
                }
            }
    } // This brace closes the Flow (dockRow)

    // --- The Multi-Style Smart Separator ---
      Item {
          id: pinnedSeparator
          z: 1 
          
          property int _refreshTrigger: 0
          Connections {
              target: DockModel.tasksModel
              function onLayoutChanged() { pinnedSeparator._refreshTrigger++ }
              function onRowsInserted() { pinnedSeparator._refreshTrigger++ }
              function onRowsRemoved() { pinnedSeparator._refreshTrigger++ }
          }

          property int boundaryIndex: {
              let _poke = _refreshTrigger;
              let lastPinned = -1;
              for (let i = 0; i < dockRepeater.count; i++) {
                  if (DockModel.isPinned(i)) lastPinned = i;
                  else break;
              }
              return lastPinned;
          }

          visible: boundaryIndex >= 0 && boundaryIndex < (dockRepeater.count - 1)
          opacity: DockSettings.separatorOpacity

          // --- STRICT PROPORTIONAL MATH ---
          // Line thickness is 6% of icon, Length is 70% of icon
	  property real autoThickness: Math.max(1, Math.round(DockSettings.iconSize * 0.05))
	  property real autoLength: Math.round(DockSettings.iconSize * 0.7)
          
	  width: Math.round(!DockView.isVertical ? autoThickness : autoLength)
	  height: Math.round(DockView.isVertical ? autoThickness : autoLength)

          x: {
              if (!visible) return 0;
              let item = dockRepeater.itemAt(boundaryIndex);
              if (!item) return 0;
              return Math.round(DockView.isVertical 
                  ? dockRow.x + (dockRow.width - width) / 2 
                  : dockRow.x + item.x + item.width + (DockSettings.iconSpacing / 2) - (width / 2));
          }
          y: {
              if (!visible) return 0;
              let item = dockRepeater.itemAt(boundaryIndex);
              if (!item) return 0;
              return Math.round(DockView.isVertical 
                  ? dockRow.y + item.y + item.height + (DockSettings.iconSpacing / 2) - (height / 2)
                  : dockRow.y + item.y + (item.height - height) / 2);
          }

          // Style 0: Classic Line
          Rectangle {
              anchors.fill: parent
              visible: DockSettings.separatorStyle === 0
              color: "white" 
              radius: width / 2 // Pill-shaped ends look softer and more premium
          }

          // Style 1: Blueprint Dots
          Grid {
              id: dotsGrid
              anchors.centerIn: parent
              visible: DockSettings.separatorStyle === 1
              
              // Gap is 15% of icon size
              spacing: Math.max(2, Math.round(DockSettings.iconSize * 0.15))
              rows: DockView.isVertical ? 1 : 3
              columns: DockView.isVertical ? 3 : 1

              Repeater {
                  // A professional dot separator is almost always exactly 3 dots
                  model: 3 
                  
                  Rectangle { 
                      // Dot size is 12% of icon size
                      width: Math.max(3, Math.round(DockSettings.iconSize * 0.12))
                      height: width
                      color: "white" 
                      radius: width / 2 
                  }
              }
          }
      }

        // External drag and drop (files, .desktop, URLs from other apps)
        DropArea {
            id: externalDropArea
            anchors.fill: parent
            property int dropTargetIndex: -1

            onEntered: function(drag) {
                drag.accepted = true
            }

            onPositionChanged: function(drag) {
                dropTargetIndex = root.computeExternalDropIndex(drag.x)
            }

            onDropped: function(drop) {
                let urls = []
                if (drop.hasUrls) {
                    for (let i = 0; i < drop.urls.length; i++) {
                        urls.push(drop.urls[i])
                    }
                }

                if (urls.length === 0) {
                    drop.accepted = false
                    dropTargetIndex = -1
                    return
                }

                // Check first URL to classify the drop
                let firstUrl = urls[0]
                let isLauncher = DockModel.isDesktopFile(firstUrl)

                if (isLauncher) {
                    // .desktop file → add as pinned launcher
                    DockActions.addLauncher(firstUrl)
                } else if (dropTargetIndex >= 0) {
                    // Regular file(s) on an app icon → open with that app
                    DockActions.openUrlsWithTask(dropTargetIndex, urls)
                }
                // else: regular file on dock background → no action

                drop.accepted = true
                dropTargetIndex = -1
            }

            onExited: {
                dropTargetIndex = -1
            }
        }
    }

    // Floating drag ghost icon (follows cursor during internal reorder drag)
    Kirigami.Icon {
        id: dragGhost
        Accessible.ignored: true
        visible: root._dragActive && root._dragSourceIndex >= 0
        width: DockSettings.iconSize
        height: DockSettings.iconSize
        source: {
            if (!visible) return ""
            return DockModel.iconData(root._dragSourceIndex)
        }
        x: root._dragCurrentX - width / 2
        y: root._dragCurrentY - height / 2
        opacity: 0.8
        z: 200
    }

    // Drop position indicator line (shown during internal reorder drag)
    Rectangle {
        id: dropIndicator
        Accessible.ignored: true
        visible: root._dragActive && root._dragTargetIndex >= 0
                 && root._dragTargetIndex !== root._dragSourceIndex
        width: DockView.isVertical ? DockSettings.iconSize : 2
        height: DockView.isVertical ? 2 : DockSettings.iconSize
        color: Kirigami.Theme.highlightColor
        radius: 1
        z: 150

        x: {
            if (!visible || root._dragTargetIndex < 0) return 0
            if (DockView.isVertical) return dockPanel.x + dockRow.x
            let targetItem = dockRepeater.itemAt(root._dragTargetIndex)
            if (!targetItem) return 0
            let itemX = dockPanel.x + dockRow.x + targetItem.x
            if (root._dragTargetIndex > root._dragSourceIndex) {
                return itemX + targetItem.width + DockSettings.iconSpacing / 2 - 1
            } else {
                return itemX - DockSettings.iconSpacing / 2 - 1
            }
        }
        y: {
            if (!visible || root._dragTargetIndex < 0) return 0
            if (!DockView.isVertical) return dockPanel.y + dockRow.y
            let targetItem = dockRepeater.itemAt(root._dragTargetIndex)
            if (!targetItem) return 0
            let itemY = dockPanel.y + dockRow.y + targetItem.y
            if (root._dragTargetIndex > root._dragSourceIndex) {
                return itemY + targetItem.height + DockSettings.iconSpacing / 2 - 1
            } else {
                return itemY - DockSettings.iconSpacing / 2 - 1
            }
        }
    }

    // Handle launch bounce trigger from C++ signal.
    // Only sets manualLaunching for already-running apps (IsWindow): their
    // delegate stays alive, so manualLaunching persists through the bounce.
    // For launchers (first launch), we skip manualLaunching entirely:
    // IsStartup fires within ~5ms and, being model data, survives the
    // delegate recreation caused by hideActivatedLaunchers.
    Connections {
        target: DockActions
        function onTaskLaunching(index) {
            let item = dockRepeater.itemAt(index)
            if (!item) return

            // Announce launch to screen reader (must call on root Item, not Connections)
            root.announceLaunch(item.displayName)

            // Skip for launcher items — IsStartup will drive the bounce.
            if (!item.model.IsWindow) return

            item.manualLaunching = true
        }
    }

    // Auto-trigger preview when a hovered launcher becomes a window.
    // Polls only while the text tooltip is visible (launcher hover state).
    // When IsWindow becomes true → switches from text tooltip to preview popup.
    Timer {
        id: autoPreviewTimer
        interval: 200
        repeat: true
        running: tooltipItem.visible && !PreviewController.visible
        onTriggered: root._tryAutoPreview()
    }

    // Sync dock hover state when preview closes:
    // If preview was keeping dock hovered and mouse is no longer on dock,
    // release hover so dock can hide.
    Connections {
        target: PreviewController
        function onVisibleChanged() {
            if (!PreviewController.visible && !dockMouseArea.containsMouse) {
                // Preview closed and mouse not on dock → release zoom smoothly
                dockPanel.mouseX = -1
                dockPanel.mouseY = -1
                root._zoomActive = false
                DockVisibility.setHovered(false)
            }
        }
    }

    // Custom tooltip / preview trigger timer.
    // For window tasks: shows the preview popup (separate layer-shell surface).
    // For launcher-only tasks: shows the in-scene text tooltip.
    Timer {
        id: tooltipTimer
        interval: DockSettings.previewHoverDelay
        onTriggered: {
            if (root.hoveredIndex < 0) return
            let idx = DockModel.tasksModel.index(root.hoveredIndex, 0)
            let isWindow = DockModel.tasksModel.data(
                idx, TaskManager.AbstractTasksModel.IsWindow)
            if (isWindow && DockSettings.previewEnabled) {
                // Window task → show preview popup
                let item = dockRepeater.itemAt(root.hoveredIndex)
                if (item) {
                    let globalPos = item.mapToGlobal(0, 0)
                    let pos = DockView.isVertical ? globalPos.y : globalPos.x
                    let ext = DockView.isVertical ? item.height : item.width
                    PreviewController.showPreview(root.hoveredIndex, pos, ext)
                }
            } else {
                // Launcher-only → show text tooltip
                tooltipItem.show = true
            }
        }
    }

    Rectangle {
        id: tooltipItem
        Accessible.ignored: true
        property bool show: false
        visible: show && root.hoveredName.length > 0

        // Reset when hover changes
        onVisibleChanged: if (!visible) show = false

        // Position on the opposite side of the dock edge
        x: {
            if (root.hoveredIndex < 0 || root.hoveredIndex >= dockRepeater.count)
                return 0
            let item = dockRepeater.itemAt(root.hoveredIndex)
            if (!item) return 0
            let sp = Kirigami.Units.largeSpacing
            if (DockView.edge === 2) return dockPanel.x + dockPanel.width + sp  // Left → right
            if (DockView.edge === 3) return dockPanel.x - width - sp            // Right → left
            return dockPanel.x + dockRow.x + item.x + item.width / 2 - width / 2
        }
        y: {
            if (root.hoveredIndex < 0 || root.hoveredIndex >= dockRepeater.count)
                return 0
            let item = dockRepeater.itemAt(root.hoveredIndex)
            if (!item) return 0
            let sp = Kirigami.Units.largeSpacing
            if (DockView.edge === 0) return dockPanel.y + dockPanel.height + sp  // Top → below
            if (DockView.edge === 1) return dockPanel.y - height - sp            // Bottom → above
            return dockPanel.y + dockRow.y + item.y + item.height / 2 - height / 2
        }

        Kirigami.Theme.colorSet: Kirigami.Theme.Tooltip
        Kirigami.Theme.inherit: false

        width: tooltipLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
        height: tooltipLabel.implicitHeight + Kirigami.Units.largeSpacing
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.backgroundColor
        z: 100

        QQC2.Label {
            id: tooltipLabel
            anchors.centerIn: parent
            text: root.hoveredName
            Accessible.ignored: true
        }

        // Hide tooltip and manage preview when hover changes
        Connections {
            target: root
            function onHoveredIndexChanged() {
                tooltipItem.show = false
                tooltipTimer.stop()
                if (root.hoveredIndex < 0) {
                    // Mouse left dock: start delayed preview hide
                    PreviewController.hidePreviewDelayed()
                } else if (!root.keyboardNavigating) {
                    // Moved to different icon (mouse): restart tooltip timer,
                    // hide preview with delay (allows moving to adjacent icon)
                    PreviewController.hidePreviewDelayed()
                    tooltipTimer.restart()
                }
                // In keyboard mode: don't auto-trigger tooltip/preview
            }
        }
    }

    // Auto-trigger preview when a hovered launcher's window appears.
    // Reacts to TasksModel row insertion — more responsive than polling.
    Connections {
        target: DockModel.tasksModel
        function onRowsInserted() {
            if (root.hoveredIndex < 0) return
            if (PreviewController.visible) return
            let idx = DockModel.tasksModel.index(root.hoveredIndex, 0)
            let isWindow = DockModel.tasksModel.data(
                idx, TaskManager.AbstractTasksModel.IsWindow)
            if (isWindow) {
                tooltipItem.show = false
                let item = dockRepeater.itemAt(root.hoveredIndex)
                if (item) {
                    let globalPos = item.mapToGlobal(0, 0)
                    let pos = DockView.isVertical ? globalPos.y : globalPos.x
                    let ext = DockView.isVertical ? item.height : item.width
                    PreviewController.showPreview(root.hoveredIndex, pos, ext)
                }
             }
        }
    }
    
    Loader {
            id: settingsUnifiedLoader
            x: {
                if (DockSettings.edge === 2) return blueprintGhost.width + 20; // Left
                if (DockSettings.edge === 3) return parent.width - blueprintGhost.width - width - 20; // Right
                return (parent.width - width) / 2; // Center horizontally for Top/Bottom
            }
            y: {
                if (DockSettings.edge === 0) return blueprintGhost.height + 20; // Top
                if (DockSettings.edge === 1) return parent.height - blueprintGhost.height - height - 20; // Bottom
                return (parent.height - height) / 2; // Center vertically for Left/Right
            }
                                    
            // 1. Let C++ dictate if this loader is active
            active: SettingsController ? SettingsController.visible : false
            visible: active
            source: active ? "qrc:/qml/SettingsDialog.qml" : ""

            // 2. Control the physical window (Grow/Shrink)
            Connections {
                target: SettingsController || null
                function onVisibleChanged() {
                    console.log("[DEBUG] SettingsController.visible is now:", SettingsController.visible);
                    if (DockVisibility) {
			    if (SettingsController.visible) {
                                DockVisibility.liveEditMode = true;
                                DockVisibility.setInteracting(true); // <--- ADD THIS
                            } else {
                                DockVisibility.liveEditMode = false;
                                DockVisibility.setInteracting(false);
                                DockVisibility.setSettingsRect(0, 0, 0, 0); 
                            }
                    }
                }
            }

            // 3. Keep Hitbox synced
            onXChanged: updateSettingsHitbox()
            onYChanged: updateSettingsHitbox()
            onWidthChanged: updateSettingsHitbox()
            onHeightChanged: updateSettingsHitbox()

            function updateSettingsHitbox() {
                if (item && active && DockVisibility) {
                    DockVisibility.setSettingsRect(x, y, width, height);
                }
            }

            onLoaded: {
                if (item && SettingsController) {
                    item.open(SettingsController.module);
                    updateSettingsHitbox();
                }
            }
        }
}
