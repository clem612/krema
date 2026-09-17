import os
with open('src/shell/mpriscontroller.cpp', 'r') as f:
    c = f.read()

c = c.replace(
    'QVariant metaVar = changedProps.value(QLatin1String("Metadata"));',
    'QVariant metaVar = changedProps.value(QLatin1String("Metadata"));\n        qWarning() << "RECEIVED METADATA, Type:" << metaVar.typeName();'
)

with open('src/shell/mpriscontroller.cpp', 'w') as f:
    f.write(c)
