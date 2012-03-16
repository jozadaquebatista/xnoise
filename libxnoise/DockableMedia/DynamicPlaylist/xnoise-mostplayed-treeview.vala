/* xnoise-playlist-treeview.vala
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
 * 	Jörn Magens
 */


using Gtk;

private class Xnoise.PlaylistTreeView : Gtk.TreeView {
	private unowned MainWindow win;
	
	public PlaylistTreeView(MainWindow window) {
		this.win = window; // use this ref because static main_window
		                   //is not yet set up at construction time
		
		this.headers_visible = false;
		this.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		
		var column = new TreeViewColumn();
		
		var renderer = new CellRendererText();
		renderer.ellipsize = Pango.EllipsizeMode.END;
		renderer.ellipsize_set = true;
		
		var rendererPb = new CellRendererPixbuf();
		
		column.pack_start(rendererPb, false);
		column.pack_start(renderer, true);
		column.add_attribute(rendererPb, "pixbuf", 0);
		column.add_attribute(renderer, "text", 1);
		
		this.insert_column(column, -1);
		
		this.model = new MostplayedTreeviewModel();
		
		this.row_activated.connect( (s,tp,c) => {
			Item? item = Item(ItemType.UNKNOWN);
			TreeIter iter;
			this.model.get_iter(out iter, tp);
			this.model.get(iter, MostplayedTreeviewModel.Column.ITEM, out item);
			ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
			if(tmp == null)
				return;
			unowned Action? action = tmp.get_action(item.type, ActionContext.MEDIABROWSER_ITEM_ACTIVATED, ItemSelectionType.SINGLE);
		
			if(action != null)
				action.action(item, null);
			else
				print("action was null\n");
		});
	}
}

