// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "baseisland.h"
#include <QAbstractItemModel>

namespace krema
{

BaseIsland::BaseIsland(const QString &id, QAbstractItemModel *model, QObject *parent)
    : QObject(parent)
    , m_islandId(id)
    , m_tasksModel(model)
{
}

BaseIsland::~BaseIsland() = default;

QString BaseIsland::islandId() const
{
    return m_islandId;
}

QObject *BaseIsland::tasksModel() const
{
    return static_cast<QObject *>(m_tasksModel);
}

BaseIsland::AnchorZone BaseIsland::anchorZone() const
{
    return m_anchorZone;
}

void BaseIsland::setAnchorZone(AnchorZone zone)
{
    if (m_anchorZone != zone) {
        m_anchorZone = zone;
        Q_EMIT anchorZoneChanged();
    }
}

BaseIsland::SizeMode BaseIsland::sizeMode() const
{
    return m_sizeMode;
}

void BaseIsland::setSizeMode(SizeMode mode)
{
    if (m_sizeMode != mode) {
        m_sizeMode = mode;
        Q_EMIT sizeModeChanged();
    }
}

int BaseIsland::fixedWidth() const
{
    return m_fixedWidth;
}

void BaseIsland::setFixedWidth(int width)
{
    if (m_fixedWidth != width) {
        m_fixedWidth = width;
        Q_EMIT fixedWidthChanged();
    }
}

} // namespace krema
