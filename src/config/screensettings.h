// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <KConfigGroup>
#include <KSharedConfig>

#include <QObject>

class KremaSettings;

namespace krema
{

/**
 * Per-screen settings overlay on top of global KremaSettings.
 *
 * Reads from a KConfig group named "Screen-{screenName}" (e.g. "Screen-HDMI-A-1").
 * If a key exists in the per-screen group, its value is used.
 * Otherwise, falls back to the global KremaSettings default.
 *
 * Only a subset of properties can be overridden per-screen:
 *   iconSize, edge, visibilityMode, backgroundStyle, backgroundOpacity,
 *   pinnedLaunchers, maxZoomFactor, floating, cornerRadius
 */
class ScreenSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool hasOverrides READ hasOverrides NOTIFY hasOverridesChanged)
    Q_PROPERTY(int iconSize READ iconSize WRITE setIconSize NOTIFY iconSizeChanged)
    Q_PROPERTY(int edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(int visibilityMode READ visibilityMode WRITE setVisibilityMode NOTIFY visibilityModeChanged)
    Q_PROPERTY(int backgroundStyle READ backgroundStyle WRITE setBackgroundStyle NOTIFY backgroundStyleChanged)
    Q_PROPERTY(double backgroundOpacity READ backgroundOpacity WRITE setBackgroundOpacity NOTIFY backgroundOpacityChanged)
    Q_PROPERTY(double maxZoomFactor READ maxZoomFactor WRITE setMaxZoomFactor NOTIFY maxZoomFactorChanged)
    Q_PROPERTY(bool floating READ floating WRITE setFloating NOTIFY floatingChanged)
    Q_PROPERTY(int cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY cornerRadiusChanged)
    Q_PROPERTY(int panelHeight READ panelHeight WRITE setPanelHeight NOTIFY panelHeightChanged)
    Q_PROPERTY(QStringList pinnedLaunchers READ pinnedLaunchers WRITE setPinnedLaunchers NOTIFY pinnedLaunchersChanged)
    Q_PROPERTY(int separatorStyle READ separatorStyle WRITE setSeparatorStyle NOTIFY separatorStyleChanged)
    Q_PROPERTY(double separatorOpacity READ separatorOpacity WRITE setSeparatorOpacity NOTIFY separatorOpacityChanged)
    Q_PROPERTY(int separatorWidth READ separatorWidth WRITE setSeparatorWidth NOTIFY separatorWidthChanged)

public:
    explicit ScreenSettings(const QString &screenName, KremaSettings *fallback, QObject *parent = nullptr);

    [[nodiscard]] QString screenName() const;
    [[nodiscard]] bool hasOverrides() const;

    // --- Overrideable properties (read from per-screen group or fallback) ---

    [[nodiscard]] int iconSize() const;
    [[nodiscard]] int edge() const;
    [[nodiscard]] int visibilityMode() const;
    [[nodiscard]] int backgroundStyle() const;
    [[nodiscard]] double backgroundOpacity() const;
    [[nodiscard]] double maxZoomFactor() const;
    [[nodiscard]] bool floating() const;
    [[nodiscard]] int cornerRadius() const;
    [[nodiscard]] int panelHeight() const;
    [[nodiscard]] QStringList pinnedLaunchers() const;
    [[nodiscard]] int separatorStyle() const;
    [[nodiscard]] double separatorOpacity() const;
    [[nodiscard]] int separatorWidth() const;

    // --- Write per-screen overrides ---

    void setIconSize(int size);
    void setEdge(int edge);
    void setVisibilityMode(int mode);
    void setBackgroundStyle(int style);
    void setBackgroundOpacity(double opacity);
    void setMaxZoomFactor(double factor);
    void setFloating(bool floating);
    void setCornerRadius(int radius);
    void setPanelHeight(int height);
    void setPinnedLaunchers(const QStringList &launchers);
    void setSeparatorStyle(int style);
    void setSeparatorOpacity(double opacity);
    void setSeparatorWidth(int width);

    /// Remove all per-screen overrides (revert to global defaults).
    Q_INVOKABLE void clearOverrides();

    /// Remove a specific per-screen override.
    Q_INVOKABLE void clearOverride(const QString &key);

    /// Save changes to disk.
    Q_INVOKABLE void save();

Q_SIGNALS:
    void hasOverridesChanged();
    // Per-property change signals (emitted when the effective value changes)
    void iconSizeChanged();
    void edgeChanged();
    void visibilityModeChanged();
    void backgroundStyleChanged();
    void backgroundOpacityChanged();
    void maxZoomFactorChanged();
    void floatingChanged();
    void panelHeightChanged();
    void cornerRadiusChanged();
    void pinnedLaunchersChanged();
    void separatorStyleChanged();
    void separatorOpacityChanged();
    void separatorWidthChanged();

private:
    /// Read a value from per-screen group, falling back to the global default.
    template<typename T>
    T readWithFallback(const QString &key, T fallbackValue) const;

    /// Write a value to the per-screen group (creates the group if needed).
    template<typename T>
    void writeOverride(const QString &key, T value);

    QString m_screenName;
    KremaSettings *m_fallback;
    KConfigGroup m_group;
};

} // namespace krema
