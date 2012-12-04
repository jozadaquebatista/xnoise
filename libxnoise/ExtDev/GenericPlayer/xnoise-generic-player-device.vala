/* xnoise-generic-player-device.vala
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
using Xnoise.ExtDev;



private class Xnoise.ExtDev.GenericPlayerDevice : Device {
    
    private string uri;
    private GenericPlayerMainView view;
    private Cancellable cancellable = new Cancellable();
    private string[] player_folders;
    
    
    public GenericPlayerDevice(Mount _mount) {
        mount = _mount;
        uri = mount.get_default_location().get_uri();
        player_folders = {};
        print("created new audio player device for %s\n", uri);
    }
    
    ~GenericPlayerDevice() {
    }
    
    
    public static Device? get_device(Mount mount) {
        if(File.new_for_uri(mount.get_default_location().get_uri() + "/.is_audio_player").query_exists()) {
            return new GenericPlayerDevice(mount);
        }
        return null;
    }
    
    public override bool initialize() {
        File f = File.new_for_uri(mount.get_default_location().get_uri() + "/.is_audio_player");
        if(f.query_exists(cancellable)) {
            device_type = DeviceType.GENERIC_PLAYER;
            if(f.query_exists() == true) {
                try {
                    var stream = new DataInputStream(f.read());
                    string line;
                    while((line = stream.read_line(null)) != null) {
                        if(line.contains("audio_folders=")) {
                            string dirs = line.substring((long)"audio_folders=".length,
                                                            (long)(line.length - "audio_folders=".length));
                            foreach(string dir in dirs.split(",")) {
                                string s = mount.get_default_location().get_uri() + "/" + dir.strip();
                                player_folders += s;
                            }
                            break;
                        }
                    }
                }
                catch(Error e) {
                    print("%s\n", e.message);
                }
            }
        }
        return true;
    }
    
    public override string get_uri() {
        return uri;
    }
    
    public override IMainView? get_main_view_widget() {
        if(view != null)
            return view;
        view = new GenericPlayerMainView(this, cancellable);
        view.show_all();
        return view;
    }
    
    public override string get_presentable_name() {
        return "Player";
    }
    
    public override void cancel() {
        cancellable.cancel();
    }
}




