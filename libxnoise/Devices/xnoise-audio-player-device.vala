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
using Xnoise.ExtDev;
using Xnoise.Utilities;
using Xnoise.TagAccess;



private class Xnoise.ExtDev.AudioPlayerDevice : Device {
    
    private string uri;
    private AudioPlayerMainView view;
    
    
    public AudioPlayerDevice(Mount _mount) {
        mount = _mount;
        uri = mount.get_default_location().get_uri();
        print("created new audio player device for %s\n", uri);
    }
    
    ~AudioPlayerDevice() {
        main_window.main_view_sbutton.del(this.get_identifier());
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



private class Xnoise.ExtDev.AudioPlayerMainView : Gtk.Box, IMainView {
    
    private uint32 id;
    private unowned AudioPlayerDevice audio_player_device;
    private TreeView tree;
    private TreeStore treemodel;
    
    public AudioPlayerMainView(AudioPlayerDevice audio_player_device) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
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
        var label = new Label("");
        label.set_markup("<span size=\"xx-large\"><b>" +
                         Markup.printf_escaped(_("External Player Device")) +
                         "</b></span>"
        );
        this.pack_start(label, false, false, 12);
        File b = File.new_for_uri(audio_player_device.get_uri());
        assert(b != null);
        b = b.get_child("Music");
        assert(b != null);
        assert(b.get_path() != null);
        if(b.query_exists(null))
            treemodel = new PlayerTreeStore(b);
        else {
            b = File.new_for_uri(audio_player_device.get_uri());
            b = b.get_child("media"); // old android devices
            treemodel = new PlayerTreeStore(b);
        }
        tree = new TreeView();
        tree.set_headers_visible(false);
        var cell = new CellRendererText();
        tree.insert_column_with_attributes(-1, "", cell, "text", PlayerTreeStore.Column.VIS_TEXT);
        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tree);
        this.pack_start(sw, true, true, 0);
        tree.set_model(treemodel);
    }
}


private class Xnoise.ExtDev.PlayerTreeStore : Gtk.TreeStore {
    private static int FILE_COUNT = 150;
    
    private File base_folder;
    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(string)     //VIS_TEXT
    };

    public enum Column {
        VIS_TEXT,
        N_COLUMNS
    }
    
    public PlayerTreeStore(File base_folder) {
        this.set_column_types(col_types);
        this.base_folder = base_folder;
        populate();
    }

    private void populate() {
        tda = {};
        var job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
        device_worker.push_job(job);
    }

    private TrackData[] tda = {}; 
    
    private bool read_media_folder_job(Worker.Job job) {
        return_val_if_fail(device_worker.is_same_thread(), false);
        read_recoursive(this.base_folder, job);
        return false;
    }
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        return_if_fail(device_worker.is_same_thread());
        
        job.counter[0]++;
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            job.counter[0]--;
            if(job.counter[0] == 0)
                end_import(job);
            return;
        }
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                TrackData td = null;
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    string uri_lc = filename.down();
                    if(!Playlist.is_playlist_extension(get_suffix_from_filename(uri_lc))) {
                        var tr = new TagReader();
                        td = tr.read_tag(filepath);
                        if(td != null) {
                            td.mimetype = GLib.ContentType.get_mime_type(info.get_content_type());
                            tda += td;
                            job.big_counter[1]++;
                        }
                        if(job.big_counter[1] % 50 == 0) {
                        }
                        if(tda.length > FILE_COUNT) {
                            foreach(var tdi in tda) {
                                print("found title: %s\n", tdi.title);
                            }
//                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
//                            db_job.track_dat = (owned)tda;
//                            db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
                            tda = {};
//                            db_worker.push_job(db_job);
                        }
                    }
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        job.counter[0]--;
        if(job.counter[0] == 0) {
            if(tda.length > 0) {
//                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
//                db_job.track_dat = (owned)tda;
                tda = {};
//                db_worker.push_job(db_job);
            }
            end_import(job);
        }
        return;
    }
    
    private void end_import(Worker.Job job) {
        print("end import 1 %d %d\n", job.counter[1], job.counter[2]);
//        if(job.counter[1] != job.counter[2])
//            return;
//        var finisher_job = new Worker.Job(Worker.ExecutionType.ONCE, finish_import_job);
//        finisher_job.set_arg("msg_id", job.get_arg("msg_id"));
//        db_worker.push_job(finisher_job);
    }
}

