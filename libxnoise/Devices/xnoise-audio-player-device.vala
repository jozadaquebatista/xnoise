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
    private PlayerTreeView tree;
    
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
        tree = new PlayerTreeView(audio_player_device);

        var sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tree);
        this.pack_start(sw, true, true, 0);
//        tree.set_model(treemodel);
    }
}


private class Xnoise.ExtDev.PlayerTreeView : Gtk.TreeView {
    private PlayerTreeStore treemodel;
    private unowned AudioPlayerDevice audio_player_device;
    
    
    public PlayerTreeView(AudioPlayerDevice audio_player_device) {
        this.audio_player_device = audio_player_device;
        File b = File.new_for_uri(audio_player_device.get_uri());
        assert(b != null);
        b = b.get_child("Music");
        assert(b != null);
        assert(b.get_path() != null);
        if(b.query_exists(null))
            treemodel = new PlayerTreeStore(this, b, GlobalAccess.main_cancellable);
        else {
            b = File.new_for_uri(audio_player_device.get_uri());
            b = b.get_child("media"); // old android devices
            treemodel = new PlayerTreeStore(this, b, GlobalAccess.main_cancellable);
        }
        setup_view();
//        tree.set_headers_visible(false);
//        var cell = new CellRendererText();
//        tree.insert_column_with_attributes(-1, "", cell, "text", PlayerTreeStore.Column.VIS_TEXT);
    }
    
    private void on_row_expanded(TreeIter iter, TreePath path) {
        treemodel.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        treemodel.unload_children(ref iter);
    }
    
    private void setup_view() {
        
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
//        this.set_size_request(300, 500);
        
//        fontsize = Params.get_int_value("fontsizeMB");
//        Gtk.StyleContext context = this.get_style_context();
//        font_description = context.get_font(StateFlags.NORMAL).copy();
//        font_description.set_size((int)(global.fontsize_dockable * Pango.SCALE));
        
        var column = new TreeViewColumn();
        
//        int expander = 0;
//        this.style_get("expander-size", out expander);
//        int hsepar = 0;
//        this.style_get("horizontal-separator", out hsepar);
//        renderer = new FlowingTextRenderer(this.ow, font_description, column, expander, hsepar);
        
//        main_window.msw.selection_changed.connect( (s,n) => {
//            if(n == name_buffer)
//                return;
//            if(n == this.dock.name())
//                last_width++;
//            name_buffer = n;
//        });
        
//        this.ow.size_allocate.connect_after( (s, a) => {
//            unowned TreeViewColumn tvc = this.get_column(0);
//            int current_width = this.ow.get_allocated_width();
//            if(last_width == current_width)
//                return;
//            
//            last_width = current_width;
//            
//            tvc.max_width = tvc.min_width = current_width - 20;
//            TreeModel? xm = this.get_model();
//            if(xm != null && !in_update_view)
//                xm.foreach( (mo, pt, it) => {
//                    if(mo == null)
//                        return true;
//                    mo.row_changed(pt, it);
//                    return false;
//                });
//        });
        
        var pixbufRenderer = new CellRendererPixbuf();
        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
        var renderer = new CellRendererText();
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", PlayerTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", PlayerTreeStore.Column.VIS_TEXT); // no markup!!
        column.add_attribute(renderer, "level", PlayerTreeStore.Column.LEVEL);
        column.add_attribute(renderer, "pix", PlayerTreeStore.Column.ICON);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
        
//        global.notify["fontsize-dockable"].connect( () => {
//            this.fontsize = global.fontsize_dockable;
//        });
    }


}


