// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "inputregion.h"
#include <algorithm>

namespace krema
{

QRegion computeDockInputRegion(const InputRegionParams &p)
{
    // 1. Create the Trigger Strip (The invisible 4px line that unhides the dock)
    QRegion triggerStrip;
    int ts = p.triggerStripHeight;

    switch (p.edge) {
    case 0:
        triggerStrip = QRegion(0, 0, p.surfaceWidth, ts);
        break; // Top
    case 1:
        triggerStrip = QRegion(0, p.surfaceHeight - ts, p.surfaceWidth, ts);
        break; // Bottom
    case 2:
        triggerStrip = QRegion(0, 0, ts, p.surfaceHeight);
        break; // Left
    case 3:
        triggerStrip = QRegion(p.surfaceWidth - ts, 0, ts, p.surfaceHeight);
        break; // Right
    }

    // If dock is hidden and settings are closed, only the trigger line is active
    if (!p.visible && !p.settingsVisible) {
        return triggerStrip;
    }

    QRegion finalRegion = triggerStrip;

    // 2. Add the Dock Hitbox (The "Hole" for the icons)
    if (p.visible) {
        if (p.edge <= 1) { // Horizontal
            int regionY = p.hovered ? std::max(0, p.panelY - p.zoomOverflowHeight - p.margin) : std::max(0, p.panelY - p.margin);
            finalRegion += QRegion(std::max(0, p.panelX - p.margin), regionY, p.panelWidth + 2 * p.margin, p.surfaceHeight - regionY);
        } else { // Vertical
            int regionX = p.hovered ? std::max(0, p.panelX - p.zoomOverflowHeight - p.margin) : std::max(0, p.panelX - p.margin);
            finalRegion += QRegion(regionX, std::max(0, p.panelY - p.margin), p.surfaceWidth - regionX, p.panelHeight + 2 * p.margin);
        }
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
    int surfaceX = 0, surfaceY = 0;
    switch (p.edge) {
    case 1:
        surfaceY = p.screenY + p.screenHeight - p.surfaceHeight;
        break; // Bottom anchor
    case 3:
        surfaceX = p.screenX + p.screenWidth - p.surfaceWidth;
        break; // Right anchor
    }
    return QRect(surfaceX + p.panelX, surfaceY + p.panelRefY, p.panelWidth, p.panelHeight);
}

} // namespace krema
