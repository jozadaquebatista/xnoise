/* xnoise-cdda-device.vala
 *
 * Copyright (C) 2013  Jörn Magens
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


private class Xnoise.ExtDev.CddaDevice : Device {
    
//    private Mount mount;
    private Cancellable cancellable;
    private string uri;
    internal DeviceMainView? view = null;
    
    public CddaDevice(Mount mount) {
        this.mount = mount;
        cancellable = new Cancellable();
    }
    
    
    public override bool initialize() {
        device_type = DeviceType.CDROM;
        return true;
    }
    
    public static Device? get_device(Mount mount) {
        if(mount.get_default_location().get_uri().has_prefix("cdda://") && mount.get_volume() != null) {
            var dev = new CddaDevice(mount);
            assert(dev != null);
            return dev;
        }
        return null;
    }
    
    public override DeviceMainView? get_main_view_widget() {
        if(view != null)
            return view;
        view = new CddaMainView(this, cancellable);
        view.show_all();
        return view;
    }
    
    public override ItemHandler? get_item_handler() {
//        if(handler == null)
//            handler = new HandlerCddaDevice(this, cancellable);
//        return handler;
        return null;
    }
    
    public override string get_uri() {
        return uri;
    }
    
    public override void cancel() {
        cancellable.cancel();
    }
    
    public override string get_presentable_name() {
        return "CD";
    }
}

