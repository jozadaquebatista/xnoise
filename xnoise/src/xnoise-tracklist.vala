/* xnoise-tracklist.vala
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

public class Xnoise.TrackList : TreeView {
	private Main xn;
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};
	private const string USE_LEN_COL   = "use_length_column";
	private const string USE_TR_NO_COL = "use_tracknumber_column";
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
	private uint hide_timer;
	private bool hide_timer_set = false;
	private const uint HIDE_TIMEOUT = 1000;
	
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

		tracklistmodel = xn.tlm;
		this.set_model(tracklistmodel);
		this.setup_view();
		this.get_selection().set_mode(SelectionMode.MULTIPLE);

		Gtk.drag_source_set(
			this,
			Gdk.ModifierType.BUTTON1_MASK,
			this.target_list,
			Gdk.DragAction.COPY|
			Gdk.DragAction.MOVE
			);

		Gtk.drag_dest_set(
			this,
			Gtk.DestDefaults.ALL,
			this.target_list,
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
		this.drag_data_received.connect(this.on_drag_data_received);
		this.drag_leave.connect(this.on_drag_leave);
		this.button_release_event.connect(this.on_button_release);
		this.button_press_event.connect(this.on_button_press);
		
		menu = create_rightclick_menu();
	}
	
	/*private bool on_pointer_leave(CrossingEvent e) {
		xn.main_window.tracklistnotebook.set_current_page(xn.main_window.temporary_tab);
		return false;
	}*/

	private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
		Gtk.TreePath path;
		Gtk.TreeViewColumn column;

		Gtk.TreeSelection selection = this.get_selection();
		int x = (int)e.x;
		int y = (int)e.y;
		int cell_x, cell_y;
		if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y))) return true;

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
		var playpause_popup_image = new Gtk.Image();
		playpause_popup_image.set_from_stock(STOCK_DELETE, IconSize.MENU);
		var removeLabel = new Label(_("Remove selected"));
		removeLabel.set_alignment(0, 0);
		removeLabel.set_width_chars(20);
		var removetrackItem = new MenuItem();
		var removeHbox = new HBox(false,1);
		removeHbox.set_spacing(10);
		removeHbox.pack_start(playpause_popup_image, false, true, 0);
		removeHbox.pack_start(removeLabel, true, true, 0);
		removetrackItem.add(removeHbox);
		removetrackItem.activate.connect(this.remove_selected_rows);
		rightmenu.append(removetrackItem);
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
		
		expose_area.x      = this.allocation.x;
		expose_area.y      = this.allocation.y;
		expose_area.width  = this.allocation.width;
		expose_area.height = this.allocation.height;
		
		if(delta > 0) {
			expose_area.y = expose_area.height - (int)delta;
		} 
		else {
			if(delta < 0)
				expose_area.height = (int)(-1.0 * delta);
		}

		expose_area.x -= this.allocation.x;
		expose_area.y -= this.allocation.y;

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
		this.window.get_pointer(null, out y_pos, null);
		delta = 0.0;
		if(y_pos < autoscroll_distance) 
			delta = (double)(y_pos - autoscroll_distance);

		if(y_pos > (this.allocation.height - autoscroll_distance)) {
			if(delta != 0) { //window too narrow, don't autoscroll.
				return;
			}
			delta = (double)(y_pos - (this.allocation.height - autoscroll_distance));
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
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND_MULTIPLE);
		}
		else {
			Gtk.drag_source_set_icon_stock(this, Gtk.STOCK_DND);
		}
		return;
	}

	private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		this.dragging = false;
		this.reorder_dragging = false;
		this.unset_rows_drag_dest();
		Gtk.drag_dest_set(
			this,
			Gtk.DestDefaults.ALL,
			this.target_list,
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
		string uri = null;
		File file;
		FileType filetype;
		string[] uris = selection.get_uris();
		this.get_dest_row_at_pos(x, y, out path, out drop_pos);
		DbBrowser dbBr = null;
		try {
			dbBr = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		if(!this.reorder_dragging) { 					// DRAGGING NOT WITHIN TRACKLIST
			string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
			              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
			bool is_first = true;
			for(int i=0; i<uris.length; i++) {
				bool is_stream = false;
				uri = uris[i];
				file = File.new_for_uri(uri);
				if(file.get_uri_scheme() == "http") is_stream = true;
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
						handle_dropped_file(ref uri, ref path, ref is_first, ref dbBr);	//FILES
					}
					else {
						handle_dropped_files_for_folders(file, ref path, ref is_first, ref dbBr); //DIRECTORIES
					}
				}
				else {
					handle_dropped_stream(ref uri, ref path, ref is_first, ref dbBr);
				}
			}
			is_first = false;
		}
		else { // DRAGGING WITHIN TRACKLIST
			drop_rowref = null;
			if(path!=null) {
				//TODO:check if drop position is selected
				drop_rowref = new TreeRowReference(this.tracklistmodel, path);
				if(drop_rowref == null || !drop_rowref.valid()) return;
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
			if(hide_timer_set) GLib.Source.remove(hide_timer);
			hide_timer = Timeout.add(HIDE_TIMEOUT, () => {
				hide_timer_set = false;
				if(xn.main_window.temporary_tab != TrackListNoteBookTab.TRACKLIST) {
					xn.main_window.tracklistnotebook.set_current_page(xn.main_window.temporary_tab);
					xn.main_window.temporary_tab = TrackListNoteBookTab.TRACKLIST;
				}
				return false;
			});
			hide_timer_set = true;
		}
	}

	private void handle_dropped_files_for_folders(File dir, ref TreePath? path, ref bool is_first, ref DbBrowser dbBr) {
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
					this.handle_dropped_files_for_folders(file, ref path, ref is_first, ref dbBr);
				}
				else {
					string buffer = file.get_uri();
					handle_dropped_file(ref buffer, ref path, ref is_first, ref dbBr);
				}
			}
		}
		catch(Error e) {
			print("Error: %s\n", e.message);
			return;
		}
	}

	private void handle_dropped_stream(ref string streamuri, ref TreePath? path, 
	                                   ref bool is_first, ref DbBrowser dbBr) {
		//Function to import music STREAMS in drag'n'drop
		TreeIter iter, new_iter;
		File file = File.new_for_uri(streamuri);

		string artist, album, title;
		TrackData td;
		if(dbBr.get_trackdata_for_stream(streamuri, out td)) {
			artist    = "";
			album     = "";
			title     = td.Title;
		}
		else {
			artist    = "";
			album     = "";
			title     = file.get_uri();
		}

		TreeIter first_iter;
		if(!this.tracklistmodel.get_iter_first(out first_iter)) { //dropped on empty list, first uri
			this.tracklistmodel.insert(out new_iter, 0);
		}
		else if(path==null) { //dropped below all entries, first uri
			tracklistmodel.append(out new_iter);
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
		tracklistmodel.set(new_iter,
		                   TrackListModel.Column.TITLE, title,
		                   TrackListModel.Column.ALBUM, album,
		                   TrackListModel.Column.ARTIST, artist,
		                   TrackListModel.Column.URI, streamuri,
		                   -1);
		path = tracklistmodel.get_path(new_iter);
	}

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

	private void handle_dropped_file(ref string fileuri, ref TreePath? path,
	                                 ref bool is_first, ref DbBrowser dbBr) {
		//Function to import music FILES in drag'n'drop
		TreeIter iter, new_iter;
		File file;
		FileType filetype;
		unowned string mime;
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
			mime = g_content_type_get_mime_type(content);
		}
		catch(GLib.Error e){
			print("%s\n", e.message);
			return;
		}

		if((filetype == GLib.FileType.REGULAR)&
		   ((psAudio.match_string(mime))|(psVideo.match_string(mime)))) {
			string artist, album, title, lengthString = "";
			uint tracknumb;
			TrackData td;
			if(dbBr.get_trackdata_for_uri(fileuri, out td)) {
				artist    = td.Artist;
				album     = td.Album;
				title     = td.Title;
				tracknumb = td.Tracknumber;
				lengthString = make_time_display_from_seconds(td.Length);
			}
			else {
				if(!(psVideo.match_string(mime))) {
					var tr = new TagReader(); // TODO: Check dataimport for video
					var tags = tr.read_tag(file.get_path());
					artist         = tags.Artist;
					album          = tags.Album;
					title          = tags.Title;
					tracknumb      = tags.Tracknumber;
					lengthString = make_time_display_from_seconds(td.Length);
				}
				else { //TODO: Handle video data
					artist         = "";
					album          = "";
					title          = file.get_basename();
					tracknumb      = 0;
				}
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

		if(track.get_uri_scheme() == "file") {
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
		global.track_state = GlobalAccess.TrackState.PLAYING;

		TreeIter iter;
		this.tracklistmodel.get_iter(out iter, path);
		this.set_focus_on_iter(ref iter);
	}

	private void setup_view() {
		CellRendererText renderer;

		// STATUS ICON
		var pixbufRenderer = new CellRendererPixbuf();
		columnPixb         = new TreeViewColumn();
		pixbufRenderer.set_fixed_size(-1,22);
		columnPixb.pack_start(pixbufRenderer, false);
		columnPixb.add_attribute(pixbufRenderer, "pixbuf", TrackListModel.Column.ICON);
		columnPixb.set_fixed_width(30);
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
		columnTracknumber.resizable = false;
		columnTracknumber.reorderable = false;
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
		columnTitle.reorderable = false;
		columnTitle.resized.connect(on_column_resized);
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
		columnAlbum.reorderable = false;
		columnAlbum.resized.connect( on_column_resized);
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
		columnArtist.resizable = false; // This is the case for the current column order
		columnArtist.reorderable = false;
		columnArtist.resized.connect(on_column_resized);
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
		columnLength.resizable = false;
		columnLength.reorderable = false;
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
		
		this.enable_search = false;
		this.rules_hint = true;
	}

	//Resize of a column affects resizable columns to the right, only and, of course, the resized column itself
	//Howto get the next cols to the right dynamically?
	//If a column is not resizable, use a width dependent on the contained text
	//Store the available space and maybe relative shares of it for the resizable columns, for later use in window resize etc.
	//During window/hpane resize a different mode has to be active to get 

	private double relative_fraction_title = 0.2;
	private double relative_fraction_album = 0.2;
	private double relative_fraction_artist = 0.2;
	
	private void on_column_resized(TextColumn sender, bool grow, int delta, TrackListModel.Column id) {
		switch(id) {
			case TrackListModel.Column.TITLE:
				if((columnTitle.width + columnAlbum.get_min_width() + columnArtist.get_min_width()) > available_dynamic_width) {
					//print("max delta %d %s\n", delta, grow.to_string());
					if(grow) {
						columnTitle.adjust_width(columnTitle.width - delta);
						break;
					}
				}
				int half_delta = ((int)(delta / 2)).abs();
				if(grow) {
					int cAlb = 0, cArt = 0, cAlbDelta = 0, cArtDelta = 0;
					cAlb = columnAlbum.width - (delta - half_delta);
					if(cAlb < columnAlbum.get_min_width()) {
						cAlbDelta = cAlb - columnAlbum.get_min_width();
						cAlb = columnAlbum.get_min_width();
					}

					cArt = columnArtist.width - half_delta - cAlbDelta;
					if(cArt < columnArtist.get_min_width()) {
						cArtDelta = cArt - columnArtist.get_min_width();
						cArt = columnArtist.get_min_width();
					}
					if(cArtDelta.abs() > 0) {
						columnTitle.adjust_width(columnTitle.width - cArtDelta.abs());
					}
					columnAlbum.adjust_width(cAlb);
					columnArtist.adjust_width(cArt);
				}
				else{
					columnAlbum.adjust_width(columnAlbum.width + (delta - half_delta));
					columnArtist.adjust_width(columnArtist.width + half_delta);
				}
				break;
			case TrackListModel.Column.ALBUM:
				if((columnTitle.width + columnAlbum.width + columnArtist.get_min_width()) > available_dynamic_width) {
					//print("max ALBUM delta %d %s\n", delta, grow.to_string());
					if(grow) {
						columnAlbum.adjust_width(columnAlbum.width - delta);
						break;
					}
				}
				if(grow) {
//					columnArtist.adjust_width(columnArtist.width - delta);
					int cArt = 0, cArtDelta = 0;
					cArt = columnArtist.width - delta;
					if(cArt < columnArtist.get_min_width()) {
						cArtDelta = cArt - columnArtist.get_min_width();
						cArt = columnArtist.get_min_width();
					}
					if(cArtDelta.abs() > 0) {
						columnAlbum.adjust_width(columnAlbum.width - cArtDelta.abs());
					}
					columnArtist.adjust_width(cArt);
				}
				else {
					columnArtist.adjust_width(columnArtist.width + delta);
				}
				break;
			case TrackListModel.Column.ARTIST:
				break;
			default:
				break;
		}
		relative_fraction_title  = (double)columnTitle.width  / (double)available_dynamic_width;
		relative_fraction_album  = (double)columnAlbum.width  / (double)available_dynamic_width;
		relative_fraction_artist = (double)columnArtist.width / (double)available_dynamic_width;
	}
	
	private int available_width {
		get {
			int w, h;
			xn.main_window.get_size(out w, out h);
			return (w - xn.main_window.hpaned.position);
		}
	}
	
	private int available_dynamic_width {
		get {
			return (available_width - (columnPixb.width + (columnTracknumber.visible ? columnTracknumber.width : 0) + (columnLength.visible ? 75 : 22)));
		}
	}
	
	public void handle_resize() {
		if(xn.main_window.window == null)
			return;
		//print("resized by hpaned or window\n");
		columnTitle.adjust_width((int)(relative_fraction_title * available_dynamic_width));
		columnAlbum.adjust_width((int)(relative_fraction_album * available_dynamic_width));
		columnArtist.adjust_width((int)(relative_fraction_artist * available_dynamic_width));
	}
}
