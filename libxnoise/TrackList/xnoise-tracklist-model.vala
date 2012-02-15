/* xnoise-tracklist-model.vala
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

using Xnoise;
using Xnoise.Services;
using Xnoise.TagAccess;
using Xnoise.Playlist;

public class Xnoise.TrackListModel : ListStore, TreeModel {

	private Main xn;
	private IconTheme icon_theme;

	public enum Column {
		ICON = 0,
		TRACKNUMBER,
		TITLE,
		ALBUM,
		ARTIST,
		LENGTH,
		WEIGHT,
		GENRE,
		YEAR,
		ITEM
	}

	private GLib.Type[] col_types = new GLib.Type[] {
		typeof(Gdk.Pixbuf),  // ICON
		typeof(string),      // TRACKNUMBER
		typeof(string),      // TITLE
		typeof(string),      // ALBUM
		typeof(string),      // ARTIST
		typeof(string),      // LENGTH
		typeof(int),         // WEIGHT
		typeof(string),      // GENRE
		typeof(string),      // YEAR
		typeof(Xnoise.Item?) // Item
	};

	public signal void sign_active_path_changed(PlayerState ts);

	public TrackListModel() {
		this.xn = Main.instance;
		this.icon_theme = IconTheme.get_default();
		this.set_column_types(col_types);

		// Use these two signals to handle the position_reference representation in tracklist
		global.before_position_reference_changed.connect(on_before_position_reference_changed);
		global.position_reference_changed.connect(on_position_reference_changed);
		global.player_state_changed.connect( () => {
			switch(global.player_state) {
				case PlayerState.PLAYING: {
					this.set_play_state();
					break;
				}
				case PlayerState.PAUSED: {
					this.set_pause_state();
					break;
				}
				case PlayerState.STOPPED: {
					this.reset_state();
					break;
				}
				default: break;
			}
		});
		global.tag_changed.connect( () => {
			if(upd_tl_data_src != 0)
				Source.remove(upd_tl_data_src);
			upd_tl_data_src = Timeout.add_seconds(2, () => {
				HashTable<TrackListModel.Column,string?> ntags = new HashTable<TrackListModel.Column,string?>(direct_hash, direct_equal);
				if(global.current_uri != null)
					ntags.insert(Column.ITEM,   global.current_uri); // cheating - the uri is not an item
				else
					return false;
				if(global.current_artist != null)
					ntags.insert(Column.ARTIST, global.current_artist);
				if(global.current_album != null)
					ntags.insert(Column.ALBUM,  global.current_album);
				if(global.current_title != null)
					ntags.insert(Column.TITLE, global.current_title);
				if(global.current_genre != null)
					ntags.insert(Column.GENRE,  global.current_genre);
				// TODO: Add year, tracknumber
				upd_tl_data_src = 0;
				update_tracklist_data(ntags);
				return false;
			});
		});
		icon_theme.changed.connect(update_icons); //TODO update icon
	}
	
	private uint upd_tl_data_src = 0;
	
	// update rows with data from tag edit or delayed receival from gstreamer
	// uri is in the Column.ITEM field of the hashtable
	public void update_tracklist_data(HashTable<TrackListModel.Column,string?> ntags) {
		this.@foreach( (m,p,i) => {
			if(ntags == null)
				return true;
			string? u = null;
			if((u = ntags.lookup(Column.ITEM)) == null)
				return true;
			Item? item;
			this.get(i, Column.ITEM, out item);
			if(item.uri == u) {
				string? title = ntags.lookup(Column.TITLE);
				if(title != null)
					this.set(i, Column.TITLE, title);
				
				string? album = ntags.lookup(Column.ALBUM);
				if(album != null)
					this.set(i, Column.ALBUM, album);
				
				string? artist = ntags.lookup(Column.ARTIST);
				if(artist != null)
					this.set(i, Column.ARTIST, artist);
				
				string? genre = ntags.lookup(Column.GENRE);
				if(genre != null)
					this.set(i, Column.GENRE, genre);
				
				string? tracknumber = ntags.lookup(Column.TRACKNUMBER);
				if(tracknumber != null && tracknumber.strip() != "0")
					this.set(i, Column.TRACKNUMBER, tracknumber);
				
				string? year = ntags.lookup(Column.YEAR);
				if(year != null && year.strip() != "0")
					this.set(i, Column.YEAR, year);
			}
			return false;
		});
	}
	
	private void update_icons() {
	print("update_icons tlm\n");
		//TODO
	}
	
//	public Iterator iterator() {
//		return new Iterator(this);
//	}

//	public class Iterator {
//		private int index;
//		private unowned TrackListModel tlm;

//		public Iterator(TrackListModel tlm) {
//			this.tlm = tlm;
//		}

//		public bool next() {
//			return true;
//		}

//		public TreeIter get() {
//			TreeIter iter;
//			tlm.iter_nth_child(out iter, null, index);
//			return iter;
//		}
//	}

	public void on_before_position_reference_changed() {
		unbolden_row();
		reset_state();
	}

	public bool get_first_row(ref TreePath treepath) {
		int n_children = this.iter_n_children(null);

		if(n_children == 0) {
			return false;
		}
		treepath = new TreePath.from_indices(0);

		if(treepath!=null) return true;

		return false;
	}

	public bool get_random_row(ref TreePath treepath){
		int n_children = this.iter_n_children(null);

		if(n_children <= 1) {
			return false;
		}
		//RANDOM FUNCTION
		var rand = new Rand();
		uint32 rand_val = rand.int_range((int32)0, (int32)(n_children - 1));

		treepath = new TreePath.from_indices((int)rand_val);

		if(treepath!=null)
			return true;

		return false;
	}

	public bool path_is_last_row(ref TreePath path, out bool trackList_is_empty) {
		trackList_is_empty = false;
		int n_children = this.iter_n_children(null);

		if(n_children == 0) {
			trackList_is_empty = true;
			return false; // Here something is wrong
		}

		// create treepath pointing to last row
		var tp = new TreePath.from_indices(n_children - 1);

		if(tp == null) {
			trackList_is_empty = true;
			return false;
		}

		// compare my treepath with last row
		if(path.compare(tp) == 0) return true;
		return false;
	}

	public void on_position_reference_changed() {
		TreePath treepath;
		TreeIter iter;
//		string uri = EMPTYSTRING;

		// Handle uri stuff
		if(get_current_path(out treepath)) {
			Item? item;
			this.get_iter(out iter, treepath);
			this.get(iter, Column.ITEM, out item);
			if((item.uri != EMPTYSTRING) && (item.uri == global.current_uri)) {
				global.do_restart_of_current_track();
				global.uri_repeated(item.uri);
			}
			
			if(item.uri != EMPTYSTRING)
				global.current_uri = item.uri;
			
		}
		else {
			return;
		}

		// Set visual feedback for tracklist
		if(((int)global.player_state) > 0) { //playing or paused
			bolden_row();

			if(global.player_state == PlayerState.PLAYING)
				set_play_state();
			else if(global.player_state== PlayerState.PAUSED)
				set_pause_state();
		}
		else {
			unbolden_row();
			reset_state();
		}
	}

	// gets path global-position_reference is pointing to
	public bool get_current_path(out TreePath treepath) {
		treepath = null;
		if((global.position_reference.valid()&&
		  (global.position_reference != null))) {
			treepath = global.position_reference.get_path();
			if(treepath!=null) {
				// print("active path: " + treepath.to_string() + "\n");
				return true;
			}
			return false;
		}
		return false;
	}

	// gets active path, or first path
	public bool get_active_path(out TreePath treepath, out bool used_next_pos) {
		TreeIter iter;
		used_next_pos = false;
		treepath = null;
		if((global.position_reference.valid()&&
		  (global.position_reference != null))) {
			treepath = global.position_reference.get_path();
			if(treepath!=null) {
				this.get_iter(out iter, treepath);
				return true;
			}
			return false;
		}
		else if(global.position_reference_next.valid()&&
		  (global.position_reference_next != null)) {
			//print("use position_reference_next \n");
			used_next_pos = true;
			global.position_reference = global.position_reference_next;
			treepath = global.position_reference.get_path();
			if(treepath!=null) {
				this.get_iter(out iter, treepath);
				return true;
			}
			return false;
		}
		else if(this.get_iter_first(out iter)) {
			treepath = this.get_path(iter);
			used_next_pos = true;

			if(treepath != null)
				global.position_reference_next = new TreeRowReference(this, treepath);

			return true;
		}
		global.position_reference = null;
		global.position_reference_next = null;
		return false;
	}

	public TreeIter insert_title(Gdk.Pixbuf? pixbuf,
	                             ref TrackData td,
	                             bool bold = false) {
		TreeIter iter;
		int int_bold = Pango.Weight.NORMAL;
		string? tracknumberString = null;
		string? lengthString = null;
		string? yearString = null;
		this.append(out iter);
		
		if(!(td.tracknumber==0))
			tracknumberString = "%u".printf(td.tracknumber);
		
		if(td.length > 0) {
			// convert seconds to a user convenient mm:ss display
			int dur_min, dur_sec;
			dur_min = (int)(td.length / 60);
			dur_sec = (int)(td.length % 60);
			lengthString = "%02d:%02d".printf(dur_min, dur_sec);
		}
		if(td.year > 0) {
			yearString = "%u".printf(td.year);
		}
		if(bold)
			int_bold = Pango.Weight.BOLD;
		else
			int_bold = Pango.Weight.NORMAL;
		
		this.set(iter,
		         TrackListModel.Column.ITEM ,td.item,
		         TrackListModel.Column.ICON, pixbuf,
		         TrackListModel.Column.TRACKNUMBER, tracknumberString,
		         TrackListModel.Column.TITLE, td.title,
		         TrackListModel.Column.ALBUM, td.album,
		         TrackListModel.Column.ARTIST, td.artist,
		         TrackListModel.Column.LENGTH, lengthString,
		         TrackListModel.Column.WEIGHT, int_bold,
		         TrackListModel.Column.YEAR, yearString,
		         TrackListModel.Column.GENRE, td.genre
		         );
		return iter;
	}

	public bool not_empty() {
		if(this.iter_n_children(null) > 0)
			return true;
		else
			return false;
	}

	public void set_reference_to_last() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = this.iter_n_children(null);

		if(numberOfRows == 0) return;

		this.iter_nth_child(out iter, null, numberOfRows -1);
		var tpath = this.get_path(iter);

		if(tpath == null) return;

		// if reference is null and reference_next is pointing to a row,
		// reference _next shall be used
		global.position_reference = null;
		global.position_reference_next = new TreeRowReference(this, tpath);
	}

	// used for saving current tracks in list before quit
	public Item[] get_all_tracks() {
		list_of_items = {};
		this.foreach(list_foreach);
		return list_of_items;
	}

	private Item[] list_of_items;
	private bool list_foreach(TreeModel sender, TreePath path, TreeIter iter) {
		Item? item = null;
		sender.get(iter, Column.ITEM, out item);
		if(item == null)
			return false;
		list_of_items += item;
		return false;
	}

	public string get_uri_for_current_position() {
//		string uri = EMPTYSTRING;
		TreeIter iter;
		Item? item = Item(ItemType.UNKNOWN);
		if((global.position_reference != null)&&
		   (global.position_reference.valid())) {
		// Use position_reference, if available...
			this.get_iter(out iter, global.position_reference.get_path());
			this.get(iter, Column.ITEM, out item);
		}
		else if((global.position_reference != null)&&
		   (global.position_reference.valid())) {
		// ...or use position_reference_next, if available
			this.get_iter(out iter, global.position_reference_next.get_path());
			this.get(iter, Column.ITEM, out item);
		}
		else if(this.get_iter_first(out iter)){
			// ... or use first position, if available and 
			// set global.position_reference to that track
			this.get(iter, Column.ITEM, out item);
			global.position_reference = null;
			global.position_reference = new TreeRowReference(this, this.get_path(iter));
		}
		return item.uri;
	}

	// find active row, set state picture, bolden and set uri for gpl
	private bool set_player_state(PlayerState ts) {
		Gdk.Pixbuf? pixbuf = null;
		Gtk.Invisible w = new Gtk.Invisible();
		if((global.position_reference == null)||
		  (!global.position_reference.valid())) {
/*
			print("current position not found, use _next\n");
			global.position_reference = global.position_reference_next;
*/
			return false;
		}
		TreeIter citer;
		this.get_iter(out citer, global.position_reference.get_path());
		if(ts==PlayerState.PLAYING) {
			bolden_row();
			pixbuf = w.render_icon(Gtk.Stock.MEDIA_PLAY, IconSize.BUTTON, null);
		}
		else if(ts==PlayerState.PAUSED) {
			bolden_row();
			pixbuf = w.render_icon(Gtk.Stock.MEDIA_PAUSE, IconSize.BUTTON, null);
		}
		else if(ts==PlayerState.STOPPED) {
			unbolden_row();
			this.set(citer, Column.ICON, null);
			return true;
		}
		Item? item;
		this.get(citer,
				 Column.ITEM, out item
				 );
		if(item.uri == gst_player.uri) {
			this.set(citer, Column.ICON, pixbuf);
		}
		return true;
	}

	public bool reset_state() {
		return set_player_state(PlayerState.STOPPED);
	}

	private bool set_play_state() {
		return set_player_state(PlayerState.PLAYING);
	}

	private bool set_pause_state() {
		return set_player_state(PlayerState.PAUSED);
	}

	private void bolden_row() {
		if(global.position_reference == null) return;
		if(!global.position_reference.valid()) return;
		
		var tpath = global.position_reference.get_path();
		
		if(tpath == null) return;
		
		TreeIter citer;
		this.get_iter(out citer, tpath);
		
		this.set(citer,
		         Column.WEIGHT, Pango.Weight.BOLD,
		         -1);
	}

	private void unbolden_row() {
		if(global.position_reference == null) return;
		if(!global.position_reference.valid()) return;
		
		var tpath = global.position_reference.get_path();
		
		if(tpath == null) return;
		
		TreeIter citer;
		this.get_iter(out citer, tpath);
		this.set(citer,
		         Column.WEIGHT, Pango.Weight.NORMAL,
		         -1);
	}

	private Item add_uri_helper(string fileuri,ref bool first,bool from_playlist = false) {
		//print("xnoise-tracklist-model add_uri_helper %s\n", fileuri);
		
		Item? item = Item(ItemType.UNKNOWN);
		TreeIter iter, iter_2;
		
		TrackData td;
		
		File file = File.new_for_uri(fileuri);
		item = ItemHandlerManager.create_item(fileuri);

		if(item.type == ItemType.UNKNOWN) // only handle file, if we know it
			if(from_playlist == true)
				item.type = Xnoise.ItemType.STREAM;
		
		// TODO: maybe a check for remote schemes is necessary to avoid blocking
		TagReader tr = new TagReader();
		td = tr.read_tag(file.get_path()); // move to worker thread
		
		if(td == null) { //This is a possible URL
			td = new TrackData();
			td.title = file.get_basename();
		}
		
		if(first == true) {
			iter = this.insert_title(null, ref td, true);
			
			global.position_reference = new TreeRowReference(this, this.get_path(iter));
			
			iter_2 = iter;
			first = false;
		}
		else {
			iter = this.insert_title(null, ref td, false);
		}
		return item;
	}

	public void add_uris(string[]? uris) {
		//print("FIME: xnoise-tracklist-model.vala add_uris\n"); 
		//FIXME: When open xnoise first time(restore last playlist) or when open a playlist using double click or open with Xnoise.
		//Try stop and play, then error, FIXME
		if(uris == null) return;
		if(uris[0] == null) return;
		int k = 0;
		TreeIter iter_2;
		FileType filetype;
		this.get_iter_first(out iter_2);
		Item? item = Item(ItemType.UNKNOWN);
		Item? item2 = item;
		bool first = true;
		
		File file;
		string mime;
		
		var psVideo = new PatternSpec("video*");
		var psAudio = new PatternSpec("audio*");
		string attr = FileAttribute.STANDARD_TYPE + "," +
			      FileAttribute.STANDARD_CONTENT_TYPE;
		
		while(uris[k] != null) { //because foreach is not working for this array coming from libunique
			//print("1. add_uris %s\n",uris[k]);
			//write(f,"1. add_uris %s\n",uris[k]);
			var fileuri = uris[k];
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
			catch(GLib.Error e) {
				print("%s\n", e.message);
				return;
			}
			bool is_playlist = Playlist.is_playlist_extension(get_suffix_from_filename(file.get_uri()));
			if((filetype == GLib.FileType.REGULAR)&&
			   (psAudio.match_string(mime)||
			    psVideo.match_string(mime)||
			    is_playlist == true)) {
				
				if(is_playlist) {
					//print("Playlist: %s\n",fileuri);
					Reader reader = new Reader();
					Result result = Result.UNHANDLED;
					try {
						result = reader.read(fileuri);
					}
					catch(Error e) {
						print("%s\n", e.message);
						result = Result.UNHANDLED;
					}
					if(result != Result.UNHANDLED) {
						EntryCollection results = reader.data_collection;
						if(results != null) {
							int size = results.get_size();
							for(int i = 0; i < size; i++) {
								Xnoise.Playlist.Entry entry = results[i];
								string current_uri = entry.get_uri();
								item = this.add_uri_helper(current_uri,ref first,true);
								if(k == 0 && item2.type == ItemType.UNKNOWN) {
									item2 = item;
								}
								//print("add_uri_helper %s\n", current_uri);
							}
						}
					}
				}
				else {
					//this.add_uri_helper(ref fileuri,ref path,ref is_first);
					item = this.add_uri_helper(fileuri,ref first);
					if(k == 0 && item2.type == ItemType.UNKNOWN) {
						item2 = item;
					}
					//print("add_uri_helper %s\n", fileuri);
				}
			}
			k++;
		}
		//Play first uri added to playlist
		if(item2.type != ItemType.UNKNOWN) { // TODO ????
			ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.PLAY_NOW);
			if(tmp == null)
				return;
			unowned Action? action = tmp.get_action(item2.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);
			if(action != null)
				action.action(item2, null);
		}
		tl.set_focus_on_iter(ref iter_2);
	}
}
