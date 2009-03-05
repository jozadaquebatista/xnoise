/* xnoise-tracklist.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

using GLib;
using Gtk;
using Gdk;

public class Xnoise.TrackList : TreeView, IConfigure {
	private const TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};
	private TreeRowReference[] rowref_list;
	private bool dragging;
    private Menu menu;
	public new ListStore model;
	
//	public signal void sign_activated(string uri, TreePath path);
	public signal void sign_active_path_changed();
//	public signal void tdata_dragreceive();

	public TrackList() {
		this.create_model();
		this.create_view();
		this.get_selection().set_mode(SelectionMode.MULTIPLE); 
//		this.sign_activated           += this.on_activated;
		this.sign_active_path_changed += this.active_path_changed_cb;

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
		// The popup menu that is displayed when you right click in the playlist
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
                		print("uuuns\n");
                		//TODO handle right click menu opening right
//                		return false; 
//                		selection.unselect_path(path);
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

////REGION IConfigurable
	//TODO: do column width ? maybe via cellrenderer width
	public void read_data(KeyFile file) throws KeyFileError {
//		weak TreeViewColumn tvc = this.get_column(TrackListColumn.TITLE);
//		tvc.width = file.get_integer("settings", "title_width");;
	}

	public void write_data(KeyFile file) {
//		int title_width = 10;
//		weak TreeViewColumn tvc = this.get_column(TrackListColumn.TITLE);
//		title_width = tvc.width;
//		file.set_integer("settings", "title_width", title_width);
	}
////END REGION IConfigurable

    public bool on_button_release(TrackList sender, Gdk.EventButton e) {
		//Called when a button is released
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
		Gtk.TreeViewDropPosition position;
		if(!(this.get_dest_row_at_pos(x, y, out path, out position))) return false;
        this.set_drag_dest_row(path, position);
		return true; 
    }	

	private bool reorder_dragging;	
	private void on_drag_begin(TrackList sender, DragContext context) {
		// Called when dnd is started
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
		// Called when the dnd is ended
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
//      Called when a drag source wants data for this drag operation
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
            this.model.get_iter(out iter, path);
            this.model.get_value(iter, TrackListColumn.URI, out uri);
            uris[i] = uri.get_string();
            i++;
			TreeRowReference treerowref = new TreeRowReference(this.model, path);
			if(treerowref.valid()) {
				rowref_list += #treerowref; //TODO: Check if this has to be owned in new syntax
			}
		}
        selection.set_uris(uris); 
    }

	private Gtk.TreeViewDropPosition position;
	private void on_drag_data_received (TrackList seder, DragContext context, int x, int y, 
	                                    SelectionData selection, uint target_type, uint time) {
		//set uri list for dragging out of xnoise. in parallel work around with rowreferences
		//if reorder = false then data is coming from outside (music browser or nautilus) -> use uri_list
		Gtk.TreePath path;
		TreeRowReference drop_rowref;
		string file = "";
        string[] uris = selection.get_uris();
		this.get_dest_row_at_pos(x, y, out path, out position);
		if(!this.reorder_dragging) {
			for(int i=(uris.length-1); i>=0;i--) {
				try {
					file = GLib.Filename.from_uri(uris[i]); 
				}
				catch(GLib.ConvertError e) {
					print("%s\n", e.message);
					return;
				}
				handle_dropped_file(file, ref path);			
			}
		}
		else {
			drop_rowref = null;
			if(path!=null) {
				//TODO:check if drop position is selected
				drop_rowref = new TreeRowReference(this.model, path);
				if (drop_rowref == null || !drop_rowref.valid()) return;
			}
			else {
				get_last_unselected_path(ref path);
				drop_rowref = new TreeRowReference(this.model, path);
				if (drop_rowref == null || !drop_rowref.valid()) {
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
				this.model.get_iter(out current_iter, current_path);
				//get iter for drop position
				weak TreeIter drop_iter;
				TreePath drop_path = drop_rowref.get_path();
				this.model.get_iter(out drop_iter, drop_path);
				//move
				if((position == Gtk.TreeViewDropPosition.BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
					this.model.move_before(current_iter, drop_iter);	
				}
				else {
					this.model.move_after(current_iter, drop_iter);
				}
			}
		}
		rowref_list = null;
	}
	
	private GLib.List<string> list_of_uris;
	private bool list_foreach(TreeModel sender, TreePath path, TreeIter iter) { 
		GLib.Value gv;
		sender.get_value(
			iter, 
			TrackListColumn.URI, 
			out gv);
		
		list_of_uris.prepend(gv.get_string());
		return false;
	}
	
	public void get_track_ids(ref GLib.List<string> final_tracklist) {
		list_of_uris = new GLib.List<string>();
		this.model.foreach(list_foreach);
		var dbb = new DbBrowser();
		foreach(string uri in list_of_uris) {
//			final_tracklist.resize(final_tracklist.length + 1);
//			string buffer = dbb.get_track_id_for_path(GLib.Filename.from_uri(uri));
//			if(GLib.Filename.from_uri(uri)) print("uri: %s\n", uri);
//			final_tracklist[list_of_uris.length-1] = dbb.get_track_id_for_path(GLib.Filename.from_uri(uri));
//			final_tracklist += dbb.get_track_id_for_path(GLib.Filename.from_uri(uri)); 

			//TODO handle files not in db
			//TODO change data type
			final_tracklist.prepend("%d".printf(dbb.get_track_id_for_path(GLib.Filename.from_uri(uri))));
		}
		dbb = null;
//		list_of_uris = null;
	}
	
	private void handle_dropped_file(string file, ref TreePath? path) {
		TreeIter iter, new_iter;
		if(GLib.FileUtils.test(file, GLib.FileTest.IS_REGULAR)) {
			DbBrowser dbBr = new DbBrowser();
			string artist, album, title;
			if(dbBr.path_is_in_db(file)) {
				string[] val = dbBr.get_trackdata_for_path(file);
				artist = val[0];
				album = val[1];
				title = val[2];
			}
			else {
				var tr = new TagReader();
				string[] tags = tr.read_tag_from_file(file);
				artist = Markup.printf_escaped("%s", tags[TagReaderField.ARTIST]); //TODO: check if the markup shall be handled elsewhere
				album  = Markup.printf_escaped("%s", tags[TagReaderField.ALBUM]); 
				title  = Markup.printf_escaped("%s", tags[TagReaderField.TITLE]); 
			}
			TreeIter first_iter;
			if(!this.model.get_iter_first(out first_iter)) { 
				//dropped on empty list, first uri
				this.model.insert(out new_iter, 0);
			}
			else if(path==null) {
				//dropped below all entries, first uri
				model.append(out new_iter);
			}					
			else {
				//all other uris
				this.model.get_iter(out iter, path); 
				if((position == Gtk.TreeViewDropPosition.BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)||
				   (position == Gtk.TreeViewDropPosition.INTO_OR_AFTER)) {
					this.model.insert_before(out new_iter, iter);
				}
				else {
					this.model.insert_after(out new_iter, iter);
				}
			}
			model.set(new_iter,
				TrackListColumn.STATE, TrackStatus.STOPPED,
				TrackListColumn.TITLE, title,
				TrackListColumn.ALBUM, album,
				TrackListColumn.ARTIST, artist,
				TrackListColumn.URI, GLib.Filename.to_uri(file),
				-1);
			path = model.get_path(new_iter);
		}
		else if(GLib.FileUtils.test(file, GLib.FileTest.IS_DIR)) {
			print("is directory: %s\n", file);
			//TODO: Handle directories
		}	
	}
	
	private void get_last_unselected_path(ref TreePath? path) {
		int rowcount = -1;
		rowcount = (int)this.model.iter_n_children(null); 
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

	private void on_row_activated(TrackList tree, TreePath path, TreeViewColumn column) { 
		string uri = null;
		TreeIter iter;
		if (model.get_iter(out iter, path)) {
			model.get(iter, 
				TrackListColumn.URI, out uri, 
				-1);
		}
		this.on_activated(uri, path);
//		this.sign_activated(uri, path);
	}

	private bool on_key_released(TrackList sender, Gdk.EventKey e) {
		int KEY_DELETE = 0xFFFF; 
		if (e.keyval==KEY_DELETE) 
			this.remove_selected_row();
		return true; 
	}

	public TreeIter insert_title(int status = 0, Gdk.Pixbuf? pixbuf, string title, string album, string artist, string uri) {
		TreeIter iter;
		model.append(out iter);
		model.set(iter,
			TrackListColumn.STATE, status,
			TrackListColumn.ICON, pixbuf,
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
			model.set(iter,
				TrackListColumn.STATE, TrackStatus.PLAYING,
				TrackListColumn.ICON, pixbuf,
				-1);
			bolden_row(ref iter);
			sign_active_path_changed();
		}
		else {
			model.set(iter,
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
		int numberOfRows = model.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			model.iter_nth_child(out iter, null, i);
			model.get(iter, 
				TrackListColumn.STATE, out status, 
				-1);
			if(status>0) {
				model.set(iter,
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
		int numberOfRows = model.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			model.iter_nth_child(out iter, null, i);
			model.get(iter, 
				TrackListColumn.STATE, out status, 
				-1);
			if(status>0) {
				model.set(iter,
					TrackListColumn.ICON, pixbuf,
					-1);
			}
		}		
	}

	public void set_focus_on_iter(ref TreeIter iter) {
		TreePath start_path, end_path;
		TreePath current_path = model.get_path(iter);
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
			model.get_iter(out iter, path);
			path_2 = model.get_path(iter);
			model.remove(iter);
		}
		if (path_2.prev()) { //TODO: check if this is handled right
			model.get_iter(out iter, path_2);
			model.set(iter, TrackListColumn.STATE, TrackStatus.PLAYING, -1);
			return;
		}
		this.mark_last_title_active();
	}

	private void mark_last_title_active() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = model.iter_n_children(null);
		if (numberOfRows == 0) return;
		model.iter_nth_child (out iter, null, numberOfRows -1);
		model.set(iter, TrackListColumn.STATE, TrackStatus.POSITION_FLAG, -1);
	}
	
	public bool not_empty() {
		if (model.iter_n_children(null)>0) {
			return true;
		}
		else {
			return false;
		}
	}

	public void reset_play_status_for_title() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = model.iter_n_children(null);
		if (numberOfRows == 0) return;
		for (int i = 0; i < numberOfRows; i++) {
			model.iter_nth_child (out iter, null, i);
			model.set(iter,
				TrackListColumn.STATE, TrackStatus.STOPPED,
				TrackListColumn.ICON, null,
				-1);
		unbolden_row(ref iter);
		}
	}

	private void bolden_row(ref TreeIter iter) {
		GLib.Value valArtist, valAlbum, valTitle;
		this.model.get_value(
			iter,
			TrackListColumn.ARTIST,
			out valArtist);
		this.model.get_value(
			iter,
			TrackListColumn.ALBUM,
			out valAlbum);
		this.model.get_value(
			iter,
			TrackListColumn.TITLE,
			out valTitle);
		model.set(iter,
			TrackListColumn.ARTIST, "<b>%s</b>".printf(valArtist.get_string()),
			TrackListColumn.ALBUM, "<b>%s</b>".printf(valAlbum.get_string()),
			TrackListColumn.TITLE, "<b>%s</b>".printf(valTitle.get_string()),
			-1);
	}

//	public void update_play_status_for_playlisttitle(bool paused) {
//		TreeIter iter;
//		Gtk.Invisible w = new Gtk.Invisible();
//		Gdk.Pixbuf pixbuf;
//		int state = PLTrackStatus.STOPPED;
//		int new_state;
//		int numberOfRows = model.iter_n_children(null);
//		
//		for(int i = 0; i < numberOfRows; i++) {
//			model.iter_nth_child (out iter, null, i);
//			model.get(iter,
//				TrackListColumn.STATE, out state,
//				-1);
//			if(state > 0) {
//				if(paused) {
//					pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
//					new_state = PLTrackStatus.PAUSED;
//				}
//				else {
//					pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
//					new_state = PLTrackStatus.PLAYING;
//				}
//				model.set(iter,
//					TrackListColumn.STATE, new_state,
//					TrackListColumn.ICON, pixbuf,
//					-1);
//			}
//		}
//	}

	private void unbolden_row(ref TreeIter iter) {
		GLib.Value valArtist, valAlbum, valTitle;
//		string artist = "", album = "", title = "";
		this.model.get_value(
			iter,
			TrackListColumn.ARTIST,
			out valArtist);
		this.model.get_value(
			iter,
			TrackListColumn.ALBUM,
			out valAlbum);
		this.model.get_value(
			iter,
			TrackListColumn.TITLE,
			out valTitle);
		
		if(valArtist.get_string().has_prefix("<b>")) {
			string artist = valArtist.get_string().substring(3, valArtist.get_string().length - 7); 
			string album  = valAlbum.get_string().substring(3, valAlbum.get_string().length - 7);
			string title  = valTitle.get_string().substring(3, valTitle.get_string().length - 7);
			model.set(iter,
				TrackListColumn.ARTIST, artist,
				TrackListColumn.ALBUM, album,
				TrackListColumn.TITLE, title,
				-1);
		}
	}

	public bool get_active_path(out TreePath path) {
		TreeIter iter;
		int status = 0;
		int numberOfRows = model.iter_n_children(null);
		for (int i = 0; i < numberOfRows; i++) {
			model.iter_nth_child (out iter, null, i);
			model.get(iter,
				TrackListColumn.STATE, out status,
				-1);
			if (status > 0) {
				path = model.get_path(iter);
				return true;
			}
		}
		if (model.get_iter_first(out iter)) {
			path = model.get_path(iter); //first song in list
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
//		Gdk.Pixbuf pixbuf;
//		try {
//			pixbuf = new Gdk.Pixbuf.from_file("ui/note.png");
//		}
//		catch (GLib.Error e) {
//			print("Error: %s\n", e.message);
//		}
		this.model.get_iter(out iter, path);
		this.reset_play_status_for_title();
		this.set_state_picture_for_title(iter, TrackStatus.PLAYING);
	}

	private void active_path_changed_cb(TrackList sender){ 
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
		if (model.get_iter(out iter, path)) {
			model.get(iter,
				TrackListColumn.URI, out uri,
				-1);
		}
		return uri;
	}

	private void create_view() {	
		Gtk.TreeViewColumn columnStatus, columnPixb, columnArtist, columnAlbum, columnTitle, columnUri;
	
		columnPixb 	 = new TreeViewColumn();
		columnStatus = new TreeViewColumn();
		columnArtist = new TreeViewColumn();
		columnAlbum  = new TreeViewColumn();
		columnTitle  = new TreeViewColumn();
		columnUri    = new TreeViewColumn();

		columnPixb.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		columnStatus.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		columnArtist.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		columnAlbum.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		columnTitle.set_sizing(Gtk.TreeViewColumnSizing.FIXED);
		columnUri.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

		var pixbufRenderer = new CellRendererPixbuf();
		pixbufRenderer.set_fixed_size(-1,22); //TODO: Automatically determine height; maybe automatically set width once when adding songs
		var renderer = new CellRendererText();
		renderer.set_fixed_size(-1,22);

		columnStatus.pack_start(renderer, false);
		columnStatus.title = "Status";
		columnStatus.visible = false;
		this.insert_column(columnStatus, -1);

		columnPixb.pack_start(pixbufRenderer, false);
		columnPixb.add_attribute(pixbufRenderer, "pixbuf", TrackListColumn.ICON);
		columnPixb.min_width = 30;
		this.insert_column(columnPixb, -1);

		columnTitle.pack_start(renderer, false);
		columnTitle.add_attribute(renderer, "markup", TrackListColumn.TITLE);
		columnTitle.title = "Title";
		columnTitle.min_width = 300; //TODO: is it possible to set the min width via number of characters for the used font?
		columnTitle.resizable = true;
		this.insert_column(columnTitle, -1);

		columnAlbum.pack_start(renderer, false);
		columnAlbum.add_attribute(renderer, "markup", TrackListColumn.ALBUM);
		columnAlbum.title = "Album";
		columnAlbum.min_width = 300;
		columnAlbum.resizable = true;
		this.insert_column(columnAlbum, -1);

		columnArtist.pack_start(renderer, false);
		columnArtist.add_attribute(renderer, "markup", TrackListColumn.ARTIST);
		columnArtist.title = "Artist";
		columnArtist.min_width = 300;
		columnArtist.resizable = true;
		this.insert_column(columnArtist, -1);

		columnUri.pack_start(renderer, false);
		columnUri.title = "Uri";
		columnUri.visible = false;
		this.insert_column(columnUri, -1);
	}
	
	private void create_model() {	// DATA
		model = new ListStore(6, typeof(int), typeof(Gdk.Pixbuf), typeof(string), typeof(string), typeof(string), typeof(string));
		this.set_model(model); 
	}
}

