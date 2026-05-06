// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

#include "application.h"

#include "krema.h"
#include "models/dockactions.h"
#include "models/dockmodel.h"
#include "models/notificationtracker.h"
#include "shell/dockshell.h"
#include "shell/dockview.h"
#include "shell/dockvisibilitycontroller.h"
#include "shell/multidockmanager.h"

#include <KAboutData>
#include <KActionCollection>
#include <KCrash>
#include <KDBusService>
#include <KGlobalAccel>
#include <KLocalizedString>
#include <LayerShellQt/Shell>

#include <QAction>
#include <QLoggingCategory>
#include <QQuickStyle>
#include <QtQml>

#include <iostream>

void kremaLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    using namespace Qt::StringLiterals;
    QByteArray localMsg = msg.toLocal8Bit();
    QString category = QString::fromLatin1(context.category);

    // ANSI Color Codes
    const char *reset = "\x1b[0m";
    const char *red = "\x1b[31m";
    const char *green = "\x1b[32m";
    const char *yellow = "\x1b[33m";
    const char *blue = "\x1b[34m";
    const char *magenta = "\x1b[35m";
    const char *cyan = "\x1b[36m";
    const char *bold = "\x1b[1m";

    const char *color = reset;

    // Clean up tag: Remove "krema." prefix and uppercase it
    QString tag = category;
    if (tag.startsWith(u"krema."_s))
        tag.remove(0, 6);
    tag = tag.toUpper();
    if (tag == u"DEFAULT"_s)
        tag = u"DEBUG"_s;

    // 1. Determine Color by Category
    if (category.contains(u"model"_s))
        color = yellow;
    else if (category.contains(u"notifications"_s) || category.contains(u"notif"_s))
        color = cyan;
    else if (category.contains(u"icons"_s))
        color = magenta;
    else if (category.contains(u"shell"_s) || category.contains(u"preview"_s))
        color = green;
    else if (category.contains(u"config"_s))
        color = blue;
    else if (category.contains(u"app"_s))
        color = bold;

    // 2. Override Color for Warnings/Errors
    if (type == QtWarningMsg || type == QtCriticalMsg)
        color = red;

    // 3. Print to terminal
    std::fprintf(stderr, "%s[%s]%s %s\n", color, tag.toLocal8Bit().constData(), reset, localMsg.constData());
}

Q_LOGGING_CATEGORY(lcApp, "krema.app")

// Static library resources must be explicitly initialized.
// Must be called from global namespace, not inside krema namespace.
static void initResources()
{
    Q_INIT_RESOURCE(qml);
}

