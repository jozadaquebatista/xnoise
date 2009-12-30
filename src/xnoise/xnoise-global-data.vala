/* xnoise-general-data.vala
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


/**
 * This class is used to hold application wide states like if the application is playing, the uri of the current title...
 * All these are properties, so that changes can be tracked application wide.
 */

public class Xnoise.GlobalData : GLib.Object {
	// Signals
	public signal void position_reference_changed();
	public signal void before_position_reference_changed();
	public signal void track_state_changed();
	public signal void current_uri_changed();

	// Private fields
	private TrackState _track_state = TrackState.STOPPED;
	private string  _current_uri = "";
	private Gtk.TreeRowReference? _position_reference = null;

	// Public properties
	public TrackState track_state {
		get {
			return _track_state;
		}
		set {
			if(_track_state != value) {
				_track_state = value;
				track_state_changed();
			}
		}
	}

	public string current_uri {
		get {
			return _current_uri;
		}
		set {
			if(_current_uri != value) {
				_current_uri = value;
				current_uri_changed();
			}
		}
	}

	public Gtk.TreeRowReference position_reference {
		get {
			return _position_reference;
		}
		set {
			if(_position_reference != value) {
				before_position_reference_changed();
				_position_reference = value;
				position_reference_changed();
			}
		}
	}

	public Gtk.TreeRowReference next_position_reference { get; set; default = null; }

	public void handle_eos() {
		print("global: handle eos\n");
	}
}
