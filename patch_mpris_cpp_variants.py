import re

with open('src/shell/mpriscontroller.cpp', 'r') as f:
    c = f.read()

# Fix QDBusVariant(volume) to QVariant::fromValue(QDBusVariant(QVariant(volume)))
c = c.replace('QDBusVariant(volume)', 'QVariant::fromValue(QDBusVariant(QVariant(volume)))')
c = c.replace('QDBusVariant(shuffle)', 'QVariant::fromValue(QDBusVariant(QVariant(shuffle)))')
c = c.replace('QDBusVariant(loopStatus)', 'QVariant::fromValue(QDBusVariant(QVariant(loopStatus)))')

with open('src/shell/mpriscontroller.cpp', 'w') as f:
    f.write(c)
