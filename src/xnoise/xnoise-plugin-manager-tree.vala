/* xnoise-plugin-manager-tree.vala
 *
 * Copyright (C) 2009  Jörn Magens
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

using GLib;
using Gtk;

public class Xnoise.PluginManagerTree: Gtk.TreeView {
	private const string group = "XnoisePlugin";
	private ListStore listmodel;
	private enum PluginManagerColumn {
		TOGGLE,
		ICON,
		TEXT,
		N_COLUMNS
	}

	private Main xn;
	
	//TODO: File vala bug: if this is called sign_plugin_active_state_changed compilation fails
	public signal void sign_plugin_activestate_changed(string name); 

	public PluginManagerTree(ref Main xn) {
		this.xn = xn;
		this.create_model();
		this.create_view();
	}
	
//	~PluginManagerTree() {
//		print("destruct PluginGuiElement\n");
//	}

	public void create_view() {
		this.set_size_request(200, 200);

		var toggle = new CellRendererToggle();
		toggle.toggled += (toggle, path) => {
			TreeIter iter;
			var tree_path = new TreePath.from_string(path);
			listmodel.get_iter(out iter, tree_path);
			string name;
			listmodel.get(iter, PluginManagerColumn.TEXT, out name);
			bool plugin_state = this.xn.plugin_loader.plugin_htable.lookup(name).activated;
			this.xn.plugin_loader.plugin_htable.lookup(name).activated = !plugin_state;
			listmodel.set(iter, 
			              PluginManagerColumn.TOGGLE, !plugin_state);
			sign_plugin_activestate_changed(name);
		};

		var column = new TreeViewColumn();
		column.pack_start(toggle, false);
		column.add_attribute(toggle, "active", PluginManagerColumn.TOGGLE);
		this.append_column(column);


		column = new TreeViewColumn();
		var pixbufRenderer = new CellRendererPixbuf();
		column.pack_start(pixbufRenderer, false);
		column.add_attribute(pixbufRenderer, "pixbuf", PluginManagerColumn.ICON);
		column.set_fixed_width(50);
		this.append_column(column);

		var text = new CellRendererText();

		column = new TreeViewColumn();
		column.pack_start(text, true);
		column.add_attribute(text, "text", PluginManagerColumn.TEXT);
		this.append_column(column);

		this.set_headers_visible(false);
		setup_entries();
		this.set_model(listmodel);
	}

	private void setup_entries() {
		foreach(string s in this.xn.plugin_loader.get_info_files()) {
			string name, description, icon, author, website, license, copyright;
			try	{
				var kf = new KeyFile();
				kf.load_from_file(s, KeyFileFlags.NONE);
				if(!kf.has_group(group)) continue;
				name        = kf.get_string(group, "name"); //TODO: Write this data into cell; maybe info button?
				description = kf.get_string(group, "description");
				icon        = kf.get_string(group, "icon");
				author      = kf.get_string(group, "author");
				website     = kf.get_string(group, "website");
				license     = kf.get_string(group, "license");
				copyright   = kf.get_string(group, "copyright");
				
				var invisible = new Gtk.Invisible();
				Gdk.Pixbuf pixbuf = invisible.render_icon(Gtk.STOCK_UNDO , IconSize.BUTTON, null); //TODO: use plugins' icons
				
				TreeIter iter;
				listmodel.append(out iter);
				listmodel.set(iter, 
				              PluginManagerColumn.TOGGLE, this.xn.plugin_loader.plugin_htable.lookup(name).activated, 
				              PluginManagerColumn.ICON, pixbuf, 
				              PluginManagerColumn.TEXT, name);
			}
			catch(Error e) {
				print("Error plugin information: %s\n", e.message);
			}
		}
	}

	private void create_model() {
		listmodel = new ListStore(PluginManagerColumn.N_COLUMNS, 
		                          typeof(bool), 
		                          typeof(Gdk.Pixbuf), 
		                          typeof(string));
	}
}
