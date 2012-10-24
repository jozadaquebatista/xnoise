/* xnoise-albumart-view.vala
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


using Gtk;
using Cairo;


using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


class Xnoise.AlbumArtView : Gtk.IconView, TreeQueryable {
    private enum IconState {
        UNRESOLVED,
        RESOLVED
    }
    
    private static IconCache icon_cache;
    private IconsModel icons_model;
    private uint col_count_source = 0;
    private uint update_icons_source = 0;
    
    public int get_model_item_column() {
        return (int)IconsModel.Column.ITEM;
    }

    public TreeModel? get_queryable_model() {
        TreeModel? tm = this.get_model();
        return tm;
    }

    public GLib.List<TreePath>? query_selection() {
        return this.get_selected_items();
    }

    private class IconsModel : Gtk.ListStore, Gtk.TreeModel {
        public enum Column {
            ICON = 0,
            TEXT,
            STATE,
            ARTIST,
            ALBUM,
            ITEM,
            IMAGE_PATH
        }

        private GLib.Type[] col_types = new GLib.Type[] {
            typeof(Gdk.Pixbuf),  // ICON
            typeof(string),      // TEXT
            typeof(Xnoise.AlbumArtView.IconState),// STATE
            typeof(string),      // ARTIST
            typeof(string),      // ALBUM
            typeof(Xnoise.Item?),// ITEM
            typeof(string)       //IMAGE_PATH
        };

        private Gdk.Pixbuf? logo = null;
        public const int ICONSIZE = 180;
        private unowned AlbumArtView view;
        
        public IconsModel(AlbumArtView view) {
            this.set_column_types(col_types);
            this.view = view;
            try {
                logo = icon_repo.albumart;
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
            if(logo.get_width() != ICONSIZE)
                logo = logo.scale_simple(ICONSIZE, ICONSIZE, Gdk.InterpType.HYPER);
            
            global.sign_searchtext_changed.connect( (s,t) => {
                if(main_window.album_view_toggle.get_active()) {
                    if(search_idlesource != 0)
                        Source.remove(search_idlesource);
                    search_idlesource = Timeout.add(180, () => {
                        this.filter();
                        search_idlesource = 0;
                        return false;
                    });
                }
                else {
                    if(search_idlesource != 0)
                        Source.remove(search_idlesource);
                    search_idlesource = Timeout.add_seconds(1, () => {
                        this.filter();
                        search_idlesource = 0;
                        return false;
                    });
                }
            });
            MediaImporter.ResetNotificationData cbr = MediaImporter.ResetNotificationData();
            cbr.cb = reset_change_cb;
            media_importer.register_reset_callback(cbr);
            global.notify["media-import-in-progress"].connect( () => {
                if(!global.media_import_in_progress) {
                    Idle.add(() => {
                        this.filter();
                        return false;
                    });
                }
            });
        }
        
        private void reset_change_cb() {
            Idle.add(() => {
                this.remove_all();
                return false;
            });
        }
        
        public void remove_all() {
            view.set_model(null);
            this.clear();
            view.set_model(this);
        }
        
        private uint search_idlesource = 0;
        
        public void filter() {
            //print("filter\n");
            view.set_model(null);
            this.clear();
            this.populate_model();
        }
        
        private bool populating_model = false;
        internal void populate_model() {
            if(populating_model)
                return;
            print("populate model\n");
            populating_model = true;
            //print("populate_model\n");
            var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_job);
            db_worker.push_job(a_job);
            a_job.finished.connect(on_populate_finished);
            return;
        }
        
        private bool populate_job(Worker.Job job) {
            return_if_fail(db_worker.is_same_thread());
            AlbumData[] ad_list = db_reader.get_all_albums_with_search(global.searchtext);
            foreach(AlbumData ad in ad_list) {
                IconState st = IconState.UNRESOLVED;
                string albumname = Markup.printf_escaped("<b>%s</b>\n", ad.album) + 
                                   Markup.printf_escaped("<i>%s</i>", ad.artist);
                Gdk.Pixbuf? art = null;
                File? f = get_albumimage_for_artistalbum(ad.artist, ad.album, "extralarge");
                if(f != null)
                    art = icon_cache.get_image(f.get_path());
                
                if(art == null)
                    art = logo;
                else
                    st = IconState.RESOLVED;
                
                string ar = ad.artist;
                string al = ad.album;
                Item? it  = ad.item;
                Idle.add(() => {
                    TreeIter iter;
                    this.append(out iter);
                    this.set(iter,
                             Column.ICON, art,
                             Column.TEXT, albumname,
                             Column.STATE, st,
                             Column.ARTIST, ar,
                             Column.ALBUM,  al,
                             Column.ITEM,  it,
                             Column.IMAGE_PATH, (f != null ? f.get_path() : null)
                    );
                    return false;
                });
            }
            return false;
        }
        
        private void on_populate_finished(Worker.Job sender) {
            return_if_fail(Main.instance.is_same_thread());
            sender.finished.disconnect(on_populate_finished);
            view.set_model(this);
            populating_model = false;
        }
    }
    
    public AlbumArtView() {
        this.set_pixbuf_column(IconsModel.Column.ICON);
        this.set_markup_column(IconsModel.Column.TEXT);
        var font_description = new Pango.FontDescription();
        font_description.set_family("Sans");
        this.set_column_spacing(60);
        this.set_margin(20);
        this.set_row_spacing(40);
        if(icon_cache == null) {
            File album_image_dir =
                File.new_for_path(GLib.Path.build_filename(data_folder(), "album_images", null));
            icon_cache = new IconCache(album_image_dir, icons_model.ICONSIZE);
        }
        icons_model = new IconsModel(this);
        this.set_item_width(icons_model.ICONSIZE + 40);
        this.set_model(icons_model);
        icon_cache.loading_done.connect(() => {
            this.icons_model.populate_model();
        });
        this.item_activated.connect(this.on_row_activated);
        this.button_press_event.connect(this.on_button_press);
        this.key_release_event.connect(this.on_key_released);
    }

    private void on_row_activated(Gtk.IconView sender, TreePath path) {
        Item? item = Item(ItemType.UNKNOWN);
        TreeIter iter;
        if(icons_model.get_iter(out iter, path)) {
            icons_model.get(iter, IconsModel.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(item.type, 
                                                    ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED, 
                                                    ItemSelectionType.SINGLE
            );
            
            if(action != null)
                action.action(item, null);
            else
                print("action was null\n");
            
            Idle.add(() => {
                main_window.set_bottom_view(0);
                return false;
            });
            Idle.add(() => {
                if(global.position_reference == null || !global.position_reference.valid())
                    return false;
                TreePath p = global.position_reference.get_path();
                var store = (ListStore)tlm;
                TreeIter it;
                store.get_iter(out it, p);
                tl.set_focus_on_iter(ref it);
                return false;
            });
        }
    }

    public override bool draw(Cairo.Context cr) {
        
        if(col_count_source != 0)
            Source.remove(col_count_source);
        col_count_source = Timeout.add(100, set_column_count_idle);
        
        if(update_icons_source != 0)
            Source.remove(update_icons_source);
        update_icons_source = Timeout.add(100, () => {
            update_visible_icons();
            update_icons_source = 0;
            return false;
        });
        return base.draw(cr);
    }
    
    public void update_visible_icons() {
        TreePath? start_path = null, end_path = null;
        TreeIter iter;
        Xnoise.AlbumArtView.IconState state;
        string artist, album, pth;
        if(this.get_visible_range(out start_path, out end_path)) {
            do {
                this.icons_model.get_iter(out iter, start_path);
                start_path.next();
                
                this.icons_model.get(iter,
                                     IconsModel.Column.STATE, out state,
                                     IconsModel.Column.ARTIST, out artist,
                                     IconsModel.Column.ALBUM, out album,
                                     IconsModel.Column.IMAGE_PATH, out pth
                );
                if(state == IconState.RESOLVED)
                    continue;
                
                Gdk.Pixbuf? art = null;
                File? f = null;
                if(pth != null && pth != "")
                    f = File.new_for_path(pth);
                
                if(f == null) {
                    continue;
                }
                
                art = icon_cache.get_image(f.get_path());
                if(art == null) {
                    continue;
                }
                else {
                    this.icons_model.set(iter, 
                                         IconsModel.Column.ICON, art,
                                         IconsModel.Column.STATE, IconState.RESOLVED
                    );
                }
            } while(start_path != null && start_path.get_indices()[0] <= end_path.get_indices()[0]);
        }
    }
    
    private Gtk.Menu menu;
    
    private int w = 0;
    private int w_last = 0;
    private bool set_column_count_idle() {
        w = this.get_allocated_width();
        if(w == w_last) {
            col_count_source = 0;
            return false;
        }
        this.set_columns(3);
        this.set_columns(-1);
        w_last = w;
        col_count_source = 0;
        return false;
    }

    private bool on_button_press(Gdk.EventButton e) {
        Gtk.TreePath treepath = null;
        GLib.List<TreePath> selection = this.get_selected_items();
        int x = (int)e.x;
        int y = (int)e.y;
        
        if((treepath = this.get_path_at_pos(x, y)) == null)
            return true;
        
        switch(e.button) {
            case 1:
                break;
            case 3: {
                TreeIter iter;
                this.get_model().get_iter(out iter, treepath);
                bool in_sel = false;
                foreach(var px in selection) {
                    if(treepath == px) {
                        in_sel = true;
                        break;
                    }
                }
                if(!(in_sel)) {
                    this.unselect_all();
                    this.select_path(treepath);
                }
                rightclick_menu_popup(e.time);
                return true;
            }
            default: {
                break;
            }
        }
        if(selection.length() <= 0 )
            this.select_path(treepath);
        return false;
    }

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//        print("%d\n",(int)e.keyval);
        switch(e.keyval) {
            case Gdk.Key.Menu: {
                rightclick_menu_popup(e.time);
                return true;
            }
            default:
                break;
        }
        return false;
    }

    private void rightclick_menu_popup(uint activateTime) {
        menu = create_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, activateTime);
    }

    private Gtk.Menu create_rightclick_menu() {
        TreeIter iter;
        var rightmenu = new Gtk.Menu();
        GLib.List<TreePath> list;
        list = this.get_selected_items();
        ItemSelectionType itemselection = ItemSelectionType.SINGLE;
        if(list.length() > 1)
            itemselection = ItemSelectionType.MULTIPLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        this.get_model().get_iter(out iter, path);
        this.get_model().get(iter, IconsModel.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.QUERYABLE_TREE_MENU_QUERY, itemselection);
        for(int i =0; i < array.length; i++) {
            unowned Action x = array.index(i);
            //print("%s\n", x.name);
            var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? x.stock_item : Gtk.Stock.INFO), null);
            menu_item.set_label(x.info);
            menu_item.activate.connect( () => {
                x.action(item, this);
            });
            rightmenu.append(menu_item);
        }
        rightmenu.show_all();
        return rightmenu;
    }
}

private class Xnoise.IconCache : GLib.Object {
    
    private static HashTable<string,Gdk.Pixbuf> cache;
    
    private File dir;
    private int icon_size;
    
    public Cancellable cancellable;
    public signal void sign_new_album_art_loaded(string path);
    
    public signal void loading_done();
    
    
    public IconCache(File dir, int icon_size) {
        assert(io_worker != null);
        lock(cache) {
            if(cache == null) {
                cache = new HashTable<string,Gdk.Pixbuf>(str_hash, str_equal);
            }
        }
        this.cancellable = global.main_cancellable;
        this.dir = dir;
        this.icon_size = icon_size;
        Worker.Job job = new Worker.Job(Worker.ExecutionType.ONCE, this.populate_cache);
        job.cancellable = this.cancellable;
        io_worker.push_job(job);
        global.sign_album_image_fetched.connect(on_album_image_fetched);
    }
    
    private void on_album_image_fetched(string _artist, string _album, string image_path) {
//        print("on_image_fetched aav %s - %s : %s", _artist, _album, image_path);
        if(image_path == EMPTYSTRING) 
            return;
        
        if((prepare_for_comparison(global.current_artist) != prepare_for_comparison(_artist))||
           (prepare_for_comparison(check_album_name(global.current_artist, global.current_album))  != 
                prepare_for_comparison(check_album_name(_artist, _album)))) 
            return;
        File f = File.new_for_path(image_path);
        if(!f.query_exists(null)) 
            return;
        string p1 = f.get_path();
        p1 = p1.replace("_medium", "_extralarge"); // medium images are reported, extralarge not
        Worker.Job fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
        fjob.set_arg("file", p1);
        fjob.set_arg("initial_import", false);
        fjob.cancellable = this.cancellable;
        io_worker.push_job(fjob);
    }

    private void on_loading_finished() {
        return_if_fail(Main.instance.is_same_thread());
        loading_done();
    }
    
    private bool populate_cache(Worker.Job job) {
        if(job.cancellable.is_cancelled())
            return false;
        return_val_if_fail(io_worker.is_same_thread(), false);
        read_recoursive(this.dir, job);
        return false;
    }
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_val_if_fail(io_worker.is_same_thread(), false);
        
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            return;
        }
        job.big_counter[0]++;
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                string filename = info.get_name();
                string filepath = GLib.Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    var fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
                    fjob.set_arg("file", file.get_path());
                    fjob.set_arg("initial_import", true);
                    fjob.cancellable = this.cancellable;
                    import_job_count++;
                    io_worker.push_job(fjob);
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        job.big_counter[0]--;
        if(job.big_counter[0] == 0) {
            all_jobs_in_queue = true;
        }
    }
    
    private int import_job_count;
    private bool all_jobs_in_queue;

    private void import_job_count_dec_and_test(Worker.Job job) {
        if(!((bool)job.get_arg("initial_import")))
            return;
        assert(io_worker.is_same_thread());
        import_job_count--;
        if(all_jobs_in_queue && import_job_count <=0) {
            Timeout.add(100, () => {
                print("Icon Cache: inital import done.\n");
                on_loading_finished();
                return false;
            });
        }
    }
    
    private bool read_file_job(Worker.Job job) {
        return_val_if_fail(io_worker.is_same_thread(), false);
        File file = File.new_for_path((string)job.get_arg("file"));
        if(!file.get_path().has_suffix("_extralarge") && !file.get_path().has_suffix("_embedded")) {
            import_job_count_dec_and_test(job);
            return false;
        }
        if(!file.query_exists(null)) {
            import_job_count_dec_and_test(job);
            return false;
        }
        Gdk.Pixbuf? px = null;
        try {
            px = new Gdk.Pixbuf.from_file(file.get_path());
        }
        catch(Error e) {
            print("%s\n", e.message);
            import_job_count_dec_and_test(job);
            return false;
        }
        if(px == null) {
            import_job_count_dec_and_test(job);
            return false;
        }
        else {
            //px = px.scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
            px = add_shadow(px, icon_size);
            insert_image(file.get_path().replace("_embedded", "_extralarge"), px);
        }
        import_job_count_dec_and_test(job);
        return false;
    }
    
    public Gdk.Pixbuf? get_image(string path) {
        Gdk.Pixbuf? p = null;
        lock(cache) {
            p = cache.lookup(path);
        }
        return p;
    }
    
    private void insert_image(string name, Gdk.Pixbuf? pix) {
        //print("insert image : %s\n", name);
        if(pix == null) {
            lock(cache) {
                print("remove image %s\n", name);
                cache.remove(name);
            }
            return;
        }
        lock(cache) {
            cache.insert(name, pix);
        }
    }

    private Gdk.Pixbuf? shadow = null;
    
    private Gdk.Pixbuf? add_shadow(Gdk.Pixbuf pixbuf, int size) {
        if(size <= 34)
            return pixbuf;
        int shadow_size = 16;
        Gdk.Pixbuf? pix = pixbuf;
        var surface = new ImageSurface(Format.ARGB32, size, size);
        var cr = new Cairo.Context(surface);
        cr.rectangle(0, 0, size, size);
        if(shadow == null) {
            try {
                if(IconTheme.get_default().has_icon("xn-shadow"))
                    shadow = IconTheme.get_default().load_icon("xn-shadow",
                                                               size,
                                                               IconLookupFlags.FORCE_SIZE);
            }
            catch(Error e) {
                print("%s\n", e.message);
                return pixbuf;
            }
        }
        Gdk.cairo_set_source_pixbuf(cr, shadow, 0, 0);
        cr.paint();
        
        int imagesize = size -(2 * shadow_size);
        if(pixbuf.get_width() != imagesize || pixbuf.get_height() != imagesize)
            pix = pix.scale_simple(imagesize, imagesize, Gdk.InterpType.BILINEAR);
        
        Gdk.cairo_set_source_pixbuf(cr, pix, shadow_size, shadow_size);
        cr.paint();
        
        pix = Gdk.pixbuf_get_from_surface(surface, 0, 0, size, size);
        return (owned)pix;
    }
}
