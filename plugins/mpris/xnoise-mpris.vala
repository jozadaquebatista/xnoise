/* xnoise-mpris.vala
 *
 * Copyright (C) 2010 Andreas Obergrusberger
 * Copyright (C) 2010 - 2012 Jörn Magens
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
using Xnoise.Services;
using Xnoise.PluginModule;


public class Xnoise.Mpris : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private uint owner_id;
	private uint object_id_root;
	private uint object_id_player;
	private uint object_id_tracklist;
	public MprisPlayer player = null;
	public MprisRoot root = null;
	public MprisTrackList tracklist = null;
	private unowned PluginModule.Container _owner;
	private unowned DBusConnection conn;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	
	public string name { 
		get {
			return "mpris";
		} 
	}
	
	private void on_bus_acquired(DBusConnection connection, string name) {
		this.conn = connection;
		//print("bus acquired\n");
		try {
			root = new MprisRoot();
			object_id_root = connection.register_object("/org/mpris/MediaPlayer2", root);
			player = new MprisPlayer(connection);
			object_id_player = connection.register_object("/org/mpris/MediaPlayer2", player);
			tracklist = new MprisTrackList(connection);
			object_id_tracklist = connection.register_object("/org/mpris/MediaPlayer2", tracklist);
		} 
		catch(IOError e) {
			print("%s\n", e.message);
		}
	}

	private void on_name_acquired(DBusConnection connection, string name) {
		//print("name acquired\n");
	}	

	private void on_name_lost(DBusConnection connection, string name) {
		print("name_lost\n");
	}
	
	public bool init() {
			owner_id = Bus.own_name(BusType.SESSION,
			                        "org.mpris.MediaPlayer2.xnoise",
			                         GLib.BusNameOwnerFlags.NONE,
			                         on_bus_acquired,
			                         on_name_acquired,
			                         on_name_lost);
		if(owner_id == 0) {
			print("mpris error\n");
			return false;
		}
		owner.sign_deactivated.connect(clean_up);
		return true;
	}
	
	public void uninit() {
		clean_up();
	}

	private void clean_up() {
		if(owner_id == 0)
			return;
		//this.conn.unregister_object(object_id_player);
		//this.conn.unregister_object(object_id_tracklist);
		//this.conn.unregister_object(object_id_root);
		Bus.unown_name(owner_id);
		object_id_player = 0;
		object_id_tracklist =0;
		object_id_root = 0;
		owner_id = 0;
	}
	
	~Mpris() {
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
}





[DBus(name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {
	private unowned Xnoise.Main xn;
	
	public MprisRoot() {
		xn = Xnoise.Main.instance;
	}
	
	public bool CanQuit { get { return true; } }

	public bool CanRaise { get { return true; } }
	
	public bool HasTrackList { get { return false; } }
	
	public string DesktopEntry { 
		owned get {
			return "xnoise";
		} 
	}
	
	public string Identity {
		owned get {
			return "xnoise media player";
		}
	}
	
	public string[] SupportedUriSchemes {
		owned get {
			string[] sa = {"http", "file", "https", "ftp", "mms"};
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
		main_window.show_window();
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
	
	private enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	public MprisPlayer(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
		
		Xnoise.global.notify["player-state"].connect( (s, p) => {
			//print("player state queued for mpris: %s\n", this.PlaybackStatus);
			Variant variant = this.PlaybackStatus;
			queue_property_for_notification("PlaybackStatus", variant);
		});
		
		Xnoise.global.tag_changed.connect(on_tag_changed);
		
		gst_player.notify["volume"].connect( () => {
			Variant variant = gst_player.volume;
			queue_property_for_notification("Volume", variant);
		});
		
		Xnoise.global.notify["image-path-large"].connect( () => {
			string? s = Xnoise.global.image_path_large;
			if(s == null) {
				_metadata.insert("mpris:artUrl", EMPTYSTRING);
			}
			else {
				File f = File.new_for_commandline_arg(s);
				if(f != null)
					_metadata.insert("mpris:artUrl", f.get_uri());
				else
					_metadata.insert("mpris:artUrl", EMPTYSTRING);
			}
			trigger_metadata_update();
		});
		
		gst_player.notify["length-time"].connect( () => {
			//print("length-time: %lld\n", (int64)(gst_player.length_time / (int64)1000));
			if(_metadata.lookup("mpris:length") == null) {
				_metadata.insert("mpris:length", ((int64)0));
				trigger_metadata_update();
				return;
			}
			
			int64 length_val = (int64)(gst_player.length_time / (int64)1000);
			if(((int64)_metadata.lookup("mpris:length")) != length_val) { 
				_metadata.insert("mpris:length", length_val);
				trigger_metadata_update();
			}
		});
	}
	
	private void trigger_metadata_update() {
		if(update_metadata_source != 0)
			Source.remove(update_metadata_source);

		update_metadata_source = Timeout.add(300, () => {
			//print("trigger_metadata_update %s\n", global.current_artist);
			Variant variant = _metadata;//this.PlaybackStatus;
			queue_property_for_notification("Metadata", variant);
			update_metadata_source = 0;
			return false;
		});
	}
	
	private void on_tag_changed(Xnoise.GlobalAccess sender, ref string? newuri, string? tagname, string? tagvalue) {
		//print("on_tag_changed newusi: %s,tagname: %s,tagvalue: %s \n",newuri,tagname, tagvalue);
		switch(tagname){
			case "artist":
				string[] sa = {};
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				sa += tagvalue;
				_metadata.insert("xesam:artist", sa);
				break;
			case "album":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string s = tagvalue;
				_metadata.insert("xesam:album", s);
				break;
			case "title":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string s = tagvalue;
				_metadata.insert("xesam:title", s);
				break;
			case "genre":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string[] sa = {};
				sa += tagvalue;
				_metadata.insert("xesam:genre", sa);
				break;
			default:
				return;
		}
		trigger_metadata_update();
	}
	
	private bool send_property_change() {
		
		if(changed_properties == null)
			return false;
		
		var builder             = new VariantBuilder(VariantType.DICTIONARY);
		var invalidated_builder = new VariantBuilder(new VariantType("as"));
		
		foreach(string name in changed_properties.get_keys()) {
			Variant variant = changed_properties.lookup(name);
			//print("%s changed\n", name);
			builder.add("{sv}", name, variant);
		}
		
		changed_properties = null;
		
		Variant[] arg_tuple = {
			new Variant("s", this.INTERFACE_NAME),
			builder.end(),
			invalidated_builder.end()
		};
		Variant args = new Variant.tuple(arg_tuple);
		//print("tupletypestring: %s\n", tupv.get_type_string());
		try {
			conn.emit_signal(null,
			                 "/org/mpris/MediaPlayer2", 
			                 "org.freedesktop.DBus.Properties", 
			                 "PropertiesChanged", 
			                 args
			                 );
		}
		catch(Error e) {
			print("Error emmitting PropertiesChanged dbus signal: %s\n", e.message);
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
			send_property_source = Timeout.add(100, send_property_change);
		}
	}
	
	public string PlaybackStatus {
		owned get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
			switch(global.player_state) {
				case(PlayerState.STOPPED):
					return "Stopped";
				case(PlayerState.PLAYING):
					return "Playing";
				case(PlayerState.PAUSED):
					return "Paused";
				default:
					return "Stopped";
			}
		}
	}
	
	public string LoopStatus {
		owned get {
			switch(main_window.repeatState) {
				case(MainWindow.PlayerRepeatMode.NOT_AT_ALL):
					return "None";
				case(MainWindow.PlayerRepeatMode.SINGLE):
					return "Track";
				case(MainWindow.PlayerRepeatMode.ALL):
					return "Playlist";
				case(MainWindow.PlayerRepeatMode.RANDOM):
					return "Playlist";
				default:
					return "Playlist";
			}
		}
		set {
			switch(value) {
				case("None"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.NOT_AT_ALL;
					break;
				case("Track"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.SINGLE;
					break;
				case("Playlist"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.ALL;
					break;
				default:
					main_window.repeatState = MainWindow.PlayerRepeatMode.ALL;
					break;
			}
			Variant variant = value;
			queue_property_for_notification("LoopStatus", variant);
		}
	}
	
	public double Rate { get { return 1.0; } set {} }
	
	private MainWindow.PlayerRepeatMode buffer_repeat_state = MainWindow.PlayerRepeatMode.NOT_AT_ALL;
	public bool Shuffle {
		get {
			if(main_window.repeatState == MainWindow.PlayerRepeatMode.RANDOM)
				return true;
			return false;
		}
		set {
			if(value == true) {
				buffer_repeat_state = main_window.repeatState;
				main_window.repeatState = MainWindow.PlayerRepeatMode.RANDOM;
			}
			else {
				main_window.repeatState = buffer_repeat_state;
			}
			Variant variant = value;
			queue_property_for_notification("Shuffle", variant);
		}
	}
	
	private HashTable<string,Variant> _metadata = new HashTable<string,Variant>(str_hash, str_equal);
	public HashTable<string,Variant> Metadata { //a{sv}
		owned get {
			Variant variant = "1";
			_metadata.insert("mpris:trackid", variant); //dummy
			return _metadata;
		}
	}
	
	public double Volume {
		get {
			return gst_player.volume;
		}
		set {
			if(value < 0.0)
				value = 0.0;
			if(value > 1.0)
				value = 1.0;

			gst_player.volume = value;
		}
	}
	
	public int64 Position {
		get {
			//print("get position\n");
			if(gst_player.length_time == 0)
				return -1;
			double pos = gst_player.gst_position;
			return (int64)(pos * gst_player.length_time / 1000.0);
		}
	}
	
	public double MinimumRate { get { return 1.0; } }

	public double MaximumRate { get { return 1.0; } }

	public bool CanGoNext     { get { return true; } }
	
	public bool CanGoPrevious { get { return true; } }
	
	public bool CanPlay       { get { return true; } }
	
	public bool CanPause      { get { return true; } }
	
	public bool CanSeek       { get { return true; } }
	
	public bool CanControl    { get { return true; } }
	
	public signal void Seeked(int64 Position);
	
	public void Next() {
		//print("next\n");
		global.next();
	}
	
	public void Previous() {
		//print("prev\n");
		global.prev();
	}
	
	public void Pause() {
		//print("pause\n");
		global.pause();
	}
	
	public void PlayPause() {
		//print("playpause\n");
		global.play(true);
	}
	
	public void Stop() {
		//print("stop\n");
		global.stop();
	}
	
	public void Play() {
		//print("play\n");
		global.play(false);
	}
	
	public void Seek(int64 Offset) {
		//print("seek\n");
		return;
	}
	
	public void SetPosition(string dobj, int64 Position) {
		print(" set position %lf\n", ((double)Position/(gst_player.length_time / 1000.0)));
		gst_player.gst_position = ((double)Position/(gst_player.length_time / 1000.0));
	}
	
	public void OpenUri(string Uri) {
		print("OpenUri %s\n",Uri);
		xn.add_track_to_gst_player(Uri);
	}
}


[DBus(name = "org.mpris.MediaPlayer2.Tracklist")]
public class MprisTrackList : GLib.Object {
	private unowned Xnoise.Main xn;
	private unowned DBusConnection conn;
	
	public signal void TrackListChange(int Nb_Tracks);
	
	public MprisTrackList(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
	}
	
	public HashTable<string,Variant>? GetTracksMetadata(int Position) {
		print("GetTracksMetadata %d\n",Position); 
		return null;
	}

	public int AddTrack(string Uri, bool PlayImmediately) {
		print("AddTrack %s %b\n",Uri,PlayImmediately); 
		return 0;
	}

	//RemoveTrack
	//GoTo
	
	
	public int GetCurrentTrack() {
		print("GetCurrentTrack\n"); 
		return 0;
	}
	
	public int GetLength() {
		print("GetLength\n"); 
		return 0;
	}
	
	public void DelTrack(int Position) {
		print("DelTrack\n"); 
	}
	
	public void SetLoop(bool State) {
		print("SetLoop\n"); 
	}
	
	public void SetRandom(bool State) {
		print("SetRandom\n"); 
	}
}
