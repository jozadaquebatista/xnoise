/* xnoise-mpris-one.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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

// exposes xnoise's player and tracklist controls via dbus using the mpris v1 interface
// refer to 
// http://www.mpris.org/1.0/spec.html

using Gtk;

using Xnoise;
using Xnoise.Services;
using Xnoise.PluginModule;


public class Xnoise.FirstMpris : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private uint owner_id;
	private uint object_id_root;
	private uint object_id_player;
	private uint object_id_tracklist;
	public FirstMprisPlayer player = null;
	public FirstMprisRoot root = null;
	public FirstMprisTrackList tracklist = null;
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
			root = new FirstMprisRoot(connection);
			object_id_root = connection.register_object("/", root);
			player = new FirstMprisPlayer(connection);
			object_id_player = connection.register_object("/Player", player);
			tracklist = new FirstMprisTrackList(connection);
			object_id_tracklist = connection.register_object("/TrackList", tracklist);
		} 
		catch(IOError e) {
			print("%s\n", e.message);
		}
	}

	private void on_name_acquired(DBusConnection connection, string name) {
		//print("name acquired\n");
	}	

	private void on_name_lost(DBusConnection connection, string name) {
		print("name_lost mpris v1\n");
	}
	
	public bool init() {
			owner_id = Bus.own_name(BusType.SESSION,
			                        "org.mpris.xnoise",
			                         GLib.BusNameOwnerFlags.NONE,
			                         on_bus_acquired,
			                         on_name_acquired,
			                         on_name_lost);
		if(owner_id == 0) {
			print("mpris v1 error\n");
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
		this.conn.unregister_object(object_id_tracklist);
		this.conn.unregister_object(object_id_player);
		this.conn.unregister_object(object_id_root);
		Bus.unown_name(owner_id);
		object_id_player = 0;
		object_id_tracklist = 0;
		object_id_root = 0;
		owner_id = 0;
	}
	
	~FirstMpris() {
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
}


[DBus(name = "org.freedesktop.MediaPlayer")]
public class FirstMprisRoot : GLib.Object {
	private unowned Main xn;
	private unowned DBusConnection conn;
	
	public FirstMprisRoot(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
	}
	
	public string Identity() {
		return "xnoise";
	}
	
	public void Quit() {
		xn.quit();
	}
	
	public VersionStruct MprisVersion() {
		var v = VersionStruct();
		v.Major = 1;
		v.Minor = 0;
		return v;
	}
}

public struct VersionStruct {
	uint16 Major;
	uint16 Minor;
}


public struct StatusStruct {
	int playback_state;
	int shuffle_state;
	int repeat_current_state;
	int endless_state;
}

[DBus(name = "org.freedesktop.MediaPlayer")]
public class FirstMprisPlayer : GLib.Object {
	private unowned Main xn;
	private unowned DBusConnection conn;
	private uint trackchange_source_id = 0;
	
	public signal void TrackChange(HashTable<string, Variant?> Metadata);
	public signal void StatusChange(StatusStruct Status);
	public signal void CapsChange(int Capabilities);

	public FirstMprisPlayer(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
		
		global.notify["player-state"].connect( (s, p) => {
			int playbackstate;
			switch(global.player_state) {
				case PlayerState.STOPPED: playbackstate = 2; break;
				case PlayerState.PLAYING: playbackstate = 0; break;
				case PlayerState.PAUSED:  playbackstate = 1; break;
				default: playbackstate = 2; break;
			}
			// incomplete implementation !!
			StatusStruct stat = {
				playbackstate, 0, 0, 0
			};
			Idle.add( () => {
				StatusChange(stat);
				return false;
			});
		});
		
		global.notify["current-uri"].connect( () => {
			if(trackchange_source_id != 0)
				Source.remove(trackchange_source_id);
			trackchange_source_id = Timeout.add_seconds(1, () => { 
				//send delayed so metadata will already be available
				TrackChange(GetMetadata());
				trackchange_source_id = 0;
				return false;
			});
		});
	}
	
	public HashTable<string, Variant> GetMetadata() {
		HashTable<string, Variant> retv = new HashTable<string, Variant>(str_hash, str_equal);
		// For now, this is working for the currently played track, only!
		if(global.current_artist != null && global.current_artist != EMPTYSTRING)
			retv.insert("artist", global.current_artist);
		if(global.current_album != null && global.current_album != EMPTYSTRING)
			retv.insert("album", global.current_album);
		if(global.current_title != null && global.current_title != EMPTYSTRING)
			retv.insert("title", global.current_title);
		if(global.current_location != null && global.current_location != EMPTYSTRING)
			retv.insert("location", global.current_location);
		if(global.current_genre != null && global.current_genre != EMPTYSTRING)
			retv.insert("genre", global.current_genre);
		if(global.current_organization != null && global.current_organization != EMPTYSTRING)
			retv.insert("organization", global.current_organization);
		uint32 len_ms = (uint32)(gst_player.length_nsecs / Gst.MSECOND);
		uint32 len_s  = (uint32)(gst_player.length_nsecs / Gst.SECOND);
		retv.insert("mtime", len_ms);
		retv.insert("time",  len_s );
		if(global.current_uri != null && global.current_uri != EMPTYSTRING)
			retv.insert("location", global.current_uri);
		return retv;
	}
	
	public void Next() {
		global.next();
	}
	
	public void Prev() {
		global.prev();
	}
	
	public void Pause() {
		global.pause();
	}
	
	public void Play() {
		global.play(false);
	}

	public void Repeat(bool rpt) {
	}
	
	public void Stop() {
		global.stop();
	}
	
	public StatusStruct GetStatus() {
		int playbackstate;
		switch(global.player_state) {
			case PlayerState.STOPPED: playbackstate = 2; break;
			case PlayerState.PLAYING: playbackstate = 0; break;
			case PlayerState.PAUSED:  playbackstate = 1; break;
			default: playbackstate = 2; break;
		}
		StatusStruct stat = {
			playbackstate, 0, 0, 0
		};
		return stat;
	}
	
	public int GetCaps() {
		int val = 0;
		
		val |= 1 << 0;
		val |= 1 << 1;
		val |= 1 << 2;
		val |= 1 << 3;
		val |= 1 << 4;
		val |= 1 << 5;
		// val |= 1 << 6;
		
		return val;
	}
	
	public void VolumeSet(int Volume) {
		double v = (double)Volume/100;
		if(v < 0.0)
			v = 0.0;
		if(v > 1.0)
			v = 1.0;
		
		gst_player.volume = v;
	}
	
	public int VolumeGet() {
		double vol = 100.0 * gst_player.volume;
		return (int)vol;
		
	}
	
	public void PositionSet(int Position) {
		if(gst_player.length_nsecs == 0) return; 
		gst_player.position = (double)Position / (double)(gst_player.length_nsecs / 1000000);
	}
	
	public int PositionGet() {
		if(gst_player.length_nsecs == 0) return -1;
		double pos = gst_player.position;
		double rel_pos = pos * gst_player.length_nsecs / 1000000;
		return (int)rel_pos;//buf.to_int();
	}
}

[DBus(name = "org.freedesktop.MediaPlayer")]
public class FirstMprisTrackList : GLib.Object {
	
	private unowned Xnoise.Main xn;
	private unowned DBusConnection conn;
	
	public signal void TrackListChange(int Nb_Tracks);
	
	public FirstMprisTrackList(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
	}
	
	public HashTable<string, Variant> GetMetadata(int Position) {
		HashTable<string, Variant> retv = new HashTable<string, Variant>(str_hash, str_equal);
		// For now, this is working for the currently played track, only!
		//if(global.current_artist != null && global.current_artist != EMPTYSTRING)
		//	retv.insert("artist", global.current_artist);
		//if(global.current_album != null && global.current_album != EMPTYSTRING)
		//	retv.insert("album", global.current_album);
		//if(global.current_title != null && global.current_title != EMPTYSTRING)
		//	retv.insert("title", global.current_title);
		//if(global.current_location != null && global.current_location != EMPTYSTRING)
		//	retv.insert("location", global.current_location);
		//if(global.current_genre != null && global.current_genre != EMPTYSTRING)
		//	retv.insert("genre", global.current_genre);
		//if(global.current_organization != null && global.current_organization != EMPTYSTRING)
		//	retv.insert("organization", global.current_organization);
		return retv;
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

