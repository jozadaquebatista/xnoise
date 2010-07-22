/* xnoise-media-browser.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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
using Gdk;

public class Xnoise.MediaBrowser : TreeView, IParams {
	public MediaBrowserModel mediabrowsermodel;
	private MediaBrowserModel dummymodel;
	private unowned Main xn;
	private bool dragging;
	private bool _use_treelines = false;
	private bool _use_linebreaks = false;
	private CellRendererText renderer = null;
	public bool use_linebreaks {
		get {
			return _use_linebreaks;
		}
		set {
			_use_linebreaks = value;
			if(!value) {
				renderer.set_fixed_height_from_font(1);
				renderer.wrap_width = -1;
				if(visible)
					Idle.add( () => {
						this.change_model_data();
						return false;
						});
				return;
			}
			renderer.set_fixed_height_from_font(-1);
			renderer.wrap_mode = Pango.WrapMode.WORD_CHAR;
			if(xn.main_window == null)
				return;
			if(xn.main_window.hpaned == null)
				return;
			this.resize_line_width(xn.main_window.hpaned.position);
		}
	}
	
	public bool use_treelines {
		get {
			return _use_treelines;
		}
		set {
			_use_treelines = value;
			this.enable_tree_lines = value;
		}
	}

	internal int fontsizeMB = 8;
	public signal void sign_activated();
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};// This is not a very long list but uris are so universal

	public MediaBrowser() {
		this.xn = Main.instance;
		par.iparams_register(this);
		mediabrowsermodel = new MediaBrowserModel();
		setup_view();
		Idle.add(this.populate_model);
		this.get_selection().set_mode(SelectionMode.MULTIPLE);

		Gtk.drag_source_set(
			this,
			Gdk.ModifierType.BUTTON1_MASK,
			this.target_list,
			Gdk.DragAction.COPY);

		Gtk.drag_dest_set(
			this,
			Gtk.DestDefaults.ALL,
			this.target_list,
			Gdk.DragAction.COPY);
		
		this.dragging = false;

		//Signals
		this.row_activated.connect(this.on_row_activated);
		this.drag_begin.connect(this.on_drag_begin);
		this.drag_data_get.connect(this.on_drag_data_get);
		this.drag_end.connect(this.on_drag_end);
		this.button_release_event.connect(this.on_button_release);
		this.button_press_event.connect(this.on_button_press);
		this.key_press_event.connect(this.on_key_pressed);
		this.key_release_event.connect(this.on_key_released);
		this.drag_data_received.connect(this.on_drag_data_received);
	}
	
	private void on_drag_data_received(Gtk.Widget sender, DragContext context, int x, int y,
	                                   SelectionData selection, uint target_type, uint time) {
		//TODO: Open media import dialog for dropped files and folders
		print("drag receive\n");
	}

	// This function is intended for the usage
	// with GLib.Idle
	private bool populate_model() {
		bool res = mediabrowsermodel.populate_model();
		this.set_model(mediabrowsermodel);
		return res;
	}

	// IParams functions
	public void read_params_data() {
		if(par.get_int_value("use_treelines") == 1)
			use_treelines = true;
		else
			use_treelines = false;
		
		if(par.get_int_value("use_linebreaks") == 1)
			use_linebreaks = true;
		else
			use_linebreaks = false;
	}

	public void write_params_data() {
		if(this.use_treelines)
			par.set_int_value("use_treelines", 1);
		else
			par.set_int_value("use_treelines", 0);
			
		if(this.use_linebreaks)
			par.set_int_value("use_linebreaks", 1);
		else
			par.set_int_value("use_linebreaks", 0);
		par.set_int_value("fontsizeMB", fontsizeMB);
	}
	// end IParams functions

	private const int KEY_CURSOR_RIGHT = 0xFF53;
	private const int KEY_CURSOR_LEFT  = 0xFF51;

	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//		print("%d\n",(int)e.keyval);
		Gtk.TreeModel m;
		switch(e.keyval) {
			case KEY_CURSOR_RIGHT:
				Gtk.TreeSelection selection = this.get_selection();
				if(selection.count_selected_rows()<1) break;
				GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
				TreePath? treepath = selected_rows.nth_data(0);
				if(treepath.get_depth()>2) break;
				if(treepath!=null) this.expand_row(treepath, false);
				break;
			case KEY_CURSOR_LEFT:
				Gtk.TreeSelection selection = this.get_selection();
				if(selection.count_selected_rows()<1) break;
				GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
				TreePath? treepath = selected_rows.nth_data(0);
				if(treepath.get_depth()>2) break;
				if(treepath!=null) this.collapse_row(treepath);
				break;
			default:
				break;
		}
		return false;
	}

	private const int F_KEY = 0x0066;
	private bool on_key_pressed(Gtk.Widget sender, Gdk.EventKey e) {
		return false;
	}
	
	public void on_searchtext_changed(string? txt) {
		if(txt != null)
			mediabrowsermodel.searchtext = txt.down();
		else
			mediabrowsermodel.searchtext = "";
		change_model_data();
		if((txt != "") &&
		   (txt != null)) {
			this.expand_all();
		}
	}

	private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
		Gtk.TreePath treepath = null;
		Gtk.TreeViewColumn column;
		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x;
		int y = (int)e.y;
		int cell_x, cell_y;

		if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y))
			return true;

		switch(e.button) {
			case 1: {
				if(selection.count_selected_rows()<= 1) {
					return false;
				}
				else {
					if(selection.path_is_selected(treepath)) {
						if(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
						   ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK)) {
							selection.unselect_path(treepath);
						}
						return true;
					}
					else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
							((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK))) {
						return true;
					}
					return false;
				}
			}
			case 3: {
				print("button 3\n"); //TODO
				return false; //TODO check if this is right
			}
			default: {
				break;
			}
		}
		if(!(selection.count_selected_rows()>0 ))
			selection.select_path(treepath);
		return false;
	}


	private bool on_button_release(Gtk.Widget sender, Gdk.EventButton e) {
		Gtk.TreePath treepath;
		Gtk.TreeViewColumn column;
		int cell_x, cell_y;

		if((e.button != 1)|(this.dragging)) {
			this.dragging = false;
			return true;
		}
		if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
			((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
			return true;
		}

		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x;
		int y = (int)e.y;
		if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y)) return false;
		selection.unselect_all();
		selection.select_path(treepath);

		return false;
	}

	private void on_drag_begin(Gtk.Widget sender, DragContext context) {
		this.dragging = true;
		Gdk.drag_abort(context, Gtk.get_current_event_time());
		Gtk.TreeSelection selection = this.get_selection();
		if(selection.count_selected_rows() > 1) {
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND_MULTIPLE);
		}
		else {
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND);
		}
		return;
	}

	private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context, Gtk.SelectionData selection, uint info, uint etime) {
		string[] uris = {};
		List<unowned TreePath> treepaths;
		unowned Gtk.TreeSelection sel;
		sel = this.get_selection();
		treepaths = sel.get_selected_rows(null);
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}

		foreach(unowned TreePath treepath in treepaths) {
			string[] l = mediabrowsermodel.build_uri_list_for_treepath(treepath, ref dbb);
			foreach(unowned string u in l) {
				uris += u;
			}
		}
		uris += null;
		selection.set_uris(uris);
	}

	private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		this.dragging = false;
		this.unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  this.target_list,
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.MOVE
		                  );
	}

	private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
		if(treepath.get_depth() > 1) {
			TrackData[] td_list = mediabrowsermodel.get_trackdata_for_treepath(treepath);
			this.xn.tl.tracklistmodel.add_tracks(td_list, true);
			td_list = null;
		}
		else {
			this.expand_row(treepath, false);
		}
	}

	public bool change_model_data() {
		dummymodel = new MediaBrowserModel();
		set_model(dummymodel);
		mediabrowsermodel.clear();
		mediabrowsermodel.populate_model();
		set_model(mediabrowsermodel);
		xn.main_window.searchEntryMB.set_sensitive(true);
		this.set_sensitive(true);
		return false;
	}

	private void setup_view() {
		fontsizeMB = par.get_int_value("fontsizeMB");
		if((fontsizeMB < 7)||(fontsizeMB > 14)) fontsizeMB = 7;

		this.set_size_request (300,500);
		renderer = new CellRendererText();
		renderer.font = "Sans " + fontsizeMB.to_string();
//		renderer.family = "Sans"; //TODO: Does not work!?
//		renderer.size = 9; //TODO: Does not work!?



		var pixbufRenderer = new CellRendererPixbuf();
		pixbufRenderer.stock_id = Gtk.STOCK_GO_FORWARD;

		var column = new TreeViewColumn();

		column.pack_start(pixbufRenderer, false);
		column.add_attribute(pixbufRenderer, "pixbuf", 0);
		column.pack_start(renderer, false);
		column.add_attribute(renderer, "text", 1); // no markup!!
		this.insert_column(column, -1);

		this.headers_visible = false;
		this.enable_search = false;
		this.set_row_separator_func((m, iter) => {
			int sepatator = 0;
			m.get(iter, MediaBrowserModel.Column.DRAW_SEPTR, ref sepatator);
			if(sepatator==0) return false;
			return true;
		});
	}
	
	
	/* TODO: Find a more cpu efficient way to update the linebreaks, which also
		 keeps the currently expanded nodes expanded!*/
		 
	/* calculates the size available for the text in the treeview, one expander's size usage is
	ignored, though */
	public void resize_line_width(int new_width) {
		if(!use_linebreaks)
			return;
		//check for options
		//get scrollbar width of the scrolled window
		int scrollbar_w = 0;
		if(xn.main_window.mediaBrScrollWin != null) {
			var scrollbar = xn.main_window.trackListScrollWin.get_vscrollbar();
			if(scrollbar != null) {
				Requisition req; 
				scrollbar.get_child_requisition(out req);
				scrollbar_w = req.width;				
			}
		}
		//substract scrollbar width and the space used up by the icons from the
		//total width	
		new_width -= mediabrowsermodel.get_max_icon_width() + scrollbar_w;
		if(new_width < 60) return;
		renderer.wrap_width = new_width;
		Idle.add( () => {
			this.change_model_data();
			return false;
		});
	}
}
