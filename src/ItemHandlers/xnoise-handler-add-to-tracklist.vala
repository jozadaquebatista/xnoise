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
 * 	Jörn Magens
 */

using Gtk;
// ItemHandler Implementation 
// provides the right Action for the given ActionContext
// has one or more Actions
public class Xnoise.HandlerAddToTracklist : ItemHandler {
	private Action add;
	private const string binfo = "B HandlerAddToTracklistinfo";
	private const string bname = "B HandlerAddToTracklistname";
	
	private const string name = "HandlerAddToTracklist";
	private unowned Main xn;
	
	public HandlerAddToTracklist() {
		//action for adding item(s)
		xn = Main.instance;
		add = new Action(); 
		add.action = on_mediabrowser_activated;
		add.info = this.binfo;
		add.name = this.bname;// (char[])"HandlerAddToTracklist";
		add.context = ActionContext.MEDIABROWSER_ITEM_ACTIVATED;
		print("constructed HandlerAddToTracklist\n");
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TRACKLIST_ADDER;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context) {
		if(context == ActionContext.MEDIABROWSER_ITEM_ACTIVATED)
			return add;
		
		return null;
	}

	private void on_mediabrowser_activated(Item item, GLib.Value? data) {
		var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.add_item_job);
		job.item = item;
		worker.push_job(job);
	}
	
	private void add_item_job(Worker.Job job) {
		Item? item = job.item;//(Item?)job.get_arg("item");
		//print("item.type is %s\n", item.type.to_string());
		DbBrowser dbBr = null;
		try {
			dbBr = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		job.track_dat = item_converter.to_trackdata(item, ref xn.main_window.mediaBr.mediabrowsermodel.searchtext, ref dbBr);;
		
		if(job.track_dat != null) {
			Idle.add( () => {
				append_tracks(ref job.track_dat);
				return false;
			});
		}
	}
	
	private void append_tracks(ref TrackData[]? tda) {
		if(tda == null || tda[0] == null) 
			return;
		
		int k = 0;
		TreeIter iter, iter_2 = {};
		while(tda[k] != null) {
			string current_uri = tda[k].uri;
			
			if(k == 0) { // First track
				iter = xn.tlm.insert_title(null,
				                         (int)tda[k].tracknumber,
				                         tda[k].title,
				                         tda[k].album,
				                         tda[k].artist,
				                         tda[k].length,
				                         true,
				                         current_uri,
				                         tda[k].item);
				global.position_reference = null;
				global.position_reference = new TreeRowReference(xn.tlm, xn.tlm.get_path(iter));
				iter_2 = iter;
			}
			else { // from second to last track
				iter = xn.tlm.insert_title(null,
				                         (int)tda[k].tracknumber,
				                         tda[k].title,
				                         tda[k].album,
				                         tda[k].artist,
				                         tda[k].length,
				                         false,
				                         current_uri,
				                         tda[k].item);
			}
			k++;
		}
		
		if(tda[0].item.type != ItemType.UNKNOWN) {
			ItemHandler? tmp = item_handler_manager.get_handler_by_type(ItemHandlerType.PLAY_NOW);
			if(tmp == null)
				return;
			unowned Action? action = tmp.get_action(tda[0].item.type, ActionContext.ANY);
			if(action != null)
				action.action(tda[0].item, null);
		}
		xn.tl.set_focus_on_iter(ref iter_2);
	}
}

