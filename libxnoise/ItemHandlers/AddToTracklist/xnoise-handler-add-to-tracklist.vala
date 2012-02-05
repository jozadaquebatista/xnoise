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
 * 	Jörn Magens
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
	
	private Action menu_add;
	private const string ainfo = _("Add to tracklist");
	private const string aname = "HandlerAddToTracklistAction2";
	
	private const string name = "HandlerAddToTracklist";
	private unowned Main xn;
	
	public HandlerAddToTracklist() {
		//action for adding item(s)
		xn = Main.instance;
		
		add = new Action(); 
		add.action = on_mediabrowser_activated;
		add.info = this.binfo;
		add.name = this.bname;
		add.context = ActionContext.MEDIABROWSER_ITEM_ACTIVATED;
		
		menu_add = new Action(); 
		menu_add.action = on_menu_add;
		menu_add.info = this.ainfo;
		menu_add.name = this.aname;
		menu_add.stock_item = Gtk.Stock.ADD;
		menu_add.context = ActionContext.MEDIABROWSER_MENU_QUERY;
		//print("constructed HandlerAddToTracklist\n");
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TRACKLIST_ADDER;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection = ItemSelectionType.NOT_SET) {
		if(context == ActionContext.MEDIABROWSER_ITEM_ACTIVATED || context == ActionContext.REQUESTED)
			return add;
		
		if(context == ActionContext.MEDIABROWSER_MENU_QUERY)
			return menu_add;
		
		return null;
	}

	private void on_menu_add(Item item, GLib.Value? data) {
		GLib.List<TreePath> list;
		list = main_window.mediaBr.get_selection().get_selected_rows(null);
		if(list.length() == 0) return;
		Item? ix = Item(ItemType.UNKNOWN);
		TreeIter iter;
//		list.reverse();
		Item[] items = {};
		var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.menu_add_job);
		foreach(TreePath path in list) {
			main_window.mediaBr.mediabrowsermodel.get_iter(out iter, path);
			main_window.mediaBr.mediabrowsermodel.get(iter, MediaBrowserModel.Column.ITEM, out ix);
			items += ix;
		}
		job.items = items;
		db_worker.push_job(job);
	}

	private bool menu_add_job(Worker.Job job) {
		TrackData[] tmp = {};
		TrackData[] tda = {};
		foreach(Item item in job.items) {
			tmp = item_converter.to_trackdata(item, ref main_window.mediaBr.mediabrowsermodel.searchtext);
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
	
	private void on_mediabrowser_activated(Item item, GLib.Value? data) {
		var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_item_job);
		job.item = item;
		db_worker.push_job(job);
	}
	
	private bool add_item_job(Worker.Job job) {
		Item? item = job.item;//(Item?)job.get_arg("item");
		//print("item.type is %s\n", item.type.to_string());
		
		job.track_dat = item_converter.to_trackdata(item, ref main_window.mediaBr.mediabrowsermodel.searchtext);
		
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