private class Xnoise.ExtDev.PlayerTreeStore : Gtk.TreeStore {
    private static int FILE_COUNT = 150;
    private AudioPlayerTempDb db;
    private unowned PlayerTreeView view;
    private File base_folder;
    
    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf),  //ICON
        typeof(string),      //VIS_TEXT
        typeof(Xnoise.Item?),//ITEM
        typeof(int)          //LEVEL
    };
    
    public enum Column {
        ICON,
        VIS_TEXT,
        ITEM,
        LEVEL,
        N_COLUMNS
    }
    
    private unowned Cancellable cancel;
    
    public PlayerTreeStore(PlayerTreeView view, File base_folder, Cancellable cancel) {
        db = new AudioPlayerTempDb(GlobalAccess.main_cancellable);
        this.set_column_types(col_types);
        this.base_folder = base_folder;
        this.cancel = cancel;
        this.view = view;
        load_files();
    }

    private void load_files() {
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
                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
                            db_job.track_dat = (owned)tda;
                            db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
                            tda = {};
                            db_worker.push_job(db_job);
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
                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
                db_job.track_dat = (owned)tda;
                tda = {};
                db_worker.push_job(db_job);
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
        Idle.add(() => {
            filter();
            return false;
        });
    }
    
    private bool insert_trackdata_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        db.begin_transaction();
        foreach(TrackData td in job.track_dat) {
            db.insert_tracks(ref job.track_dat);
        }
        db.commit_transaction();
        return false;
    }
    
    
    public void filter() {
        //print("filter\n");
        view.set_model(null);
        this.clear();
        this.populate_model();
    }
    
    public void unload_children(ref TreeIter iter) {
        TreeIter iter_loader;
        TreePath pa = this.get_path(iter);
        if(pa.get_depth() != 1)
            return;
        Item? loader_item = Item(ItemType.LOADER);
        this.append(out iter_loader, iter);
        this.set(iter_loader,
                      Column.ICON, icon_repo.loading_icon,
                      Column.VIS_TEXT, LOADING,
                      Column.ITEM, loader_item,
                      Column.LEVEL, 0
        );
        TreeIter child;
        for(int i = (this.iter_n_children(iter) -2); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.remove(ref child);
        }
    }
    
    private void remove_loader_child(ref TreeIter iter) {
        TreeIter child;
        Item? item;
        for(int i = (this.iter_n_children(iter) - 1); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.get(child, Column.ITEM, out item);
            if(item.type == ItemType.LOADER) {
                this.remove(ref child);
                return;
            }
        }
    }
    
    private bool row_is_resolved(ref TreeIter iter) {
        if(this.iter_n_children(iter) != 1)
            return true;
        TreeIter child;
        Item? item = Item(ItemType.UNKNOWN);
        this.iter_nth_child(out child, iter, 0);
        this.get(child, Column.ITEM, out item);
        return (item.type != ItemType.LOADER);
    }

    public void load_children(ref TreeIter iter) {
        if(!row_is_resolved(ref iter))
            load_content(ref iter);
    }
    
    private void load_content(ref TreeIter iter) {
        //print("load_content\n");
        Worker.Job job;
        Item? item = Item(ItemType.UNKNOWN);
        this.get(iter, Column.ITEM, out item);
        TreePath path = this.get_path(iter);
        if(path == null)
            return;
        TreeRowReference treerowref = new TreeRowReference(this, path);
        if(path.get_depth() == 1) {
            job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_album_and_tracks_job);
            job.set_arg("treerowref", treerowref);
            job.item = item;
            db_worker.push_job(job);
        }
    }

    private bool load_album_and_tracks_job(Worker.Job job) {
        if(this.cancel.is_cancelled())
            return false;
        HashTable<ItemType,Item?>? item_ht = 
            new HashTable<ItemType,Item?>(direct_hash, direct_equal);
        item_ht.insert(job.item.type, job.item);
        
        job.items = db.get_albums(global.searchtext,
                                        global.collection_sort_mode,
                                        item_ht);
        //print("xx1 job.items cnt = %d\n", job.items.length);
        Idle.add( () => {
            TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
            if(row_ref == null || !row_ref.valid())
                return false;
            TreePath p = row_ref.get_path();
            TreeIter iter_artist, iter_album;
            this.get_iter(out iter_artist, p);
            Item? artist;
            string artist_name;
            this.get(iter_artist, Column.ITEM, out artist, Column.VIS_TEXT, out artist_name);
            foreach(Item? album in job.items) {     //ALBUMS
                if(this.cancel.is_cancelled())
                    return false;
                File? albumimage_file = get_albumimage_for_artistalbum(artist_name,
                                                                       album.text,
                                                                       "embedded");
                Gdk.Pixbuf albumimage = null;
                if(albumimage_file != null) {
                    if(albumimage_file.query_exists(null)) {
                        try {
                            albumimage = new Gdk.Pixbuf.from_file_at_scale(
                                                             albumimage_file.get_path(),
                                                             30,
                                                             30,
                                                             true
                                                             );
                        }
                        catch(Error e) {
                            albumimage = null;
                        }
                    }
                    else {
                        albumimage_file = get_albumimage_for_artistalbum(artist_name, album.text, null);
                       if(albumimage_file.query_exists(null)) {
                            try {
                                albumimage = new Gdk.Pixbuf.from_file_at_scale(
                                                                 albumimage_file.get_path(),
                                                                 30,
                                                                 30,
                                                                 true
                                                                 );
                            }
                            catch(Error e) {
                                albumimage = null;
                            }
                        }
                    }
                }
                this.append(out iter_album, iter_artist);
                this.set(iter_album,
                         Column.ICON, (albumimage != null ? albumimage : icon_repo.album_icon),
                         Column.VIS_TEXT, album.text,
                         Column.ITEM, album,
                         Column.LEVEL, 1
                );
                Gtk.TreePath p1 = this.get_path(iter_album);
                TreeRowReference treerowref = new TreeRowReference(this, p1);
                var job_title = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY,
                                               this.populate_title_job);
                job_title.set_arg("treerowref", treerowref);
                job_title.item = album;
                db_worker.push_job(job_title);
            }
            remove_loader_child(ref iter_artist);
            return false;
        });
        return false;
    }

    private const string LOADING = _("Loading ...");

    private bool populate_title_job(Worker.Job job) {
        if(this.cancel.is_cancelled())
            return false;
        
        HashTable<ItemType,Item?>? item_ht =
            new HashTable<ItemType,Item?>(direct_hash, direct_equal);
        item_ht.insert(job.item.type, job.item);
        job.track_dat = db.get_trackdata_for_album(global.searchtext,
                                                          CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                          item_ht);
//        job.track_dat = db.get_trackdata_for_album(global.searchtext, (int32)job.get_arg("albumid"), (uint32)job.get_arg("stamp"));
        Idle.add( () => {
            TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
            if((row_ref == null) || (!row_ref.valid()))
                return false;
            TreePath p = row_ref.get_path();
            TreeIter iter_title, iter_album;
            this.get_iter(out iter_album, p);
            foreach(TrackData td in job.track_dat) {
                if(this.cancel.is_cancelled())
                    return false;
                this.append(out iter_title, iter_album);
                this.set(iter_title,
                              Column.ICON, icon_repo.title_icon,
                              Column.VIS_TEXT, td.title,
                              Column.ITEM, (Item?)td.item,
                              Column.LEVEL, 2
                         );
            }
            return false;
        });
        return false;
    }
    
    private bool populate_model() {
        if(this.cancel.is_cancelled())
            return false;
        view.model = null;
        this.clear();
        var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_artists_job);
        db_worker.push_job(a_job);
        return false;
