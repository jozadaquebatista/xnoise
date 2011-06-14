/* xnoise-media-browser.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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
	private unowned Main xn;
	private bool dragging;
	private bool _use_treelines = false;
	private bool _use_linebreaks = false;
	private CellRendererText renderer = null;
	private List<TreePath> expansion_list = null;
	private Gtk.Menu menu;
	
	public MediaBrowserModel mediabrowsermodel;
//	public MediaBrowserFilterModel filtermodel;
//	public TreeModelSort sortmodel;
	//public bool drag_from_mediabrowser = false;
	
	public bool use_linebreaks {
		get {
			return _use_linebreaks;
		}
		set {
			if(_use_linebreaks == value) return;
			_use_linebreaks = value;
			if(!value) {
				renderer.set_fixed_height_from_font(1);
				renderer.wrap_width = -1;
				if(visible)
					Idle.add(update_view);
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
	
	private int _fontsizeMB = 0;
	internal int fontsizeMB {
		get {
			return _fontsizeMB;
		}
		set {
			if (_fontsizeMB == 0) { //intialization
				if((value < 7)||(value > 14)) _fontsizeMB = 7;
				else _fontsizeMB = value;
				renderer.font = "Sans " + fontsizeMB.to_string();
			}
			else {
				if((value < 7)||(value > 14)) _fontsizeMB = 7;
				else _fontsizeMB = value;
				renderer.font = "Sans " + fontsizeMB.to_string();
				Idle.add(update_view);
			}
		}
	}
		
	public signal void sign_activated();
	// targets used with this as a source
	private const TargetEntry[] src_target_entries = {
		{"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
	};

	// targets used with this as a destination
	private const TargetEntry[] dest_target_entries = {
		{"text/uri-list", TargetFlags.OTHER_APP, 0}
	};// This is not a very long list but uris are so universal

	public MediaBrowser() {
		this.xn = Main.instance;
		par.iparams_register(this);
		mediabrowsermodel = new MediaBrowserModel();
//		filtermodel = new MediaBrowserFilterModel(mediabrowsermodel);
//		sortmodel = new TreeModelSort.with_model(filtermodel);
//		sortmodel.set_sort_column_id(MediaBrowserModel.Column.VIS_TEXT, SortType.ASCENDING);
		setup_view();
		Idle.add(this.populate_model);
		this.get_selection().set_mode(SelectionMode.MULTIPLE);

		Gtk.drag_source_set(this,
		                    Gdk.ModifierType.BUTTON1_MASK,
		                    this.src_target_entries,
		                    Gdk.DragAction.COPY
		                    );

		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  this.dest_target_entries,
		                  Gdk.DragAction.COPY
		                  );
		
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
		this.set_model(mediabrowsermodel);//mediabrowsermodel);
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
	
	public void on_searchtext_changed() {
		string txt = xn.main_window.searchEntryMB.text;
		if(txt != null) {
			if(txt.down() == mediabrowsermodel.searchtext)
				return;
			mediabrowsermodel.searchtext = txt.down();
		}
		else {
			mediabrowsermodel.searchtext = "";
		}
		mediabrowsermodel.filter();
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
				MediaBrowserModel.CollectionType ct = MediaBrowserModel.CollectionType.UNKNOWN;
				TreeIter iter;
				this.mediabrowsermodel.get_iter(out iter, treepath);
				this.mediabrowsermodel.get(iter, MediaBrowserModel.Column.COLL_TYPE, ref ct);
				if(ct != MediaBrowserModel.CollectionType.HIERARCHICAL)
					return false;
//				treerowref = new TreeRowReference(this.mediabrowsermodel, treepath);
				if(!selection.path_is_selected(treepath)) {
					selection.unselect_all();
					selection.select_path(treepath);
				}
				rightclick_menu_popup(e.time);
				return true;
			}
			default: {
				break;
			}
		}
		if(!(selection.count_selected_rows()>0 ))
			selection.select_path(treepath);
		return false;
	}
	private void rightclick_menu_popup(uint activateTime) {
		menu = create_rightclick_menu();
		if(menu != null)
			menu.popup(null, null, null, 0, activateTime);
	}

	private Menu create_rightclick_menu() {
		TreeIter iter;
		var rightmenu = new Menu();
		GLib.List<TreePath> list;
		list = this.get_selection().get_selected_rows(null);
		ItemSelectionType itemselection = ItemSelectionType.SINGLE;
		if(list.length() > 1)
			itemselection = ItemSelectionType.MULTIPLE;
		Item? item = null;
		Array<unowned Action?> array = null;
//		foreach(Gtk.TreePath path in list) { //TODO
//		}
		TreePath path = (TreePath)list.data;
		mediabrowsermodel.get_iter(out iter, path);
		mediabrowsermodel.get(iter, TrackListModel.Column.ITEM, out item);
		array = item_handler_manager.get_actions(item.type, ActionContext.MEDIABROWSER_MENU_QUERY, itemselection);
		for(int i =0; i < array.length; i++) {
			unowned Action x = array.index(i);
			print("%s\n", x.name);
			var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? x.stock_item : Gtk.Stock.INFO), null);
			menu_item.set_label(x.info);
			menu_item.activate.connect( () => {
				x.action(item, null);
			});
			rightmenu.append(menu_item);
		}
		rightmenu.show_all();
		return rightmenu;
	}

//	private void rightclick_menu_popup(int depth, uint activateTime) {
//		switch(depth) {
//			case 1:
//				this.menu = create_edit_artist_tag_menu();
//				break;
//			case 2:
//				this.menu = create_edit_album_tag_menu();
//				break;
//			case 3:
//				this.menu = create_edit_title_tag_menu();
//				break;
//			default:
//				menu = null;
//				break;
//		}
//		if(menu != null)
//			menu.popup(null, null, null, 0, activateTime);
//	}

//	private TreeRowReference treerowref = null;
	
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
		//this.drag_from_mediabrowser = true;
		Gdk.drag_abort(context, Gtk.get_current_event_time());
		Gtk.TreeSelection selection = this.get_selection();
		if(selection.count_selected_rows() > 1) {
			Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		return;
	}

	private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint etime) {
		List<unowned TreePath> treepaths;
		unowned Gtk.TreeSelection selection;
		selection = this.get_selection();
		treepaths = selection.get_selected_rows(null);
		DndData[] ids = {};
		if(treepaths.length() < 1)
			return;
		foreach(TreePath treepath in treepaths) { 
			//TreePath tp = filtermodel.convert_path_to_child_path(treepath);
			DndData[] l = mediabrowsermodel.get_dnd_data_for_path(ref treepath); 
			foreach(DndData u in l) {
				//print("dnd data get %d  %s\n", u.db_id, u.mediatype.to_string());
				ids += u; // this is necessary, if more than one path can be selected
			}
		}
		Gdk.Atom dnd_atom = Gdk.Atom.intern(src_target_entries[0].target, true);
		unowned uchar[] data = (uchar[])ids;
		data.length = (int)(ids.length * sizeof(DndData));
		selection_data.set(dnd_atom, 8, data);
	}

	private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		this.dragging = false;
		//this.drag_from_mediabrowser = false;
		
		this.unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  this.dest_target_entries,
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.MOVE
		                  );
	}

	private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
		if(treepath.get_depth() > 1) {
			Item? item = Item(ItemType.UNKNOWN);
			TreeIter iter;
			this.mediabrowsermodel.get_iter(out iter, treepath);
			this.mediabrowsermodel.get(iter, MediaBrowserModel.Column.ITEM, out item);
			ItemHandler? tmp = item_handler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
			if(tmp == null)
				return;
			unowned Action? action = tmp.get_action(item.type, ActionContext.MEDIABROWSER_ITEM_ACTIVATED, ItemSelectionType.SINGLE);
			
			if(action != null)
				action.action(item, null);
			else
				print("action was null\n");
		}
		else {
			this.expand_row(treepath, false);
		}
	}

	public bool change_model_data() {
		set_model(null);
		mediabrowsermodel.filter();
//		mediabrowsermodel.populate_model();
//		update_view();

//		this.set_sensitive(true);
		return false;
	}
	
	/* updates the view, leaves the original model untouched.
	   expanded rows are kept as well as the scrollbar position */
	public bool update_view() {
		double scroll_position = xn.main_window.mediaBrScrollWin.vadjustment.value;
//print("scroll_position: %.3lf\n", scroll_position);
//		this.row_collapsed.disconnect(on_row_collapsed);
//		this.row_expanded.disconnect(on_row_expanded);
		this.set_model(null);
		this.set_model(mediabrowsermodel);
		//TODO: delete the expanion list after import
//		foreach(TreePath tp in this.expansion_list)
//			this.expand_row(tp, false);
		xn.main_window.mediaBrScrollWin.vadjustment.set_value(scroll_position);
		xn.main_window.mediaBrScrollWin.vadjustment.value_changed();
//		this.row_collapsed.connect(on_row_collapsed);
//		this.row_expanded.connect(on_row_expanded);
		return false;
	}
		
	
	public void on_row_expanded(TreeIter iter, TreePath path) {
		//print("on_row_expanded\n");
		mediabrowsermodel.load_children(ref iter);
	}
	
	public void on_row_collapsed(TreeIter iter, TreePath path) {
		mediabrowsermodel.unload_children(ref iter);
//		uint list_iter = 0;
//		foreach(TreePath tp in this.expansion_list) {
//			if(path.compare(tp) == 0) {
//				this.expansion_list.delete_link(this.expansion_list.nth(list_iter));
//				break;
//			}
//			list_iter++;
//		}
	}

	private void setup_view() {
		
		//we keep track of which rows are expanded, so we can expand them again
		//when the view is updated
		expansion_list = new List<TreePath>();
		this.row_collapsed.connect(on_row_collapsed);
		this.row_expanded.connect(on_row_expanded);
		
		this.set_size_request (300,500);
		renderer = new CellRendererText();
//		renderer.family = "Sans"; //TODO: Does not work!?
//		renderer.size = 9; //TODO: Does not work!?
		fontsizeMB = par.get_int_value("fontsizeMB");

		var pixbufRenderer = new CellRendererPixbuf();
		pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
		
		var column = new TreeViewColumn();

		column.pack_start(pixbufRenderer, false);
		column.add_attribute(pixbufRenderer, "pixbuf", MediaBrowserModel.Column.ICON);
		column.pack_start(renderer, false);
		column.add_attribute(renderer, "text", MediaBrowserModel.Column.VIS_TEXT); // no markup!!
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
		 keeps the currently expanded nodes expanded!
		 
	   TODO: Find out the correct expander size at runtime */
		 
	/* calculates the size available for the text in the treeview */
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
		//substract scrollbar width, expander width, vertical separator width and the space used 
		//up by the icons from the total width
		Value v = Value(typeof(int));
		widget_style_get_property(this, "expander-size", v);
		int expander_size = v.get_int();
		v.reset();
		widget_style_get_property(this, "vertical-separator", v);
		int vertical_separator_size = v.get_int();
		new_width -= mediabrowsermodel.get_max_icon_width() + scrollbar_w + expander_size + vertical_separator_size * 4;
		if(new_width < 60) return;
		renderer.wrap_width = new_width;
		Idle.add(update_view);
	}
}

