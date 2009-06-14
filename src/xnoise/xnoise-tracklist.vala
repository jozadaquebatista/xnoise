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

using GLib;
using Gtk;
using Gdk;

public class Xnoise.TrackList : TreeView, IParameter {
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};
	private TreeRowReference[] rowref_list;
	private bool dragging;
	private Menu menu;
	public ListStore listmodel;
	
	public signal void sign_active_path_changed();

	public TrackList() {
		this.create_model();
		this.create_view();
		this.get_selection().set_mode(SelectionMode.MULTIPLE); 
		this.sign_active_path_changed += this.on_active_path_changed;

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

		this.row_activated        += this.on_row_activated;
		this.key_release_event    += this.on_key_released;
		this.drag_begin           += this.on_drag_begin;
		this.drag_data_get        += this.on_drag_data_get;
		this.drag_end             += this.on_drag_end;
		this.drag_motion          += this.on_drag_motion;
		this.drag_data_received   += this.on_drag_data_received;
		this.button_release_event += this.on_button_release;
		this.button_press_event   += this.on_button_press;
			
		menu = create_rightclick_menu();
	}

	public bool on_button_press(TrackList sender, Gdk.EventButton e) {
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
						print("xyz\n");
						//TODO handle right click menu opening right
//						return false; 
//						selection.unselect_path(path);
				} 								
//				selection.select_path(path);
				rightclick_menu_popup(e.time);
				return true;
				}
		if(!(selection.count_selected_rows()>0)) 
			selection.select_path(path);
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
		removetrackItem.activate += this.remove_selected_row;
		rightmenu.append(removetrackItem);
//		var separator = new SeparatorMenuItem();
//		rightmenu.append(separator);
		rightmenu.show_all();
		return rightmenu;
	}

////REGION IParameter
	public void read_data(KeyFile file) throws KeyFileError {
//		title_width_chars = file.get_integer("settings", "title_width_chars");
//		tvc.width = file.get_integer("settings", "title_width");;
	}

	public void write_data(KeyFile file) {
//		weak TreeViewColumn tvc = this.get_column(TrackListColumn.TITLE);
//		GLib.List<CellRendererText> cell_title = tvc.cell_list.copy();
//		var abc = (CellRendererText)cell_title.first();//
////		Gtk.CellRendererText fff = abc..nth_data(0);
//		
//		file.set_integer("settings", "title_width_chars", abc.width_chars);
////		int title_width = 10;
////		weak TreeViewColumn tvc = this.get_column(TrackListColumn.TITLE);
////		title_width = tvc.width;
	}