//        if(this.cancel.is_cancelled())
//            return false;
//        view.model = null;
//        this.clear();
//        db_worker.push_job(a_job);
//        return false;
    }
    
    private bool populate_artists_job(Worker.Job job) {
        if(this.cancel.is_cancelled())
            return false;
        job.items = db.get_artists(global.searchtext,
                                         global.collection_sort_mode,
                                         null
                                         );
//        job.items = db.get_artists_with_search(global.searchtext);
        //print("job.items.length : %d\n", job.items.length);
        Idle.add(() => {
            if(this == null)
                return false;
            TreeIter iter, iter_loader;
            foreach(Item? i in job.items) {
                if(this.cancel.is_cancelled())
                    return false;
                this.prepend(out iter, null);
                this.set(iter,
                              Column.ICON, icon_repo.artist_icon,
                              Column.VIS_TEXT, i.text,
                              Column.ITEM, i,
                              Column.LEVEL, 0
                );
                Item? loader_item = Item(ItemType.LOADER);
                this.append(out iter_loader, iter);
                this.set(iter_loader,
                              Column.ICON, icon_repo.loading_icon,
                              Column.VIS_TEXT, LOADING,
                              Column.ITEM, loader_item,
                              Column.LEVEL, 1
                );
            }
            if(this.cancel.is_cancelled())
                return false;
            view.set_model(this);
            return false;
        });
        return false;
    }
}