namespace krema
{

Application::Application(int &argc, char **argv)
    : QApplication(argc, argv)
{
}

Application::~Application() = default;

int Application::run()
{
    // Install the global color interceptor immediately
    qInstallMessageHandler(kremaLogHandler);

    // Ensure Qt Quick Controls use the KDE Plasma style (needed for Kirigami theming)
    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    // Initialize KDE crash handler (must be called early)
    KCrash::initialize();

    // Set up KDE application metadata (required for KGlobalAccel, D-Bus, etc.)
    KAboutData aboutData(QStringLiteral("krema"), i18n("Krema"), QStringLiteral(KREMA_VERSION_STRING), i18n("A dock for KDE Plasma 6"), KAboutLicense::GPL_V3);
    aboutData.addAuthor(i18n("Byeonghoon Yoo"), {}, QStringLiteral("bhyoo@bhyoo.com"));
    aboutData.setOrganizationDomain(QByteArrayLiteral("bhyoo.com"));
    KAboutData::setApplicationData(aboutData);
    setDesktopFileName(QStringLiteral("com.bhyoo.krema"));

    // Enforce single instance via D-Bus (exits if another instance is already running)
    KDBusService service(KDBusService::Unique);
    connect(&service, &KDBusService::activateRequested, this, [](const QStringList &args, const QString &) {
        qCInfo(lcApp) << "Another instance attempted to start, ignoring. args:" << args;
    });

    // Initialize Qt resources from static library
    initResources();

    // LayerShellQt::Shell::useLayerShell(); // Deprecated and removed for modern Qt 6

    // Load settings from KConfig (~/.config/kremarc)
    m_settings = std::make_unique<KremaSettings>();
    m_settings->load();

    // Create data model
    m_dockModel = std::make_unique<DockModel>();
    m_dockModel->setPinnedLaunchers(m_settings->pinnedLaunchers());

    // Create notification tracker (before QML loading)
    m_notificationTracker = std::make_unique<NotificationTracker>();

    // Register global QML singletons (must be before any QML loading)
    auto *model = m_dockModel.get();
    qmlRegisterSingletonType<DockModel>("com.bhyoo.krema", 1, 0, "DockModel", [model](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(model, QQmlEngine::CppOwnership);
        return model;
    });
    auto *settings = m_settings.get();
    qmlRegisterSingletonType<KremaSettings>("com.bhyoo.krema", 1, 0, "DockSettings", [settings](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(settings, QQmlEngine::CppOwnership);
        return settings;
    });
    auto *tracker = m_notificationTracker.get();
    qmlRegisterSingletonType<NotificationTracker>("com.bhyoo.krema", 1, 0, "NotificationTracker", [tracker](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(tracker, QQmlEngine::CppOwnership);
        return tracker;
    });

    // Create and initialize the multi-dock manager (creates DockShell(s) based on monitor mode)
    m_dockManager = std::make_unique<MultiDockManager>(m_settings.get(), m_dockModel.get(), m_notificationTracker.get(), this);
    m_dockManager->initialize();

    // Apply initial virtual desktop display mode
    m_dockModel->setVirtualDesktopMode(m_settings->virtualDesktopMode());

    // Auto-save pinned launchers when they change on any shell
    connect(m_dockManager.get(), &MultiDockManager::pinnedLaunchersChanged, this, [this]() {
        m_settings->setPinnedLaunchers(m_dockModel->pinnedLaunchers());
        m_settings->save();
    });

    // Auto-save on any setting change
    auto *s = m_settings.get();
    connect(s, &KremaSettings::configChanged, this, [s]() {
        s->save();
    });

    // Virtual desktop mode change
    connect(s, &KremaSettings::VirtualDesktopModeChanged, this, [this]() {
        m_dockModel->setVirtualDesktopMode(m_settings->virtualDesktopMode());
    });

    // Monitor mode change
    connect(s, &KremaSettings::MonitorModeChanged, this, [this]() {
        m_dockManager->setMonitorMode(static_cast<MultiDockManager::MonitorMode>(m_settings->monitorMode()));
    });

    // The dock window is now created with layer-shell.
    // Unset the env var so child processes (launched apps) don't inherit it.
    qunsetenv("QT_WAYLAND_SHELL_INTEGRATION");

    // Register global shortcuts (KGlobalAccel)
    registerGlobalShortcuts();

    return exec();
}

void Application::registerGlobalShortcuts()
{
    m_actionCollection = new KActionCollection(this, QStringLiteral("krema"));
    auto *kga = KGlobalAccel::self();

    // Toggle dock visibility: Meta+`
    auto *toggleAction = m_actionCollection->addAction(QStringLiteral("toggle-dock"));
    toggleAction->setText(i18nc("@action global shortcut", "Toggle Dock"));
    kga->setDefaultShortcut(toggleAction, {QKeySequence(Qt::META | Qt::Key_QuoteLeft)});
    kga->setShortcut(toggleAction, {QKeySequence(Qt::META | Qt::Key_QuoteLeft)});
    connect(toggleAction, &QAction::triggered, this, [this]() {
        if (auto *shell = m_dockManager->primaryShell()) {
            shell->view()->visibilityController()->toggleVisibility();
        }
    });

    // Focus dock for keyboard navigation: Meta+F5
    auto *focusDockAction = m_actionCollection->addAction(QStringLiteral("focus-dock"));
    focusDockAction->setText(i18nc("@action global shortcut", "Focus Dock"));
    kga->setDefaultShortcut(focusDockAction, {QKeySequence(Qt::META | Qt::Key_F5)});
    kga->setShortcut(focusDockAction, {QKeySequence(Qt::META | Qt::Key_F5)});
    connect(focusDockAction, &QAction::triggered, this, [this]() {
        if (auto *shell = m_dockManager->shellAtCursor()) {
            shell->focusDock();
        }
    });

    // Meta+1..9: Activate N-th app (targets primary dock)
    for (int i = 1; i <= 9; ++i) {
        auto *activateAction = m_actionCollection->addAction(QStringLiteral("activate-entry-%1").arg(i));
        activateAction->setText(i18nc("@action global shortcut", "Activate Entry %1", i));
        const auto seq = QKeySequence(Qt::META | static_cast<Qt::Key>(Qt::Key_1 + i - 1));
        kga->setDefaultShortcut(activateAction, {seq});
        kga->setShortcut(activateAction, {seq});
        connect(activateAction, &QAction::triggered, this, [this, i]() {
            if (auto *shell = m_dockManager->primaryShell()) {
                shell->actions()->activate(i - 1);
            }
        });
    }

    // Meta+Shift+1..9: New instance of N-th app (targets primary dock)
    for (int i = 1; i <= 9; ++i) {
        auto *newInstanceAction = m_actionCollection->addAction(QStringLiteral("new-instance-entry-%1").arg(i));
        newInstanceAction->setText(i18nc("@action global shortcut", "New Instance of Entry %1", i));
        const auto seq = QKeySequence(Qt::META | Qt::SHIFT | static_cast<Qt::Key>(Qt::Key_1 + i - 1));
        kga->setDefaultShortcut(newInstanceAction, {seq});
        kga->setShortcut(newInstanceAction, {seq});
        connect(newInstanceAction, &QAction::triggered, this, [this, i]() {
            if (auto *shell = m_dockManager->primaryShell()) {
                shell->actions()->newInstance(i - 1);
            }
        });
    }

    qCDebug(lcApp) << "Global shortcuts registered";
}

} // namespace krema
