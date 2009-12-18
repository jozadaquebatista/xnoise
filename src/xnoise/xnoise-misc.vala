/* xnoise-misc.vala
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

// GENERAL NAMESPACE FUNCTIONS

namespace Xnoise {
	
	public static Params par;
	
	public static void initialize() {
		if(par==null) par = new Params();
	}
	
	public static string remove_linebreaks(string value) {
		try {
			GLib.Regex r = new GLib.Regex("\n");
			return r.replace(value, -1, 0, " ");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return value;
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

// Enums

public enum Xnoise.BrowserColumn {
	ICON = 0,
	VIS_TEXT,
	DB_ID,
	MEDIATYPE,
	COLL_TYPE,
	DRAW_SEPTR,
	N_COLUMNS
}

public enum Xnoise.MediaStorageType {
	FILE = 0,
	FOLDER,
	STREAM
}

public enum Xnoise.BrowserCollectionType {
	UNKNOWN = 0,
	HIERARCHICAL = 1,
	LISTED = 2
}

public enum Xnoise.Repeat { 
	NOT_AT_ALL = 0,
	SINGLE,
	ALL
}

public enum Xnoise.MediaType {
	UNKNOWN = 0,
	AUDIO,
	VIDEO,
	STREAM,
	PLAYLISTFILE
}

public enum Xnoise.TrackListColumn {
	STATE = 0,
	ICON,
	TRACKNUMBER,
	TITLE,
	ALBUM,
	ARTIST,
	URI,
	N_COLUMNS
}

public enum Xnoise.TrackState {
	STOPPED = 0,
	PLAYING,
	PAUSED,
	POSITION_FLAG
}

public enum Xnoise.Direction {
	NEXT = 0,
	PREVIOUS,
}

public enum Gst.StreamType {
    UNKNOWN = 0,
    AUDIO   = 1, 
    VIDEO   = 2
}

// Classes

public class Xnoise.TrackData { // track meta information
	public string Artist;
	public string Album;
	public string Title;
	public string Genre;
	public uint Year;
	public uint Tracknumber;
	public MediaType Mediatype = MediaType.UNKNOWN;
	public string Uri;
}


// Structs

public struct Xnoise.StreamData { // meta information structure
	public string Name;
	public string Uri;
}

public struct Xnoise.TitleMtypeId {
	public string name;
	public int id;
	public MediaType mediatype;
}


// Interfaces

public interface Xnoise.IParams : GLib.Object {
	public abstract void read_params_data();
	public abstract void write_params_data();
}

public interface Xnoise.ILyrics : GLib.Object {
	public abstract void* fetch();
	public abstract string get_text();
	public abstract string get_identifier();
	public abstract string get_credits();

	public signal void sign_lyrics_fetched(string text);
	public signal void sign_lyrics_done(ILyrics instance);
}

public interface Xnoise.ILyricsProvider : GLib.Object {
	public abstract ILyrics from_tags(string artist, string title);
}

public interface Xnoise.IAlbumCoverImage : GLib.Object {
	public abstract void fetch();
	public abstract string get_image_uri();
	//public abstract bool find_image(string uri, string artist, string album);

	public signal void sign_album_image_fetched(string image_uri);
	public signal void sign_album_image_done(IAlbumCoverImage instance);
}

public interface Xnoise.IAlbumCoverImageProvider : GLib.Object {
	public abstract IAlbumCoverImage from_tags(string artist, string album);
}


