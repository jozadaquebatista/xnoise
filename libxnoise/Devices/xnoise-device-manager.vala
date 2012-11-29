/* xnoise-audio-player-device.vala
 *
 * Copyright (C) 2012  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */

using Gtk;

using Xnoise;



private class Xnoise.DeviceManager : GLib.Object {
    
    private GLib.VolumeMonitor volume_monitor;
    
    public HashTable<string,Xnoise.Device> devices;
    
    
    public DeviceManager() {
        devices = new HashTable<string,Xnoise.Device>(str_hash, str_equal);
        
        volume_monitor = VolumeMonitor.get();
        
        volume_monitor.mount_added.connect( (s,m) => {
            this.mount_added(m);
        });
        volume_monitor.mount_removed.connect( (s,m) => {
            this.mount_removed(m);
        });
    }
    
    public void mount_added(Mount mount) {
        foreach(Device d in devices.get_values()) {
            if(mount.get_default_location().get_uri() == d.get_uri())
                return; // already here
        }
        if(File.new_for_uri(mount.get_default_location().get_uri() + "/Android").query_exists() ||
           File.new_for_uri(mount.get_default_location().get_uri() + "/.is_audio_player").query_exists()) {
            var ad = new AudioPlayerDevice(mount);
            if(ad.initialize()) {
                devices.insert(ad.get_identifier(), ad);
            }
            else {
                mount_removed(mount);
            }
        }
        else {
            print ("unknown device in %s", mount.get_default_location().get_parse_name());
            return;
        }
    }
    
    public void mount_removed(Mount mount) {
        foreach(Device d in devices.get_values()) {
            if(mount.get_default_location().get_uri() == d.get_uri()) {
                print("remove device for %s\n", mount.get_default_location().get_uri());
                devices.remove(d.get_identifier());
                return;
            }
        }
    }
}
