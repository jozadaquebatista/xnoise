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
    
    public int get_model_item_column() {
        return (int)IconsModel.Column.ITEM;
    }

    private class IconsModel : Gtk.ListStore, Gtk.TreeModel {
        public enum Column {
            ICON = 0,
            TEXT,
            STATE,
            ARTIST,
            ALBUM,
            ITEM
        }

        private GLib.Type[] col_types = new GLib.Type[] {
            typeof(Gdk.Pixbuf),  // ICON
            typeof(string),      // TEXT
            typeof(Xnoise.AlbumArtView.IconState),// STATE
            typeof(string),      // ARTIST
            typeof(string),      // ALBUM
            typeof(Xnoise.Item?) // ITEM
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
//            TreeIter iter;
            Timeout.add_seconds(1, () => {
                this.clear();
                populate_model();
                return false;
            });
        }
        
        private bool populating_model = false;
        internal void populate_model() {
            if(populating_model)
                return;
            populating_model = true;
            //print("populate_model\n");
            var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_job);
            db_worker.push_job(a_job);
            a_job.finished.connect(on_populate_finished);
            return;
        }
        
        private bool populate_job(Worker.Job job) {
            return_if_fail(db_worker.is_same_thread());
            AlbumData[] ad_list = db_reader.get_all_albums_with_search("");
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
                Item? it = ad.item;
                Idle.add(() => {
                    TreeIter iter;
                    this.append(out iter);
                    this.set(iter,
                             Column.ICON, art,
                             Column.TEXT, albumname,
                             Column.STATE, st,
                             Column.ARTIST, ar,
                             Column.ALBUM,  al,
                             Column.ITEM,  it
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
        icons_model = new IconsModel(this);
        this.set_model(icons_model);
        this.set_pixbuf_column(IconsModel.Column.ICON);
        this.set_markup_column(IconsModel.Column.TEXT);
        var font_description = new Pango.FontDescription();
        font_description.set_family("Sans");
        this.set_item_width(icons_model.ICONSIZE + 40);
        this.set_column_spacing(60);
        this.set_row_spacing(40);
        if(icon_cache == null) {
            File album_image_dir =
                File.new_for_path(Path.build_filename(data_folder(), "album_images", null));
            icon_cache = new IconCache(album_image_dir, icons_model.ICONSIZE);
        }
        icon_cache.loading_started.connect(() => {
            Timeout.add_seconds(1, () => {
                this.set_model(null);
                icons_model.clear();
                icons_model.populate_model();
                return false;
            });
        });
        this.item_activated.connect(this.on_row_activated);
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
        Idle.add(set_column_count_idle);
        Idle.add(() => {
            update_visible_icons();
            return false;
        });
        return base.draw(cr);
    }
    
    public void update_visible_icons() {
        TreePath? start_path = null, end_path = null;
        TreeIter iter;
        Xnoise.AlbumArtView.IconState state;
        string artist, album;
        if(this.get_visible_range(out start_path, out end_path)) {
            do {
                this.icons_model.get_iter(out iter, start_path);
                start_path.next();
                
                this.icons_model.get(iter,
                                     IconsModel.Column.STATE, out state,
                                     IconsModel.Column.ARTIST, out artist,
                                     IconsModel.Column.ALBUM, out album
                );
                
                if(state == IconState.RESOLVED)
                    continue;
                
                Gdk.Pixbuf? art = null;
                File f = get_albumimage_for_artistalbum(artist, album, "extralarge");
                if(f == null)
                    continue;
                art = icon_cache.get_image(f.get_path());
                if(art == null) {
//                    print("pix not in buffer\n");
                    continue;
                }
                else {
//                    print("pix in buffer\n");
                    if(art.get_width() != icons_model.ICONSIZE)
                        art = art.scale_simple(icons_model.ICONSIZE,
                                               icons_model.ICONSIZE,
                                               Gdk.InterpType.HYPER);
                    this.icons_model.set(iter, 
                                         IconsModel.Column.ICON, art,
                                         IconsModel.Column.STATE, IconState.RESOLVED
                    );
                }
            } while(start_path != null && start_path.get_indices()[0] <= end_path.get_indices()[0]);
        }
    }
    
    private int w = 0;
    private int w_last = 0;
    private bool set_column_count_idle() {
        w = this.get_allocated_width();
        if(w == w_last)
            return false;
            
        //TODO Improve size calculation
//        print("item width: %d   margin: %d   padding: %d    spaceing: %d\n", this.get_item_width(),
//                                                                             this.get_margin(),
//                                                                             this.get_item_padding(),
//                                                                             this.get_column_spacing());
        int c = (int)((w + (this.get_column_spacing() + this.get_item_padding()) )/ 
                                (this.get_item_width() + 
                                ( 2 * this.get_margin()) +
                                (2 * this.get_item_padding()) +
                                (this.get_column_spacing())));
//        int c = (int)((w) ) / ( this.get_item_width() + 
//                                (2 * this.get_margin()) +
//                                (2 * this.get_item_padding()) );
////        c = (int)((w) ) / ( this.get_item_width() + 
////                            (2 * this.get_margin()) +
////                            (2 * this.get_item_padding()) + 
////                            (c - 1) * this.get_column_spacing());
////        c = c + (c - 1) * this.get_column_spacing();
//        int w2 = c * ( this.get_item_width() + 
//                       (2 * this.get_margin()) +
//                       (2 * this.get_item_padding()) ) + 
//                 ((c - 1) * this.get_column_spacing());
//        if(w2 > w)
//            c = c - 1;
        if(c < 1)
            c = 1;
//        print("w: %d  w2: %d   c: %d\n", w, w2, c);
        //int xw = c * this.get_item_width() + c * 2 * this.get_margin() + int.max(0, (c - 1) * this.get_column_spacing());
        //print("w: %d   xw: %d\n", w, xw);
        this.set_columns(c);
        w_last = w;
        return false;
    }
}

private class Xnoise.IconCache : GLib.Object {
    
    private static HashTable<string,Gdk.Pixbuf> cache;
    
    private File dir;
    private int icon_size;
    
    public Cancellable cancellable = new Cancellable();
    
    public signal void loading_started();
    public IconCache(File dir, int icon_size) {
        assert(io_worker != null);
        lock(cache) {
            if(cache == null) {
                cache = new HashTable<string,Gdk.Pixbuf>(str_hash, str_equal);
            }
        }
        this.dir = dir;
        this.icon_size = icon_size;
        Worker.Job job = new Worker.Job(Worker.ExecutionType.ONCE, this.populate_cache);
        job.cancellable = this.cancellable;
        io_worker.push_job(job);
        job.finished.connect(on_loading_finished);
    }
    
    private void on_loading_finished(Worker.Job sender) {
        return_if_fail(Main.instance.is_same_thread());
        sender.finished.disconnect(on_loading_finished);
        Idle.add(() => {
            loading_started();
            return false;
        });
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
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    Worker.Job fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
                    fjob.set_arg("file", file.get_path());
                    fjob.cancellable = this.cancellable;
                    io_worker.push_job(fjob);
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
    }

    private bool read_file_job(Worker.Job job) {
        return_val_if_fail(io_worker.is_same_thread(), false);
        File file = File.new_for_path((string)job.get_arg("file"));
        if(!file.get_path().has_suffix("extralarge"))
            return false;
        Gdk.Pixbuf? px = null;
        try {
            px = new Gdk.Pixbuf.from_file(file.get_path());
        }
        catch(Error e) {
            print("%s\n", e.message);
            return false;
        }
        if(px == null) {
            return false;
        }
        else {
            px = px.scale_simple(icon_size, icon_size, Gdk.InterpType.HYPER);
            insert_image(file.get_path(), px);
        }
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
        if(pix == null) {
            lock(cache) {
                cache.remove(name);
            }
            return;
        }
        lock(cache) {
            cache.insert(name, pix);
        }
    }
}
