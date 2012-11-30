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



private class Xnoise.AudioPlayerDevice : Xnoise.Device {
    
    private string uri;
    private AudioPlayerMainView view;
    
    
    public AudioPlayerDevice(Mount _mount) {
        mount = _mount;
        uri = mount.get_default_location().get_uri();
        print("created new audio player device for %s\n", uri);
    }
    
    ~AudioPlayerDevice() {
        main_window.main_view_sbutton.del(this.get_identifier());
//        main_window.sbuttonLY.del(this.get_identifier());
//        main_window.sbuttonVI.del(this.get_identifier());
        main_window.mainview_box.remove_main_view(view);
        print("removed audio player %s\n", get_identifier());
    }
    
    
    public override bool initialize() {
        device_type = 
            (File.new_for_uri(mount.get_default_location().get_uri() + "/Android").query_exists() ?
                DeviceType.ANDROID :
                DeviceType.GENERIC_PLAYER
            );
        Idle.add(() => {
            main_window.mainview_box.add_main_view(this.get_main_view_widget());
            if(!main_window.main_view_sbutton.has_item(this.get_identifier())) {
                string playername = "Player";
                main_window.main_view_sbutton.insert(this.get_identifier(), playername);
//                main_window.sbuttonLY.insert(this.get_identifier(), playername);
//                main_window.sbuttonVI.insert(this.get_identifier(), playername);
            }
            return false;
        });
        return true;
    }
    
    public override string get_uri() {
        return uri;
    }
    
    public override IMainView? get_main_view_widget() {
        view = new AudioPlayerMainView(this);
        view.show_all();
        return view;
    }
}



private class Xnoise.AudioPlayerMainView : Gtk.Box, IMainView {
    
    private uint32 id;
    private unowned AudioPlayerDevice audio_player_device;
    
    
    public AudioPlayerMainView(AudioPlayerDevice audio_player_device) {
        GLib.Object(orientation:Orientation.HORIZONTAL, spacing:0);
        this.audio_player_device = audio_player_device;
        this.id = Random.next_int();
        setup_widgets();
    }
    
    ~AudioPlayerMainView() {
        print("DTOR AudioPlayerMainView\n");
    }
    
    public string get_view_name() {
        return audio_player_device.get_identifier();
    }
    
    private void setup_widgets() {
        this.pack_start(new Label("audioplayer"), true, true, 0);
    }
}

