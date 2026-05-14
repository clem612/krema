// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#pragma once

#include <QLoggingCategory>
#include <QObject>

namespace krema
{

class DebugManager : public QObject
{
    Q_OBJECT
public:
    static DebugManager *self();

    enum Category {
        App,
        Geom,
        Input,
        Anim,
        Preview,
        Model,
        Shell,
        Count
    };
    Q_ENUM(Category)

    bool isEnabled(Category cat) const
    {
        return m_enabled[cat];
    }
    void setEnabled(Category cat, bool enabled)
    {
        m_enabled[cat] = enabled;
    }

    static const char *categoryName(Category cat);
    static const char *categoryColor(Category cat);

    // QML-accessible logging methods
    Q_INVOKABLE void app(const QString &msg);
    Q_INVOKABLE void geom(const QString &msg);
    Q_INVOKABLE void input(const QString &msg);
    Q_INVOKABLE void anim(const QString &msg);
    Q_INVOKABLE void preview(const QString &msg);
    Q_INVOKABLE void model(const QString &msg);
    Q_INVOKABLE void shell(const QString &msg);

private:
    explicit DebugManager(QObject *parent = nullptr);
    bool m_enabled[Count];
};

} // namespace krema

Q_DECLARE_LOGGING_CATEGORY(lcApp)
Q_DECLARE_LOGGING_CATEGORY(lcGeom)
Q_DECLARE_LOGGING_CATEGORY(lcInput)
Q_DECLARE_LOGGING_CATEGORY(lcAnim)
Q_DECLARE_LOGGING_CATEGORY(lcPreview)
Q_DECLARE_LOGGING_CATEGORY(lcModel)
Q_DECLARE_LOGGING_CATEGORY(lcShell)
