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
	//public static Timer t1;
	//public static Timer t2;
	public static Params par = null;
	public static GlobalAccess global = null;
	public static UserInfo userinfo = null;
	public static Worker worker = null;
	public static MediaImporter media_importer = null;
	public static ItemHandlerManager item_handler_manager = null;
	public static MainContext mc;
	/*
	 * This function is used to create static instances of Params
	 * and GlobalInfo in the xnoise namespace.
	 */
	public static void initialize(out bool is_first_start) {
		is_first_start = false;
		
		item_handler_manager = new ItemHandlerManager();
		
		media_importer = new MediaImporter();
		
		// setup worker with reference to default context
		worker = new Worker(MainContext.default());
		
		if(global == null)
			global = new GlobalAccess();
		
		File xnoise_home = File.new_for_path(global.settings_folder);
		File xnoiseini = null;
		xnoiseini = xnoise_home.get_child("db.sqlite");
		if(!xnoiseini.query_exists(null)) {
			is_first_start = true;
		}

		if(par == null)
			par = new Params();
		//t1 = new Timer();
		//t2 = new Timer();
	}
	
	private static string check_album_name(string? artistname, string? albumname) {
		if(albumname == null || albumname == "")
			return "";
		if(artistname == null || artistname == "")
			return "";
		
		string _artistname = artistname.strip().down();
		string _albumname = albumname.strip().down();
		string[] self_a = {
			"self titled",
			"self-titled",
			"s/t"
		};
		string[] media_a = {
			"cd",
			"ep",
			"7\"",
			"10\"",
			"12\"",
			"7inch",
			"10inch",
			"12inch"
		};
		foreach(string selfs in self_a) {
			if(_albumname == selfs) 
				return _artistname;
			foreach(string media in media_a) {
				if(_albumname == (selfs + " " + media)) 
					return _artistname;
			}
		}
		return _albumname;
	}

	public static string escape_album_for_local_folder_search(string _artist, string? album_name) {
		// transform the name to match the naming scheme
		string artist = _artist;
		string tmp = "";
		if(album_name == null)
			return tmp;
		if(artist == null)
			return tmp;
		
		tmp = check_album_name(artist, album_name);
		
		try {
			var r = new GLib.Regex("\n");
			tmp = r.replace(tmp, -1, 0, "_");
			r = new GLib.Regex(" ");
			tmp = r.replace(tmp, -1, 0, "_");
		}
		catch(RegexError e) {
			print("%s\n", e.message);
			return album_name;
		}
		if(tmp.contains("/")) {
			string[] a = tmp.split("/", 20);
			tmp = "";
			foreach(string s in a) {
				tmp = tmp + s;
			}
		}
		return tmp;
	}
	
	public static string escape_for_local_folder_search(string? value) {
		// transform the name to match the naming scheme
		string tmp = "";
		if(value == null)
			return tmp;
		
		try {
			var r = new GLib.Regex("\n");
			tmp = r.replace(value, -1, 0, "_");
			r = new GLib.Regex(" ");
			tmp = r.replace(tmp, -1, 0, "_");
		}
		catch(RegexError e) {
			print("%s\n", e.message);
			return value;
		}
		if(tmp.contains("/")) {
			string[] a = tmp.split("/", 20);
			tmp = "";
			foreach(string s in a) {
				tmp = tmp + s;
			}
		}
		return tmp;
	}

	private string[] characters_not_used_in_comparison__escaped = null;
	
	public static string prepare_for_comparison(string? value) {
		// transform strings to make it easier to compare them
		if(value == null)
			return "";
		
		if(characters_not_used_in_comparison__escaped == null) {
			string[] characters_not_used_in_comparison = {
			   "/", 
			   " ", 
			   "\\", 
			   ".", 
			   ",", 
			   ";", 
			   ":", 
			   "\"", 
			   "'", 
			   "'", 
			   "`", 
			   "´", 
			   "!", 
			   "_", 
			   "+", 
			   "*", 
			   "#", 
			   "?", 
			   "(", 
			   ")", 
			   "[", 
			   "]", 
			   "{", 
			   "}", 
			   "&", 
			   "§", 
			   "$", 
			   "%", 
			   "=", 
			   "ß", 
			   "ä", 
			   "ö", 
			   "ü", 
			   "|", 
			   "µ", 
			   "@", 
			   "~"
			};
			
			characters_not_used_in_comparison__escaped = {};
			foreach(unowned string s in characters_not_used_in_comparison)
				characters_not_used_in_comparison__escaped += GLib.Regex.escape_string(s);
		}
		string result = value != null ? value.strip().down() : "";
		try {
			foreach(unowned string s in characters_not_used_in_comparison__escaped) {
				var regex = new GLib.Regex(s);
				result = regex.replace_literal(result, -1, 0, "");
			}
		}
		catch (GLib.RegexError e) {
			GLib.assert_not_reached ();
		}
		return result;
	}

	public static string prepare_for_search(string? val) {
		// transform strings to improve searches
		if(val == null)
			return "";
		
		string result = val.strip().down();
		
		result = remove_linebreaks(result);
		
		result.replace("_", " ");
		result.replace("%20", " ");
		result.replace("@", " ");
		result.replace("<", " ");
		result.replace(">", " ");
		//		if(result.contains("<")) 
		//			result = result.substring(0, result.index_of("<", 0));
		//		
		//		if(result.contains(">")) 
		//			result = result.substring(0, result.index_of(">", 0));
		
		return result;
	}

	public static string remove_linebreaks(string? val) {
		// unexpected linebreaks do not look nice
		if(val == null)
			return "";
		
		try {
			GLib.Regex r = new GLib.Regex("\n");
			return r.replace(val, -1, 0, " ");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return val;
	}

	public static string remove_suffix_from_filename(string? val) {
		if(val == null)
			return "";
		string name = val;
		string prep;
		if(name.last_index_of(".") != -1) 
			prep = name.substring(0, name.last_index_of("."));
		else
			prep = name;
		return prep;
	}

	public static string prepare_name_from_filename(string? val) {
		if(val == null)
			return "";
		string name = val;
		string prep;
		if(name.last_index_of(".") != -1) 
			prep = name.substring(0, name.last_index_of("."));
		else
			prep = name;
		
		try {
			GLib.Regex r = new GLib.Regex("_");
			prep = r.replace(prep, -1, 0, " ");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return prep;
	}

	public static string replace_underline_with_blank_encoded(string value) {
		try {
			GLib.Regex r = new GLib.Regex("_");
			return r.replace(value, -1, 0, "%20");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return value;
	}

	public static File? get_albumimage_for_artistalbum(string? artist, string? album, string? size) {
		if(artist == null)
			return null;
		if(album == null)
			return null;
		if(size == null)
			size = "medium";
		File f = File.new_for_path(GLib.Path.build_filename(GLib.Path.build_filename(global.settings_folder,
		                                                                             "album_images",
		                                                                             null
		                                                                             ),
		                           escape_for_local_folder_search(artist.down()),
		                           escape_album_for_local_folder_search(artist, album),
		                           escape_album_for_local_folder_search(artist, album) +
		                           "_" +
		                           size,
		                           null)
		                           );
		return f;
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
	
	public static TrackData copy_trackdata(TrackData td) {
		TrackData td_new = new TrackData();
		td_new.artist      = td.artist;
		td_new.album       = td.album;
		td_new.title       = td.title;
		td_new.genre       = td.genre;
		td_new.year        = td.year;
		td_new.tracknumber = td.tracknumber;
		td_new.length      = td.length;
		td_new.bitrate     = td.bitrate;
		td_new.mediatype   = td.mediatype;
		td_new.uri         = td.uri;
		td_new.db_id       = td.db_id;
		return td_new;
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



// DATA TRANSFER CLASS

/**
 * This class is used to move around media information
 */
public class Xnoise.TrackData { // track meta information
	public string? artist = null;
	public string? album = null;
	public string? title = null;
	public string? genre = null;
	public string? name = null;
	public uint year = 0;
	public uint tracknumber = 0;
	public int32 length = 0;
	public int bitrate = 0;
	public ItemType mediatype = ItemType.UNKNOWN;
	public Item item = Item(ItemType.UNKNOWN);
	public string? uri = null;
	public int32 db_id = -1;
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


// DELEGATES

public delegate void Xnoise.LyricsFetchedCallback(string artist, string title, string credits, string identifier, string text, string providername);



// INTERFACES

/**
 * Implementors of this interface have to register themselves in
 * the static Parameter class instance `par' at start time of xnoise.
 * The read_* and write_* methods will be called then to put some
 * configuration data to the implementing class instances.
 */
public interface Xnoise.IParams : GLib.Object {
	public abstract void read_params_data();
	public abstract void write_params_data();
}


// this is used by mediakeys plugin. Only works if the interface  is in xnoise itself 
[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface Xnoise.GnomeMediaKeys : GLib.Object {
	public abstract void GrabMediaPlayerKeys(string application, uint32 time) throws IOError;
	public abstract void ReleaseMediaPlayerKeys(string application) throws IOError;
	public signal void MediaPlayerKeyPressed(string application, string key);
}


/**
 * ILyrics implementors should be asynchronously look for lyrics
 * The reply is checked for matching artist/title
 */
public interface Xnoise.ILyrics : GLib.Object {
	public abstract void find_lyrics();
	public abstract string get_identifier();
	public abstract string get_credits();
	public abstract uint get_timeout(); // id of the GLib.Source of the timeout for the search
	
	
	// DEFAULT IMPLEMENTATIONS
	
	protected bool timeout_elapsed() { 
		Timeout.add_seconds(1, () => {
			this.destruct();
			return false;
		});
		return false;
	}
	
	// ILyrics implementor have to call destruct after signalling the arrival of a new lyrics text
	public void destruct() { // default implementation of explizit destructor
		Idle.add( () => {
			if(get_timeout() != 0)
				Source.remove(get_timeout());
			ILyrics* p = this;
			delete p;
			return false;
		});
	}
}


public interface Xnoise.ILyricsProvider : GLib.Object, IPlugin {
	public abstract ILyrics* from_tags(LyricsLoader loader, string artist, string title, LyricsFetchedCallback cb);
	public abstract int priority { get; set; default = 1;}
	public abstract string provider_name { get; }
	
	
	// DEFAULT IMPLEMENTATIONS
	
	public bool equals(ILyricsProvider other) { // default implementation of comparation
		ILyricsProvider t = (ILyricsProvider)this;
		if(direct_equal((void*)t, (void*)other)) {
			return true;
		}
		return false;
	}
}


/**
 * IAlbumCoverImage implementors should be asynchronously look for images
 * The reply is checked for matching artist/album
 */
public interface Xnoise.IAlbumCoverImage : GLib.Object {
	//delivers local image path on success, "" otherwise
	public signal void sign_image_fetched(string artist, string album, string image_path);
	//start image search
	public abstract void find_image();
}


public interface Xnoise.IAlbumCoverImageProvider : GLib.Object {
	public abstract IAlbumCoverImage from_tags(string artist, string album);
}
