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
		typeof(int), 
		typeof(Gdk.Pixbuf), 
		typeof(string), 
		typeof(string), 
		typeof(string), 
		typeof(string), 
		typeof(string)
	};

	public signal void sign_active_path_changed(TrackState ts);

	public TrackListModel() {
		this.xn = Main.instance();
		set_column_types(col_types);
		
	}

	// gets active path, or first path
	public bool get_active_path(out TreePath treepath, out TrackState currentstate, out bool is_first) {
		//print("tracklist: get_active_path\n");
		TreeIter iter;
		is_first = false;
		currentstate = TrackState.STOPPED;
		int numberOfRows = this.iter_n_children(null);
		for(int i = 0; i < numberOfRows; i++) {
			this.iter_nth_child(out iter, null, i);
			this.get(iter,
			         TrackListColumn.STATE, out currentstate
			         );
			if(currentstate != TrackState.STOPPED) {
				treepath = this.get_path(iter);
				return true;
			}
		}
		if(this.get_iter_first(out iter)) {
			// first song in list
			treepath = this.get_path(iter); 
			is_first = true;
			return true;
		}
		return false;
	}

	public TreeIter insert_title(TrackState status = 0, Gdk.Pixbuf? pixbuf, int tracknumber, string title, string album, string artist, string uri) {
		TreeIter iter;
		string? tracknumberString = null;
		this.append(out iter);
		if(!(tracknumber==0)) {
			tracknumberString = "%d".printf(tracknumber);
		}
		this.set(iter,
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

	public void set_state_picture_for_title(TreeIter iter, TrackState state = TrackState.STOPPED) {
		Gdk.Pixbuf pixbuf = null;
		var invisible = new Gtk.Invisible();
	
		if(state == TrackState.PLAYING) {
			pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
			this.set(iter,
				TrackListColumn.STATE, TrackState.PLAYING,
				TrackListColumn.ICON, pixbuf,
				-1);
			bolden_row(ref iter);
			sign_active_path_changed(state);
		}
		else if(state==TrackState.PAUSED) {
			pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
			this.set(iter,
				TrackListColumn.STATE, TrackState.PAUSED,
				TrackListColumn.ICON, pixbuf,
				-1);
			bolden_row(ref iter);
			sign_active_path_changed(state);
		}
	}
	
	public bool set_play_state_for_first_song() {
		//print("tracklist: set_play_state_for_first_song\n");
		TreeIter iter;
		Gdk.Pixbuf pixbuf;
		Gtk.Invisible invisible = new Gtk.Invisible();
		string uri;
		pixbuf = invisible.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
		int numberOfRows = this.iter_n_children(null);
		if(numberOfRows==0) return false;
		
		this.iter_nth_child(out iter, null, 0);
		
		this.get(iter, 
		              TrackListColumn.URI, out uri
		              );
		if(uri == xn.gPl.Uri) {	  
			this.set(iter,
			              TrackListColumn.ICON, pixbuf,
			              TrackListColumn.STATE, TrackState.PLAYING,
			              -1
			              );
			bolden_row(ref iter);
			xn.gPl.Uri = uri;
		}
		else {
			this.set(iter,
			              TrackListColumn.ICON, null,
			              TrackListColumn.STATE, TrackState.POSITION_FLAG,
			              -1
			              );
		}
		return true;
	}

	public int get_n_rows() {
		int val = 0;
		val = this.iter_n_children(null);
		print("get_n_rows: %d", val);
		return val;
	}
	
	// find active row, set state picture, bolden and set uri for gpl
	private bool set_track_state(TrackState ts) {
		//print("tracklist: set_track_state\n");
		TreeIter iter;
		Gdk.Pixbuf? pixbuf = null;
		Gtk.Invisible w = new Gtk.Invisible();
		string uri;
		if(ts==TrackState.PLAYING)
			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PLAY, IconSize.BUTTON, null);
		else if(ts==TrackState.PAUSED)
			pixbuf = w.render_icon(Gtk.STOCK_MEDIA_PAUSE, IconSize.BUTTON, null);
		int numberOfRows = (int)this.iter_n_children(null);
		if(numberOfRows==0) return false;
		for(int i=0; i<numberOfRows; i++) {
			int state = 0;
			this.iter_nth_child(out iter, null, i);
			this.get(iter, 
			         TrackListColumn.STATE, out state
			         );
			if(state>0) {
				this.get(iter, 
				         TrackListColumn.URI, out uri
				         );
				if(uri==xn.gPl.Uri) {
					this.set(iter,
					         TrackListColumn.ICON, pixbuf,
					         -1
					         );
					bolden_row(ref iter);
				}
				return true;
			}
		}
		return false;		
	}
	
	public bool set_play_state() {
		return set_track_state(TrackState.PLAYING);
	}
	
	public bool set_pause_state() {
		return set_track_state(TrackState.PAUSED);
	}

	public void bolden_row(ref TreeIter iter) {
		string valArtist = "";
		string valAlbum = "";
		string valTitle = "";
		this.get(
			iter,
			TrackListColumn.ARTIST,	out valArtist,
			TrackListColumn.ALBUM,  out valAlbum,
			TrackListColumn.TITLE,  out valTitle);
		if(valTitle.has_prefix("<b>")) return;

		this.set(iter,
			TrackListColumn.ARTIST, "<b>%s</b>".printf(valArtist),
			TrackListColumn.ALBUM,  "<b>%s</b>".printf(valAlbum),
			TrackListColumn.TITLE,  "<b>%s</b>".printf(valTitle),
			-1);
	}

	public void unbolden_row(ref TreeIter iter) {
		string valArtist = "";
		string valAlbum = "";
		string valTitle = "";
		this.get(iter,
			TrackListColumn.ARTIST, 
			out valArtist,
			TrackListColumn.ALBUM, 
			out valAlbum,
			TrackListColumn.TITLE, 
			out valTitle);
		if(valTitle.has_prefix("<b>")) {
			string artist = valArtist.substring(3, (int)valArtist.length - 7); 
			string album  = valAlbum.substring( 3, (int)valAlbum.length  - 7);
			string title  = valTitle.substring( 3, (int)valTitle.length  - 7);
			this.set(iter,
			         TrackListColumn.ARTIST, artist,
			         TrackListColumn.ALBUM,  album,
			         TrackListColumn.TITLE,  title,
			         -1
			         );
		}
	}
}
