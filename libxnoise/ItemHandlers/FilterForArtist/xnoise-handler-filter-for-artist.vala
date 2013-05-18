/* xnoise-handler-remove-cover.vala
 *
 * Copyright (C) 2013  Jörn Magens
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

using Sqlite;


using Xnoise;
using Xnoise.Resources;


internal class Xnoise.HandlerFilterForArtist : ItemHandler {
    private Action a; 
    private Action b; 
    private static const string ainfo = _("Filter for artist");
    private static const string aname = "A HandlerFilterForArtist";
    
    private static const string name = "HandlerFilterForArtist";
    
    public HandlerFilterForArtist() {
        a = new Action();
        a.action = set_filter;
        a.info = ainfo;
        a.name = aname;
        a.stock_item = Gtk.Stock.INFO;
        a.context = ActionContext.NONE;
        
        b = new Action();
        b.action = set_filter_tl_track;
        b.info = ainfo;
        b.name = aname;
        b.stock_item = Gtk.Stock.INFO;
        b.context = ActionContext.NONE;
    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.MENU_PROVIDER;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type,
                                               ActionContext context,
                                               ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        if(selection != ItemSelectionType.SINGLE)
            return null;
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
            if(type == ItemType.COLLECTION_CONTAINER_ALBUMARTIST ||
               type == ItemType.COLLECTION_CONTAINER_ALBUM ||
               type == ItemType.COLLECTION_CONTAINER_ARTIST ||
               type == ItemType.LOCAL_AUDIO_TRACK) {
                if(type == ItemType.COLLECTION_CONTAINER_ALBUM && 
                   global.collection_sort_mode != CollectionSortMode.ARTIST_ALBUM_TITLE &&
                   global.collection_sort_mode != CollectionSortMode.GENRE_ARTIST_ALBUM)
                    return null;
                return a;
            }
        }
        else if(context == ActionContext.TRACKLIST_MENU_QUERY) {
            return b;
        }
        
        return null;
    }
    
    private string? uri = null;
    
    private void set_filter_tl_track(Item item, GLib.Value? data, GLib.Value? data2) { 
        string? artist = item.text;
        if(artist != null) {
            Idle.add(() => {
                main_window.album_art_view.icons_model.immediate_search(artist);
                main_window.album_art_view_visible = true;
                main_window.search_entry.text = artist;
                return false;
            });
        }
    }
    
    private void set_filter(Item item, GLib.Value? data, GLib.Value? data2) { 
        if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
           item.type != ItemType.COLLECTION_CONTAINER_ALBUM &&
           item.type != ItemType.COLLECTION_CONTAINER_ALBUMARTIST &&
           item.type != ItemType.COLLECTION_CONTAINER_ARTIST) 
            return;
        
        if(item.type == ItemType.COLLECTION_CONTAINER_ALBUMARTIST ||
           item.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
            string? artist = item.text;
            if(artist != null) {
                Idle.add(() => {
                    main_window.album_art_view.icons_model.immediate_search(artist);
                    main_window.album_art_view_visible = true;
                    main_window.search_entry.text = artist;
                    return false;
                });
            }
            return;
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.get_artist_name_job);
        Item[] tmp = new Item[2];
        tmp[0] = item;
        if(data2 != null) {
            Item? i = (Item)data2;
            tmp[1] = i;
        }
        else {
            tmp += Item(ItemType.UNKNOWN);
        }
        job.items = tmp;
        db_worker.push_job(job);
    }
    
    private bool get_artist_name_job(Worker.Job job) {
        HashTable<ItemType,Item?>? extra_items = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
        if(job.items[1].type != ItemType.UNKNOWN)
            extra_items.insert(job.items[1].type, job.items[1]);
        
        
        TrackData[]? tda = null;
        if(extra_items.get_keys().length() > 0)
            tda = item_converter.to_trackdata(job.items[0], EMPTYSTRING, extra_items);
        else
            tda = item_converter.to_trackdata(job.items[0], EMPTYSTRING, null);
        
        if(tda == null || tda.length == 0)
            return false;
        
        string artist = tda[0].artist;
        if(job.items[0].type == ItemType.COLLECTION_CONTAINER_ALBUM &&
           global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE &&
           tda[0].albumartist == VARIOUS_ARTISTS)
            artist = VARIOUS_ARTISTS;
        if(artist != null) {
            Idle.add(() => {
                main_window.album_art_view.icons_model.immediate_search(artist);
                main_window.album_art_view_visible = true;
                main_window.search_entry.text = artist;
                return false;
            });
        }
        return false;
    }
}

