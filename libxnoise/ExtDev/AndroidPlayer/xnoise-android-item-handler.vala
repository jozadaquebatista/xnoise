/* xnoise-android-item-handler.vala
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
 *     Jörn Magens
 */


using Xnoise;
using Xnoise.ExtDev;


private class Xnoise.HandlerAndroidDevice : HandlerPlayerDevice {
    private static const string ainfo = _("Add to Android Device");
    private static const string aname = "A HandlerAndroidDevicename";
    private static const string cinfo = _("Delete from device");
    private static const string cname = "C HandlerAndroidDevicename";
    
    
    public HandlerAndroidDevice(PlayerDevice _audio_player_device,
                                Cancellable _cancellable) {
        base(_audio_player_device, _cancellable);
    }
    
    
    protected override unowned string get_add_info() {
        return ainfo;
    }
    
    protected override unowned string get_add_name() {
        return aname;
    }
    
    protected override unowned string get_del_info() {
        return cinfo;
    }
    
    protected override unowned string get_del_name() {
        return cname;
    }
    
    protected override File? get_dest_dir() {
        File dest_base = File.new_for_uri(audio_player_device.get_uri());
        assert(dest_base != null);
        File dest1 = dest_base.get_child("Music");
        assert(dest1 != null);
        if(!dest1.query_exists(cancellable)) {
            dest1 = dest_base.get_child("media");
        }
        return dest1;
    }
}

