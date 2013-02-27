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


internal class Xnoise.HandlerRemoveCoverImage : ItemHandler {
    private Action a;
    private static const string ainfo = _("Remove Cover Image");
    private static const string aname = "A HandlerRemoveCoverImage";
    
    private static const string name = "HandlerRemoveCoverImage";
    
    public HandlerRemoveCoverImage() {
        a = new Action();
        a.action = remove_cover;
        a.info = ainfo;
        a.name = aname;
        a.stock_item = Gtk.Stock.DELETE;
        a.context = ActionContext.NONE;
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
        if(type == ItemType.COLLECTION_CONTAINER_ALBUM) {
            return a;
        }
        
        return null;
    }
    
    private string? uri = null;
    
    private void remove_cover(Item item, GLib.Value? data, GLib.Value? data2) { 
        if(item.type != ItemType.COLLECTION_CONTAINER_ALBUM) 
            return;
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.get_album_info_job);
        job.item = item;
        db_worker.push_job(job);
    }
    
    private bool get_album_info_job(Worker.Job job) {
        HashTable<ItemType,Item?>? item_ht = 
            new HashTable<ItemType,Item?>(direct_hash, direct_equal);
        item_ht.insert(job.item.type, job.item);
        TrackData[]? tda =  db_reader.get_trackdata_for_album(EMPTYSTRING,
                                                         CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                         item_ht);
        if(tda == null || tda.length == 0)
            return false;
        
        string artist = tda[0].artist;
        string album  = tda[0].album;
        
        File? med = get_albumimage_for_artistalbum(artist, album, "medium");
        File? exl = get_albumimage_for_artistalbum(artist, album, "extralarge");
        File? emb = get_albumimage_for_artistalbum(artist, album, "embedded");
        
        Idle.add(() => {
            try {
                if(med != null && med.query_exists(null))
                    med.delete();
                if(exl != null && exl.query_exists(null)) {
                    exl.delete();
                    global.sign_album_image_removed(artist, album, exl.get_path());
                }
                if(emb != null && emb.query_exists(null))
                    emb.delete();
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
            string buf = global.searchtext;
            global.searchtext = Random.next_int().to_string();
            global.searchtext = buf;
            return false;
        });
        return false;
    }
}

