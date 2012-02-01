/* xnoise-dbus.vala
 *
 * Copyright (C) 2012 Jörn Magens
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

using Xnoise;
using Xnoise.Services;


public class Xnoise.Dbus : GLib.Object {
	private uint owner_id;
	private uint object_id_service;
	public PlayerDbusService service = null;
	private unowned DBusConnection conn;

	
	private void on_bus_acquired(DBusConnection connection, string name) {
		this.conn = connection;
		//print("bus acquired\n");
		try {
			service = new PlayerDbusService(connection);
			object_id_service = connection.register_object("/PlayerEngine", service);
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
	
	public Dbus() {
		owner_id = Bus.own_name(BusType.SESSION,
		                        "org.gtk.xnoise.PlayerEngine",
		                         GLib.BusNameOwnerFlags.NONE,
		                         on_bus_acquired,
		                         on_name_acquired,
		                         on_name_lost);
		if(owner_id == 0) {
			print("mpris error\n");
		}
	}
	
	~Dbus() {
		clean_up();
	}

	private void clean_up() {
		if(owner_id == 0)
			return;
		Bus.unown_name(owner_id);
		owner_id = 0;
	}
}





[DBus(name = "org.gtk.xnoise.PlayerEngine")]
public class PlayerDbusService : GLib.Object {
	private unowned Xnoise.Main xn;
	
	private unowned DBusConnection conn;
	
	private const string INTERFACE_NAME = "org.gtk.xnoise";
	
	private uint send_property_source = 0;
	private uint update_metadata_source = 0;
	private HashTable<string,Variant> changed_properties = null;
	
	private enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	public PlayerDbusService(DBusConnection conn) {
		this.conn = conn;
		this.xn = Main.instance;
		
		Xnoise.global.notify["player-state"].connect( (s, p) => {
			//print("player state queued for  %s\n", this.PlaybackStatus);
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
				_metadata.insert("artUrl", EMPTYSTRING);
			}
			else {
				File f = File.new_for_commandline_arg(s);
				if(f != null)
					_metadata.insert("artUrl", f.get_uri());
				else
					_metadata.insert("artUrl", EMPTYSTRING);
			}
			trigger_metadata_update();
		});
		
		gst_player.notify["length-time"].connect( () => {
			//print("length-time: %lld\n", (int64)(gst_player.length_time / (int64)1000));
			if(_metadata.lookup("length") == null) {
				_metadata.insert("length", ((int64)0));
				trigger_metadata_update();
				return;
			}
			
			int64 length_val = (int64)(gst_player.length_time / (int64)1000);
			if(((int64)_metadata.lookup("length")) != length_val) { 
				_metadata.insert("length", length_val);
				trigger_metadata_update();
			}
		});
	}
	
	private void trigger_metadata_update() {
		if(update_metadata_source != 0)
			Source.remove(update_metadata_source);

		update_metadata_source = Timeout.add(120, () => {
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
				_metadata.insert("artist", sa);
				break;
			case "album":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string s = tagvalue;
				_metadata.insert("album", s);
				break;
			case "title":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string s = tagvalue;
				_metadata.insert("title", s);
				break;
			case "genre":
				if(tagvalue == null)
					tagvalue = EMPTYSTRING;
				string[] sa = {}; // genre can be an array
				sa += tagvalue;
				_metadata.insert("genre", sa);
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
			                 "/org/gtk/xnoise", 
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
	
	public void Quit() {
		xn.quit();
	}
	
	public void Raise() {
		main_window.show_window();
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
	
	public string RepeatStatus {
		owned get {
			switch(main_window.repeatState) {
				case(MainWindow.PlayerRepeatMode.NOT_AT_ALL):
					return "None";
				case(MainWindow.PlayerRepeatMode.SINGLE):
					return "SingleTrack";
				case(MainWindow.PlayerRepeatMode.ALL):
					return "TracklistAll";
				case(MainWindow.PlayerRepeatMode.RANDOM):
					return "TracklistRandom";
				default:
					return "None";
			}
		}
		set {
			switch(value) {
				case("None"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.NOT_AT_ALL;
					break;
				case("SingleTrack"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.SINGLE;
					break;
				case("TracklistAll"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.ALL;
					break;
				case("TracklistRandom"):
					main_window.repeatState = MainWindow.PlayerRepeatMode.RANDOM;
					break;
				default:
					main_window.repeatState = MainWindow.PlayerRepeatMode.NOT_AT_ALL;
					break;
			}
			Variant variant = value;
			queue_property_for_notification("LoopStatus", variant);
		}
	}
	
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

	public int64 Length {
		get {
			if(gst_player.length_time == 0)
				return -1;
			else
				return (int64)(gst_player.length_time / Gst.SECOND);
		}
	}
	
	public int64 Position {
		get {
			if(gst_player.length_time == 0)
				return -1;
			return (int64)(gst_player.gst_position * gst_player.length_time / Gst.SECOND);
		}
		set {
			if(gst_player.length_time == 0)
				return;
			if(value < 0)
				value = 0;
			gst_player.gst_position = (double)((double)value / (double)(gst_player.length_time / Gst.SECOND));
		}
	}
	
	
	public void Next() {
		global.next();
	}
	
	public void Previous() {
		global.prev();
	}
	
	public void Pause() {
		global.pause();
	}
	
	public void TogglePlaying() {
		global.play(true);
	}
	
	public void Stop() {
		global.stop();
	}
	
	public void Play() {
		global.play(false);
	}
	
	public void OpenUri(string Uri) {
		xn.add_track_to_gst_player(Uri);
	}
}


