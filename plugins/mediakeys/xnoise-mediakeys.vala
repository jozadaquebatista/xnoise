/* xnoise-mediakeys.vala
 *
 * Copyright (C) 2010  Jörn Magens
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
 * Jörn Magens
 */

using Gtk;
using DBus;
using Xnoise;

public class Xnoise.MediaKeys : GLib.Object, IPlugin {
	private unowned Xnoise.Plugin _owner;

	public unowned Main xn { get; set; }
	
	public Xnoise.Plugin owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public Connection conn;
	public dynamic DBus.Object bus;
	
	public string name { 
		get {
			return "mediakeys";
		} 
	}

	public bool init() {
		try {
			conn = DBus.Bus.get(DBus.BusType.SESSION);
			if(conn == null) return false;
			
			bus = conn.get_object("org.gnome.SettingsDaemon",
			                      "/org/gnome/SettingsDaemon/MediaKeys",
			                      "org.gnome.SettingsDaemon.MediaKeys");
			if(bus == null)
				return false;
			
			bus.MediaPlayerKeyPressed.connect(on_media_player_key_pressed);
			
			bus.GrabMediaPlayerKeys("xnoise", (uint32)0);
		}
		catch(GLib.Error e) {
			stderr.printf("media keys: failed to setup dbus interface: %s\n", e.message);
			return false;
		}
		return true;
	}
	
	~MediaKeys() {
		print("release media keys\n");
		bus.ReleaseMediaPlayerKeys("xnoise");
	}


	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public Gtk.Widget? get_singleline_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public bool has_singleline_settings_widget() {
		return false;
	}
	
	
	private void on_media_player_key_pressed(dynamic DBus.Object bus, 
	                                         string application,
	                                         string key) {
		//print("key pressed (%s %s)\n", application, key);
		if(application != "xnoise")
			return;
		
		//TODO: Create some convenience methods in GlobalAccessrmation class to control xnoise
		switch(key) {
			case "Next": {
				this.xn.main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
				break;
			}
			case "Previous": {
				this.xn.main_window.change_track(Xnoise.ControlButton.Direction.PREVIOUS);
				break;
			}
			case "Play": {
				if(global.current_uri == null) {
					string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
					if((uri != "")&&(uri != null)) 
						global.current_uri = uri;
				}

				if(global.track_state == TrackState.PLAYING) {
					global.track_state = TrackState.PAUSED;
				}
				else {
					global.track_state = TrackState.PLAYING;
				}
				break;
			}
			case "Stop": {
				this.xn.main_window.stop();
				break;
			}
			default:
				//print("not an used mediakey\n");
				break;
		}
	}
}
