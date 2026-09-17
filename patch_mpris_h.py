import re

with open('src/shell/mpriscontroller.h', 'r') as f:
    c = f.read()

# Add includes
c = c.replace('#include <QString>', '#include <QString>\n#include <QTimer>')

# Add properties
props = """    Q_PROPERTY(bool canControl READ canControl NOTIFY canControlChanged)
    Q_PROPERTY(qint64 length READ length NOTIFY metadataChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(QString loopStatus READ loopStatus WRITE setLoopStatus NOTIFY loopStatusChanged)"""
c = re.sub(r'    Q_PROPERTY\(bool canControl READ canControl NOTIFY canControlChanged\)', props, c)

# Add accessors
accessors = """    bool canControl() const
    {
        return m_canControl;
    }
    qint64 length() const { return m_length; }
    qint64 position() const { return m_position; }
    double volume() const { return m_volume; }
    bool shuffle() const { return m_shuffle; }
    QString loopStatus() const { return m_loopStatus; }

    void setPosition(qint64 position);
    void setVolume(double volume);
    void setShuffle(bool shuffle);
    void setLoopStatus(const QString &loopStatus);"""
c = re.sub(r'    bool canControl\(\) const\s*\{\s*return m_canControl;\s*\}', accessors, c)

# Add signals
signals = """    void canControlChanged();
    void positionChanged();
    void volumeChanged();
    void shuffleChanged();
    void loopStatusChanged();"""
c = re.sub(r'    void canControlChanged\(\);', signals, c)

# Add slots
slots = """private Q_SLOTS:
    void updatePlayers();
    void onServiceOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner);
    void onPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps);
    void onSeeked(qlonglong position);
    void updatePosition();"""
c = re.sub(r'private Q_SLOTS:.*?void onPropertiesChanged.*?;\n', slots + '\n', c, flags=re.DOTALL)

# Add members
members = """    bool m_canControl = false;
    qint64 m_length = 0;
    qint64 m_position = 0;
    double m_volume = 1.0;
    bool m_shuffle = false;
    QString m_loopStatus = "None";
    QTimer *m_positionTimer = nullptr;"""
c = re.sub(r'    bool m_canControl = false;', members, c)

with open('src/shell/mpriscontroller.h', 'w') as f:
    f.write(c)
