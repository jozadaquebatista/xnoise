/* magnatune-treestore.vala
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
using Xnoise.Resources;



private class MagnatuneTreeStore : Gtk.TreeStore {
    private Gdk.Pixbuf artist_icon;
    private Gdk.Pixbuf album_icon;
    private Gdk.Pixbuf title_icon;
    private Gdk.Pixbuf loading_icon;
    private static const string LOADING = _("Loading ...");
    private unowned DockableMedia dock;
    private unowned MagnatuneTreeView view;
    private uint search_idlesource = 0;
    public MagnatuneDatabaseReader dbreader;

    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf),  //ICON
        typeof(string),      //VIS_TEXT
        typeof(Xnoise.Item?),//ITEM
        typeof(int)          //LEVEL
    };

    public enum Column {
        ICON = 0,
        VIS_TEXT,
        ITEM,
        LEVEL,
        N_COLUMNS
    }
    
    private int data_source_id = -1;
    
    private Cancellable cancel;
    
    public MagnatuneTreeStore(DockableMedia dock, MagnatuneTreeView view, Cancellable cancel) {
        this.dock = dock;
        this.view = view;
        this.cancel = cancel;
        set_column_types(col_types);
        create_icons();
        
        if(dbreader == null) {
            dbreader = new MagnatuneDatabaseReader(cancel);
        }
        if(dbreader == null)
            assert_not_reached();
        dbreader.refreshed_stamp.connect( () => {
            this.filter();
        });
        data_source_id = register_data_source(dbreader);
        
        global.sign_searchtext_changed.connect( (s,t) => {
            if(this.dock.name() != global.active_dockable_media_name) {
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
        global.notify["image-path-small"].connect( () => {
            Timeout.add_seconds(1, () => {
                update_album_image();
                return false;
            });
        });
    }
    
    ~MagnatuneTreeStore() {
        print("remove mag data source\n");
        remove_data_source_by_id(data_source_id);
    }
    
    public string? get_download_url(string? sku) {
        if(sku == null)
            return null;
        if(dbreader.username == null || dbreader.password == null)
            return null;
        string url = null;
        url = "http://" +
              Uri.escape_string(dbreader.username, null, true) +
              ":" +
              Uri.escape_string(dbreader.password, null, true) +
              "@" +
              "download" + //membershipType
              ".magnatune.com/buy/membership_free_dl_xml?sku=" +
              sku +
              "&id=xnoise";
        return url;
    }
    
    private void update_album_image() {
        if(this.cancel.is_cancelled())
            return;
        TreeIter? artist_iter = TreeIter(), album_iter;
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
                    albumimage_file = get_albumimage_for_artistalbum(artist, album, null);
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
                             Column.ICON, (albumimage != null ? albumimage : null),
                             Column.LEVEL, 1
                             );
                    break;
                }
            }
        }
    }

    private void create_icons() {
        try {
            unowned IconTheme theme = IconTheme.get_default();
            Gtk.Invisible w = new Gtk.Invisible();
            Gdk.Pixbuf icon  = w.render_icon_pixbuf(Gtk.Stock.FILE, IconSize.BUTTON);
            int iconheight = icon.height;
            if(theme.has_icon("system-users")) 
                artist_icon = theme.load_icon("system-users", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("stock_person")) 
                artist_icon = theme.load_icon("stock_person", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                artist_icon = w.render_icon_pixbuf(Gtk.Stock.ORIENTATION_PORTRAIT, IconSize.BUTTON);
            
            album_icon = w.render_icon_pixbuf(Gtk.Stock.CDROM, IconSize.BUTTON);
            
            if(theme.has_icon("media-audio")) 
                title_icon = theme.load_icon("media-audio", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("audio-x-generic")) 
                title_icon = theme.load_icon("audio-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                title_icon = w.render_icon_pixbuf(Gtk.Stock.OPEN, IconSize.BUTTON);
                
            loading_icon = w.render_icon_pixbuf(Gtk.Stock.REFRESH , IconSize.BUTTON);
        }
        catch(GLib.Error e) {
            print("Error: %s\n",e.message);
        }
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
                      Column.ICON, loading_icon,
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
        
        job.items = dbreader.get_albums(global.searchtext,
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
                         Column.ICON, (albumimage != null ? albumimage : null),
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

    private bool populate_title_job(Worker.Job job) {
        if(this.cancel.is_cancelled())
            return false;
        
        HashTable<ItemType,Item?>? item_ht =
            new HashTable<ItemType,Item?>(direct_hash, direct_equal);
        item_ht.insert(job.item.type, job.item);
        job.track_dat = dbreader.get_trackdata_for_album(global.searchtext,
                                                          CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                          item_ht);
//        job.track_dat = dbreader.get_trackdata_for_album(global.searchtext, (int32)job.get_arg("albumid"), (uint32)job.get_arg("stamp"));
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
                              Column.ICON, null,
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
    }
    
    private bool populate_artists_job(Worker.Job job) {
        if(this.cancel.is_cancelled())
            return false;
        job.items = dbreader.get_artists(global.searchtext,
                                         global.collection_sort_mode,
                                         null
                                         );
//        job.items = dbreader.get_artists_with_search(global.searchtext);
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
                              Column.ICON, null,
                              Column.VIS_TEXT, i.text,
                              Column.ITEM, i,
                              Column.LEVEL, 0
                );
                Item? loader_item = Item(ItemType.LOADER);
                this.append(out iter_loader, iter);
                this.set(iter_loader,
                              Column.ICON, loading_icon,
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

    public DndData[] get_dnd_data_for_path(ref TreePath treepath) {
        TreeIter iter;
        DndData[] dnd_data_array = {};
        Item? item = null;
        this.get_iter(out iter, treepath);
        this.get(iter, Column.ITEM, out item);
        if(item != null && item.type != ItemType.UNKNOWN) {
            int id = -1;
            id = dbreader.get_source_id();
            DndData dnd_data = { item.db_id, item.type, id, item.stamp };
            dnd_data_array += dnd_data;
        }
        return dnd_data_array;
    }
}

