/* xnoise-dockable-dynamic-playlist.vala
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

public class Xnoise.DockableDynamicPlaylists : DockableMedia {
	private unowned MainWindow win;
	
	public DockableDynamicPlaylists() {
		
	}
	
	public override string name() {
		return "DockableDynamicPlaylists";
	}
	
	public override string headline() {
		return _("Dynamic Playlists");
	}
	
	// TODO use custom TreeView
	public override Gtk.Widget? get_widget(MainWindow window) {
		this.win = window; // use this ref because static main_window
		                   //is not yet set up at construction time
		var tv = new TreeView();
		tv.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
		tv.headers_visible = false;
		tv.get_selection().set_mode(SelectionMode.MULTIPLE);
		TreeStore mod = new TreeStore(2, typeof(Gdk.Pixbuf), typeof(string));
		TreeIter iter;
		Gdk.Pixbuf pixb = null;
		Gtk.Invisible i = new Gtk.Invisible();
		try {
			if(IconTheme.get_default().has_icon("xn-playlist"))
				pixb = IconTheme.get_default().load_icon("xn-playlist", 16, IconLookupFlags.FORCE_SIZE);
			else
				pixb = i.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
		}
		catch(Error e) {
		}
		mod.append(out iter, null);
		mod.set(iter, 0, pixb, 1 , _("Most popular"));
		mod.append(out iter, null);
		mod.set(iter, 0, pixb, 1 , _("Recently added"));
		var column = new TreeViewColumn();
		var renderer = new CellRendererText();
		var rendererPb = new CellRendererPixbuf();
		column.pack_start(rendererPb, false);
		column.pack_start(renderer, true);
		column.add_attribute(rendererPb, "pixbuf", 0);
		column.add_attribute(renderer, "text", 1);
		tv.insert_column(column, -1);
		tv.model = mod;
		return tv;
	}
	
}

