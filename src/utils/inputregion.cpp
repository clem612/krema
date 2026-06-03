// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "inputregion.h"
#include <algorithm>

namespace krema
{

QRegion computeDockInputRegion(const InputRegionParams &p)
{
    if (p.panelWidth == 0 || p.panelHeight == 0) {
        return QRegion();
    }

    // 1. Create the Trigger Strip (The invisible 4px line that unhides the dock)
    QRegion triggerStrip;
    int ts = p.triggerStripHeight;

    switch (p.edge) {
    case 0: // Top
        triggerStrip = QRegion(0, 0, p.surfaceWidth, ts);
        break;
    case 1: // Bottom
        triggerStrip = QRegion(0, p.surfaceHeight - ts, p.surfaceWidth, ts);
        break;
    case 2: // Left
        triggerStrip = QRegion(0, 0, ts, p.surfaceHeight);
        break;
    case 3: // Right
        triggerStrip = QRegion(p.surfaceWidth - ts, 0, ts, p.surfaceHeight);
        break;
    }

    // If dock is hidden and settings are closed, only the trigger line is active
    if (!p.visible && !p.settingsVisible) {
        return triggerStrip;
    }

    QRegion finalRegion = triggerStrip;

    // 2. Add the Dock Hitbox (The "Hole" for the icons)
    if (p.visible) {
        int x, y, w, h;
        if (p.edge <= 1) { // Horizontal (Top=0, Bottom=1)
            x = std::max(0, p.panelX - p.margin);
            w = p.panelWidth + 2 * p.margin;

            if (p.edge == 1) { // Bottom
                // Rule 17 Compliance: Always cover the potential zoom area to 'catch' the mouse.
                y = std::max(0, p.panelY - p.zoomOverflowHeight - p.margin);
                h = p.surfaceHeight - y;
            } else { // Top
                y = 0;
                h = p.panelY + p.panelHeight + p.zoomOverflowHeight + p.margin;
            }
        } else { // Vertical (Left=2, Right=3)
            y = std::max(0, p.panelY - p.margin);
            h = p.panelHeight + 2 * p.margin;

            if (p.edge == 3) { // Right
                x = std::max(0, p.panelX - p.zoomOverflowHeight - p.margin);
                w = p.surfaceWidth - x;
            } else { // Left
                x = 0;
                w = p.panelX + p.panelWidth + p.zoomOverflowHeight + p.margin;
            }
        }
        finalRegion += QRect(x, y, w, h);
    }

    // 3. Add the Settings Hitbox (Solid interaction for the menu)
    if (p.settingsVisible) {
        int sx = (p.surfaceWidth - p.settingsWidth) / 2;
        int sy = p.surfaceHeight - p.panelHeight - p.settingsMargin - p.settingsHeight;
        finalRegion += QRect(sx, sy, p.settingsWidth, p.settingsHeight);
    }

    return finalRegion;
}

QRect computeDockScreenRect(const DockScreenRectParams &p)
{
    int surfaceX = p.screenX;
    int surfaceY = p.screenY;
    switch (p.edge) {
    case 0:
        break; // Top anchor
    case 1:
        surfaceY += p.screenHeight - p.surfaceHeight;
        break; // Bottom anchor
    case 2:
        break; // Left anchor
    case 3:
        surfaceX += p.screenWidth - p.surfaceWidth;
        break; // Right anchor
    }
    return QRect(surfaceX + p.panelX, surfaceY + p.panelRefY, p.panelWidth, p.panelHeight);
}

} // namespace krema
