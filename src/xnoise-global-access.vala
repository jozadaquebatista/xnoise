/* xnoise-global-access.vala
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

public class Xnoise.GlobalAccess : GLib.Object {

	construct {
		_settings_folder = 
		GLib.Path.build_filename(GLib.Environment.get_user_config_dir(),
		                         "xnoise",
		                         null);
		uri_changed.connect( (s,v) => {
			this.set_meta_information(v);
		});
	
		this.notify.connect( (s, p) => {
			//print("p.name: %s\n", p.name);
			switch(p.name) {
				case "current-artist":
					this.tag_changed(ref this._current_uri, "artist", this._current_artist);
					break;
				case "current-album":
					this.tag_changed(ref this._current_uri, "album", this._current_album);
					break;
				case "current-title":
					this.tag_changed(ref this._current_uri, "title", this._current_title);
					break;
				case "current-location":
					this.tag_changed(ref this._current_uri, "location", this._current_location);
					break;
				case "current-genre":
					this.tag_changed(ref this._current_uri, "genre", this._current_genre);
					break;
				case "current-org":
					this.tag_changed(ref this._current_uri, "organization", this._current_organization);
					break;
			}
		});
	}

	
	// SIGNALS

	// TreeRowReference for current track changed
	public signal void position_reference_changed();
	// TreeRowReference for current track changed, triggered before change
	public signal void before_position_reference_changed();
	public signal void before_position_reference_next_changed();
	public signal void position_reference_next_changed();
	// state changed to playing, paused or stopped
	public signal void player_state_changed();
	public signal void uri_changed(string? uri);
	public signal void uri_repeated(string? uri);
	public signal void tag_changed(ref string? newuri, string? tagname, string? tagvalue);
	
	public signal void caught_eos_from_player();
	//signal to be triggered after a change of the media folders
	public signal void sig_media_path_changed();
	public signal void sig_item_imported(string uri);
	
	public signal void sign_restart_song();
	public signal void sign_song_info_required();

	// PRIVATE FIELDS
	private PlayerState _player_state = PlayerState.STOPPED;
	private string? _current_uri = null;
	private Gtk.TreeRowReference? _position_reference = null;
	private Gtk.TreeRowReference? _position_reference_next = null;
	
	private RemoteSchemes _remote_schemes = new RemoteSchemes();
	private LocalSchemes  _local_schemes  = new LocalSchemes();

	// PROPERTIES

	// User specific settings directory following freedesktop standard:
	//http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
	private string _settings_folder = "";
	public string settings_folder { 
		get {
			return _settings_folder;
		}
	}

	public PlayerState player_state {
		get {
			return _player_state;
		}
		set {
			if(_player_state != value) {
				_player_state = value;
				// signal changed
				player_state_changed();
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
				uri_changed(value);
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

	private bool _media_import_in_progress;
	public bool media_import_in_progress {
		get {
			return _media_import_in_progress;
		}
		set {
			_media_import_in_progress = value;
		}
	}

	public RemoteSchemes remote_schemes { 
		get {
			return _remote_schemes;
		}
	}
	
	public LocalSchemes local_schemes { 
		get {
			return _local_schemes;
		}
	}
	
	// Current track's meta data
	public string current_artist { get; set; default = null; }
	public string current_album { get; set; default = null; }
	public string current_title { get; set; default = null; }
	public string current_location { get; set; default = null; }
	public string current_genre { get; set; default = null; }
	public string current_organization { get; set; default = null; }
	
	public string? image_path_small { get; set; default = null; }
	public string? image_path_large { get; set; default = null; }
	
	// PUBLIC GLOBAL FUNCTIONS
	public void reset_position_reference() {
		this._position_reference = null;
	}

	public void do_restart_of_current_track() {
		sign_restart_song();
	}
	
	public void handle_eos() {
		//emmit signal
		caught_eos_from_player();
	}
	
	public void check_image_for_current_track() {
		string? small_name = null;
		string? large_name = null; 
		File f = get_file_for_current_artistalbum(current_artist, current_album, "medium");
		small_name = f != null ? f.get_path() : "";
		if((small_name == "") || (small_name == null)) {
			image_path_small = null;
			image_path_large = null;
			return;
		}
		
		large_name = small_name.substring(0, small_name.length - "medium".length);
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
	
	// set meta information after start of new track/stream from 
	// database. If not available, just reset tag info and wait for 
	// data from gstreamer
	private void set_meta_information(string? newuri) {
		string basename = null;
		if((newuri == "")|(newuri == null)) {
			current_artist = null;
			current_album = null;
			current_title = null;
			current_location = null;
			current_genre = null;
			current_organization = null;
			return;
		}
		File file = File.new_for_uri(newuri);
		basename = file.get_basename();
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		TrackData td;
		if(dbb.get_trackdata_for_uri(newuri, out td)) {
			current_artist = td.Artist;
			current_album  = td.Album;
			current_title  = td.Title;
			current_genre  = td.Genre;
		}
		else { 
			current_artist = null;
			current_album = null;
			
			if(basename.last_index_of(".") != -1) 
				current_title = prepare_name_from_filename(basename);
			else 
				current_title = basename;
			
			current_location = null;
			current_genre = null;
			current_organization = null;
		}
	}
	
	public void prev() {
		if(player_state == PlayerState.STOPPED)
			return;
		Main.instance.main_window.change_track(Xnoise.ControlButton.Direction.PREVIOUS);
	}

	public void play(bool pause_if_playing) {
		if(current_uri == null) {
			string uri = Main.instance.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "") && (uri != null)) 
				current_uri = uri;
		}
		if(player_state == PlayerState.PLAYING && pause_if_playing) 
			player_state = PlayerState.PAUSED;
		else 
			player_state = PlayerState.PLAYING;
	}

	public void pause() {
		if(current_uri == null) {
			string uri = Main.instance.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "") && (uri != null)) 
				current_uri = uri;
		}
		player_state = PlayerState.PAUSED;
	}

	public void next() {
		if(global.player_state == PlayerState.STOPPED)
			return;
		Main.instance.main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
	}

	public void stop() {
		Main.instance.main_window.stop();
	}
}
