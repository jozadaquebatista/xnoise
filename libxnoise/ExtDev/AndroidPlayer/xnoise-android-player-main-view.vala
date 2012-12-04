/* xnoise-android-player-main-view.vala
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



private class Xnoise.ExtDev.AndroidPlayerMainView : Gtk.Box, IMainView {
    
    private uint32 id;
    private unowned AndroidPlayerDevice player_device;
    private AndroidPlayerTreeView tree;
    private unowned Cancellable cancellable;
    
    public AndroidPlayerMainView(AndroidPlayerDevice player_device,
                                 Cancellable cancellable) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.cancellable = cancellable;
        this.player_device = player_device;
        this.id = Random.next_int();
        setup_widgets();
    }
    
    ~AndroidPlayerMainView() {
        print("DTOR AndroidPlayerMainView\n");
    }
    
    public string get_view_name() {
        return player_device.get_identifier();
    }
    
    private void setup_widgets() {
        var label = new Label("");
        label.set_markup("<span size=\"xx-large\"><b>" +
                         Markup.printf_escaped(_("Android Player Device")) +
                         "</b></span>"
        );
        this.pack_start(label, false, false, 12);
        tree = new AndroidPlayerTreeView(player_device, cancellable);

        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tree);
        this.pack_start(sw, true, true, 0);
    }
}


