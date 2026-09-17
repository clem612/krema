import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

class MockPlayer(dbus.service.Object):
    def __init__(self, bus, object_path):
        dbus.service.Object.__init__(self, bus, object_path)
        self.metadata = {
            'mpris:trackid': '/org/mpris/MediaPlayer2/TrackList/NoTrack',
            'xesam:title': 'Test Song',
            'xesam:artist': ['Test Artist'],
            'mpris:artUrl': 'file:///home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/.user_uploaded/media_1789497540335.png',
            'mpris:length': dbus.Int64(300000000) # 5 minutes in microseconds
        }

    @dbus.service.property('org.mpris.MediaPlayer2.Player', signature='a{sv}')
    def Metadata(self):
        return self.metadata
        
    @dbus.service.property('org.mpris.MediaPlayer2.Player', signature='s')
    def PlaybackStatus(self):
        return 'Playing'
        
    @dbus.service.property('org.mpris.MediaPlayer2.Player', signature='x')
    def Position(self):
        return dbus.Int64(120000000) # 2 minutes
        
    @dbus.service.property('org.mpris.MediaPlayer2.Player', signature='d')
    def Volume(self):
        return 0.5

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName("org.mpris.MediaPlayer2.Mock", bus)
player = MockPlayer(bus, '/org/mpris/MediaPlayer2')

loop = GLib.MainLoop()
print("Running Mock Player")
loop.run()
