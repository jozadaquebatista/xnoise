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
using DBus;
using Xnoise;

public class Xnoise.Mpris : GLib.Object, IPlugin {
	public Main xn { get; set; }
	public Connection conn;
	public dynamic DBus.Object bus;
	
	public MprisPlayer player = null;
	public MprisRoot root = null;
	public MprisTrackList tracklist = null;
	
	public string name { 
		get {
			return "mpris";
		} 
	}

	public bool init() {
		try {
			// connect to the session bus
			conn = DBus.Bus.get(DBus.BusType.SESSION);
			if(conn == null) return false;
			
			bus = conn.get_object("org.freedesktop.DBus",
			                      "/org/freedesktop/DBus",
			                      "org.freedesktop.DBus");
			if(bus == null) return false;
			
			// request our name
			uint request_name_result = bus.request_name("org.mpris.MediaPlayer2.xnoise", (uint)0);
			//print("request_name_result %d\n", (int)request_name_result);
			// if we got our name setup / /Player and /TrackList objects
			if(request_name_result == DBus.RequestNameReply.PRIMARY_OWNER) {
				
				root = new MprisRoot();
				conn.register_object("/org/mpris/MediaPlayer2", root);
				
				 player = new MprisPlayer();
				conn.register_object("/org/mpris/MediaPlayer2/Player", player);
				
//				tracklist = new MprisTrackList(); 
//				conn.register_object("/TrackList", tracklist);
			}
			else {
				print("mpris: cannot acquire name org.mpris.MediaPlayer2.xnoise in session bus\n");
			}
		} 
		catch(GLib.Error e) {
			stderr.printf("mpris: failed to setup dbus interface: %s\n", e.message);
			return false;
		}
		
		return true;
	}
	
	~Mpris() {
		RawError error = RawError();
		bus.release_name("org.mpris.MediaPlayer2.xnoise");//FIXME: This is giving warnings
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
	
//	public VersionStruct MprisVersion() {
//		var v = VersionStruct();
//		v.Major = 2;
//		v.Minor = 0;
//		return v;
//	}
}

//public struct VersionStruct {
//	uint16 Major;
//	uint16 Minor;
//}



[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
	private unowned Main xn;
	private static enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}	
	public string PlaybackStatus {
		get {
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
	
	public HashTable<string, Value?>? Metadata { //a{sv}
		owned get {
			var ht = new HashTable<string, Value?>(direct_hash, direct_equal);
			Value v = "1";
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

	public MprisPlayer() {
		this.xn = Main.instance;
	}

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



[DBus(name = "org.mpris.MediaPlayer2.Tracklist")]
public class MprisTrackList : GLib.Object {
	public signal void TrackListChange(int Nb_Tracks);
	
	
	public HashTable<string, Value?>? GetTracksMetadata(int Position) {
		return null;
	}
	
	public int GetCurrentTrack() {
		return 0;
	}
	
	public int GetLength() {
		return 0;
	}
	
	public int AddTrack(string Uri, bool PlayImmediately) { 
		return 0;
	}
	
	public void DelTrack(int Position) {
	}
	
	public void SetLoop(bool State) {
	}
	
	public void SetRandom(bool State) {
	}
}















