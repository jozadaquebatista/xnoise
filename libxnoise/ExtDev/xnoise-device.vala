/* xnoise-device.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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


public enum Xnoise.ExtDev.DeviceType {
    UNKNOWN,
    ANDROID,
    GENERIC_PLAYER,
    IPOD,
    CDROM
}

public abstract class Xnoise.ExtDev.Device : GLib.Object {
    public unowned Mount mount;
    private string? identifier = null;
    protected ItemHandler? handler = null;
    
    public DeviceType device_type { get; set; }
    public bool in_data_transfer { get; set; default = false; }
    
    public abstract bool initialize();
    public abstract string get_uri();
    public abstract DeviceMainView? get_main_view_widget();
    public abstract void cancel();
    public abstract ItemHandler? get_item_handler();
    
    public bool in_loading { get; set; }
    
    public virtual string get_presentable_name() {
        return "Dev";
    }
    
    public virtual string get_identifier() {
        if(identifier != null)
            return identifier;
        assert(mount != null);
//            return "";
        string uuid = mount.get_uuid();
        File f = mount.get_default_location();
        string ret = "";
        if(f != null && f.get_uri() != null)
            ret = ret + f.get_uri();
        
        if(uuid != null && uuid != "")
            ret = ret + "/" + uuid;
        //print("id = %s\n", ret);
        identifier = ret;
        return ret;
    }
    
    public virtual Gtk.Image? get_icon() {
        return icon_repo.get_themed_image_icon("multimedia-player-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
    }
}

