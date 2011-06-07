/* xnoise-handler-edit-tags.vala
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

public class Xnoise.HandlerEditTags : ItemHandler {
	private Action edit_title_mediabrowser;
	private const string titleinfo = _("Edit metadata for track");
	private const string titlename = "HandlerEditTagsActionTitle";
	
	private const string name = "HandlerEditTags";
	private unowned Main xn;
	
	public HandlerEditTags() {
		xn = Main.instance;
		
		edit_title_mediabrowser = new Action(); 
		edit_title_mediabrowser.action = on_edit_title_mediabrowser;
		edit_title_mediabrowser.info = this.titleinfo;
		edit_title_mediabrowser.name = this.titlename;
		edit_title_mediabrowser.stock_item = Gtk.Stock.EDIT;
		edit_title_mediabrowser.context = ActionContext.MEDIABROWSER_MENU_QUERY;
		print("constructed %s\n", this.name);
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TAG_EDITOR;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context) {
		if(context == ActionContext.MEDIABROWSER_MENU_QUERY)
			return edit_title_mediabrowser;
		
		return null;
	}

	private void on_edit_title_mediabrowser(Item item, GLib.Value? data) {
		if(item.type != ItemType.LOCAL_AUDIO_TRACK)
			return;
		this.open_tagtitle_changer(item);
//		switch(item.type) {
//			case ItemType.COLLECTION_CONTAINER_ARTIST:
//				this.open_tagartist_changer();
//				break;
//			case ItemType.COLLECTION_CONTAINER_ALBUM:
//				this.open_tagalbum_changer();
//				break;
//			case ItemType.LOCAL_AUDIO_TRACK:
//				this.open_tagtitle_changer();
//				break;
//			default:
//				menu = null;
//				break;
//		}
//		GLib.List<TreePath> list;
//		list = xn.main_window.mediaBr.get_selection().get_selected_rows(null);
//		if(list.length() == 0) return;
//		Item? ix = Item(ItemType.UNKNOWN);
//		TreeIter iter;
////		list.reverse();
//		Item[] items = {};
//		var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.edit_title_mediabrowser_job);
//		TreePath path = list.data; // only first
//		xn.main_window.mediaBr.mediabrowsermodel.get_iter(out iter, path);
//		xn.main_window.mediaBr.mediabrowsermodel.get(iter, TrackListModel.Column.ITEM, out ix);
//		job.item = ix;
//		worker.push_job(job);
	}

	private void edit_title_mediabrowser_job(Worker.Job job) {
//		TrackData[] tmp = {};
//		TrackData[] tda = {};
//		foreach(Item item in job.items) {
//			tmp = item_converter.to_trackdata(item, ref xn.main_window.mediaBr.mediabrowsermodel.searchtext);
//			if(tmp == null)
//				continue;
//			foreach(TrackData td in tmp) {
//				tda += td;
//			}
//		}
//		job.track_dat = tda;
//		
//		if(job.track_dat != null) {
//			Idle.add( () => {
//				append_tracks(ref job.track_dat, false);
//				return false;
//			});
//		}
	}

//	private Menu create_edit_artist_tag_menu() {
//		var rightmenu = new Menu();
//		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//		menu_item.set_label(_("Change artist name"));
//		menu_item.activate.connect(this.open_tagartist_changer);
//		rightmenu.append(menu_item);
//		rightmenu.show_all();
//		return rightmenu;
//	}

//	private Menu create_edit_album_tag_menu() {
//		var rightmenu = new Menu();
//		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//		menu_item.set_label(_("Change album name"));
//		menu_item.activate.connect(this.open_tagalbum_changer);
//		rightmenu.append(menu_item);
//		rightmenu.show_all();
//		return rightmenu;
//	}

//	private Menu create_edit_title_tag_menu() {
//		var rightmenu = new Menu();
//		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
//		menu_item.set_label(_("Edit metadata for track"));
//		menu_item.activate.connect(this.open_tagtitle_changer);
//		rightmenu.append(menu_item);
//		rightmenu.show_all();
//		return rightmenu;
//	}

	private TagTitleEditor tte;
	private void open_tagtitle_changer(Item item) {
		tte = new TagTitleEditor(item);
		tte.sign_finish.connect( () => {
			tte = null;
			menu = null;
		});
	}

//	private TagArtistAlbumEditor tae;
//	private void open_tagartist_changer() {
//		tae = new TagArtistAlbumEditor(ref treerowref);
//		tae.sign_finish.connect( () => {
//			tae = null;
//			menu = null;
//		});
//	}

//	private void open_tagalbum_changer() {
//		tae = new TagArtistAlbumEditor(ref treerowref);
//		tae.sign_finish.connect( () => {
//			tae = null;
//			menu = null;
//		});
//	}
}

