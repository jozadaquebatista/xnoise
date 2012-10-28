/* xnoise-icons-model.vala
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
//using Xnoise.Resources;
//using Xnoise.Utilities;




private class Xnoise.IconsModel : Gtk.ListStore, Gtk.TreeModel {
    
    private enum IconState {
        UNRESOLVED,
        RESOLVED
    }
    
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
        typeof(IconState),// STATE
        typeof(string),      // ARTIST
        typeof(string),      // ALBUM
        typeof(Xnoise.Item?),// ITEM
        typeof(string)       //IMAGE_PATH
    };

    private Gdk.Pixbuf? logo = null;
    public const int ICONSIZE = 250;
    private unowned AlbumArtView view;
    
    public IconsModel(AlbumArtView view) {
        this.set_column_types(col_types);
        this.view = view;
        logo = view.icon_cache.album_art;
        if(logo.get_width() != ICONSIZE)
            logo = logo.scale_simple(ICONSIZE, ICONSIZE, Gdk.InterpType.HYPER);
        
        global.sign_searchtext_changed.connect( (s,t) => {
            if(!cache_ready)
                return;
            if(main_window.album_view_toggle.get_active()) {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add(500, () => {
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
    }
    
    public bool cache_ready = false;
    
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
        //print("populate model\n");
        populating_model = true;
        var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_job);
        db_worker.push_job(a_job);
        a_job.finished.connect(on_populate_finished);
        return;
    }
    
    private bool populate_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        AlbumData[] ad_list = db_reader.get_all_albums_with_search(global.searchtext);
        foreach(AlbumData ad in ad_list) {
            IconState st = IconState.UNRESOLVED;
            string albumname = Markup.printf_escaped("<b>%s</b>\n", ad.album) + 
                               Markup.printf_escaped("<i>%s</i>", ad.artist);
            Gdk.Pixbuf? art = null;
            File? f = get_albumimage_for_artistalbum(ad.artist, ad.album, "extralarge");
            if(f != null)
                art = view.icon_cache.get_image(f.get_path());
            
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
