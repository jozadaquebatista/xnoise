/* xnoise-mpris.vala
 *
 * Copyright (C) 2010 Andreas Obergrusberger
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
 * Andreas Obergrusberger
 * Jörn Magens
 */

// exposes xnoise's player and tracklist controls via dbus using the mpris v2 interface
// refer to 
// http://www.mpris.org/2.0/spec/

using Gtk;
using Xnoise;

public class Xnoise.Mpris : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private uint owner_id;
	public MprisPlayer player = null;
	public MprisRoot root = null;
//	public MprisTrackList tracklist = null;
	
	public string name { 
		get {
			return "mpris";
		} 
	}
	private void on_bus_acquired(DBusConnection connection, string name) {
		//print("bus acquired\n");
		try {
			root = new MprisRoot();
			connection.register_object("/org/mpris/MediaPlayer2", root);
			player = new MprisPlayer(connection);
			connection.register_object("/org/mpris/MediaPlayer2", player);
		} 
		catch(IOError e) {
			print("%s\n", e.message);
		}
	}

	private void on_name_acquired(DBusConnection connection, string name) {
		//print("name acquired\n");
	}	

	private void on_name_lost(DBusConnection connection, string name) {
		//print("name_lost\n");
	}
	
	public bool init() {
		try {
			owner_id = Bus.own_name(BusType.SESSION,
			                        "org.mpris.MediaPlayer2.xnoise",
			                         GLib.BusNameOwnerFlags.NONE,
			                         on_bus_acquired,
			                         on_name_acquired,
			                         on_name_lost);
		} 
		catch(IOError e) {
			print("%s\n", e.message);
			return false;
		}
		return true;
	}
	
	~Mpris() {
		Bus.unown_name(owner_id);
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
}





