// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <QObject>
#include <QString>

class QAbstractItemModel;

namespace krema
{

/**
 * @brief BaseIsland represents a logical group of items (Tier 2).
 * For Phase 1 of the 3-Tier Migration, this wraps an underlying QAbstractItemModel.
 */
class BaseIsland : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString islandId READ islandId CONSTANT)
    Q_PROPERTY(QObject *tasksModel READ tasksModel CONSTANT)

    Q_PROPERTY(AnchorZone anchorZone READ anchorZone WRITE setAnchorZone NOTIFY anchorZoneChanged)
    Q_PROPERTY(SizeMode sizeMode READ sizeMode WRITE setSizeMode NOTIFY sizeModeChanged)
    Q_PROPERTY(int fixedWidth READ fixedWidth WRITE setFixedWidth NOTIFY fixedWidthChanged)

public:
    enum AnchorZone {
        Start = 0,
        Center = 1,
        End = 2,
        Justify = 3
    };
    Q_ENUM(AnchorZone)

    enum SizeMode {
        Dynamic = 0,
        Fixed = 1
    };
    Q_ENUM(SizeMode)

    explicit BaseIsland(const QString &id, QAbstractItemModel *model, QObject *parent = nullptr);
    ~BaseIsland() override;

    [[nodiscard]] QString islandId() const;
    [[nodiscard]] QObject *tasksModel() const;

    [[nodiscard]] AnchorZone anchorZone() const;
    void setAnchorZone(AnchorZone zone);

    [[nodiscard]] SizeMode sizeMode() const;
    void setSizeMode(SizeMode mode);

    [[nodiscard]] int fixedWidth() const;
    void setFixedWidth(int width);

Q_SIGNALS:
    void anchorZoneChanged();
    void sizeModeChanged();
    void fixedWidthChanged();

private:
    QString m_islandId;
    QAbstractItemModel *m_tasksModel = nullptr;
    AnchorZone m_anchorZone = Center;
    SizeMode m_sizeMode = Dynamic;
    int m_fixedWidth = 100;
};

} // namespace krema
