/* xnoise-tracklist.vala
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

public class Xnoise.TrackList : TreeView, IParams {
	private Main xn;
	private const TargetEntry[] src_target_entries = {
		{"text/uri-list", Gtk.TargetFlags.SAME_WIDGET, 0}
	};

	// targets used with this as a destination
	private const TargetEntry[] dest_target_entries = {
		{"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
		{"text/uri-list", 0, 1}
	};

	private const string USE_LEN_COL     = "use_length_column";
	private const string USE_TR_NO_COL   = "use_tracknumber_column";
	private const string USE_ALBUM_COL   = "use_album_column";

	private TreeViewColumn columnPixb;
	private TextColumn columnAlbum;
	private TextColumn columnTitle;
	private TextColumn columnArtist;
	private TextColumn columnLength;
	private TextColumn columnTracknumber;
	private int variable_col_count = 0;
	private TreeRowReference[] rowref_list;
	private bool dragging;
	private Menu menu;
	private const int autoscroll_distance = 50;
	private uint autoscroll_source = 0;
	private bool reorder_dragging = false;
	private uint hide_timer = 0;
	private const uint HIDE_TIMEOUT = 1000;
	private HashTable<string,double?> relative_column_sizes;
	private int n_columns = 0;
	
	public bool column_length_visible {
		get {
			return this.columnLength.visible;
		}
		set {
			this.columnLength.visible = value;
		}
	}
	
	public bool column_tracknumber_visible {
		get {
			return this.columnTracknumber.visible;
		}
		set {
			this.columnTracknumber.visible = value;
		}
	}
	
	public bool column_album_visible {
		get {
			return this.columnAlbum.visible;
		}
		set {
			this.columnAlbum.visible = value;
		}
	}
			

	public TrackListModel tracklistmodel;

	public TrackList() {
		this.xn = Main.instance;
		if(xn.tlm == null)
			print("tracklist model instance not available\n");
		
		par.iparams_register(this);
		tracklistmodel = xn.tlm;
		this.set_model(tracklistmodel);
		this.setup_view();
		this.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		Gtk.drag_source_set(this,
		                    Gdk.ModifierType.BUTTON1_MASK,
		                    this.src_target_entries,
		                    Gdk.DragAction.COPY|
		                    Gdk.DragAction.MOVE
		                    );
		
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  this.dest_target_entries,
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.DEFAULT
		                  );
		
		// Signals
		this.row_activated.connect(this.on_row_activated);
		this.key_release_event.connect(this.on_key_released);
		this.key_press_event.connect(this.on_key_pressed);
		this.drag_begin.connect(this.on_drag_begin);
		this.drag_data_get.connect(this.on_drag_data_get);
		this.drag_end.connect(this.on_drag_end);
		this.drag_motion.connect(this.on_drag_motion);
//		this.drag_drop.connect(this.on_drag_drop);
		this.drag_data_received.connect(this.on_drag_data_received);
		this.drag_leave.connect(this.on_drag_leave);
		this.button_release_event.connect(this.on_button_release);
		this.button_press_event.connect(this.on_button_press);
		
		menu = create_rightclick_menu();
	}
	
	private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
		Gtk.TreePath path;
		Gtk.TreeViewColumn column;
		
		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x;
		int y = (int)e.y;
		int cell_x, cell_y;
		if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y)))
			return true;
		
		switch(e.button) {
			case 1:
				if(selection.count_selected_rows()<=1) {
					return false;
				}
				else {
					if(selection.path_is_selected(path)) {
						if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
							((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
								selection.unselect_path(path);
						}
						return true;
					}
					else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
							((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
						return true;
					}
					return false;
				}
			case 2:
				print("button 2\n");
				break;
			case 3:
				if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
					((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
						return false;
				}
				else {
					int selectioncount = selection.count_selected_rows();
					if(selectioncount <= 1) {
						selection.unselect_all();
						selection.select_path(path);
					}
				}
				rightclick_menu_popup(e.time);
				return true;
			}
		if(!(selection.count_selected_rows()>0)) selection.select_path(path);
		return false;
	}

	private void rightclick_menu_popup(uint activateTime) {
		menu.popup(null, null, null, 0, activateTime);
	}

	private Menu create_rightclick_menu() {
		var rightmenu = new Menu();
		var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.DELETE, null);
		menu_item.set_label(_("Remove selected"));
		menu_item.activate.connect(this.remove_selected_rows);
		rightmenu.append(menu_item);
		rightmenu.show_all();
		return rightmenu;
	}

	private bool on_button_release(Gtk.Widget sender, Gdk.EventButton e) {
		Gtk.TreePath path;
		Gtk.TreeViewColumn column;
		int cell_x, cell_y;

		if((e.button != 1) | (this.dragging)) {
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
		if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y))) return false;
		selection.unselect_all();
		selection.select_path(path);
		return false; //for testing
	}

	private bool on_drag_motion(Gtk.Widget sender, Gdk.DragContext context, int x, int y, uint timestamp) {
		Gtk.TreePath path;
		Gtk.TreeViewDropPosition pos;
		if(!(this.get_dest_row_at_pos(x, y, out path, out pos))) return false;
		this.set_drag_dest_row(path, pos);
		
		// Autoscroll
		start_autoscroll();
		return true;
	}
	
	private bool do_scroll(int delta) { 
		int buffer;
		Gtk.Adjustment adjustment = this.get_vadjustment();
		
		if(adjustment == null)
			return false;
		
		buffer = (int)adjustment.get_value();
		adjustment.set_value(adjustment.get_value() + delta);
		return (adjustment.get_value() != buffer);
	}
	
	private bool autoscroll_timeout() {
		double delta = 0.0;
		Gdk.Rectangle expose_area = Gdk.Rectangle();
		
		get_autoscroll_delta(ref delta);
		if(delta == 0) 
			return true;
		
		if(!do_scroll((int)delta))
			return true;
		
		Allocation alloc;
		this.get_allocation(out alloc);
		expose_area.x      = alloc.x;
		expose_area.y      = alloc.y;
		expose_area.width  = alloc.width;
		expose_area.height = alloc.height;
		
		if(delta > 0) {
			expose_area.y = expose_area.height - (int)delta;
		} 
		else {
			if(delta < 0)
				expose_area.height = (int)(-1.0 * delta);
		}

		expose_area.x -= alloc.x;
		expose_area.y -= alloc.y;

		this.queue_draw_area(expose_area.x,
		                     expose_area.y,
		                     expose_area.width,
		                     expose_area.height);
		return true;
	}
	
	private void start_autoscroll() { 
		double delta = 0.0;
		get_autoscroll_delta(ref delta);
		if(delta != 0) {
			if(autoscroll_source == 0) 
				autoscroll_source = Timeout.add(100, autoscroll_timeout);
		} 
		else {
			stop_autoscroll();
		}
	}

	private void stop_autoscroll() {
		if(autoscroll_source != 0) {
			Source.remove(autoscroll_source);
			autoscroll_source = 0;
		}
	}

	private void get_autoscroll_delta(ref double delta) {
		int y_pos;
		this.get_window().get_pointer(null, out y_pos, null);
		delta = 0.0;
		if(y_pos < autoscroll_distance) 
			delta = (double)(y_pos - autoscroll_distance);
		Allocation alloc;
		this.get_allocation(out alloc);
		if(y_pos > (alloc.height - autoscroll_distance)) {
			if(delta != 0) { //window too narrow, don't autoscroll.
				return;
			}
			delta = (double)(y_pos - (alloc.height - autoscroll_distance));
		}
		if(delta == 0) {
			return;
		}
		if(delta != 0) {
			delta /= autoscroll_distance;
			delta *= 60;
		}
	}

	private void on_drag_begin(Gtk.Widget sender, DragContext context) {
		this.dragging = true;
		this.reorder_dragging = true;

		Gtk.TreeSelection selection = this.get_selection();
		Gdk.drag_abort(context, Gtk.get_current_event_time());
		if(selection.count_selected_rows() == 0) {
			return;
		}

		if(selection.count_selected_rows() > 1) {
			Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		return;
	}

	private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		this.dragging = false;
		this.reorder_dragging = false;
		this.unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  this.dest_target_entries,
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.MOVE
		                  );
		stop_autoscroll();
	}

	private void on_drag_leave(Gtk.Widget sender, Gdk.DragContext context, uint etime) {
		stop_autoscroll();
		
		Gdk.Window win = this.get_window();
		if(win == null) return;
		
		int px = 0, py = 0;
		win.get_pointer(out px, out py, null);
		
		if(px < 0 || py < 0) {
			if(xn.main_window.temporary_tab != TrackListNoteBookTab.TRACKLIST) {
				xn.main_window.tracklistnotebook.set_current_page(xn.main_window.temporary_tab);
				xn.main_window.temporary_tab = TrackListNoteBookTab.TRACKLIST;
			}
		}
	}

	private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context,
	                              Gtk.SelectionData selection, 
	                              uint target_type, uint etime) {
		rowref_list = {};
		TreeIter iter;
		GLib.Value uri;
		List<unowned TreePath> paths;
		unowned Gtk.TreeSelection sel;
		string[] uris;

		sel = this.get_selection();
		paths = sel.get_selected_rows(null);
 		int i = 0;
		uris = new string[(int)paths.length() + 1];
		foreach(unowned TreePath path in paths) {
			this.tracklistmodel.get_iter(out iter, path);
			this.tracklistmodel.get_value(iter, TrackListModel.Column.URI, out uri);
			uris[i] = uri.get_string();
			i++;
			TreeRowReference treerowref = new TreeRowReference(this.tracklistmodel, path);
			if(treerowref.valid()) {
				rowref_list += (owned)treerowref;
			}
		}
		selection.set_uris(uris);
	}

	private Gtk.TreeViewDropPosition drop_pos;
	private void on_drag_data_received(Gtk.Widget sender, DragContext context, int x, int y,
	                                   SelectionData selection, uint target_type, uint time) {
		//set uri list for dragging out of xnoise. in parallel work around with rowreferences
		//if reorder = false then data is coming from outside (music browser or nautilus)
		// -> use uri_list
		Gtk.TreePath path;
		TreeRowReference drop_rowref;
		FileType filetype;
		File file;
		string[] uris;
		this.get_dest_row_at_pos(x, y, out path, out drop_pos);
		
		if(!this.reorder_dragging ) {
			switch(target_type) {
				// DRAGGING NOT WITHIN TRACKLIST
				case 0: // custom dnd data from media browser
					unowned DndData[] ids = (DndData[])selection.get_data();
					ids.length = (int)(selection.get_length() / sizeof(DndData));
					
					TreeRowReference row_ref = null;
					if(path != null)
						row_ref = new TreeRowReference(this.model, path);
					
					var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.insert_dnd_data_job);
					job.set_arg("row_ref", row_ref);
					job.set_arg("drop_pos", drop_pos);
					job.dnd_data = ids;
					worker.push_job(job);
					break;
				case 1: // uri list from outside
					uris = selection.get_uris();
					drop_rowref = null;
					bool is_first = true;
					string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
					              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
					foreach(string uri in uris) {
						bool is_stream = false;
						file = File.new_for_uri(uri);
						if(file.get_uri_scheme() in global.remote_schemes) is_stream = true;
						if(!is_stream) {
							try {
								FileInfo info = file.query_info(attr,
								                                FileQueryInfoFlags.NONE,
								                                null);
								filetype = info.get_file_type();
							}
							catch(GLib.Error e){
								print("%s\n", e.message);
								return;
							}
							if(filetype != GLib.FileType.DIRECTORY) {
								handle_dropped_file(ref uri, ref path, ref is_first);	//FILES
							}
							else {
								handle_dropped_files_for_folders(file, ref path, ref is_first); //DIRECTORIES
							}
						}
					}
					break;
				default:
					assert_not_reached();
			
			}
		}
		else { // DRAGGING WITHIN TRACKLIST
			uris = selection.get_uris();
			drop_rowref = null;
			if(path != null) {
				//TODO:check if drop position is selected
				drop_rowref = new TreeRowReference(this.tracklistmodel, path);
				if(drop_rowref == null || !drop_rowref.valid()) 
					return;
			}
			else {
				get_last_unselected_path(ref path);
				drop_rowref = new TreeRowReference(this.tracklistmodel, path);
				if(drop_rowref == null || !drop_rowref.valid()) {
					return;
				}
			}
			if((!(drop_pos == Gtk.TreeViewDropPosition.BEFORE))&&
			   (!(drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE))) {
				for(int i=rowref_list.length-1;i>=0;i--) {
					if(rowref_list[i] == null || !rowref_list[i].valid()) {
						return;
					}
					unowned TreeIter current_iter;
					unowned TreeIter drop_iter;
					var current_path = rowref_list[i].get_path();
					this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
					TreePath drop_path = drop_rowref.get_path();
					this.tracklistmodel.get_iter(out drop_iter, drop_path);//get iter for drop position
					this.tracklistmodel.move_after(ref current_iter, drop_iter); //move
				}
			}
			else {
				for(int i=0;i<rowref_list.length;i++) {
					if(rowref_list[i] == null || !rowref_list[i].valid()) {
						return;
					}
					unowned TreeIter current_iter;
					unowned TreeIter drop_iter;
					var current_path = rowref_list[i].get_path();
					this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
					TreePath drop_path = drop_rowref.get_path();
					this.tracklistmodel.get_iter(out drop_iter, drop_path); //get iter for drop position
					this.tracklistmodel.move_before(ref current_iter, drop_iter); //move
				}
			}
		}
		drop_pos = Gtk.TreeViewDropPosition.AFTER; //Default position for next run
		rowref_list = null;
		
		//After dropping an item hide the tracklist with a delay of HIDE_TIMEOUT ms 
		//if it was only shown temporarily
		
		if(xn.main_window.temporary_tab != TrackListNoteBookTab.TRACKLIST) {
			if(hide_timer != 0) 
				GLib.Source.remove(hide_timer);
			
			hide_timer = Timeout.add(HIDE_TIMEOUT, () => {
				if(xn.main_window.temporary_tab != TrackListNoteBookTab.TRACKLIST) {
					xn.main_window.tracklistnotebook.set_current_page(xn.main_window.temporary_tab);
					xn.main_window.temporary_tab = TrackListNoteBookTab.TRACKLIST;
				}
				hide_timer = 0;
				return false;
			});
		}
	}

	private void insert_dnd_data_job(Worker.Job job) {
		DndData[] ids = job.dnd_data;
		TrackData td;
		DbBrowser dbBr = null;
		try {
			dbBr = new DbBrowser();
		}
		catch(DbError e) {
			print("%s\n", e.message);
			return;
		}
		bool is_first = true;
		TreeViewDropPosition drop_pos_1 = (TreeViewDropPosition)job.get_arg("drop_pos");
		TreeRowReference row_ref = (TreeRowReference)job.get_arg("row_ref");
		TreePath path = null;
		if(row_ref != null && row_ref.valid())
			path = row_ref.get_path();
		//TODO: Decide if it is video or stream or local file and then get data from the right source
		foreach(DndData ix in ids) {
			switch(ix.mediatype) {
				case MediaType.VIDEO: 
				case MediaType.AUDIO: {
					string lengthString = "", artist, album, title, uri;
					int tracknumb;
					if(dbBr.get_trackdata_for_id((int)ix.db_id, out td)) {
						artist    = td.artist;
						album     = td.album;
						title     = td.title;
						tracknumb = (int)td.tracknumber;
						lengthString = make_time_display_from_seconds(td.length);
						uri = td.uri;
						Idle.add( () => {
					
							TreeIter iter, new_iter;
							TreeIter first_iter = TreeIter();
							if((path == null)||(!this.tracklistmodel.get_iter_first(out first_iter))) { 
								//dropped below all entries, first uri OR
								//dropped on empty list, first uri
								tracklistmodel.append(out new_iter);
								drop_pos_1 = Gtk.TreeViewDropPosition.AFTER;
							}
							else { //all other uris
								this.tracklistmodel.get_iter(out iter, path);
								if(is_first) {
									if((drop_pos_1 == Gtk.TreeViewDropPosition.BEFORE)||
									   (drop_pos_1 == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
									   //Determine drop position for first, insert all others after first
										this.tracklistmodel.insert_before(out new_iter, iter);
									}
									else {
										this.tracklistmodel.insert_after(out new_iter, iter);
									}
									is_first = false;
								}
								else {
									this.tracklistmodel.insert_after(out new_iter, iter);
								}
							}
							string tracknumberString = null;
							if(tracknumb!=0) {
								tracknumberString = "%u".printf(tracknumb);
							}
							tracklistmodel.set(new_iter,
							                   TrackListModel.Column.TRACKNUMBER, tracknumberString,
							                   TrackListModel.Column.TITLE, title,
							                   TrackListModel.Column.ALBUM, album,
							                   TrackListModel.Column.ARTIST, artist,
							                   TrackListModel.Column.LENGTH, lengthString,
							                   TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
							                   TrackListModel.Column.URI, uri,
							                   -1);
							path = tracklistmodel.get_path(new_iter);
							return false;
						});
					}
					break;
				}
				case MediaType.STREAM: {
					string lengthString = "", artist, album, title, uri;
					int tracknumb;
					if(dbBr.get_stream_td_for_id((int)ix.db_id, out td)) {
						artist    = td.artist;
						album     = td.album;
						title     = td.title;
						tracknumb = (int)td.tracknumber;
						lengthString = make_time_display_from_seconds(td.length);
						uri = td.uri;
						Idle.add( () => {
							TreeIter iter, new_iter;
							TreeIter first_iter = TreeIter();
							if((path == null)||(!this.tracklistmodel.get_iter_first(out first_iter))) { 
								//dropped below all entries, first uri OR
								//dropped on empty list, first uri
								tracklistmodel.append(out new_iter);
								drop_pos_1 = Gtk.TreeViewDropPosition.AFTER;
							}
							else { //all other uris
								this.tracklistmodel.get_iter(out iter, path);
								if(is_first) {
									if((drop_pos_1 == Gtk.TreeViewDropPosition.BEFORE)||
									   (drop_pos_1 == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
									   //Determine drop position for first, insert all others after first
										this.tracklistmodel.insert_before(out new_iter, iter);
									}
									else {
										this.tracklistmodel.insert_after(out new_iter, iter);
									}
									is_first = false;
								}
								else {
									this.tracklistmodel.insert_after(out new_iter, iter);
								}
							}
							string tracknumberString = null;
							if(tracknumb!=0) {
								tracknumberString = "%u".printf(tracknumb);
							}
							tracklistmodel.set(new_iter,
							                   TrackListModel.Column.TRACKNUMBER, tracknumberString,
							                   TrackListModel.Column.TITLE, title,
							                   TrackListModel.Column.ALBUM, album,
							                   TrackListModel.Column.ARTIST, artist,
							                   TrackListModel.Column.LENGTH, lengthString,
							                   TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
							                   TrackListModel.Column.URI, uri,
							                   -1);
							path = tracklistmodel.get_path(new_iter);
							return false;
						});
					}
					break;
				}
//				case MediaType.STREAM:
//					break;
				default:
					break;
			}
		}
	}

	private void handle_dropped_files_for_folders(File dir, ref TreePath? path, ref bool is_first) {
		//Recursive function to import music DIRECTORIES in drag'n'drop
		//as soon as a file is found it is passed to handle_dropped_file function
		//the TreePath path is just passed through if it is a directory
		FileEnumerator enumerator;
		try {
			string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
			              FILE_ATTRIBUTE_STANDARD_TYPE;
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
		}
		catch(Error e) {
			print("Error importing directory %s. %s\n", dir.get_path(), e.message);
			return;
		}
		FileInfo info;
		try {
			while((info = enumerator.next_file(null)) != null) {
				string filename = info.get_name();
				string filepath = Path.build_filename(dir.get_path(), filename);
				File file = File.new_for_path(filepath);
				FileType filetype = info.get_file_type();

				if(filetype == FileType.DIRECTORY) {
					this.handle_dropped_files_for_folders(file, ref path, ref is_first);
				}
				else {
					string buffer = file.get_uri();
					handle_dropped_file(ref buffer, ref path, ref is_first);
				}
			}
		}
		catch(Error e) {
			print("Error: %s\n", e.message);
			return;
		}
	}

//	private void handle_dropped_stream(ref string streamuri, ref TreePath? path, 
//	                                   ref bool is_first) {
//		//Function to import music STREAMS in drag'n'drop
//		TreeIter iter, new_iter;
//		File file = File.new_for_uri(streamuri);

//		string artist, album, title;
//		artist    = "";
//		album     = "";
//		title     = file.get_uri();

//		TreeIter first_iter;
//		if(!this.tracklistmodel.get_iter_first(out first_iter)) { //dropped on empty list, first uri
//			this.tracklistmodel.insert(out new_iter, 0);
//		}
//		else if(path==null) { //dropped below all entries, first uri
//			tracklistmodel.append(out new_iter);
//		}
//		else { //all other uris
//			this.tracklistmodel.get_iter(out iter, path);
//			if(is_first) {
//				if((drop_pos == Gtk.TreeViewDropPosition.BEFORE)||
//				   (drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
//				   //Determine drop position for first, insert all others after first
//					this.tracklistmodel.insert_before(out new_iter, iter);
//				}
//				else {
//					this.tracklistmodel.insert_after(out new_iter, iter);
//				}
//				is_first = false;
//			}
//			else {
//				this.tracklistmodel.insert_after(out new_iter, iter);
//			}
//		}
//		//TODO use insert_title function of tracklistmodel instead ?!?
//		tracklistmodel.set(new_iter,
//		                   TrackListModel.Column.TITLE, title,
//		                   TrackListModel.Column.ALBUM, album,
//		                   TrackListModel.Column.ARTIST, artist,
//		                   TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
//		                   TrackListModel.Column.URI, streamuri,
//		                   -1);
//		path = tracklistmodel.get_path(new_iter);
//	}

	private string make_time_display_from_seconds(int length) {
		string lengthString = "";
		if(length > 0) {
			// convert seconds to a user convenient mm:ss display
			int dur_min, dur_sec;
			dur_min = (int)(length / 60);
			dur_sec = (int)(length % 60);
			lengthString = "%02d:%02d".printf(dur_min, dur_sec);
		}
		return lengthString;
	}

	private void handle_dropped_file(ref string fileuri, ref TreePath? path, ref bool is_first) {
		//Function to import music FILES in drag'n'drop
		TreeIter iter, new_iter;
		File file;
		FileType filetype;
		string mime;
		var psVideo = new PatternSpec("video*");
		var psAudio = new PatternSpec("audio*");
		string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		try {
			file = File.new_for_uri(fileuri);
			FileInfo info = file.query_info(
			                    attr,
			                    FileQueryInfoFlags.NONE,
			                    null);
			filetype = info.get_file_type();
			string content = info.get_content_type();
			mime = GLib.ContentType.get_mime_type(content);
		}
		catch(GLib.Error e){
			print("%s\n", e.message);
			return;
		}
		if((filetype == GLib.FileType.REGULAR)&
		   ((psAudio.match_string(mime))|(psVideo.match_string(mime)))) {
			string artist, album, title, lengthString = "";
			uint tracknumb;
			if(!(psVideo.match_string(mime))) {
				var tr = new TagReader(); // TODO: Check dataimport for video
				var tags = tr.read_tag(file.get_path());
				artist         = tags.artist;
				album          = tags.album;
				title          = tags.title;
				tracknumb      = tags.tracknumber;
				lengthString = make_time_display_from_seconds(tags.length);
			}
			else { //TODO: Handle video data
				artist         = "";
				album          = "";
				title          = file.get_basename();
				tracknumb      = 0;
			}
			TreeIter first_iter;
			if((path == null)||(!this.tracklistmodel.get_iter_first(out first_iter))) { 
				//dropped below all entries, first uri OR
				//dropped on empty list, first uri
				tracklistmodel.append(out new_iter);
				drop_pos = Gtk.TreeViewDropPosition.AFTER;
			}
			else { //all other uris
				this.tracklistmodel.get_iter(out iter, path);
				if(is_first) {
					if((drop_pos == Gtk.TreeViewDropPosition.BEFORE)||
					   (drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
					   //Determine drop position for first, insert all others after first
						this.tracklistmodel.insert_before(out new_iter, iter);
					}
					else {
						this.tracklistmodel.insert_after(out new_iter, iter);
					}
					is_first = false;
				}
				else {
					this.tracklistmodel.insert_after(out new_iter, iter);
				}
			}
			string tracknumberString = null;
			if(tracknumb!=0) {
				tracknumberString = "%u".printf(tracknumb);
			}
			tracklistmodel.set(new_iter,
			                   TrackListModel.Column.TRACKNUMBER, tracknumberString,
			                   TrackListModel.Column.TITLE, title,
			                   TrackListModel.Column.ALBUM, album,
			                   TrackListModel.Column.ARTIST, artist,
			                   TrackListModel.Column.LENGTH, lengthString,
			                   TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
			                   TrackListModel.Column.URI, fileuri,
			                   -1);
			path = tracklistmodel.get_path(new_iter);
		}
		else if(filetype==GLib.FileType.DIRECTORY) {
			assert_not_reached();
		}
		else {
			print("Not a regular file or at least no audio file: %s\n", fileuri);
		}
	}

	private void get_last_unselected_path(ref TreePath? path) {
		int rowcount = -1;
		rowcount = (int)this.tracklistmodel.iter_n_children(null);
		if(rowcount>0) {
			//get path of last unselected
			bool found = false;
			List<unowned TreePath> selected_paths;
			unowned Gtk.TreeSelection sel = this.get_selection();
			selected_paths = sel.get_selected_rows(null);
			int i=0;
			do {
				path = new TreePath.from_string("%d".printf(rowcount - 1 - i));
				foreach(unowned TreePath treepath in selected_paths) {
					if(treepath.compare(path)!=0) {
						found = true;
						break;
					}
				}
				if(found) break;
				i++;
			}
			while(i<(rowcount-1));
		}
		else {
			print("no path\n");
			path = null;
			return;
		}
	}

	private void on_row_activated(Gtk.Widget sender, TreePath path, TreeViewColumn column) {
		string uri = null;
		TreeIter iter;
		if(tracklistmodel.get_iter(out iter, path)) {
			tracklistmodel.get(iter, TrackListModel.Column.URI, out uri);
		}
		this.on_activated(uri, path);
	}

	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey ek) {
		int KEY_DELETE = 0xFFFF;
		if(ek.keyval==KEY_DELETE)
			this.remove_selected_rows();
		return true;
	}

	private const int F_KEY = 0x0066;
	private bool on_key_pressed(Gtk.Widget sender, Gdk.EventKey e) {
		switch(e.keyval) {
			case F_KEY: 
				return false;
			default:
				break;
		}
		return false;
	}
	
	public void set_focus_on_iter(ref TreeIter iter) {
		TreePath start_path, end_path;
		TreePath current_path = tracklistmodel.get_path(iter);

		if(!this.get_visible_range(out start_path, out end_path))
			return;

		unowned int[] start   = start_path.get_indices();
		unowned int[] end     = end_path.get_indices();
		unowned int[] current = current_path.get_indices();

		if(!((start[0] < current[0])&&
		    (current[0] < end[0])))
			this.scroll_to_cell(current_path, null, true, (float)0.3, (float)0.0);
	}

	public void remove_selected_rows() {
		bool removed_playing_title = false;
		TreeIter iter;
		TreePath path_2 = new TreePath();
		GLib.List<TreePath> list;
		list = this.get_selection().get_selected_rows(null);
		if(list.length() == 0) return;
		list.reverse();
		foreach(unowned Gtk.TreePath path in list) {
			tracklistmodel.get_iter(out iter, path);
			path_2 = path;
			if((global.position_reference!=null)&&
			   (!removed_playing_title)&&
			   (path.compare(global.position_reference.get_path()) == 0)) {
				removed_playing_title = true;
				global.position_reference = null;
				//global.reset_position_reference(); // set to null without *_changed signal
			}
			tracklistmodel.remove(iter);
		}
		if(path_2.prev() && removed_playing_title) {
			tracklistmodel.get_iter(out iter, path_2);
			global.position_reference_next = new TreeRowReference(tracklistmodel, path_2);
			return;
		}
		if(removed_playing_title) tracklistmodel.set_reference_to_last();
	}

	public void on_activated(string uri, TreePath path) {
		//check for existance on local files
		File track = File.new_for_uri(uri);

		if(track.get_uri_scheme() in global.local_schemes) {
			if(!track.query_exists(null)) return;
		}

		if(path != null) {
			global.position_reference = new TreeRowReference(this.tracklistmodel, path);
		}
		else {
			print("cannot setup treerowref\n");
			return;
		}
		global.current_uri = uri;
		global.player_state = PlayerState.PLAYING;

		TreeIter iter;
		this.tracklistmodel.get_iter(out iter, path);
		this.set_focus_on_iter(ref iter);
	}
	
	/*private void column_visibility_changed();
	private void column_resizability_changed();*/

	// i hide the default insert_colum, so we can load the column's position
	// from the config file before actually inserting it
	private new void insert_column(Gtk.TreeViewColumn column, int position) {
		if(position < 0) {
			position = par.get_int_value("position_" + column.title + "_column");
		}

		// in the config file we count from 1 onwards, because 0 means "not set"
		// if position is 0, it will -1, meaning it will be placed at the end
		position--;
		
		base.insert_column(column, position);
	}

	

	private void setup_view() {
		CellRendererText renderer;
		
		
		relative_column_sizes = new HashTable<string,double?>(str_hash, str_equal);
		this.columns_changed.connect(() => {
			bool new_column = false;
			var columns = this.get_columns();
			foreach(TreeViewColumn c in columns) {
				if(c == null) continue;
				if(relative_column_sizes.lookup(c.title) == null && c.title != "") {
					if(c.resizable) {
						double rel_size = par.get_double_value("relative_size_" + c.title + "_column");
						relative_column_sizes.insert(c.title, rel_size);
						((TextColumn)c).resized.connect(on_column_resized);
					}
					new_column = true;
				}
				// connect to visibility property change
				// connect to resizable property change
				// override this class' insert_column with this code			
			}
			if(new_column)
				n_columns++;
			else
				n_columns--;
			handle_resize();
		});
		
		this.show.connect(() => {
			// give the columns their relative sizes
			var columns = this.get_columns();
			foreach(TreeViewColumn c in columns) {
				if(c == null) continue;
				if(!c.resizable) continue;
				double? rel_size = relative_column_sizes.lookup(c.title);
				if(rel_size == null) continue;
				((TextColumn)c).adjust_width((int)((double)rel_size * (double)available_width));
			}
			handle_resize();
		});
				
				 
				

		// STATUS ICON
		var pixbufRenderer = new CellRendererPixbuf();
		columnPixb         = new TreeViewColumn();
		pixbufRenderer.set_fixed_size(-1,22);
		columnPixb.pack_start(pixbufRenderer, false);
		columnPixb.add_attribute(pixbufRenderer, "pixbuf", TrackListModel.Column.ICON);
		columnPixb.set_fixed_width(30);
		columnPixb.min_width = 30;
		columnPixb.reorderable = false;
		this.insert_column(columnPixb, -1);


		// TRACKNUMBER
		renderer = new CellRendererText();
		columnTracknumber = new TextColumn("#", renderer, TrackListModel.Column.TRACKNUMBER);
		columnTracknumber.add_attribute(renderer,
		                                "text", TrackListModel.Column.TRACKNUMBER);
		columnTracknumber.add_attribute(renderer,
		                                "weight", TrackListModel.Column.WEIGHT);
		columnTracknumber.adjust_width(32);
		columnTracknumber.min_width = 32;
		columnTracknumber.resizable = false;
		columnTracknumber.reorderable = true;
		this.insert_column(columnTracknumber, -1);
		if(par.get_int_value(USE_TR_NO_COL) == 1) {
			columnTracknumber.visible = true;
		}
		else {
			columnTracknumber.visible = false;
		}


		// TITLE
		renderer = new CellRendererText();
		renderer.ellipsize = Pango.EllipsizeMode.END;
		renderer.ellipsize_set = true;
		columnTitle = new TextColumn("Title", renderer, TrackListModel.Column.TITLE);
		columnTitle.add_attribute(renderer,
		                          "text", TrackListModel.Column.TITLE);
		columnTitle.add_attribute(renderer,
		                          "weight", TrackListModel.Column.WEIGHT);
		columnTitle.min_width = 80;
		columnTitle.resizable = true;
		columnTitle.reorderable = true;
		this.insert_column(columnTitle, -1);
		variable_col_count++;


		// ALBUM
		renderer = new CellRendererText();
		renderer.ellipsize = Pango.EllipsizeMode.END;
		renderer.ellipsize_set = true;
		columnAlbum = new TextColumn("Album", renderer, TrackListModel.Column.ALBUM);
		columnAlbum.add_attribute(renderer,
		                          "text", TrackListModel.Column.ALBUM);
		columnAlbum.add_attribute(renderer,
		                          "weight", TrackListModel.Column.WEIGHT);
		columnAlbum.min_width = 80;
		columnAlbum.resizable = true;
		columnAlbum.reorderable = true;
		this.insert_column(columnAlbum, -1);
		variable_col_count++;
		
		if(par.get_int_value(USE_ALBUM_COL) == 1) {
			columnAlbum.visible = true;
		}
		else {
			columnAlbum.visible = false;
		}

		// ARTIST
		renderer = new CellRendererText();
		renderer.ellipsize = Pango.EllipsizeMode.END;
		renderer.ellipsize_set = true;
		columnArtist = new TextColumn("Artist", renderer, TrackListModel.Column.ARTIST);
		columnArtist.add_attribute(renderer,
		                           "text", TrackListModel.Column.ARTIST);
		columnArtist.add_attribute(renderer,
		                           "weight", TrackListModel.Column.WEIGHT);
		columnArtist.min_width = 80;
		columnArtist.resizable = true; // This is the case for the current column order
		columnArtist.reorderable = true;
		this.insert_column(columnArtist, -1);
		variable_col_count++;

		// LENGTH
		renderer = new CellRendererText();
		columnLength = new TextColumn("Length", renderer, TrackListModel.Column.LENGTH);
		columnLength.add_attribute(renderer,
		                           "text", TrackListModel.Column.LENGTH);
		columnLength.add_attribute(renderer,
		                           "weight", TrackListModel.Column.WEIGHT);

		columnLength.adjust_width(75);
		columnLength.min_width = 75;
		columnLength.resizable = false;
		columnLength.reorderable = true;
		this.insert_column(columnLength, -1);

		if(par.get_int_value(USE_LEN_COL) == 1) {
			columnLength.visible = true;
		}
		else {
			columnLength.visible = false;
		}

		columnPixb.sizing        = Gtk.TreeViewColumnSizing.FIXED;
		columnTracknumber.sizing = Gtk.TreeViewColumnSizing.FIXED;
		columnTitle.sizing       = Gtk.TreeViewColumnSizing.FIXED;
		columnAlbum.sizing       = Gtk.TreeViewColumnSizing.FIXED;
		columnArtist.sizing      = Gtk.TreeViewColumnSizing.FIXED;
		columnLength.sizing      = Gtk.TreeViewColumnSizing.FIXED;
		
		this.set_enable_search(false);
		this.rules_hint = true;
	}
	
	private int available_width {
		get {
			if(xn.main_window == null) 
				return 0;
	
			int h, w;
			int scrollbar_w = 0;
			xn.main_window.get_size(out w, out h);
			
			if(xn.main_window.trackListScrollWin != null) {
				var scrollbar = xn.main_window.trackListScrollWin.get_vscrollbar();
				if(scrollbar != null) {
					Requisition req; 
					scrollbar.get_child_requisition(out req);
					scrollbar_w = req.width;
				}
			}
			
			//Value v = Value(typeof(int));
			//((TreeView)this).style_get_property("vertical-separator", out v);
			//int vertical_separator_size = v.get_int();
			
			//print("|%i|%i", w - (scrollbar_w + 
			//            xn.main_window.hpaned.position + 
			//            n_columns * vertical_separator_size), n_columns);
			
			return w - (scrollbar_w + 
			            xn.main_window.hpaned.position);/* + 
			            n_columns * vertical_separator_size);*/		
		}
	}
	
	
	public void handle_resize() {
		if(xn.main_window == null)
			return;
		if(xn.main_window.get_window() == null)
			return;
		resize_column_range_relatively(0);
	}
	
	private void on_column_resized(TextColumn sender, bool grow, int delta, TrackListModel.Column id) {
		var columns = this.get_columns();
		int iter = 0;
		int result = 0;
		
		//print("Column resize: %s\n", sender.title);
		
		foreach(TreeViewColumn c in columns) {
			if(sender.title == c.title) {
				/* now we have the position number of the column that has been resized */
				result = resize_column_range_relatively(iter+1);
				if(result < 0) {
					/* the column was resized to a size that exceeds the available space
					by result, lower its size by result again */
					sender.adjust_width(sender.width + result);
				}
			}
			if(c.resizable)
				/* store the column's new relative size in a hash table */
				relative_column_sizes.replace(c.title, (double)c.width / (double)available_width);
			iter++;
		}
	}
	

	// DANGER: resizable columns need to be text columns
	
	/* resizes a range of columns relatively the start of that range is marked
	by the number of the first column and its end is marked by the last column
	int the treeview, delta is the difference in size */
	private int resize_column_range_relatively(int starting_column) {
		if(!this.visible) return 0;
		//print("\nresizing from column %d\n", starting_column);
	
		var columns = this.get_columns();
		int iter = -1;
		
		/* that's the width to the left, we don't touch it.
		only the columns to the right are resized */
		int left_width = 0;
		
		/* that's the width of the fixed size columns */
		int fixed_width = 0;
		
		/* the minimun width for resizable columns*/
		int min_dynamic_width = 0;
		
		/* the sum of all relative column sizes, only for resizable columns.
		the single sizes are the part of each column's width that exceeds the column's
		minimun width, relative to the treeview's width as a whole.
		we can divide the min_width in this formula by an arbitrary number if we want the
		size to be distributed more equally among the columns. */
		double rel_size_sum = 0;
		
		/* iterate over the columns and calculate those sizes */
		foreach(TreeViewColumn c in columns) {
			iter++;
			/* only handle visible columns */
			if(!c.visible) continue;
			if(iter < starting_column) {
				left_width += c.width;
				continue;
			}
			
			if(c.resizable) {
				min_dynamic_width += c.min_width;
				double? rel_size = relative_column_sizes.lookup(c.title);
				if(rel_size == null) rel_size = 0.15;
				rel_size_sum += (double)rel_size - (double)c.min_width / (double)available_width;
				continue;
			}
			
			fixed_width += c.width;
		}
		
		if(starting_column > iter) return 0;
		
		
		/* the width that is not statically allocated as minimum or fixed width 
		and must be distributed among the resizable columns */
		int distributable_width = available_width - (left_width + min_dynamic_width + fixed_width);
		
		if(left_width <= 0 && available_width <= (min_dynamic_width + fixed_width)) distributable_width = 0;
		
		//print("width to dsitribute %d\n", distributable_width);
		//print("available width %d, fixed_width %d, min_dynamic_width %d, left_width %d, rel_size_sum %f\n", available_width, fixed_width, min_dynamic_width, left_width, rel_size_sum);
		
		unowned List<TreeViewColumn> starting_column_node = columns.nth(starting_column);
		foreach(TreeViewColumn c in starting_column_node) {
			if(c.resizable) {
				//get the column's relative size
				double? rel_size = relative_column_sizes.lookup(c.title);
				if(rel_size == null) rel_size = 0.15;
				rel_size = ((double)rel_size - (double)c.min_width / (double)available_width) / rel_size_sum;
				
				/* print("resizing %s to %d, rel_size %f\n", c.title, c.min_width + 
					(int)(((double)distributable_width) * (double)rel_size), rel_size); */
						
				((TextColumn) c).adjust_width(c.min_width + 
					(int)(((double)distributable_width) * (double)rel_size));
			}
		}	
		return distributable_width;
	}
	
	
		
	public void write_params_data() {
		var columns = this.get_columns();
		int counter = 0;
		foreach(TreeViewColumn c in columns) {
			if(c == null) continue;

			// write column position, counting from 1 onwards
			counter++;
			par.set_int_value("position_" + c.title + "_column", counter);

			// write relative column sizes
			if(!c.resizable) continue;
			double? relative_size = relative_column_sizes.lookup(c.title);
			if(relative_size == null) continue;
			par.set_double_value("relative_size_" + c.title + "_column", (double)relative_size);
		} 

	}
	
	public void read_params_data() {
	}
	
}




				
				
		