[DBus(name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {
	private unowned Xnoise.Main xn;
	
	public MprisRoot() {
		xn = Xnoise.Main.instance;
	}
	
	public bool CanQuit { 
		get {
			return true;
		} 
	}

	public bool CanRaise { 
		get {
			return true;
		} 
	}
	
	public bool HasTrackList {
		get {
			return false;
		}
	}
	public string DesktopEntry { 
		get {
			return "xnoise";
		} 
	}
	
	public string Identity {
		get {
			return "xnoise media player";
		}
	}
	
	public string[] SupportedUriSchemes {
		owned get {
			string[] sa = {"http", "file", "https", "ftp"};
			return sa;
		}
	}
	
	public string[] SupportedMimeTypes {
		owned get {
			string[] sa = {
			   "application/x-ogg",
			   "application/ogg",
			   "video/3gpp",
			   "video/avi",
			   "video/dv",
			   "video/fli",
			   "video/flv",
			   "video/mp4",
			   "video/mp4v-es",
			   "video/mpeg",
			   "video/msvideo",
			   "video/ogg",
			   "video/quicktime",
			   "video/vivo",
			   "video/vnd.divx",
			   "video/vnd.vivo",
			   "video/x-anim",
			   "video/x-avi",
			   "video/x-flc",
			   "video/x-fli",
			   "video/x-flic",
			   "video/x-flv",
			   "video/x-m4v",
			   "video/x-matroska",
			   "video/x-mpeg",
			   "video/x-mpg",
			   "video/x-ms-asf",
			   "video/x-msvideo",
			   "video/x-ms-wm",
			   "video/x-ms-wmv",
			   "video/x-ms-wmx",
			   "video/x-ms-wvx",
			   "video/x-nsv",
			   "video/x-ogm+ogg",
			   "video/x-theora",
			   "video/x-theora+ogg",
			   "audio/x-vorbis+ogg",
			   "audio/x-scpls",
			   "audio/x-mp3",
			   "audio/x-mpeg",
			   "audio/mpeg",
			   "audio/x-mpegurl",
			   "audio/x-flac",
			   "x-content/audio-cdda",
			   "x-content/audio-player"
			};
			return sa;
		}
	}

	public void Quit() {
		xn.quit();
	}
	
	public void Raise() {
		xn.main_window.show_window();
	}
}


[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
	private unowned Main xn;
	private unowned DBusConnection conn;
	
	private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";
	
	private uint send_property_source = 0;
	private uint update_metadata_source = 0;
	private HashTable<string,Variant> changed_properties = null;
	
	private static enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	public MprisPlayer(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
		
		Xnoise.global.notify["track-state"].connect( (s, p) => {
			Variant variant = this.PlaybackStatus;
			queue_property_for_notification("PlaybackStatus", variant);
		});
		
		Xnoise.global.tag_changed.connect(on_tag_changed);
		
		this.xn.gPl.notify["volume"].connect( () => {
			Variant variant = this.xn.gPl.volume;
			queue_property_for_notification("Volume", variant);
		});
		
		Xnoise.global.notify["image-path-large"].connect( () => {
			File f = File.new_for_commandline_arg(Xnoise.global.image_path_large);
			if(f == null)
				return;
			_metadata.insert("mpris:artUrl", f.get_uri());
			
			trigger_metadata_update();
		});
		
		this.xn.gPl.notify["length-time"].connect( () => {
			//print("length-time: %lld\n", ((int64)xn.gPl.length_time/1000));
			if(_metadata.lookup("mpris:length") == null)
				_metadata.insert("mpris:length", ((int64)0));
				
			if(((int64)_metadata.lookup("mpris:length")) != ((int64)xn.gPl.length_time/1000)) {
				_metadata.insert("mpris:length", ((int64)xn.gPl.length_time/1000));
				trigger_metadata_update();
			}
		});
	}
	
	private void trigger_metadata_update() {
		if(update_metadata_source != 0)
			Source.remove(update_metadata_source);

		update_metadata_source = Timeout.add_seconds(1, () => {
			Variant variant = this.PlaybackStatus;
			queue_property_for_notification("Metadata", variant);
			update_metadata_source = 0;
			return false;
		});
	}
	
	private void on_tag_changed(Xnoise.GlobalAccess sender, ref string? newuri, string? tagname, string? tagvalue) {
		switch(tagname){
			case "artist":
				if(tagvalue == null)
					break;
				string[] sa = {};
				sa += tagvalue;
				_metadata.insert("xesam:artist", sa);
				break;
			case "album":
				if(tagvalue == null)
					break;
				string s = tagvalue;
				_metadata.insert("xesam:album", s);
				break;
			case "title":
				if(tagvalue == null)
					break;
				string s = tagvalue;
				_metadata.insert("xesam:title", s);
				break;
			case "genre":
				if(tagvalue == null)
					break;
				string[] sa = {};
				sa += tagvalue;
				_metadata.insert("xesam:genre", sa);
				break;
			default:
				break;
		}
		
		trigger_metadata_update();
	}
	
	private bool send_property_change() {
		
		if(changed_properties == null)
			return false;
		
		var builder             = new VariantBuilder(VariantType.ARRAY);
		var invalidated_builder = new VariantBuilder(new VariantType("as"));
		
		foreach(string name in changed_properties.get_keys()) {
			Variant variant = changed_properties.lookup(name);
			builder.add("{sv}", name, variant);
		}
		
		changed_properties = null;
		
		try {
			conn.emit_signal(null,
			                 "/org/mpris/MediaPlayer2", 
			                 "org.freedesktop.DBus.Properties", 
			                 "PropertiesChanged", 
			                 new Variant("(sa{sv}as)", 
			                             this.INTERFACE_NAME, 
			                             builder, 
			                             invalidated_builder)
			                 );
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
		send_property_source = 0;
		return false;
	}
	
	private void queue_property_for_notification(string property, Variant val) {
		// putting the properties into a hashtable works as akind of event compression
		
		if(changed_properties == null)
			changed_properties = new HashTable<string,Variant>(str_hash, str_equal);
		
		changed_properties.insert(property, val);
		
		if(send_property_source == 0) {
			send_property_source = Idle.add(send_property_change);
		}
	}
	
	public string PlaybackStatus {
		owned get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
			switch(global.track_state) {
				case(GlobalAccess.TrackState.STOPPED):
					return "Stopped";
				case(GlobalAccess.TrackState.PLAYING):
					return "Playing";
				case(GlobalAccess.TrackState.PAUSED):
					return "Paused";
				default:
					return "Stopped";
			}
		}
	}
	
	public string LoopStatus {
		owned get {
			switch(this.xn.main_window.repeatState) {
				case(MainWindow.Repeat.NOT_AT_ALL):
					return "None";
				case(MainWindow.Repeat.SINGLE):
					return "Track";
				case(MainWindow.Repeat.ALL):
					return "Playlist";
				case(MainWindow.Repeat.RANDOM):
					return "Playlist";
				default:
					return "Playlist";
			}
		}
		set {
			switch(value) {
				case("None"):
					this.xn.main_window.repeatState = MainWindow.Repeat.NOT_AT_ALL;
					break;
				case("Track"):
					this.xn.main_window.repeatState = MainWindow.Repeat.SINGLE;
					break;
				case("Playlist"):
					this.xn.main_window.repeatState = MainWindow.Repeat.ALL;
					break;
				default:
					this.xn.main_window.repeatState = MainWindow.Repeat.ALL;
					break;
			}
			Variant variant = value;
			queue_property_for_notification("LoopStatus", variant);
		}
	}
	
	public double Rate {
		get {
			return 1.0;
		}
		set {
		}
	}
	
	private MainWindow.Repeat buffer_repeat_state = MainWindow.Repeat.NOT_AT_ALL;
	public bool Shuffle {
		get {
			if(this.xn.main_window.repeatState == MainWindow.Repeat.RANDOM)
				return true;
			return false;
		}
		set {
			if(value == true) {
				buffer_repeat_state = this.xn.main_window.repeatState;
				this.xn.main_window.repeatState = MainWindow.Repeat.RANDOM;
			}
			else {
				this.xn.main_window.repeatState = buffer_repeat_state;
			}
			Variant variant = value;
			queue_property_for_notification("Shuffle", variant);
		}
	}
	
	private HashTable<string,Variant> _metadata = new HashTable<string,Variant>(str_hash, str_equal);
	public HashTable<string,Variant>? Metadata { //a{sv}
		owned get {
			Variant variant = "1";
			_metadata.insert("mpris:trackid", variant);
			return _metadata;
		}
	}
	
	public double Volume {
		get {
			return this.xn.gPl.volume;
		}
		set {
			if(value < 0.0)
				value = 0.0;
			if(value > 1.0)
				value = 1.0;

			this.xn.gPl.volume = value;
		}
	}
	
	public int64 Position {
		get {
			print("get position\n");
			if(xn.gPl.length_time == 0)
				return -1;
			double pos = xn.gPl.gst_position;
			return (int64)(pos * xn.gPl.length_time / 1000.0);
		}
	}
	
	public double MinimumRate {
		get {
			return 1.0;
		}
	}

	public double MaximumRate {
		get {
			return 1.0;
		}
	}

	public bool CanGoNext {
		get {
			return true;
		}
	}
	
	public bool CanGoPrevious {
		get {
			return true;
		}
	}
	
	public bool CanPlay {
		get {
			return true;
		}
	}
	
	public bool CanPause {
		get {
			return true;
		}
	}
	
	public bool CanSeek {
		get {
			return true;
		}
	}
	
	public bool CanControl {
		get {
			return true;
		}
	}
	
	public signal void Seeked(int64 Position);
	
	public void Next() {
		//print("next\n");
		this.xn.main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
	}
	
	public void Previous() {
		//print("prev\n");
		this.xn.main_window.change_track(Xnoise.ControlButton.Direction.PREVIOUS);
	}
	
	public void Pause() {
		if(global.current_uri == null) {
			string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "")&&(uri != null)) 
				global.current_uri = uri;
		}
		
		global.track_state = GlobalAccess.TrackState.PAUSED;
	}
	
	public void PlayPause() {
		if(global.current_uri == null) {
			string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "")&&(uri != null)) 
				global.current_uri = uri;
		}
		
		if(global.track_state == GlobalAccess.TrackState.PLAYING) {
			global.track_state = GlobalAccess.TrackState.PAUSED;
		}
		else {
			global.track_state = GlobalAccess.TrackState.PLAYING;
		}
	}
	
	public void Stop() {
		this.xn.main_window.stop();
	}
	
	public void Play() {
		if(global.current_uri == null) {
			string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "")&&(uri != null)) 
				global.current_uri = uri;
		}
		
		if(!(global.track_state == GlobalAccess.TrackState.PLAYING)) {
			global.track_state = GlobalAccess.TrackState.PLAYING;
		}
	}
	
	public void Seek(int64 Offset) {
		return;
	}
	
	public void SetPosition(string dobj, int64 Position) {
		print(" set position %lf\n", ((double)Position/(xn.gPl.length_time / 1000.0)));
		xn.gPl.gst_position = ((double)Position/(xn.gPl.length_time / 1000.0));
	}
	
	public void OpenUri(string Uri) {
		//TODO
		return;
	}
}


//[DBus(name = "org.mpris.MediaPlayer2.Tracklist")]
//public class MprisTrackList : GLib.Object {
//	public signal void TrackListChange(int Nb_Tracks);
//	
//	
//	public HashTable<string,Variant>? GetTracksMetadata(int Position) {
//		return null;
//	}
//	
//	public int GetCurrentTrack() {
//		return 0;
//	}
//	
//	public int GetLength() {
//		return 0;
//	}
//	
//	public int AddTrack(string Uri, bool PlayImmediately) { 
//		return 0;
//	}
//	
//	public void DelTrack(int Position) {
//	}
//	
//	public void SetLoop(bool State) {
//	}
//	
//	public void SetRandom(bool State) {
//	}
//}






