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



private class Xnoise.ExtDev.AndroidPlayerMainView : Gtk.Overlay, IMainView {
    
    private uint32 id;
    private Gtk.Label info_label;
    private unowned AndroidPlayerDevice audio_player_device;
    private unowned Cancellable cancellable;
    internal AndroidPlayerTreeView tree;
    
    public AndroidPlayerMainView(AndroidPlayerDevice audio_player_device,
                                 Cancellable cancellable) {
        this.cancellable = cancellable;
        this.audio_player_device = audio_player_device;
        this.id = Random.next_int();
        setup_widgets();
        audio_player_device.sign_update_filesystem.connect( () => {
            print("update filesystem info\n");
            var job = new Worker.Job(Worker.ExecutionType.ONCE, fill_info_job);
            device_worker.push_job(job);
        });
    }
    
    ~AndroidPlayerMainView() {
        print("DTOR AndroidPlayerMainView\n");
    }
    
    public string get_view_name() {
        return audio_player_device.get_identifier();
    }
    
    private void setup_widgets() {
        var box = new Gtk.Box(Orientation.VERTICAL, 0);
        var header_label = new Label("");
        header_label.set_markup("<span size=\"xx-large\"><b>" +
                         Markup.printf_escaped(_("Android Player Device")) +
                         "</b></span>"
        );
        box.pack_start(header_label, false, false, 12);
        
        info_label = new Label("");
        box.pack_start(info_label, false, false, 4);
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE, fill_info_job);
        device_worker.push_job(job);
        
        tree = new AndroidPlayerTreeView(audio_player_device, cancellable);
        
        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tree);
        box.pack_start(sw, true, true, 0);
        
        var spinner = new Spinner();
        //spinner.start();
        spinner.set_size_request(160, 160);
        this.add_overlay(spinner);
        spinner.halign = Align.CENTER;
        spinner.valign = Align.CENTER;
        spinner.set_no_show_all(true);
        this.show();
        spinner.show();
        audio_player_device.notify["in-loading"].connect( () => {
            if(audio_player_device.in_loading) {
                spinner.start();
                spinner.set_no_show_all(false);
                spinner.show_all();
            }
            else {
                spinner.stop();
                spinner.hide();
                spinner.set_no_show_all(true);
            }
        });
        
        this.add(box);
    }
    
    private bool fill_info_job(Worker.Job job) {
        if(!(audio_player_device is IAudioPlayerDevice))
            return false;
        string info =
            _("Free space: ") +
            audio_player_device.get_free_space_size_formatted() +
            "\n" +
            _("Total space: ") +
            audio_player_device.get_filesystem_size_formatted();
        Idle.add(() => {
            info_label.label = info;
            return false;
        });
        return false;
    }
}


