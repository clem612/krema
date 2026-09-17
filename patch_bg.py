import os

with open('src/style/backgroundstyle.cpp', 'r') as f:
    content = f.read()

header = """#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
"""
if "#include <QFile>" not in content:
    content = content.replace('#include <KWindowEffects>', '#include <KWindowEffects>\n' + header)

get_wall_func = """
QColor getWallpaperColor(bool useAccentColor) {
    // Check Ryoku shell first (matugen)
    QString ryokuPath = QDir::homePath() + "/.cache/ryoku/colors.json";
    if (QFile::exists(ryokuPath)) {
        QFile file(ryokuPath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            QJsonObject obj = doc.object();
            if (useAccentColor && obj.contains("primary")) {
                return QColor(obj["primary"].toString());
            } else if (obj.contains("surfaceContainer")) {
                return QColor(obj["surfaceContainer"].toString());
            } else if (obj.contains("background")) {
                return QColor(obj["background"].toString());
            }
        }
    }

    // Check pywal
    QString walPath = QDir::homePath() + "/.cache/wal/colors.json";
    if (QFile::exists(walPath)) {
        QFile file(walPath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            QJsonObject obj = doc.object();
            if (useAccentColor && obj.contains("colors") && obj["colors"].isObject()) {
                QJsonObject colors = obj["colors"].toObject();
                if (colors.contains("color2")) {
                    return QColor(colors["color2"].toString());
                }
            }
            if (obj.contains("special") && obj["special"].isObject()) {
                QJsonObject special = obj["special"].toObject();
                if (special.contains("background")) {
                    return QColor(special["background"].toString());
                }
            }
        }
    }
    return QColor();
}
"""

if "getWallpaperColor(" not in content:
    # insert before computeBackgroundColor
    idx = content.find('QColor computeBackgroundColor(')
    content = content[:idx] + get_wall_func + '\n' + content[idx:]

# Now modify computeBackgroundColor logic
idx2 = content.find('QColor color;', content.find('QColor computeBackgroundColor('))
if idx2 != -1:
    logic = """
    QColor color;
    if (useWallpaperColor) {
        color = getWallpaperColor(useAccentColor);
    }
    
    if (color.isValid()) {
        color.setAlphaF(static_cast<float>(opacity));
        return color;
    }
"""
    # Replace 'QColor color;' with the logic
    content = content[:idx2] + logic + content[idx2 + len('QColor color;'):]

with open('src/style/backgroundstyle.cpp', 'w') as f:
    f.write(content)
