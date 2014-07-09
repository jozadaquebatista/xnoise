/* xnoise-folder-structure.vala
 *
 * Copyright (C) 2014  Marius Gräfe
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
 *     Marius Gräfe
 */
 
 using Gtk;
 using Xnoise;
 
 public class Xnoise.FolderStructureModel : Gtk.TreeStore, Gtk.TreeModel {
 	private unowned DockableMedia dock;
	public bool populating_model { get; private set; default = false; }
	
 	public enum Column {
 		ICON = 0,
 		VIS_TEXT,
 		ITEM,
 		ITEMTYPE,
 		N_COLUMNS
 	}
 	
 	private GLib.Type[] col_types = new GLib.Type[] {
 		typeof(Gdk.Pixbuf), 	//ICON
 		typeof(string), 		//VIS_TEXT
 		typeof(Xnoise.Item?), 	//ITEM
 		typeof(ItemType) 		//LEVEL
 	};
 	
 	public FolderStructureModel(DockableMedia dock) {
 		this.dock = dock;
 		set_column_types(col_types);
 		
 		//TODO: connect signals
 		populate_model();
 	}
 	
 	private bool populate_model() {
		if(populating_model)
			return false;
		populating_model = true;
		
		TreeIter test_iter;
		this.append(out test_iter, null);
		this.set(test_iter, 
			Column.ICON, null,
			Column.VIS_TEXT, "test text",
			Column.ITEM, null,
			Column.ITEMTYPE, ItemType.LOCAL_AUDIO_TRACK);
		return true;
 	}
}






