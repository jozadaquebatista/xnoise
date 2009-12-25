/* xnoise-tracklist.vala
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

using Gtk;
using Gdk;

public class Xnoise.TrackList : TreeView {
	private Main xn;
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};
	private TreeRowReference[] rowref_list;
	private bool dragging;
	private Menu menu;
	public TrackListModel tracklistmodel;
		
	public TrackList() {
		this.xn = Main.instance();
		if(xn.tlm == null)
			print("tracklist model instance not available\n");

		tracklistmodel = xn.tlm;
		this.set_model(tracklistmodel); 
		this.setup_view();
		this.get_selection().set_mode(SelectionMode.MULTIPLE); 
		tracklistmodel.sign_active_path_changed.connect(this.on_active_path_changed);

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
		this.drag_begin.connect(this.on_drag_begin);
		this.drag_data_get.connect(this.on_drag_data_get);
		this.drag_end.connect(this.on_drag_end);
		this.drag_motion.connect(this.on_drag_motion);
		this.drag_data_received.connect(this.on_drag_data_received);
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
					if(selectioncount<=1) {
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
//		var separator = new SeparatorMenuItem();
//		rightmenu.append(separator);
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
		return true; 
	}	

	private bool reorder_dragging;	
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
	}

	private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context, Gtk.SelectionData selection, 
	                             uint target_type, uint etime) {
		rowref_list = new TreeRowReference[0];
		TreeIter iter;
		GLib.Value uri;
		List<weak TreePath> paths;
		weak Gtk.TreeSelection sel;
		string[] uris; 

		sel = this.get_selection();
		paths = sel.get_selected_rows(null);
 		int i = 0;
		uris = new string[(int)paths.length() + 1];
		foreach(weak TreePath path in paths) {
			this.tracklistmodel.get_iter(out iter, path);
			this.tracklistmodel.get_value(iter, TrackListColumn.URI, out uri);
			uris[i] = uri.get_string();
			i++;
			TreeRowReference treerowref = new TreeRowReference(this.tracklistmodel, path);
			if(treerowref.valid()) {
				rowref_list += (owned)treerowref; 
			}
		}
		selection.set_uris(uris); 
	}

	private string[] list_of_uris;
	private bool list_foreach(TreeModel sender, TreePath path, TreeIter iter) { 
		GLib.Value gv;
		sender.get_value(
			iter, 
			TrackListColumn.URI, 
			out gv);
		list_of_uris += gv.get_string();
		return false;
	}
	
	public string[] get_all_tracks() {
		list_of_uris = {};
		this.tracklistmodel.foreach(list_foreach);
		return list_of_uris;
	}

	private Gtk.TreeViewDropPosition position;
	private void on_drag_data_received(Gtk.Widget sender, DragContext context, int x, int y, 
	                                   SelectionData selection, uint target_type, uint time) {
		//set uri list for dragging out of xnoise. in parallel work around with rowreferences
		//if reorder = false then data is coming from outside (music browser or nautilus) -> use uri_list
		Gtk.TreePath path;
		TreeRowReference drop_rowref;
		string uri = null;
		File file;
		FileType filetype;
		string[] uris = selection.get_uris();
		this.get_dest_row_at_pos(x, y, out path, out position);
		DbBrowser dbBr = new DbBrowser();

		if(!this.reorder_dragging) { 					// DRAGGING NOT WITHIN TRACKLIST
			string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
			              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
			bool is_first = true;
			for(int i=0; i<uris.length;i++) {
				bool is_stream = false;
				uri = uris[i]; 
				file = File.new_for_uri(uri);
				if(file.get_uri_scheme() == "http") is_stream = true;
				if(!is_stream) {
					try {
						FileInfo info = file.query_info(
										    attr, 
										    FileQueryInfoFlags.NONE, 
										    null);
						filetype = info.get_file_type();
					}
					catch(GLib.Error e){
						stderr.printf("%s\n", e.message);
						return;
					}	
		
					if(filetype!=GLib.FileType.DIRECTORY) {
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
		else { 											// DRAGGING WITHIN TRACKLIST
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
			if((!(position == Gtk.TreeViewDropPosition.BEFORE))&&
			   (!(position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE))) {
				for(int i=rowref_list.length-1;i>=0;i--) {
					if (rowref_list[i] == null || !rowref_list[i].valid()) {
						return;
					}
					weak TreeIter current_iter;
					weak TreeIter drop_iter;
					var current_path = rowref_list[i].get_path();
					this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
					TreePath drop_path = drop_rowref.get_path();
					this.tracklistmodel.get_iter(out drop_iter, drop_path);//get iter for drop position
					this.tracklistmodel.move_after(current_iter, drop_iter); //move
				}
			}
			else {
				for(int i=0;i<rowref_list.length;i++) { 
					if (rowref_list[i] == null || !rowref_list[i].valid()) {
						return;
					}
					weak TreeIter current_iter;
					weak TreeIter drop_iter;
					var current_path = rowref_list[i].get_path();
					this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
					TreePath drop_path = drop_rowref.get_path();
					this.tracklistmodel.get_iter(out drop_iter, drop_path); //get iter for drop position
					this.tracklistmodel.move_before(current_iter, drop_iter); //move
				}
			}
		}
		position = Gtk.TreeViewDropPosition.AFTER; //Default position for next run
		rowref_list = null;
		if(xn.main_window.drag_on_da) {
			xn.main_window.drag_on_da = false;
			xn.main_window.tracklistnotebook.set_current_page(1);
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
		} catch (Error e) {
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
		} catch(Error e) {
			print("Error: %s\n", e.message);
			return;
		}
	}

	private void handle_dropped_stream(ref string streamuri, ref TreePath? path, ref bool is_first, ref DbBrowser dbBr) {
		//Function to import music STREAMS in drag'n'drop
		TreeIter iter, new_iter;
		File file = File.new_for_uri(streamuri);
			
		string artist, album, title;
		TrackData td; 
		if(dbBr.get_trackdata_for_stream(streamuri, out td)) {
			artist    = "";
			album     = "";
			title     = Markup.printf_escaped("%s", td.Title);
		}
		else {
			artist    = ""; 
			album     = ""; 
			title     = Markup.printf_escaped("%s", file.get_uri()); 
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
				if((position == Gtk.TreeViewDropPosition.BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) { 
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
			TrackListColumn.STATE, TrackState.STOPPED,
			TrackListColumn.TITLE, title,
			TrackListColumn.ALBUM, album,
			TrackListColumn.ARTIST, artist,
			TrackListColumn.URI, streamuri,
			-1);
		path = tracklistmodel.get_path(new_iter);
	}
	
	private void handle_dropped_file(ref string fileuri, ref TreePath? path, ref bool is_first, ref DbBrowser dbBr) {
		//Function to import music FILES in drag'n'drop
		TreeIter iter, new_iter;
		File file;
		FileType filetype;
		weak string mime;
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
			stderr.printf("%s\n", e.message);
			return;
		}
	
		if((filetype==GLib.FileType.REGULAR)&
		   ((psAudio.match_string(mime))|(psVideo.match_string(mime)))) {
			string artist, album, title;
			uint tracknumb;
			TrackData td;
			if(dbBr.get_trackdata_for_uri(fileuri, out td)) {
				artist    = Markup.printf_escaped("%s", td.Artist);
				album     = Markup.printf_escaped("%s", td.Album);
				title     = Markup.printf_escaped("%s", td.Title);
				tracknumb = td.Tracknumber;
			}
			else {
				if(!(psVideo.match_string(mime))) {
					var tr = new TagReader(); // TODO: Check dataimport for video
					var tags = tr.read_tag(file.get_path());
					artist         = Markup.printf_escaped("%s", tags.Artist); 
					album          = Markup.printf_escaped("%s", tags.Album); 
					title          = Markup.printf_escaped("%s", tags.Title); 
					tracknumb      = tags.Tracknumber;
				}
				else { //TODO: Handle video data
					artist         = ""; 
					album          = ""; 
					title          = Markup.printf_escaped("%s", file.get_basename()); 
					tracknumb      = 0;
				}
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
					if((position == Gtk.TreeViewDropPosition.BEFORE)||
					   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) { 
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
				TrackListColumn.STATE, TrackState.STOPPED,
				TrackListColumn.TRACKNUMBER, tracknumberString,
				TrackListColumn.TITLE, title,
				TrackListColumn.ALBUM, album,
				TrackListColumn.ARTIST, artist,
				TrackListColumn.URI, fileuri,
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

	public void add_tracks(TrackData[]? td_list, bool imediate_play = true)	{
		if(td_list==null) return;
		if(td_list[0]==null) return;
		int k = 0;
		TreeIter iter, iter_2;
		File file;
		this.reset_play_status_all_titles();
		while(td_list[k]!=null) {
			string current_uri = td_list[k].Uri;
			file = File.new_for_uri(current_uri);

			if(k==0) {
				iter = tracklistmodel.insert_title(TrackState.PLAYING, 
											  null, 
											  (int)td_list[k].Tracknumber,
											  Markup.printf_escaped("%s", td_list[k].Title), 
											  Markup.printf_escaped("%s", td_list[k].Album), 
											  Markup.printf_escaped("%s", td_list[k].Artist), 
											  current_uri);
				tracklistmodel.set_state_picture_for_title(iter, TrackState.PLAYING);
				iter_2 = iter;
			}
			else {
				iter = tracklistmodel.insert_title(TrackState.STOPPED, 
											  null, 
											  (int)td_list[k].Tracknumber,
											  Markup.printf_escaped("%s", td_list[k].Title), 
											  Markup.printf_escaped("%s", td_list[k].Album), 
											  Markup.printf_escaped("%s", td_list[k].Artist), 
											  current_uri);
				tracklistmodel.set_state_picture_for_title(iter);
			}
			k++;
		}
		xn.add_track_to_gst_player(td_list[0].Uri); 	
	}
	
	public void add_uris(string[]? uris) {
		if(uris==null) return;
		if(uris[0]==null) return;
		int k = 0;
		TreeIter iter, iter_2;
		FileType filetype;
		this.reset_play_status_all_titles();
		while(uris[k]!=null) { //because foreach is not working for this array coming from libunique
			File file;
			TagReader tr = new TagReader();
			file = File.new_for_uri(uris[k]);
			bool is_stream = false;
			string urischeme = file.get_uri_scheme();
			var t = new TrackData();
			if(urischeme=="file") {
				try {
					FileInfo info = file.query_info(
										FILE_ATTRIBUTE_STANDARD_TYPE, 
										FileQueryInfoFlags.NONE, 
										null);
					filetype = info.get_file_type();
				}
				catch(GLib.Error e){
					stderr.printf("%s\n", e.message);
					k++;
					continue;
				}
				if(filetype==GLib.FileType.REGULAR) {
					t = tr.read_tag(file.get_path()); 
				}
				else {
					is_stream = true;
				}
			}
			else if(urischeme=="http") {
				is_stream = true;
			}
			if(k==0) {
				iter = tracklistmodel.insert_title(TrackState.PLAYING, 
											  null, 
											  (int)t.Tracknumber,
											  t.Title, 
											  t.Album, 
											  t.Artist, 
											  uris[k]);
				tracklistmodel.set_state_picture_for_title(iter, TrackState.PLAYING);
				iter_2 = iter;
			}
			else {
				iter = tracklistmodel.insert_title(TrackState.STOPPED, 
											  null, 
											  (int)t.Tracknumber,
											  t.Title, 
											  t.Album, 
											  t.Artist, 
											  uris[k]);	
				tracklistmodel.set_state_picture_for_title(iter);
			}
			tr = null;
			k++;
		}
		xn.add_track_to_gst_player(uris[0]); 
	}
	

	private void get_last_unselected_path(ref TreePath? path) {
		int rowcount = -1;
		rowcount = (int)this.tracklistmodel.iter_n_children(null); 
		if(rowcount>0) {
			//get path of last unselected
			bool found = false;
			List<weak TreePath> selected_paths;
			weak Gtk.TreeSelection sel = this.get_selection();
			selected_paths = sel.get_selected_rows(null);
			int i=0;
			do {
				path = new TreePath.from_string("%d".printf(rowcount - 1 - i));
				foreach(weak TreePath treepath in selected_paths) {
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
			tracklistmodel.get(iter, TrackListColumn.URI, out uri);
		}
		this.on_activated(uri, path);
	}

	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey ek) {
		int KEY_DELETE = 0xFFFF; 
		if(ek.keyval==KEY_DELETE) 
			this.remove_selected_rows();
		return true; 
	}

	public void set_focus_on_iter(ref TreeIter iter) {
		TreePath start_path, end_path;
		TreePath current_path = tracklistmodel.get_path(iter);
		if(!this.get_visible_range (out start_path, out end_path)) return;
		weak int[] start   = start_path.get_indices();
		weak int[] end     = end_path.get_indices();
		weak int[] current = current_path.get_indices();
		if(!((start[0] < current[0])&&(current[0] < end[0])))
			this.scroll_to_cell(current_path, null, true, (float)0.3, (float)0.0);
	}
	
	public void remove_selected_rows() { 
		bool removed_playing_title = false;
		TreeIter iter;
		TreePath path_2 = new TreePath();
		GLib.List<TreePath> list;
		list = this.get_selection().get_selected_rows(null);
		list.reverse();
		if(list.length()==0) return;
		foreach(weak Gtk.TreePath path in list) {
			TrackState state = TrackState.STOPPED;
			tracklistmodel.get_iter(out iter, path);
			path_2 = path;
			tracklistmodel.get(iter,
			              TrackListColumn.STATE, out state
			              );
			if((state==TrackState.PLAYING)||
			   (state==TrackState.PAUSED)) {
				removed_playing_title = true;
			}
			tracklistmodel.remove(iter);
		}
		if(path_2.prev() && removed_playing_title) { 
			tracklistmodel.get_iter(out iter, path_2);
			tracklistmodel.set(iter, TrackListColumn.STATE, TrackState.POSITION_FLAG, -1);
			return;
		}
		if(removed_playing_title) this.mark_last_title_active();
	}

	private void mark_last_title_active() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = tracklistmodel.iter_n_children(null);
		if (numberOfRows == 0) return;
		tracklistmodel.iter_nth_child (out iter, null, numberOfRows -1);
		tracklistmodel.set(iter, TrackListColumn.STATE, TrackState.POSITION_FLAG, -1);
	}
	
	public bool not_empty() {
		if(tracklistmodel.iter_n_children(null)>0)
			return true;
		else
			return false;
	}
	
	// Resets visual state and the TrackState for all rows
	public void reset_play_status_all_titles() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = tracklistmodel.iter_n_children(null);
		if(numberOfRows==0) return;
		
		for(int i = 0; i < numberOfRows; i++) {
			tracklistmodel.iter_nth_child(out iter, null, i);
			tracklistmodel.set(iter,
			              TrackListColumn.STATE, TrackState.STOPPED,
			              TrackListColumn.ICON, null,
			              -1);
			tracklistmodel.unbolden_row(ref iter);
		}
	}

	public void on_activated(string uri, TreePath path) {
		//check for existance on local files
		File track = File.new_for_uri(uri);
		
		if(track.get_uri_scheme()=="file") {
			if(!track.query_exists(null)) return;
		}
		
		TreeIter iter;
		this.tracklistmodel.get_iter(out iter, path);
		this.reset_play_status_all_titles();
		tracklistmodel.set_state_picture_for_title(iter, TrackState.PLAYING);
	}

	private void on_active_path_changed(TrackListModel sender, TrackState ts) {
		// set gst player to active title coming from tracklist
		// triggered by a signal in set_state_picture_for_title
		//print("tracklist: on_active_path_changed\n");
		TreePath treepath;
		TrackState currentstate;
		bool is_first;
		if(!tracklistmodel.get_active_path(out treepath, out currentstate, out is_first))
			return;
		
		string uri = this.get_uri_for_treepath(treepath);

		if((uri!=null)&&(uri!="")) {
			if(xn.gPl.Uri != uri) xn.gPl.Uri = uri;
			if(ts == TrackState.PLAYING) 
				xn.gPl.playSong(true);
			else
				xn.gPl.playSong();
		}
	}
	
	public string get_uri_for_treepath(TreePath path) {
		TreeIter iter;
		string uri = "";
		if(tracklistmodel.get_iter(out iter, path)) {
			tracklistmodel.get(iter,
				TrackListColumn.URI, out uri);
		}
		return uri;
	}

	private void setup_view() {	
		CellRendererText renderer; 
		var columnPixb 	      = new TreeViewColumn();
		var columnStatus      = new TreeViewColumn();
		var columnTracknumber = new TreeViewColumn();
		var columnArtist      = new TreeViewColumn();
		var columnAlbum       = new TreeViewColumn();
		var columnTitle       = new TreeViewColumn();
		var columnUri         = new TreeViewColumn();

		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		renderer.ellipsize = Pango.EllipsizeMode.END; 
		columnStatus.pack_start(renderer, false);
		columnStatus.title = "Status";
		columnStatus.visible = false;
		this.insert_column(columnStatus, -1);

		var pixbufRenderer = new CellRendererPixbuf();
		pixbufRenderer.set_fixed_size(-1,22); 
		columnPixb.pack_start(pixbufRenderer, false);
		columnPixb.add_attribute(pixbufRenderer, "pixbuf", TrackListColumn.ICON);
		columnPixb.set_fixed_width(30);
		columnPixb.reorderable = true;
		this.insert_column(columnPixb, -1);

		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		columnTracknumber.pack_start(renderer, false);
		columnTracknumber.add_attribute(renderer, "markup", TrackListColumn.TRACKNUMBER);
		columnTracknumber.title = "#";
		columnTracknumber.set_fixed_width(32);
		columnTracknumber.resizable = false;
		columnTracknumber.reorderable = true;
		this.insert_column(columnTracknumber, -1);
		
		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		renderer.ellipsize = Pango.EllipsizeMode.END; 
		renderer.width_chars=30;
		columnTitle.pack_start(renderer, true);
		columnTitle.add_attribute(renderer, "markup", TrackListColumn.TITLE);
		columnTitle.title = "Title";
		columnTitle.min_width = 100; //TODO: is it possible to set the min width via number of characters for the used font?
		columnTitle.resizable = true;
		columnTitle.reorderable = true;
		this.insert_column(columnTitle, -1);

		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		renderer.ellipsize = Pango.EllipsizeMode.END; 
		renderer.width_chars=22;
		columnAlbum.pack_start(renderer, true);
		columnAlbum.add_attribute(renderer, "markup", TrackListColumn.ALBUM);
		columnAlbum.title = "Album";
		columnAlbum.min_width = 100;
		columnAlbum.resizable = true;
		columnAlbum.reorderable = true;
		this.insert_column(columnAlbum, -1);

		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		renderer.ellipsize = Pango.EllipsizeMode.END; 
		renderer.width_chars=22;
		columnArtist.pack_start(renderer, true);
		columnArtist.add_attribute(renderer, "markup", TrackListColumn.ARTIST);
		columnArtist.title = "Artist";
		columnArtist.min_width = 100;
		columnArtist.resizable = true;
		columnArtist.reorderable = true;
		this.insert_column(columnArtist, -1);

		columnPixb.sizing        = Gtk.TreeViewColumnSizing.FIXED;
		columnStatus.sizing      = Gtk.TreeViewColumnSizing.FIXED;
		columnTracknumber.sizing = Gtk.TreeViewColumnSizing.FIXED;
		columnUri.sizing         = Gtk.TreeViewColumnSizing.FIXED;
		columnArtist.sizing      = Gtk.TreeViewColumnSizing.GROW_ONLY;
		columnAlbum.sizing       = Gtk.TreeViewColumnSizing.GROW_ONLY;
		columnTitle.sizing       = Gtk.TreeViewColumnSizing.GROW_ONLY;
		
		this.search_column = TrackListColumn.TITLE;
		this.enable_search = true;
		this.rules_hint = true;
	}
}
