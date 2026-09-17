import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()

def properties_changed(interface, changed_properties, invalidated_properties):
    print("Properties changed on:", interface)
    if "Metadata" in changed_properties:
        meta = changed_properties["Metadata"]
        print("Metadata type:", type(meta))
        if "xesam:title" in meta:
            print("Title:", meta["xesam:title"], "type:", type(meta["xesam:title"]))

bus.add_signal_receiver(properties_changed,
                        dbus_interface="org.freedesktop.DBus.Properties",
                        signal_name="PropertiesChanged",
                        arg0="org.mpris.MediaPlayer2.Player")

loop = GLib.MainLoop()
print("Listening for DBus properties changed... (Play/pause your media player now!)")
loop.run()
