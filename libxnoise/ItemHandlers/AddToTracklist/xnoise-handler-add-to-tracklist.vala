/* xnoise-handler-add-to-tracklist.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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
using Xnoise.Services;


// ItemHandler Implementation 
// provides the right Action for the given ActionContext
// has one or more Actions
public class Xnoise.HandlerAddToTracklist : ItemHandler {
    private Action add;
    private const string binfo = EMPTYSTRING;
    private const string bname = "HandlerAddToTracklistAction1";
    
    private Xnoise.Action menu_add_from_playlist;

    private Action menu_add;
    private const string ainfo = _("Add to tracklist");
    private const string aname = "HandlerAddToTracklistAction2";
    
    private Action request_add;
    private const string cinfo = _("Add to tracklist");
    private const string cname = "HandlerAddToTracklistAction3";
    
    private const string name = "HandlerAddToTracklist";
    private unowned Main xn;
    
    public HandlerAddToTracklist() {
        //action for adding item(s)
        xn = Main.instance;
        
        add = new Action(); 
        add.action = on_mediabrowser_activated;
        add.info = this.binfo;
        add.name = this.bname;
        add.context = ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED;
        
        menu_add = new Action(); 
        menu_add.action = on_menu_add;
        menu_add.info = this.ainfo;
        menu_add.name = this.aname;
        menu_add.stock_item = Gtk.Stock.ADD;
        menu_add.context = ActionContext.QUERYABLE_TREE_MENU_QUERY;
        //print("constructed HandlerAddToTracklist\n");
        
        menu_add_from_playlist = new Action(); 
        menu_add_from_playlist.action = on_menu_add_from_playlist;
        menu_add_from_playlist.info = this.ainfo;
        menu_add_from_playlist.name = this.aname;
        menu_add_from_playlist.stock_item = Gtk.Stock.ADD;
        menu_add_from_playlist.context = ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY;
        
        request_add = new Action(); 
        request_add.action = on_request;
        request_add.info = this.cinfo;
        request_add.name = this.cname;
        request_add.context = ActionContext.REQUESTED;

    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.TRACKLIST_ADDER;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        if(context == ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED)
            return add;
        
        if(context == ActionContext.QUERYABLE_TREE_MENU_QUERY) {
            return menu_add;
       }

        if(context == ActionContext.QUERYABLE_PLAYLIST_MENU_QUERY) {
            return menu_add_from_playlist;
       }
        
        if(context == ActionContext.REQUESTED)
            return request_add;
        
        return null;
    }

    private void on_menu_add_from_playlist(Item item, GLib.Value? data) {
        TreeView tv = (TreeView)data;
        PlaylistQueryable tq = tv as PlaylistQueryable;
        if(tv == null || tq == null)
            return;
        if(!(tv is TreeView))
            return;
        if(!(tq is PlaylistQueryable))
            return;
        //print("okokok\n");
        GLib.List<TreePath> list;
        list = tv.get_selection().get_selected_rows(null);
        if(list.length() == 0)
            return;
        
        var mod = tv.get_model();
        Item? ix = Item(ItemType.UNKNOWN);
        TreeIter iter;
//        list.reverse();
        Item[] items = {};
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.menu_add_from_playlist_job);
        foreach(TreePath path in list) {
            mod.get_iter(out iter, path);
            mod.get(iter, tq.get_model_item_column(), out ix);
            items += ix;
        }
        job.items = items;
        db_worker.push_job(job);
    }

    private void on_menu_add(Item item, GLib.Value? data) {
        TreeView tv = (TreeView)data;
        TreeQueryable tq = tv as TreeQueryable;
        if(tv == null || tq == null)
            return;
        if(!(tv is TreeView))
            return;
        if(!(tq is TreeQueryable))
            return;
        //print("okokok\n");
        GLib.List<TreePath> list;
        list = tv.get_selection().get_selected_rows(null);
        if(list.length() == 0)
            return;
        
        var mod = tv.get_model();
        Item? ix = Item(ItemType.UNKNOWN);
        TreeIter iter;
//        list.reverse();
        Item[] items = {};
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.menu_add_job);
        foreach(TreePath path in list) {
            mod.get_iter(out iter, path);
            mod.get(iter, tq.get_model_item_column(), out ix);
            items += ix;
        }
        job.items = items;
        db_worker.push_job(job);
    }

    private bool menu_add_from_playlist_job(Worker.Job job) {
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
                append_tracks(ref job.track_dat, false);
                return false;
            });
        }
        return false;
    }
    
    private bool menu_add_job(Worker.Job job) {
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
                append_tracks(ref job.track_dat, false);
                return false;
            });
        }
        return false;
    }
    
    private void on_request(Item item, GLib.Value? data) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_requested_job);
        job.item = item;
        db_worker.push_job(job);
    }
    
    private bool add_requested_job(Worker.Job job) {
        Item? item = job.item;
        job.track_dat = item_converter.to_trackdata(item, EMPTYSTRING);
        
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat, true);
                return false;
            });
        }
        return false;
    }
    
    private void on_mediabrowser_activated(Item item, GLib.Value? data) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_item_job);
        job.item = item;
        db_worker.push_job(job);
    }

    private bool add_item_job(Worker.Job job) {
        Item? item = job.item;//(Item?)job.get_arg("item");
        //print("item.type is %s\n", item.type.to_string());
        
        job.track_dat = item_converter.to_trackdata(item, global.searchtext);
        
        if(job.track_dat != null) {
            Idle.add( () => {
                append_tracks(ref job.track_dat, true);
                return false;
            });
        }
        return false;
    }
    
    private void append_tracks(ref TrackData[]? tda, bool immediate_play = true) {
        if(tda == null || tda[0] == null) 
            return;
        
        int k = 0;
        TreeIter iter, iter_2 = {};
        while(tda[k] != null) {
            if(k == 0 && immediate_play) { // First track
                iter = tlm.insert_title(null,
                                        ref tda[k],
                                        true);
                global.position_reference = null;
                global.position_reference = new TreeRowReference(tlm, tlm.get_path(iter));
                iter_2 = iter;
            }
            else { // from second to last track
                iter = tlm.insert_title(null,
                                        ref tda[k],
                                        false);
            }
            k++;
        }
        if(tda[0].item.type != ItemType.UNKNOWN && immediate_play) {
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.PLAY_NOW);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(tda[0].item.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);
            if(action != null)
                action.action(tda[0].item, null);
        }
        if(immediate_play)
            tl.set_focus_on_iter(ref iter_2);
    }
}

