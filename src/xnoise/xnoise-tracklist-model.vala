/* xnoise-tracklist-model.vala
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

public class Xnoise.TrackListModel : ListStore, TreeModel {
	private Main xn;
	private GLib.Type[] col_types = new GLib.Type[] {
		typeof(int),        // STATE
		typeof(Gdk.Pixbuf), // ICON
		typeof(string),     // TRACKNUMBER
		typeof(string),     // TITLE
		typeof(string),     // ALBUM
		typeof(string),     // ARTIST
		typeof(int),        // WEIGHT
		typeof(string)      // URI
	};

	public signal void sign_active_path_changed(TrackState ts);

	public TrackListModel() {
		this.xn = Main.instance();
		this.set_column_types(col_types);

		// Use these two signals to handle the position_reference representation in tracklist
		global.before_position_reference_changed.connect(on_before_position_reference_changed);
		global.position_reference_changed.connect(on_position_reference_changed);
		global.track_state_changed.connect( () => {
			switch(global.track_state) {
				case TrackState.PLAYING: {
					this.set_play_state();
					break;
				}
				case TrackState.PAUSED: {
					this.set_pause_state();
					break;
				}
				case TrackState.STOPPED: {
					this.reset_state();
					break;
				}
				default: break;
			}
		});
	}

	public void on_before_position_reference_changed() {
		unbolden_row();
		reset_state();
	}

	public void on_position_reference_changed() {
		TreePath treepath;
		TreeIter iter;
		TrackState currentstate;
		bool is_first;
		string uri = "";

		if(get_active_path(out treepath,
		                   out currentstate,
		                   out is_first)) {
			this.get_iter(out iter, treepath);
			this.get(iter, TrackListModelColumn.URI, out uri);
			if(uri != "") global.current_uri = uri;
		}

		if(((int)global.track_state) > 0) { //playing or paused
			bolden_row();

			if(global.track_state == TrackState.PLAYING)
				set_play_state();
			else if(global.track_state== TrackState.PAUSED)
				set_pause_state();
		}
		else {
			unbolden_row();
			reset_state();
		}
	}

	// gets active path, or first path
	public bool get_active_path(out TreePath treepath,
	                            out TrackState currentstate,
	                            out bool is_first) {
		is_first = false;
		if(global.position_reference != null) {
			treepath = global.position_reference.get_path();
			if(treepath!=null) {
				// print("active path: " + treepath.to_string() + "\n");
				if(treepath.to_string()=="0")
					is_first = true;

				TreeIter citer;
				this.get_iter(out citer, treepath);
				this.get(citer,
				         TrackListModelColumn.STATE, out currentstate
				         );
				return true;
			}
			return false;
		}
/*
		if(this.get_iter_first(out iter)) {
			// first song in list
			treepath = this.get_path(iter);

			if(treepath != null)
				global.position_reference = new TreeRowReference(this, treepath);

			is_first = true;
			return true;
		}
*/
		return false;
	}

	public TreeIter insert_title(TrackState status = TrackState.STOPPED,
	                             Gdk.Pixbuf? pixbuf,
	                             int tracknumber,
	                             string title,
	                             string album,
	                             string artist,
	                             bool bold = false,
	                             string uri) {
		TreeIter iter;
		int int_bold = 400;
		string? tracknumberString = null;
		this.append(out iter);
		if(!(tracknumber==0)) {
			tracknumberString = "%d".printf(tracknumber);
		}

		if(bold)
			int_bold = 700; // Pango code for bold
		else
			int_bold = 400; // Pango code for not bold

		this.set(iter,
		         TrackListModelColumn.STATE, status,
		         TrackListModelColumn.ICON, pixbuf,
		         TrackListModelColumn.TRACKNUMBER, tracknumberString,
		         TrackListModelColumn.TITLE, title,
		         TrackListModelColumn.ALBUM, album,
		         TrackListModelColumn.ARTIST, artist,
		         TrackListModelColumn.WEIGHT, int_bold,
		         TrackListModelColumn.URI, uri,
		         -1);
		return iter;
	}

	public void set_state_picture_for_title(TreeIter iter,
	                                        TrackState state = TrackState.STOPPED) {
/*
		Gdk.Pixbuf pixbuf = null;
		var invisible = new Gtk.Invisible();
		if(state != TrackState.STOPPED) {
			var tpath = this.get_path(iter);
			if(tpath != null) {
				global.position_reference = new TreeRowReference(this, tpath);
			}
			else {
				print("cannot setup treerowref\n");
				return;
			}
		}
		if(state == TrackState.PLAYING) {
			pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
			this.set(iter,
			         TrackListModelColumn.STATE, TrackState.PLAYING,
			         TrackListModelColumn.ICON, pixbuf,
			        -1);
			sign_active_path_changed(state);
		}
		else if(state==TrackState.PAUSED) {
			pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
			this.set(iter,
			         TrackListModelColumn.STATE, TrackState.PAUSED,
			         TrackListModelColumn.ICON, pixbuf,
			        -1);
			sign_active_path_changed(state);
		}
*/
	}

	public bool set_play_state_for_first_song() {
		TreeIter iter;
		Gdk.Pixbuf pixbuf;
		Gtk.Invisible invisible = new Gtk.Invisible();
		string uri;
		pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
		int numberOfRows = this.iter_n_children(null);
		if(numberOfRows == 0) return false;

		this.iter_nth_child(out iter, null, 0);
		var tpath = this.get_path(iter);
		if(tpath != null)
			global.position_reference = new TreeRowReference(this, tpath);

		this.get(iter,
		         TrackListModelColumn.URI, out uri
		         );

		if(uri == xn.gPl.Uri) {
			this.set(iter,
			         TrackListModelColumn.ICON, pixbuf,
			         TrackListModelColumn.STATE, TrackState.PLAYING,
			         -1
			         );
			//bolden_row();
			xn.gPl.Uri = uri;
		}
		else {
/*
			this.set(iter,
			         TrackListModelColumn.ICON, null,
			         TrackListModelColumn.STATE, TrackState.POSITION_FLAG,
			         -1
			         );
*/
		}
		return true;
	}

	public bool not_empty() {
		if(this.iter_n_children(null) > 0)
			return true;
		else
			return false;
	}

	public void mark_last_title_active() {
		// TODO: use global.position_reference_next
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = this.iter_n_children(null);

		if(numberOfRows == 0) return;

		this.iter_nth_child (out iter, null, numberOfRows -1);
		var tpath = this.get_path(iter);

		if(tpath != null) global.position_reference = new TreeRowReference(this, tpath);
	}

