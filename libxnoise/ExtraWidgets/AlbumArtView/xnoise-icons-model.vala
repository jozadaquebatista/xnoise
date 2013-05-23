/* xnoise-icons-model.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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


private class Xnoise.IconsModel : Gtk.ListStore, Gtk.TreeModel {
    
    internal enum IconState {
        UNRESOLVED,
        RESOLVED
    }
    
    public enum Column {
        ICON = 0,
        TEXT,
        STATE,
        ARTIST,
        ALBUM,
        EXTRA_INFO,
        ITEM,
        IMAGE_PATH
    }

    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf),  // ICON
        typeof(string),      // TEXT
        typeof(IconState),   // STATE
        typeof(string),      // ARTIST
        typeof(string),      // ALBUM
        typeof(string),      // EXTRA_INFO
        typeof(Xnoise.Item?),// ITEM
        typeof(string)       //IMAGE_PATH
    };

    private Gdk.Pixbuf? logo = null;
    private unowned AlbumArtView view;
    
    public IconsModel(AlbumArtView view) {
        this.set_column_types(col_types);
        this.view = view;
        logo = AlbumArtView.icon_cache.album_art;
        
        global.sign_searchtext_changed.connect( (s,t) => {
            if(main_window.album_art_view_visible) {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add(700, () => { // give the user time for typing
                    this.filter();
                    search_idlesource = 0;
                    return false;
                });
            }
            else {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add_seconds(2, () => {
                    this.filter();
                    search_idlesource = 0;
                    return false;
                });
            }
        });
        Idle.add(() => {
            //print("restore aa sort\n");
            if(main_window.album_view_sorting == null)
                return true;
            string? name = Params.get_string_value("album_art_view_sorting");
            if(name == null || name == EMPTYSTRING)
                name = "ARTIST";
            main_window.album_view_sorting.select(name, false);
            string? dir = Params.get_string_value("album_art_view_direction");
            if(dir == null || dir == EMPTYSTRING)
                dir = "ASC";
            main_window.album_view_direction.select(dir, false);
            return false;
        });
        Timeout.add_seconds(3, () => {
            main_window.album_view_sorting.sign_selected.connect( (sender,nme) => {
                Params.set_string_value("album_art_view_sorting", nme);
//                if(!cache_ready)
//                    return;
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Idle.add( () => {
                    search_idlesource = 0;
                    if(immediate_search_flag) {
                        immediate_search_flag = false;
                        return false;
                    }
                    this.filter();
                    return false;
                });
            });
            main_window.album_view_direction.sign_selected.connect( (sender,nme) => {
                Params.set_string_value("album_art_view_direction", nme);
//                if(!cache_ready)
//                    return;
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Idle.add( () => {
                    search_idlesource = 0;
                    if(immediate_search_flag) {
                        immediate_search_flag = false;
                        return false;
                    }
                    this.filter();
                    return false;
                });
            });
            return false;
        });
    }
    
    private bool immediate_search_flag = false;
    public void immediate_search(string text) {
        if(text == null)
            return;
//        if(!cache_ready)
//            return;
        global.searchtext = text;
        if(search_idlesource != 0) {
            Source.remove(search_idlesource);
            search_idlesource = 0;
        }
        immediate_search_flag = true;
        this.filter();
    }
    
//    public bool cache_ready = true;//false;
    
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
        if(global.media_import_in_progress)
            return;
        //print("populate model\n");
        populating_model = true;
        var a_job = new Worker.Job(Worker.ExecutionType.ONCE, this.populate_job, Worker.Priority.HIGH, on_populate_finished);
        db_worker.push_job(a_job);
//        a_job.finished.connect(on_populate_finished);
        return;
    }
    
    //Timer t = new Timer();
    private const int FIRST_RUN_CNT = 30;
    private bool populate_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        if(global.media_import_in_progress)
            return false;
        //t.reset();
        //t.start();
        AlbumData[] ad_list = db_reader.get_all_albums_with_search(
                global.searchtext,
                main_window.album_view_sorting.get_active_name(),
                main_window.album_view_direction.get_active_name()
        );
        //t.stop();
        //ulong usec;
        //t.elapsed(out usec);
        //print("album query done in %lu\n", usec);
        Idle.add(() => {
            for(int i = 0; i < FIRST_RUN_CNT && i < ad_list.length; i++) { 
                //AT FIRST PUT SOME RESULTS INTO THE ALBUM ART VIEW, SO
                // THE USER WILL SEE SOMETHING FOR LARGE RESULT SETS.
                IconState st = IconState.UNRESOLVED;
                string artist_name = ad_list[i].artist;
                string albumname = Markup.printf_escaped("<b>%s</b>\n", ad_list[i].album) + 
                                   Markup.printf_escaped("<i>%s</i>", artist_name);
                Gdk.Pixbuf? art = null;
                File? f = get_albumimage_for_artistalbum(ad_list[i].artist, ad_list[i].album, "extralarge");
                if(f != null)
                    art = AlbumArtView.icon_cache.get_image(f.get_path());
                
                if(art == null)
                    art = logo;
                else
                    st = IconState.RESOLVED;
                
//                string ar = ad_list[i].albumartist;
                string al = ad_list[i].album;
                Item? it  = ad_list[i].item;
                TreeIter iter;
                this.append(out iter);
                string? extra_info = null;
                switch(main_window.album_view_sorting.get_active_name()) {
                    case "YEAR":
                        extra_info = ad_list[i].year != 0 ? ad_list[i].year.to_string() : null;
                        break;
                    case "GENRE":
                        if(ad_list[i].genre != null &&
                           ad_list[i].genre != "")  {
                            extra_info = ad_list[i].genre;
                        }
                        break;
                    default:
                        break;
                }
                this.set(iter,
                         Column.ICON, art,
                         Column.TEXT, albumname,
                         Column.STATE, st,
                         Column.ARTIST, artist_name,
                         Column.ALBUM,  al,
                         Column.ITEM,  it,
                         Column.EXTRA_INFO, extra_info,
                         Column.IMAGE_PATH, (f != null ? f.get_path() : null)
                );
            }
            Idle.add(() => {
                if(FIRST_RUN_CNT < ad_list.length) {
                    for(int i = FIRST_RUN_CNT; i < ad_list.length; i++) { //foreach(AlbumData ad in ad_list) 
                        IconState st = IconState.UNRESOLVED;
                        string artist_name = ad_list[i].artist;
                        string albumname = Markup.printf_escaped("<b>%s</b>\n", ad_list[i].album) + 
                                           Markup.printf_escaped("<i>%s</i>", artist_name);
                        Gdk.Pixbuf? art = null;
                        File? f = get_albumimage_for_artistalbum(artist_name, ad_list[i].album, "extralarge");
                        if(f != null)
                            art = AlbumArtView.icon_cache.get_image(f.get_path());
                        
                        if(art == null)
                            art = logo;
                        else
                            st = IconState.RESOLVED;
                        
//                        string ar = ad_list[i].artist;
                        string al = ad_list[i].album;
                        Item? it  = ad_list[i].item;
                        string? extra_info = null;
                        switch(main_window.album_view_sorting.get_active_name()) {
                            case "YEAR":
                                extra_info = ad_list[i].year != 0 ? ad_list[i].year.to_string() : null;
                                break;
                            case "GENRE":
                                if(ad_list[i].genre != null &&
                                   ad_list[i].genre != "")  {
                                    extra_info = ad_list[i].genre;
                                }
                                break;
                            default:
                                break;
                        }
                        Idle.add(() => {
                            TreeIter iter;
                            this.append(out iter);
                            this.set(iter,
                                     Column.ICON, art,
                                     Column.TEXT, albumname,
                                     Column.STATE, st,
                                     Column.ARTIST, artist_name,
                                     Column.ALBUM,  al,
                                     Column.ITEM,  it,
                                     Column.EXTRA_INFO, extra_info,
                                     Column.IMAGE_PATH, (f != null ? f.get_path() : null)
                            );
                            return false;
                        });
                    }
                }
                return false;
            });
            return false;
        });
        return false;
    }
    
    private void on_populate_finished() {
        return_if_fail(Main.instance.is_same_thread());
//        sender.finished.disconnect(on_populate_finished);
        view.set_model(this);
        populating_model = false;
    }
}
