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
		print("bus acquired\n");
		try {
//			conn = connection;
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
		print("name acquired\n");
	}	

	private void on_name_lost(DBusConnection connection, string name) {
		print("name_lost\n");
	}
	
	public bool init() {
		try {
			uint owner_id = Bus.own_name(BusType.SESSION,
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
	
	public bool CanQuit { 
		get {
			return false;
		} 
	}

	public bool CanRaise { 
		get {
			return false;
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
		print("mpris interface requested quit.\n");
		//TODO
	}
	
	public void Raise() {
		print("mpris interface requested raise.\n");
		//TODO
	}
}

//[DBus(name = "org.freedesktop.DBus.Properties")]
//public interface Notifier : GLib.Object {
////	public DBusConnection conn;
////	public HashTable<string,Variant>  player_property_changes = null;
////	private string[] invalidated = {};
//	[CCode (array_length = false, array_null_terminated = true)]
//	string[] invalidated = {};
//	
//	public signal void PropertiesChanged(string interface_name, HashTable<string,Variant> changed_properties, string[] inv);

////	private bool property_changed() {
////		if(player_property_changes == null)
////			return false;
////		var ht = new HashTable<string,Variant>(str_hash, str_equal);
////		
////		foreach(string s in player_property_changes.get_keys()) {
////			ht.insert(s, player_property_changes.lookup(s));
////		}
////print("property_change#3\n");
////		try {
////			//bool GLib.DBusConnection.emit_signal (string? destination_bus_name, string object_path, string interface_name, string signal_name, GLib.Variant parameters)
////			
//////			Variant v = new Variant("(sa{sv}^as)", "org.mpris.MediaPlayer2.Player", ht, invalidated);
////print("property_change#4\n");
//////			conn.emit_signal(null, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged", "org.mpris.MediaPlayer2.Player", ht, invalidated); //parameters);
////			PropertiesChanged("org.mpris.MediaPlayer2.Player", ht, invalidated);
////print("property_change#5\n");
////		}
////		catch(IOError e) {
////			print("mpris: %s\n", e.message);
////		}
////print("property_change#6\n");
////		player_property_emit_id = 0;
////		player_property_changes = null;
////		return false;
////	}

////	private uint player_property_emit_id;
////	protected void add_player_property_change(string property, Variant val) {
////		if(player_property_changes == null) {
////			player_property_changes = new HashTable<string,Variant>(str_hash, str_equal);
////		}
////		print("add_player_property_change#4 %s\n", (string)property);
////			player_property_changes.insert(property,val);
////		
////		if(player_property_emit_id == 0) {
////			player_property_emit_id = Idle.add(property_changed);
////		}
////	}
//}

[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
	private unowned Main xn;
	private DBusConnection conn;

	public signal void TestSignPlayer(string ls);
	private static enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	public MprisPlayer(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
		Xnoise.global.notify["track-state"].connect( () => {
			//send_property_change("track-state");
		});
	}

	private void send_property_change(string p) {
		if(p != "track-state") 
			return;
		
		var builder = new VariantBuilder(VariantType.ARRAY);
		var invalid_builder = new VariantBuilder(new VariantType("as"));

		if(p == "track-state") {
			Variant i = this.PlaybackStatus;
			print("now add %s\n", this.PlaybackStatus);
			builder.add ("{sv}", "PlaybackStatus", i);
		}

		try {
			conn.emit_signal(null, 
			                 "/org/mpris/MediaPlayer2", 
			                 "org.freedesktop.DBus.Properties", 
			                 "PropertiesChanged", 
			                 new Variant("(sa{sv}as)", 
			                             "org.mpris.MediaPlayer2.Player", 
			                             builder, 
			                             invalid_builder)
			                 );
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
	}
	
	public string PlaybackStatus {
		get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
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
		get {
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
		}
	}
	
	public HashTable<string,Variant>? Metadata { //a{sv}
		owned get {
			var ht = new HashTable<string,Variant>(direct_hash, direct_equal);
			Variant v = "1";
			ht.insert("mpris:trackid", v);
			return ht;
		}
	}
	
	public double Volume {
		get {
			return this.xn.gPl.volume;
		}
		set {
			if(value < 0.0)
				value = 0.0;
			this.xn.gPl.volume = value;
		}
	}
	
	public int32 Position {
		get {
			if(xn.gPl.length_time == 0)
				return -1;
			double pos = xn.gPl.gst_position;
//			double rel_pos = 
			return (int32)(pos * xn.gPl.length_time / 1000000);
//			string buf = rel_pos.to_string();
//			return buf.to_int64();
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
			return false;
		}
	}
	
	public bool CanControl {
		get {
			return true;
		}
	}
	public signal void Seeked(int64 Position);
//	public signal void TrackChange(HashTable<string, Value?> Metadata);
//	public signal void StatusChange(StatusStruct Status);
//	public signal void CapsChange(int Capabilities);

	public void Next() {
		print("next\n");
		this.xn.main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
	}
	
	public void Previous() {
		print("prev\n");
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
		//TODO
	}
	
	public void OpenUri(string Uri) {
		//TODO
		return;
	}
	
//	public StatusStruct GetStatus() {
//		var ss = StatusStruct();
//		//ss.playback_state = 
//		return ss;
//	}
	
}

//public struct StatusStruct {
//	int playback_state;
//	int shuffle_state;
//	int repeat_current_state;
//	int endless_state;
//}



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







//			var ht = new HashTable<string,Variant>(str_hash, str_equal);
//			string[] inv = {};
//			inv += "";
//			string statestring;
//			switch(global.track_state) {
//				case(GlobalAccess.TrackState.STOPPED):
//					statestring = "Stopped";
//					break;
//				case(GlobalAccess.TrackState.PLAYING):
//					statestring = "Playing";
//					break;
//				case(GlobalAccess.TrackState.PAUSED):
//					statestring = "Paused";
//					break;
//				default:
//					statestring = "Stopped";
//					break;
//			}
//			ht.insert("PlaybackStatus", statestring);
			 
//			Variant htv = ht;
//			Variant sav = inv;
//			Variant[] contents =  { new GLib.Variant.string("org.mpris.MediaPlayer2.Player"), htv, sav };
//			Variant variant = new Variant.tuple(contents);

//			conn.emit_signal(null,
//						 "/org/mpris/MediaPlayer2",
//						 "org.freedesktop.DBus.Properties",
//						 "PropertiesChanged",
//						  variant);







