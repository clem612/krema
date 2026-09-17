import os

with open('src/app/application.cpp', 'r') as f:
    content = f.read()

init_str = "    m_notificationTracker = std::make_unique<NotificationTracker>();\n    m_mprisController = std::make_unique<MprisController>();"
content = content.replace("    m_notificationTracker = std::make_unique<NotificationTracker>();", init_str)

reg_str = """
    auto *mpris = m_mprisController.get();
    qmlRegisterSingletonType<MprisController>("com.bhyoo.krema", 1, 0, "Mpris", [mpris](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(mpris, QQmlEngine::CppOwnership);
        return mpris;
    });
"""

idx = content.find('    // Create and initialize the multi-dock manager')
content = content[:idx] + reg_str + '\n' + content[idx:]

with open('src/app/application.cpp', 'w') as f:
    f.write(content)
