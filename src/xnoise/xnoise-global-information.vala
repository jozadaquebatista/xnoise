/* xnoise-global-information.vala
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


/**
 * This class is used to hold application wide states like if the application is playing, the uri of the current title...
 * All these are properties, so that changes can be tracked application wide.
 */

public class Xnoise.GlobalInfo : GLib.Object {

	// SIGNALS
	// TreeRowReference for current track changed
	public signal void position_reference_changed();
	// TreeRowReference for current track changed, triggered before change
	public signal void before_position_reference_changed();
	public signal void before_position_reference_next_changed();
	public signal void position_reference_next_changed();
	// state changed to playing, paused or stopped
	public signal void track_state_changed();
	public signal void current_uri_changed();
	public signal void current_uri_repeated(string uri);
	public signal void caught_eos_from_player();
	//signal to be triggered after a change of the media folders
	public signal void sig_media_path_changed();
	public signal void sig_item_imported(string uri);

	// PRIVATE FIELDS
	private TrackState _track_state = TrackState.STOPPED;
	private string? _current_uri = null;
	private Gtk.TreeRowReference? _position_reference = null;
	private Gtk.TreeRowReference? _position_reference_next = null;

	public enum TrackState {
		STOPPED = 0,
		PLAYING,
		PAUSED
	}

	// PROPERTIES
	public TrackState track_state {
		get {
			return _track_state;
		}
		set {
			if(_track_state != value) {
				_track_state = value;
				// signal changed
				track_state_changed();
			}
		}
	}

	public string? current_uri {
		get {
			return _current_uri;
		}
		set {
			if(_current_uri != value) {
				_current_uri = value;
				// signal changed
				current_uri_changed();
			}
		}
	}

	// position_reference is pointing to the current row in the tracklist
	public Gtk.TreeRowReference position_reference {
		get {
			return _position_reference;
		}
		set {
			if(_position_reference != value) {
				before_position_reference_changed();
				_position_reference = value;
				// signal changed
				position_reference_changed();
			}
		}
	}

	// The next_position_reference is used to hold a position in the tracklist,
	// in case the row position_reference is pointing to is removed and the next
	// song has not yet been started.
	public Gtk.TreeRowReference position_reference_next {
		get {
			return _position_reference_next;
		}
		set {
			if(_position_reference_next != value) {
				before_position_reference_next_changed();
				_position_reference_next = value;
				// signal changed
				position_reference_next_changed();
			}
		}
	}
	public bool _media_import_in_progress;
	public bool media_import_in_progress {
		get {
			return _media_import_in_progress;
		}
		set {
				_media_import_in_progress = value;
		}
	}

	public string? image_path_small { get; set; default = null; }
	public string? image_path_large { get; set; default = null; }
	
	// PUBLIC GLOBAL FUNCTIONS
	public void reset_position_reference() {
		this._position_reference = null;
	}

	public void handle_eos() {
		//emmit signal
		caught_eos_from_player();
	}
	
	public void check_image_for_current_track() {
		string? small_name = null;
		if(get_image_path_for_media_uri(current_uri, ref small_name)) {
			string? large_name = null; 
			if((small_name == "") || (small_name == null)) {
				image_path_small = null;
				image_path_large = null;
				return;
			}
			large_name = small_name.substring(0, small_name.len() - "medium".len());
			large_name = large_name + "extralarge";
			File small = File.new_for_path(small_name);
			File large = File.new_for_path(large_name);
			if(!small.query_exists(null))
				small_name = null;
			if(!large.query_exists(null))
				image_path_large = small_name;
			else
				image_path_large = large_name;
			image_path_small = small_name;
		}
		else {
			image_path_small = null;
			image_path_large = null;
		}
		//print("small: %s; \nlarge: %s\n", image_path_small, image_path_large);
	}
}
