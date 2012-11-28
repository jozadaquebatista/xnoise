/* xnoise-handler-add-to-tracklist.vala
 *
 * Copyright (C) 2011  Jörn Magens
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

internal class Xnoise.HandlerAddAllToTracklist : ItemHandler {
    
    private Xnoise.Action menu_add;
    private Xnoise.Action menu_add_from_playlist;
    private Xnoise.Action menu_add_from_extern;
    
    private static const string ainfo = _("Add all tracks to tracklist");
    private static const string aname = "HandlerAddAllToTracklistAction";
    
    private static const string name = "HandlerAddAllToTracklist";
    private unowned Main xn;
    
    public HandlerAddAllToTracklist() {
        //action for adding item(s)
        xn = Main.instance;
        
        menu_add = new Action(); 
        menu_add.action = on_menu_add;
        menu_add.info = ainfo;
        menu_add.name = aname;
        menu_add.stock_item = Gtk.Stock.DND_MULTIPLE;
        menu_add.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;

        menu_add_from_playlist = new Action(); 
        menu_add_from_playlist.action = on_menu_add_from_playlist;
        menu_add_from_playlist.info = ainfo;
        menu_add_from_playlist.name = aname;
        menu_add_from_playlist.stock_item = Gtk.Stock.DND_MULTIPLE;
        menu_add_from_playlist.context = ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY;

        menu_add_from_extern = new Action(); 
        menu_add_from_extern.action = on_menu_add_from_extern;
        menu_add_from_extern.info = ainfo;
        menu_add_from_extern.name = aname;
        menu_add_from_extern.stock_item = Gtk.Stock.DND_MULTIPLE;
        menu_add_from_extern.context = ActionContext.QUERYABLE_EXTERNAL_MENU_QUERY;
        //print("constructed HandlerAddToTracklist\n");
    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.OTHER;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
            return menu_add;
       }
        if(context == ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY) {
            return menu_add_from_playlist;
       }
        if(context == ActionContext.QUERYABLE_EXTERNAL_MENU_QUERY) {
            return menu_add_from_extern;
       }
        return null;
    }

    private void on_menu_add_from_extern(Item item, GLib.Value? data, GLib.Value? data2) {
        TreeView tv = (TreeView)data;
        if(tv == null)
            return;
        ExternQueryable pq = tv as ExternQueryable;
        if(pq == null)
            return;
        if(!(tv is TreeView))
            return;
        if(!(pq is ExternQueryable))
            return;
        Worker.Job job;
        DataSource? ds = pq.get_data_source();
        if(ds == null)
            return;
        job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, 
                             this.menu_add_from_extern_job);
        job.item = item;
        job.set_arg("datasource", ds.get_source_id());
        db_worker.push_job(job);
    }

    private bool menu_add_from_extern_job(Worker.Job job) {
        job.items = {};
        DataSource? ds = get_data_source((int)job.get_arg("datasource"));
        if(ds == null) {
            print("datasource not available\n");
            return false;
        }
        job.track_dat = ds.get_all_tracks(global.searchtext);
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat);
                return false;
            });
        }
        return false;
    }

    private void on_menu_add_from_playlist(Item item, GLib.Value? data, GLib.Value? data2) {
        TreeView tv = (TreeView)data;
        if(tv == null)
            return;
        PlaylistQueryable pq = tv as PlaylistQueryable;
        if(pq == null)
            return;
        if(!(tv is TreeView))
            return;
        if(!(pq is PlaylistQueryable))
            return;
        Worker.Job job;
        switch(pq.get_dynamic_playlist_type()) {
            case DynPlaylistType.MOSTPLAYED: {
                job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, 
                                     this.menu_add_from_mostplayed_job);
                job.item = item;
                break;
            }
            case DynPlaylistType.LASTPLAYED: {
                job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, 
                                     this.menu_add_from_lastplayed_job);
                job.item = item;
                break;
            }
            default:
                job = null;
                break;
        }
        db_worker.push_job(job);
    }

    private void on_menu_add(Item item, GLib.Value? data, GLib.Value? data2) {
        TreeQueryable? tq = data as TreeQueryable;
        if(tq == null)
            return;
        if(!(tq is TreeQueryable))
            return;
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.menu_add_job);
        job.item = item;
        db_worker.push_job(job);
    }

    private bool menu_add_from_mostplayed_job(Worker.Job job) {
        job.items = {};
        job.items = db_reader.get_most_played(global.searchtext);
        TrackData[] tmp = {};
        TrackData[] tda = {};
        foreach(Item item in job.items) {
            tmp = item_converter.to_trackdata(item, global.searchtext);
            if(tmp == null)
                continue;
            foreach(TrackData td in tmp) {
                tda += td;
            }
        }
        job.track_dat = tda;
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat);
                return false;
            });
        }
        return false;
    }
    
    private bool menu_add_from_lastplayed_job(Worker.Job job) {
        job.items = {};
        job.items = db_reader.get_last_played(global.searchtext);
        TrackData[] tmp = {};
        TrackData[] tda = {};
        foreach(Item item in job.items) {
            tmp = item_converter.to_trackdata(item, global.searchtext);
            if(tmp == null)
                continue;
            foreach(TrackData td in tmp) {
                tda += td;
            }
        }
        job.track_dat = tda;
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat);
                return false;
            });
        }
        return false;
    }
    
    private bool menu_add_job(Worker.Job job) {
        switch(job.item.type) {
            case ItemType.LOCAL_AUDIO_TRACK:
            case ItemType.COLLECTION_CONTAINER_ARTIST:
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                job.track_dat = db_reader.get_all_tracks(global.searchtext);
                break;
            case ItemType.LOCAL_VIDEO_TRACK:
                job.track_dat = db_reader.get_trackdata_for_video(global.searchtext);
                break;
            case ItemType.STREAM:
                job.track_dat = db_reader.get_trackdata_for_streams(global.searchtext);
                break;
            default:
                return false;
        }
        //print("track_dat len %d\n", (int)job.track_dat.length);
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat);
                return false;
            });
        }
        return false;
    }
    
    private void append_tracks(ref TrackData[]? tda) {
        if(tda == null || tda[0] == null) 
            return;
        int k = 0;
        TreeIter iter;
        while(tda[k] != null) {
            iter = tlm.insert_title(null,
                                    ref tda[k],
                                    false);
            k++;
        }
    }
}