////END REGION IParameter

	public bool on_button_release(TrackList sender, Gdk.EventButton e) {
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

	public bool on_drag_motion(TrackList sender, Gdk.DragContext context, int x, int y, uint timestamp) {
		Gtk.TreePath path;
		Gtk.TreeViewDropPosition pos;
		if(!(this.get_dest_row_at_pos(x, y, out path, out pos))) return false;
		this.set_drag_dest_row(path, pos);
		return true; 
	}	

	private bool reorder_dragging;	
	private void on_drag_begin(TrackList sender, DragContext context) {
		this.dragging = true;
		this.reorder_dragging = true;

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

	public void on_drag_end(TrackList sender, Gdk.DragContext context) { 
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

	public void on_drag_data_get(TrackList sender, Gdk.DragContext context, Gtk.SelectionData selection, uint target_type, uint etime) {
		rowref_list = new TreeRowReference[0];
		TreeIter iter;
		GLib.Value uri;
		List<weak TreePath> paths;
		weak Gtk.TreeSelection sel;
		string[] uris; //TODO: = new string[0] od. neuw {}

		sel = this.get_selection();
		paths = sel.get_selected_rows(null);
 		int i = 0;
		uris = new string[(int)paths.length() + 1];
		foreach(weak TreePath path in paths) {
			this.listmodel.get_iter(out iter, path);
			this.listmodel.get_value(iter, TrackListColumn.URI, out uri);
			uris[i] = uri.get_string();
			i++;
			TreeRowReference treerowref = new TreeRowReference(this.listmodel, path);
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
		this.listmodel.foreach(list_foreach);
		return list_of_uris;
	}

	private Gtk.TreeViewDropPosition position;
	private void on_drag_data_received (TrackList seder, DragContext context, int x, int y, 
	                                    SelectionData selection, uint target_type, uint time) {
		//set uri list for dragging out of xnoise. in parallel work around with rowreferences
		//if reorder = false then data is coming from outside (music browser or nautilus) -> use uri_list
		Gtk.TreePath path;
		TreeRowReference drop_rowref;
		string filename = null;
		File file;
		FileType filetype;
		string[] uris = selection.get_uris();
		this.get_dest_row_at_pos(x, y, out path, out position);
		if(!this.reorder_dragging) { 					// DRAGGING NOT WITHIN TRACKLIST
			string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
			              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
			for(int i=(uris.length-1); i>=0;i--) {
				filename = uris[i]; 
				try {
					file = File.new_for_uri(filename);
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
			
				if(!(filetype==GLib.FileType.DIRECTORY)) {
					handle_dropped_file(filename, ref path);			
				}
				else {
					handle_dropped_files_for_folders(file, ref path);
				}
			}
		}
		else { 											// DRAGGING WITHIN TRACKLIST
			drop_rowref = null;
			if(path!=null) {
				//TODO:check if drop position is selected
				drop_rowref = new TreeRowReference(this.listmodel, path);
				if(drop_rowref == null || !drop_rowref.valid()) return;
			}
			else {
				get_last_unselected_path(ref path);
				drop_rowref = new TreeRowReference(this.listmodel, path);
				if(drop_rowref == null || !drop_rowref.valid()) {
					return;
				}
			}
			foreach(weak TreeRowReference current_row in rowref_list) {
				if (current_row == null || !current_row.valid()) {
					return;
				}
				var current_path = current_row.get_path();
				//get iter for current
				weak TreeIter current_iter;
				this.listmodel.get_iter(out current_iter, current_path);
				//get iter for drop position
				weak TreeIter drop_iter;
				TreePath drop_path = drop_rowref.get_path();
				this.listmodel.get_iter(out drop_iter, drop_path);
				//move
				if((position == Gtk.TreeViewDropPosition.BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
					this.listmodel.move_before(current_iter, drop_iter);	
				}
				else {
					this.listmodel.move_after(current_iter, drop_iter);
				}
			}
		}
		rowref_list = null;
	}

	private void handle_dropped_files_for_folders(File dir, ref TreePath? path) { 
		//Recursive function to import music DIRECTORIES in drag'n'drop
		//as soon as a file is found it is passed to handle_dropped_file function
		//the TreePath path is just passed through if it is a directory
		FileEnumerator enumerator;
		try {
			string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
			              FILE_ATTRIBUTE_STANDARD_TYPE;
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
		} catch (Error error) {
			critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
			return;
		}
		FileInfo info;
		while((info = enumerator.next_file(null))!=null) {
			string filename = info.get_name();
			string filepath = Path.build_filename(dir.get_path(), filename);
			File file = File.new_for_path(filepath);
			FileType filetype = info.get_file_type();

			if(filetype == FileType.DIRECTORY) {
				this.handle_dropped_files_for_folders(file, ref path);
			} 
			else {
				handle_dropped_file(file.get_uri(), ref path);
			}
		}
	}

	
	private void handle_dropped_file(string fileuri, ref TreePath? path) {
		//Function to import music FILES in drag'n'drop
		TreeIter iter, new_iter;
		File file;
		FileType filetype;
		weak string mime;
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
		   (psAudio.match_string(mime))) {
			DbBrowser dbBr = new DbBrowser();
			string artist, album, title;
			uint tracknumb;
			if(dbBr.uri_is_in_db(fileuri)) {
				TrackData td; 
				dbBr.get_trackdata_for_uri(fileuri, out td); //strings are already escaped
				artist    = td.Artist;
				album     = td.Album;
				title     = td.Title ;
				tracknumb = td.Tracknumber; 
			}
			else {
				var tr = new TagReader();
				var tags = tr.read_tag_from_file(file.get_path());
				artist         = Markup.printf_escaped("%s", tags.Artist); 
				album          = Markup.printf_escaped("%s", tags.Album); 
				title          = Markup.printf_escaped("%s", tags.Title); 
				tracknumb      = tags.Tracknumber;
			}
			TreeIter first_iter;
			if(!this.listmodel.get_iter_first(out first_iter)) { //dropped on empty list, first uri
				this.listmodel.insert(out new_iter, 0);
			}
			else if(path==null) { //dropped below all entries, first uri
				listmodel.append(out new_iter);
			}					
			else { //all other uris
				this.listmodel.get_iter(out iter, path); 
				if((position == Gtk.TreeViewDropPosition.BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_AFTER)) {
					this.listmodel.insert_before(out new_iter, iter);
				}
				else {
					this.listmodel.insert_after(out new_iter, iter);
				}
			}
			string tracknumberString = null;
			if(!(tracknumb==0)) {
				tracknumberString = "%u".printf(tracknumb);
			}
			listmodel.set(new_iter,
				TrackListColumn.STATE, TrackStatus.STOPPED,
				TrackListColumn.TRACKNUMBER, tracknumberString,
				TrackListColumn.TITLE, title,
				TrackListColumn.ALBUM, album,
				TrackListColumn.ARTIST, artist,
				TrackListColumn.URI, fileuri,
				-1);
			path = listmodel.get_path(new_iter);
		}
		else if(filetype==GLib.FileType.DIRECTORY) {
			assert_not_reached();
		}	
		else {
			print("Not a regular file or at least no audio file: %s\n", fileuri);
		}
	}
	
	public void add_uris(string[]? uris) {
		if(uris!=null) {
			if(uris[0]==null) return;
			int k=0;
			TreeIter iter, iter_2;
			this.reset_play_status_for_title();
			while(uris[k]!=null) { //because foreach is not working for this array coming from libunique
				File file;
				TagReader tr = new TagReader();
				file = File.new_for_uri(uris[k]);

				//TODO: only for local files, so streams will not lead to a crash
				TrackData t = tr.read_tag_from_file(file.get_path()); 

				if (k==0) {
					iter = this.insert_title(TrackStatus.PLAYING, 
					                              null, 
					                              (int)t.Tracknumber,
					                              t.Title, 
					                              t.Album, 
					                              t.Artist, 
					                              uris[k]);
					this.set_state_picture_for_title(iter, TrackStatus.PLAYING);
					iter_2 = iter;
				}
				else {
					iter = this.insert_title(TrackStatus.STOPPED, 
					                              null, 
					                              (int)t.Tracknumber,
					                              t.Title, 
					                              t.Album, 
					                              t.Artist, 
					                              uris[k]);	
					this.set_state_picture_for_title(iter);
				}
				tr = null;
				k++;
			}
			Main.instance().add_track_to_gst_player(uris[0]); 
		}
	}
	

	private void get_last_unselected_path(ref TreePath? path) {
		int rowcount = -1;
		rowcount = (int)this.listmodel.iter_n_children(null); 
		if(rowcount>0) {
			//get path of last unselected
			bool found = false;
			List<weak TreePath> selected_paths;
			weak Gtk.TreeSelection sel = this.get_selection();
			selected_paths = sel.get_selected_rows(null);
			int i=0;
			do{
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

	private void on_row_activated(TrackList sender, TreePath path, TreeViewColumn column) { 
		string uri = null;
		TreeIter iter;
		if (listmodel.get_iter(out iter, path)) {
			listmodel.get(iter, 
				TrackListColumn.URI, out uri, 
				-1);
		}
		this.on_activated(uri, path);
	}

	private bool on_key_released(TrackList sender, Gdk.EventKey e) {
		int KEY_DELETE = 0xFFFF; 
		if (e.keyval==KEY_DELETE) 
			this.remove_selected_row();
		return true; 
	}

	public TreeIter insert_title(int status = 0, Gdk.Pixbuf? pixbuf, int tracknumber, string title, string album, string artist, string uri) {
		TreeIter iter;
		string tracknumberString = null;;
		listmodel.append(out iter);
		if(!(tracknumber==0)) {
			tracknumberString = "%d".printf(tracknumber);
		}
		listmodel.set(iter,
			TrackListColumn.STATE, status,
			TrackListColumn.ICON, pixbuf,
			TrackListColumn.TRACKNUMBER, tracknumberString,
			TrackListColumn.TITLE, title,
			TrackListColumn.ALBUM, album,
			TrackListColumn.ARTIST, artist,
			TrackListColumn.URI, uri,
			-1);
		return iter;
	}

	public void set_state_picture_for_title(TreeIter iter, int state = TrackStatus.STOPPED) {
		Gdk.Pixbuf pixbuf;
		Gtk.Invisible w = new Gtk.Invisible();
	
		pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
	
		if(state == TrackStatus.PLAYING) {
			listmodel.set(iter,
				TrackListColumn.STATE, TrackStatus.PLAYING,
				TrackListColumn.ICON, pixbuf,
				-1);
			bolden_row(ref iter);
			sign_active_path_changed();
		}
		else {
			listmodel.set(iter,
				TrackListColumn.STATE, TrackStatus.PAUSED,
				TrackListColumn.ICON, null,
				-1);
		}
	}
	
	public void set_play_picture() {
		TreeIter iter;
		Gdk.Pixbuf pixbuf;
		Gtk.Invisible w = new Gtk.Invisible();
	
		pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
		int status = 0;
		int numberOfRows = listmodel.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			listmodel.iter_nth_child(out iter, null, i);
			listmodel.get(iter, 
				TrackListColumn.STATE, out status, 
				-1);
			if(status>0) {
				listmodel.set(iter,
					TrackListColumn.ICON, pixbuf,
					-1);
			}
		}
	}
	
	public void set_pause_picture() {
		TreeIter iter;
		Gdk.Pixbuf pixbuf;
		Gtk.Invisible w = new Gtk.Invisible();
	
		pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
		int status = 0;
		int numberOfRows = listmodel.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			listmodel.iter_nth_child(out iter, null, i);
			listmodel.get(iter, 
				TrackListColumn.STATE, out status, 
				-1);
			if(status>0) {
				listmodel.set(iter,
					TrackListColumn.ICON, pixbuf,
					-1);
			}
		}		
	}

	public void set_focus_on_iter(ref TreeIter iter) {
		TreePath start_path, end_path;
		TreePath current_path = listmodel.get_path(iter);
		if(!this.get_visible_range (out start_path, out end_path)) return;
		weak int[] start   = start_path.get_indices();
		weak int[] end     = end_path.get_indices();
		weak int[] current = current_path.get_indices();
		if(!((start[0] < current[0]) && (current[0] < end[0])))
			this.scroll_to_cell(current_path, null, true, (float)0.3, (float)0.0);
	}
	
	public void remove_selected_row() { 
		TreeIter iter;
		TreePath path_2 = new TreePath();
		GLib.List<TreePath> list;
		list = this.get_selection().get_selected_rows(null);
		list.reverse();
		if (list.length()==0) return;
		foreach (weak Gtk.TreePath path in list) {
			listmodel.get_iter(out iter, path);
			path_2 = listmodel.get_path(iter);
			listmodel.remove(iter);
		}
		if (path_2.prev()) { //TODO: check if this is handled right
			listmodel.get_iter(out iter, path_2);
			listmodel.set(iter, TrackListColumn.STATE, TrackStatus.PLAYING, -1);
			return;
		}
		this.mark_last_title_active();
	}

	private void mark_last_title_active() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = listmodel.iter_n_children(null);
		if (numberOfRows == 0) return;
		listmodel.iter_nth_child (out iter, null, numberOfRows -1);
		listmodel.set(iter, TrackListColumn.STATE, TrackStatus.POSITION_FLAG, -1);
	}
	
	public bool not_empty() {
		if (listmodel.iter_n_children(null)>0) {
			return true;
		}
		else {
			return false;
		}
	}

	public void reset_play_status_for_title() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = listmodel.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			listmodel.iter_nth_child (out iter, null, i);
			listmodel.set(iter,
				TrackListColumn.STATE, TrackStatus.STOPPED,
				TrackListColumn.ICON, null,
				-1);
		unbolden_row(ref iter);
		}
	}

	private void bolden_row(ref TreeIter iter) {
		GLib.Value valArtist, valAlbum, valTitle;
		this.listmodel.get_value(
			iter,
			TrackListColumn.ARTIST,
			out valArtist);
		this.listmodel.get_value(
			iter,
			TrackListColumn.ALBUM,
			out valAlbum);
		this.listmodel.get_value(
			iter,
			TrackListColumn.TITLE,
			out valTitle);
		listmodel.set(iter,
			TrackListColumn.ARTIST, "<b>%s</b>".printf(valArtist.get_string()),
			TrackListColumn.ALBUM, "<b>%s</b>".printf(valAlbum.get_string()),
			TrackListColumn.TITLE, "<b>%s</b>".printf(valTitle.get_string()),
			-1);
	}

	private void unbolden_row(ref TreeIter iter) {
		GLib.Value valArtist, valAlbum, valTitle;
		this.listmodel.get_value(
			iter,
			TrackListColumn.ARTIST,
			out valArtist);
		this.listmodel.get_value(
			iter,
			TrackListColumn.ALBUM,
			out valAlbum);
		this.listmodel.get_value(
			iter,
			TrackListColumn.TITLE,
			out valTitle);
		
		if(valArtist.get_string().has_prefix("<b>")) {
			string artist = valArtist.get_string().substring(3, valArtist.get_string().length - 7); 
			string album  = valAlbum.get_string().substring(3, valAlbum.get_string().length - 7);
			string title  = valTitle.get_string().substring(3, valTitle.get_string().length - 7);
			listmodel.set(iter,
				TrackListColumn.ARTIST, artist,
				TrackListColumn.ALBUM, album,
				TrackListColumn.TITLE, title,
				-1);
		}
	}

	public bool get_active_path(out TreePath path) {
		TreeIter iter;
		int status = 0;
		int numberOfRows = listmodel.iter_n_children(null);
		for (int i = 0; i < numberOfRows; i++) {
			listmodel.iter_nth_child (out iter, null, i);
			listmodel.get(iter,
				TrackListColumn.STATE, out status,
				-1);
			if (status > 0) {
				path = listmodel.get_path(iter);
				return true;
			}
		}
		if (listmodel.get_iter_first(out iter)) {
			path = listmodel.get_path(iter); //first song in list
			return true;
		}
		return false;
	}
	
	public void on_activated(string uri, TreePath path){ 
		TreeIter iter;
		Main.instance().gPl.Uri = uri;
		Main.instance().gPl.playSong();
		if(Main.instance().gPl.playing == false) {
			Main.instance().main_window.playpause_button_set_pause_picture ();
			Main.instance().gPl.play();
		}
		this.listmodel.get_iter(out iter, path);
		this.reset_play_status_for_title();
		this.set_state_picture_for_title(iter, TrackStatus.PLAYING);
	}

	private void on_active_path_changed(TrackList sender){ 
		TreePath path;
		if (!this.get_active_path(out path)) return;
		string uri = this.get_uri_for_path(path);
		if ((uri!=null) && (uri!="")) {
			Main.instance().gPl.Uri = uri;
			Main.instance().gPl.playSong();
		}
	}
	
	public string get_uri_for_path(TreePath path) {
		TreeIter iter;
		string uri = "";
		if (listmodel.get_iter(out iter, path)) {
			listmodel.get(iter,
				TrackListColumn.URI, out uri,
				-1);
		}
		return uri;
	}

	private void create_view() {	
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
		
		Params params = Params.instance();
		params.read_from_file_for_single(this);
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

		renderer = new CellRendererText();
		renderer.set_fixed_height_from_font(1);
		columnUri.pack_start(renderer, false);
		columnUri.title = "Uri";
		columnUri.visible = false;
		this.insert_column(columnUri, -1);

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
	
	private void create_model() {	// DATA
		listmodel = new ListStore(7, typeof(int), typeof(Gdk.Pixbuf), typeof(string), typeof(string), typeof(string), typeof(string), typeof(string));
		this.set_model(listmodel); 
	}
}

