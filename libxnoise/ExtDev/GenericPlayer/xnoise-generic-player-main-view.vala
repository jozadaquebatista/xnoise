/* xnoise-generic-player-main-view.vala
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



private class Xnoise.ExtDev.GenericPlayerMainView : Gtk.Box, IMainView {
    
    private uint32 id;
    private Gtk.Label info_label;
    private unowned GenericPlayerDevice player_device;
    private GenericPlayerTreeView tree;
    private unowned Cancellable cancellable;
    
    public GenericPlayerMainView(GenericPlayerDevice player_device,
                               Cancellable cancellable) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.cancellable = cancellable;
        this.player_device = player_device;
        this.id = Random.next_int();
        setup_widgets();
    }
    
    ~GenericPlayerMainView() {
        print("DTOR GenericPlayerMainView\n");
    }
    
    public string get_view_name() {
        return player_device.get_identifier();
    }
    
    private void setup_widgets() {
        var label = new Label("");
        label.set_markup("<span size=\"xx-large\"><b>" +
                         Markup.printf_escaped(_("External Player Device")) +
                         "</b></span>"
        );
        this.pack_start(label, false, false, 12);
        tree = new GenericPlayerTreeView(player_device, cancellable);

        info_label = new Label("");
        this.pack_start(info_label, false, false, 4);
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE, fill_info_job);
        device_worker.push_job(job);

        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tree);
        this.pack_start(sw, true, true, 0);
    }

    private bool fill_info_job(Worker.Job job) {
        if(!(player_device is IAudioPlayerDevice))
            return false;
        string info =
            _("Free space: ") +
            player_device.get_free_space_size_formatted() +
            "\n" +
            _("Total space: ") +
            player_device.get_filesystem_size_formatted();
        Idle.add(() => {
            info_label.label = info;
            return false;
        });
        return false;
    }
}


