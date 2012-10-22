/* xnoise-music-browser-model.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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


using Gtk;

using Xnoise;
using Xnoise.Database;
using Xnoise.Resources;


public class Xnoise.MusicBrowserModel : Gtk.TreeStore, Gtk.TreeModel {

    private uint search_idlesource = 0;
    private unowned DockableMedia dock;
    
    public enum Column {
        ICON = 0,
        VIS_TEXT,
        ITEM,
        LEVEL,
        N_COLUMNS
    }

    public enum CollectionType {
        UNKNOWN = 0,
        HIERARCHICAL = 1,
        LISTED = 2
    }

    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf),  //ICON
        typeof(string),      //VIS_TEXT
        typeof(Xnoise.Item?),//ITEM
        typeof(int)          //LEVEL
    };

    public bool populating_model { get; private set; default = false; }
    
    public MusicBrowserModel(DockableMedia dock) {
        this.dock = dock;
        icon_repo.icon_theme_changed.connect(update_pixbufs);
        set_column_types(col_types);
        global.notify["image-path-small"].connect( () => {
            Timeout.add(100, () => {
                update_album_image();
                return false;
            });
        });
        Writer.NotificationData cbd = Writer.NotificationData();
        cbd.cb = database_change_cb;
        db_writer.register_change_callback(cbd);
        
        global.sign_searchtext_changed.connect( (s,t) => {
            //print("stc this.dock.name():%s global.active_dockable_media_name: %s\n", this.dock.name(), global.active_dockable_media_name);
            if(this.dock.name() != global.active_dockable_media_name ||
               main_window.album_view_toggle.get_active()) {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add_seconds(1, () => { //late search, if widget is not visible
                    //print("timeout search started\n");
                    filter();
                    search_idlesource = 0;
                    return false;
                });
            }
            else {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add(180, () => {
                    this.filter();
                    search_idlesource = 0;
                    return false;
                });
            }
        });
        MediaImporter.ResetNotificationData cbr = MediaImporter.ResetNotificationData();
        cbr.cb = reset_change_cb;
        media_importer.register_reset_callback(cbr);
    }
    
    private void reset_change_cb() {
        this.remove_all();
    }
    
    // this function is running in db thread so use idle
    private void database_change_cb(Writer.ChangeType changetype, Item? item) {
        switch(changetype) {
            case Writer.ChangeType.ADD_ARTIST:
                //print("got new artist\n");
                if(item.db_id == -1){
                    print("ADD_ARTIST:GOT -1\n");
                    return;
                }
                Worker.Job job;
                job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_imported_artist_job);
                job.item = item;
                db_worker.push_job(job);
                break;
            default: break;
        }
    }
    
    private bool add_imported_artist_job(Worker.Job job) {
        job.item = db_reader.get_artistitem_by_artistid(global.searchtext,
                                                        job.item.db_id,
                                                        job.item.stamp);
        if(job.item.type == ItemType.UNKNOWN) // not matching searchtext
            return false;
        Idle.add( () => {
            if(populating_model) // don't try to put an artist to the model in case we are filling anyway
                return false;
            string text = null;
            TreeIter iter_search, artist_iter = TreeIter();
            if(this.iter_n_children(null) == 0) {
                this.prepend(out artist_iter, null);
                this.set(artist_iter,
                         Column.ICON, icon_repo.artist_icon,
                         Column.VIS_TEXT, job.item.text,
                         Column.ITEM, job.item,
                         Column.LEVEL, 0
                         );
                Item? loader_item = Item(ItemType.LOADER);
                this.prepend(out iter_search, artist_iter);
                this.set(iter_search,
                         Column.ICON, icon_repo.loading_icon,
                         Column.VIS_TEXT, LOADING,
                         Column.ITEM, loader_item,
                         Column.LEVEL, 1
                         );
                return false;
            }
            string itemtext_prep = job.item.text.down().strip();
            
            for(int i = 0; i < this.iter_n_children(null); i++) {
                if(i == 0) {
                    this.iter_nth_child(out artist_iter, null, i);
                }
                else {
                    if(!iter_next(ref artist_iter))
                        break;
                }
                Item? current_item;
                this.get(artist_iter, Column.VIS_TEXT, out text, Column.ITEM, out current_item);
                if(current_item.type != ItemType.COLLECTION_CONTAINER_ARTIST)
                    continue;
                text = text != null ? text.down().strip() : EMPTYSTRING;
                if(strcmp(text.collate_key(), itemtext_prep.collate_key()) == 0) {
                    //found artist
                    return false;
                }
                if(strcmp(text.collate_key(), itemtext_prep.collate_key()) > 0) {
                    TreeIter new_artist_iter;
                    this.insert_before(out new_artist_iter, null, artist_iter);
                    this.set(new_artist_iter,
                             Column.ICON, icon_repo.artist_icon,
                             Column.VIS_TEXT, job.item.text,
                             Column.ITEM, job.item,
                             Column.LEVEL, 0
                             );
                    artist_iter = new_artist_iter;
                    Item? loader_item = Item(ItemType.LOADER);
                    this.prepend(out iter_search, artist_iter);
                    this.set(iter_search,
                             Column.ICON, icon_repo.loading_icon,
                             Column.VIS_TEXT, LOADING,
                             Column.ITEM, loader_item,
                             Column.LEVEL, 1
                             );
                    return false;
                }
            }
            TreeIter x_artist_iter;
            this.insert_after(out x_artist_iter, null, artist_iter);
            artist_iter = x_artist_iter;
//            this.append(out artist_iter, null);
            this.set(artist_iter,
                     Column.ICON, icon_repo.artist_icon,
                     Column.VIS_TEXT, job.item.text,
                     Column.ITEM, job.item,
                     Column.LEVEL, 0
                     );
            Item? loader_item = Item(ItemType.LOADER);
            this.append(out iter_search, artist_iter);
            this.set(iter_search,
                     Column.ICON, icon_repo.loading_icon,
                     Column.VIS_TEXT, LOADING,
                     Column.ITEM, loader_item,
                     Column.LEVEL, 1
                     );
            return false;
        });
        return false;
    }
    
    private void update_pixbufs() {
        if(main_window != null)
            if(main_window.musicBr != null) {
                this.ref();
                main_window.musicBr.change_model_data();
                this.unref();
            }
    }
    
    public void filter() {
        //print("filter\n");
        main_window.musicBr.set_model(null);
        this.clear();
        this.populate_model();
    }
    
    public void remove_all() {
        main_window.musicBr.set_model(null);
        this.clear();
        main_window.musicBr.set_model(this);
    }

    internal void cancel_fill_model() {
        if(populate_model_cancellable == null)
            return;
        populate_model_cancellable.cancel();
    }
    
    private Cancellable populate_model_cancellable = null;
    private bool populate_model() {
        if(populating_model)
            return false;
        populating_model = true;
        //print("populate_model\n");
        main_window.musicBr.set_model(null);
        var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_artists_job);
        a_job.cancellable = populate_model_cancellable;
        db_worker.push_job(a_job);
        a_job.finished.connect(on_populate_finished);
        return false;
    }

    private void on_populate_finished(Worker.Job sender) {
        return_if_fail(Main.instance.is_same_thread());
        //return_if_fail((int)Linux.gettid() == Main.instance.thread_id);
        sender.finished.disconnect(on_populate_finished);
        main_window.musicBr.set_model(this);
        populating_model = false;
    }
    
    // used for populating the data model
    private bool populate_artists_job(Worker.Job job) {
        if(job.cancellable.is_cancelled())
            return false;
        //Timer t = new Timer();
        //ulong x;
        //t.start();
        job.items = db_reader.get_artists_with_search(global.searchtext);
        //t.stop();
        //t.elapsed(out x);
        //print("%lu µs\n", x);
        //print("job.items.length = %d\n", job.items.length);
        Idle.add( () => {
            if(job.cancellable.is_cancelled())
                return false;
            TreeIter iter_artist, iter_search;
            foreach(Item? artist in job.items) {
                if(job.cancellable.is_cancelled())
                    break;
                this.prepend(out iter_artist, null);
                this.set(iter_artist,
                         Column.ICON, icon_repo.artist_icon,
                         Column.VIS_TEXT, artist.text,
                         Column.ITEM, artist,
                         Column.LEVEL, 0
                         );
                Item? loader_item = Item(ItemType.LOADER);
                this.append(out iter_search, iter_artist);
                this.set(iter_search,
                         Column.ICON, icon_repo.loading_icon,
                         Column.VIS_TEXT, LOADING,
                         Column.ITEM, loader_item,
                         Column.LEVEL, 1
                         );
            }
            return false;
        });
        return false;
    }

    private const string LOADING = _("Loading ...");
    
    internal void unload_children(ref TreeIter iter) {
        TreeIter iter_loader;
        Item? item = Item(ItemType.UNKNOWN);
        this.get(iter, Column.ITEM, out item);
        if(item.type != ItemType.COLLECTION_CONTAINER_ARTIST)
            return;
        Item? loader_item = Item(ItemType.LOADER);
        this.append(out iter_loader, iter);
        this.set(iter_loader,
                 Column.ICON, icon_repo.loading_icon,
                 Column.VIS_TEXT, LOADING,
                 Column.ITEM, loader_item,
                 Column.LEVEL, 1
                 );
        TreeIter child;
        for(int i = (this.iter_n_children(iter) -2); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.remove(child);
        }
    }
    
    internal void load_children(ref TreeIter iter) {
        if(!row_is_resolved(ref iter))
            load_content(ref iter);
    }
    
    private void load_content(ref TreeIter iter) {
        //print("load_content\n");
        Worker.Job job;
        Item? item = Item(ItemType.UNKNOWN);
        
        TreePath path = this.get_path(iter);
        if(path == null)
            return;
        TreeRowReference treerowref = new TreeRowReference(this, path);
        this.get(iter, Column.ITEM, out item);
        //print("item.type: %s\n", item.type.to_string());
        if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
            job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_artists_job);
            //job.cancellable = populate_model_cancellable;
            job.set_arg("treerowref", treerowref);
            job.set_arg("id", item.db_id);
            job.set_arg("stamp", item.stamp);
            db_worker.push_job(job);
        }
    }

    private bool load_artists_job(Worker.Job job) {
        if(this.populating_model)
            return false;
        job.items = db_reader.get_albums_with_search(global.searchtext,
                                                     (int32)job.get_arg("id"),
                                                     (uint32)job.get_arg("stamp"));
        //print("job.items cnt = %d\n", job.items.length);
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
                File? albumimage_file = get_albumimage_for_artistalbum(artist_name, album.text, "embedded");
                Gdk.Pixbuf albumimage = null;
                if(albumimage_file != null) {
                    if(albumimage_file.query_exists(null)) {
                        try {
                            albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
                        }
                        catch(Error e) {
                            albumimage = null;
                        }
                    }
                    else {
                        albumimage_file = get_albumimage_for_artistalbum(artist_name, album.text, null);
                       if(albumimage_file.query_exists(null)) {
                            try {
                                albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
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
                var job_title = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_title_job);
                job_title.set_arg("treerowref", treerowref);
                job_title.set_arg("artist", artist.db_id);
                job_title.set_arg("album", album.db_id);
                job_title.set_arg("stamp", album.stamp);
                db_worker.push_job(job_title);
            }
            remove_loader_child(ref iter_artist);
            return false;
        });
        return false;
    }
    
    private void remove_loader_child(ref TreeIter iter) {
        TreeIter child;
        Item? item;
        for(int i = (this.iter_n_children(iter) - 1); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.get(child, Column.ITEM, out item);
            if(item.type == ItemType.LOADER) {
                this.remove(child);
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
        this.get(child, MusicBrowserModel.Column.ITEM, out item);
        return (item.type != ItemType.LOADER);
    }

    private void update_album_image() {
        TreeIter artist_iter = TreeIter(), album_iter;
        if(!global.media_import_in_progress) {
            string text = null;
            //print("--%s\n", td.title);
            string artist = global.current_artist;
            string album = global.current_album;
            File? albumimage_file = get_albumimage_for_artistalbum(artist, album, "embedded");
            Gdk.Pixbuf albumimage = null;
            if(albumimage_file != null) {
                if(albumimage_file.query_exists(null)) {
                    try {
                        albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
                    }
                    catch(Error e) {
                        albumimage = null;
                    }
                }
                else {
                    albumimage_file = get_albumimage_for_artistalbum(artist, album, null);
                    if(albumimage_file.query_exists(null)) {
                        try {
                            albumimage = new Gdk.Pixbuf.from_file_at_scale(albumimage_file.get_path(), 30, 30, true);
                        }
                        catch(Error e) {
                            albumimage = null;
                        }
                    }
                }
            }
            for(int i = 0; i < this.iter_n_children(null); i++) {
                this.iter_nth_child(out artist_iter, null, i);
                this.get(artist_iter, Column.VIS_TEXT, out text);
                text = text != null ? text.down().strip() : EMPTYSTRING;
                if(strcmp(text, artist != null ? artist.down().strip() : EMPTYSTRING) == 0) {
                    //found artist
                    break;
                }
                if(i == (this.iter_n_children(null) - 1))
                    return;
            }
            for(int i = 0; i < this.iter_n_children(artist_iter); i++) {
                this.iter_nth_child(out album_iter, artist_iter, i);
                this.get(album_iter, Column.VIS_TEXT, out text);
                text = text != null ? text.down().strip() : EMPTYSTRING;
                if(strcmp(text, album != null ? album.down().strip() : EMPTYSTRING) == 0) {
                    //found album
                    this.set(album_iter,
                             Column.ICON, (albumimage != null ? albumimage : icon_repo.album_icon),
                             Column.LEVEL, 1
                             );
                    break;
                }
            }
        }
    }
    
    //Used for populating model
    private bool populate_title_job(Worker.Job job) {
        if(this.populating_model)
            return false;
        int32 al = (int32)job.get_arg("album");
        job.track_dat = db_reader.get_trackdata_by_albumid(global.searchtext,
                                                           al,
                                                           (uint32)job.get_arg("stamp")
        );
        Idle.add( () => {
            TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
            if((row_ref == null) || (!row_ref.valid()))
                return false;
            TreePath p = row_ref.get_path();
            TreeIter iter_title, iter_album;
            this.get_iter(out iter_album, p);
            foreach(unowned TrackData td in job.track_dat) {
                this.append(out iter_title, iter_album);
                this.set(iter_title,
                         Column.ICON, icon_repo.title_icon,
                         Column.VIS_TEXT, td.title,
                         Column.ITEM, td.item,
                         Column.LEVEL, 2
                         );
            }
            return false;
        });
        return false;
    }

    public DndData[] get_dnd_data_for_path(ref TreePath treepath) {
        TreeIter iter;
        DndData[] dnd_data_array = {};
        Item? item = null;
        this.get_iter(out iter, treepath);
        this.get(iter, Column.ITEM, out item);
        if(item != null && item.type != ItemType.UNKNOWN) {
            int id = -1;
            id = db_reader.get_source_id();
            DndData dnd_data = { item.db_id, item.type, id, item.stamp };
            dnd_data_array += dnd_data;
        }
        return dnd_data_array;
    }
}