/*
	// Resets visual state and the TrackState for all rows
	public void reset_play_status_all_titles() {
		TreeIter iter;
		int numberOfRows = 0;
		numberOfRows = this.iter_n_children(null);
		if(numberOfRows==0) return;

		for(int i = 0; i < numberOfRows; i++) {
			this.iter_nth_child(out iter, null, i);
			this.set(iter,
			         TrackListModelColumn.STATE, TrackState.STOPPED,
			         TrackListModelColumn.ICON, null,
			         -1
			         );
			//this.unbolden_row();
		}
	}
*/

	public string[] get_all_tracks() {
		list_of_uris = {};
		this.foreach(list_foreach);
		return list_of_uris;
	}

	private string[] list_of_uris;
	private bool list_foreach(TreeModel sender, TreePath path, TreeIter iter) {
		GLib.Value gv;
		sender.get_value(
			iter,
			TrackListModelColumn.URI,
			out gv);
		list_of_uris += gv.get_string();
		return false;
	}

	// find active row, set state picture, bolden and set uri for gpl
	private bool set_track_state(TrackState ts) {
		Gdk.Pixbuf? pixbuf = null;
		Gtk.Invisible w = new Gtk.Invisible();
		if(global.position_reference == null) {
			print("current position not found\n");
			return false;
		}
		TreeIter citer;
		this.get_iter(out citer, global.position_reference.get_path());
		string uri;
		if(ts==TrackState.PLAYING) {
			bolden_row();
			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
		}
		else if(ts==TrackState.PAUSED) {
			bolden_row();
			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
		}
		else if(ts==TrackState.STOPPED) {
			unbolden_row();
		}

		this.get(citer,
				 TrackListModelColumn.URI, out uri
				 );
		if(uri==xn.gPl.Uri) {
			this.set(citer,
					 TrackListModelColumn.ICON, pixbuf,
					 -1
					 );
		}
		return true;

//		TreeIter iter;
//		Gdk.Pixbuf? pixbuf = null;
//		Gtk.Invisible w = new Gtk.Invisible();
//		string uri;
//		if(ts==TrackState.PLAYING)
//			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
//		else if(ts==TrackState.PAUSED)
//			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
//		int numberOfRows = (int)this.iter_n_children(null);
//		if(numberOfRows==0) return false;
//		for(int i=0; i<numberOfRows; i++) {
//			int state = 0;
//			this.iter_nth_child(out iter, null, i);
//			this.get(iter,
//			         TrackListModelColumn.STATE, out state
//			         );
//			if(state>0) {
//				this.get(iter,
//				         TrackListModelColumn.URI, out uri
//				         );
//				if(uri==xn.gPl.Uri) {
//					this.set(iter,
//					         TrackListModelColumn.ICON, pixbuf,
//					         -1
//					         );
//					bolden_row();
//				}
//				return true;
//			}
//		}
//		return false;
	}

	private bool reset_state() {
		return set_track_state(TrackState.STOPPED);
	}

	private bool set_play_state() {
		return set_track_state(TrackState.PLAYING);
	}

	private bool set_pause_state() {
		return set_track_state(TrackState.PAUSED);
	}

	private void bolden_row() {
		if(global.position_reference == null) return;

		var tpath = global.position_reference.get_path();

		if(tpath == null) return;

		TreeIter citer;
		this.get_iter(out citer, tpath);

		this.set(citer,
		         TrackListModelColumn.WEIGHT, 700,
		         -1);
	}

	private void unbolden_row() {
		if(global.position_reference == null) return;

		var tpath = global.position_reference.get_path();

		if(tpath == null) return;

		TreeIter citer;
		this.get_iter(out citer, tpath);
		this.set(citer,
		         TrackListModelColumn.WEIGHT, 400,
		         -1);
	}

	public void add_tracks(TrackData[]? td_list, bool imediate_play = true)	{

		if(td_list == null) return;
		if(td_list[0] == null) return;

		int k = 0;
		TreeIter iter, iter_2 = {};
		while(td_list[k] != null) {
			string current_uri = td_list[k].Uri;
			if(k == 0) { // First track
				iter = this.insert_title(TrackState.PLAYING,
				                         null,
				                         (int)td_list[k].Tracknumber,
				                         td_list[k].Title,
				                         td_list[k].Album,
				                         td_list[k].Artist,
				                         true,
				                         current_uri);
				global.position_reference = null;
				global.position_reference = new TreeRowReference(this, this.get_path(iter));
				iter_2 = iter;
			}
			else {
				iter = this.insert_title(TrackState.STOPPED,
				                         null,
				                         (int)td_list[k].Tracknumber,
				                         td_list[k].Title,
				                         td_list[k].Album,
				                         td_list[k].Artist,
				                         false,
				                         current_uri);
			}
			k++;
		}

		// TODO: should this be done from gPl ???????
		if(td_list[0].Uri != null) {
			global.track_state = TrackState.PLAYING;
			global.current_uri = td_list[0].Uri;
		}

		xn.tl.set_focus_on_iter(ref iter_2);

		//xn.add_track_to_gst_player(td_list[0].Uri); 	// TODO: check this function!!!!
	}

	public void add_uris(string[]? uris) {
		if(uris == null) return;
		if(uris[0] == null) return;
		int k = 0;
		TreeIter iter, iter_2;
		FileType filetype;
		//this.reset_play_status_all_titles();
		while(uris[k] != null) { //because foreach is not working for this array coming from libunique
			File file = File.new_for_uri(uris[k]);
			TagReader tr = new TagReader();
			bool is_stream = false;
			string urischeme = file.get_uri_scheme();
			var t = new TrackData();
			if(urischeme == "file") {
				try {
					FileInfo info = file.query_info(FILE_ATTRIBUTE_STANDARD_TYPE,
				                                    FileQueryInfoFlags.NONE,
				                                    null);
					filetype = info.get_file_type();
				}
				catch(GLib.Error e){
					print("%s\n", e.message);
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
			else if(urischeme == "http") {
				is_stream = true;
			}
			if(k == 0) {
				iter = this.insert_title(TrackState.PLAYING,
				                         null,
				                         (int)t.Tracknumber,
				                         t.Title,
				                         t.Album,
				                         t.Artist,
				                         true,
				                         uris[k]);

				global.position_reference = null; // TODO: Is this necessary???
				global.position_reference = new TreeRowReference(this, this.get_path(iter));
				// this.set_state_picture_for_title(iter, TrackState.PLAYING);
				iter_2 = iter;
			}
			else {
				iter = this.insert_title(TrackState.STOPPED,
				                         null,
				                         (int)t.Tracknumber,
				                         t.Title,
				                         t.Album,
				                         t.Artist,
				                         false,
				                         uris[k]);
				// this.set_state_picture_for_title(iter);
			}
			tr = null;
			k++;
		}
		if(uris[0] != null) {
			global.current_uri = uris[0];
			global.track_state = TrackState.PLAYING;
		}
		//xn.add_track_to_gst_player(uris[0]);
	}
}
