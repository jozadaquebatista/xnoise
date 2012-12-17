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


using Xnoise;
using Xnoise.ExtDev;



public class Xnoise.ExtDev.PlayerDevice : Device {
    
    protected string uri;
    protected Cancellable cancellable { get; set; }
    
    internal PlayerMainView? view = null;
    public AudioPlayerTempDb db;
    
    
    public PlayerDevice(Mount _mount) {
        cancellable = new Cancellable();
        mount = _mount;
        uri = mount.get_default_location().get_uri();
        assert(uri != null && uri != "");
        print("created new audio player device for %s\n", uri);
    }
    
    
    public override bool initialize() {
        device_type = DeviceType.UNKNOWN;
        return false;
    }
    
    public override PlayerMainView? get_main_view_widget() {
        return null;
    }
    
    public override ItemHandler? get_item_handler() {
        return null;
    }
    
    public override string get_presentable_name() {
        return "unknown";
    }

    public override string get_uri() {
        return uri;
    }
    
    public override void cancel() {
        cancellable.cancel();
    }
    
    public signal void sign_add_track(string[] uris);
    public signal void sign_update_filesystem();
    
    public virtual uint64 get_filesystem_size() {
        uint64 size = 0;
        try {
            var f = File.new_for_uri(get_uri());
            var file_info = f.query_filesystem_info(FileAttribute.FILESYSTEM_SIZE, null);
            size = file_info.get_attribute_uint64(FileAttribute.FILESYSTEM_SIZE);
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        return size;
    }
    
    public virtual uint64 get_free_space_size() {
        uint64 size = 0;
        try {
            var f = File.new_for_uri(get_uri());
            var file_info = f.query_filesystem_info(FileAttribute.FILESYSTEM_FREE, null);
            size = file_info.get_attribute_uint64(FileAttribute.FILESYSTEM_FREE);
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        return size;
    }
    
    public virtual string get_filesystem_size_formatted() {
        return format_size(get_filesystem_size());
    }
    
    public virtual string get_free_space_size_formatted() {
        return format_size(get_free_space_size());
    }
}


