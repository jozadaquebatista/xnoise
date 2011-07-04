/* xnoise-misc.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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


// XNOISES' GENERAL NAMESPACE FUNCTIONS

namespace Xnoise {
	public static Params par = null;
	public static GlobalAccess global = null;
	public static UserInfo userinfo = null;
	public static Worker db_worker = null;
	public static Worker io_worker = null;
	public static MediaImporter media_importer = null;
	public static ItemHandlerManager item_handler_manager = null;
	public static ItemConverter item_converter = null;
	public static MainContext mc;
	public static DbBrowser db_browser;
	public static DbWriter db_writer;
	public static GstPlayer gst_player;
	public static PluginLoader plugin_loader;
	public static TrayIcon tray_icon;
	public static MainWindow main_window;
	public static TrackList tl;
	public static TrackListModel tlm;

	/*
	 * This function is used to create static instances of Params
	 * and GlobalInfo in the xnoise namespace.
	 */
	public static void initialize(out bool is_first_start) {
		is_first_start = false;
		
		// ITEM STUFF
		item_handler_manager = new ItemHandlerManager();
		item_converter = new ItemConverter();
		media_importer = new MediaImporter();
		
		// WORKERS
		db_worker = new Worker(MainContext.default());
		io_worker = new Worker(MainContext.default());
		
		
		//GLOBAL ACCESS
		if(global == null)
			global = new GlobalAccess();
		
		// PARAMS
		File xnoise_home = File.new_for_path(global.settings_folder);
		File xnoiseini = null;
		xnoiseini = xnoise_home.get_child("db.sqlite");
		if(!xnoiseini.query_exists(null)) {
			is_first_start = true;
		}
		
		if(par == null)
			par = new Params();
		
		// DATABASE
		check_database_and_tables(ref is_first_start);
		
		try {
			db_browser = new DbBrowser();
			db_writer  = new DbWriter();
		}
		catch(DbError e) {
			print("%s", e.message);
			return;
		}
		
		// PLAYER
		gst_player = new GstPlayer();
		
		
		// PLUGINS
		plugin_loader = new PluginLoader();
		
		
		// STATIC WIDGETS
		tlm = new TrackListModel();
		tl = new TrackList();
		main_window = new MainWindow();
		tray_icon = new TrayIcon();
		
	}

	private static void check_database_and_tables(ref bool is_first_start) {
		DbCreator.check_tables(ref is_first_start);
	}

	public static string get_stream_uri(string playlist_uri) {
		//print("playlist_uri: %s\n", playlist_uri);
		var file = File.new_for_uri(playlist_uri);
		DataInputStream in_stream = null;
		string outval = "";
		
		try{
			in_stream = new DataInputStream(file.read(null));
		}
		catch(Error e) {
			print("Error: %s\n", e.message);
		}
		string line;
		string[] keyval;
		try {
			while ((line = in_stream.read_line(null, null))!=null) {
				//print("line: %s\n", line);
				keyval = line.split ("=", 2);
				if (keyval[0] == "File1") {
					outval = keyval[1];
					return outval;
				}
			}
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
		return outval;
	}
}



// PROJECT WIDE USED STRUCTS, INTERFACES AND ENUMS

// ENUMS

//public enum Xnoise.ItemType { // used in various places
//	UNKNOWN = 0,
//	AUDIO,
//	VIDEO,
//	STREAM,
//	PLAYLISTFILE
//}

public enum Xnoise.TrackListNoteBookTab { // used in various places
	TRACKLIST = 0,
	VIDEO,
	LYRICS
}

public enum Gst.StreamType {
	UNKNOWN = 0,
	AUDIO   = 1,
	VIDEO   = 2
}

public enum Xnoise.PlayerState {
	STOPPED = 0,
	PLAYING,
	PAUSED
}



public class Xnoise.RemoteSchemes {
	// remote types for data
	private string[] _list = {
		"http", 
		"https", 
		"ftp"
	};

	public string[] list {
		get {
			return _list;
		}
	}
	
	// syntax support for 'in'
	public bool contains(string location) {
		foreach(unowned string s in _list) {
			if(location == s) return true;
		}
		return false;
	}
}

public class Xnoise.LocalSchemes {
	// locally mounted types for data
	private string[] _list = {
		"file", 
		"dvd", 
		"cdda"
	};

	public string[] list {
		get {
			return _list;
		}
	}
	
	// syntax support for 'in'
	public bool contains(string location) {
		foreach(unowned string s in _list) {
			if(location == s) return true;
		}
		return false;
	}
}


// STRUCTS

/**
 * This struct is used to move around certain streams information
 */
public struct Xnoise.StreamData { // meta information structure
	public string name;
	public string uri;
}

/**
 * This struct is used to move around certain media information
 */
//public struct Xnoise.Item {
//	public string name;
//	public int id;
//	public ItemType mediatype;
//}

public struct Xnoise.DndData { // drag data (mediabrowser -> tracklist)
	public int32 db_id;
	public ItemType mediatype;
}


// INTERFACES

// this is used by mediakeys plugin. Only works if the interface  is in xnoise itself 
[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface Xnoise.GnomeMediaKeys : GLib.Object {
	public abstract void GrabMediaPlayerKeys(string application, uint32 time) throws IOError;
	public abstract void ReleaseMediaPlayerKeys(string application) throws IOError;
	public signal void MediaPlayerKeyPressed(string application, string key);
}


