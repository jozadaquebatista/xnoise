/* xnoise-misc.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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

	public static Params par = null;
	public static GlobalInfo global = null;

	public static void initialize() {
		if(par == null)
			par = new Params();

		if(global == null)
			global = new GlobalInfo();
	}

	public static string escape_for_local_folder_search(string value) {
		// transform the name to match the naming scheme
		try {
			string tmp = "";
			GLib.Regex r = new GLib.Regex("\n");
			tmp = r.replace(value, -1, 0, "_");
			r = new GLib.Regex(" ");
			tmp = r.replace(tmp, -1, 0, "_");
			r = new GLib.Regex("//");
			return r.replace(tmp, -1, 0, "-");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return value;
	}

	public static string remove_linebreaks(string value) {
		// unexpected linebreaks do not look nice
		try {
			GLib.Regex r = new GLib.Regex("\n");
			return r.replace(value, -1, 0, " ");
		}
		catch(GLib.RegexError e) {
			print("%s\n", e.message);
		}
		return value;
	}

	public static string replace_underline_with_blank_encoded(string value) {
		// unexpected linebreaks do not look nice
		try {
			GLib.Regex r = new GLib.Regex("_");
			return r.replace(value, -1, 0, "%20");
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

// ENUMS

public enum Xnoise.MediaType { // used in various places
	UNKNOWN = 0,
	AUDIO,
	VIDEO,
	STREAM,
	PLAYLISTFILE
}

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



// DATA TRANSFER CLASS

/**
 * This class is used to move around media information
 */
public class Xnoise.TrackData { // track meta information
	public string Artist;
	public string Album;
	public string Title;
	public string Genre;
	public uint Year;
	public uint Tracknumber;
	public int32 Length;
	public int Bitrate;
	public MediaType Mediatype = MediaType.UNKNOWN;
	public string Uri;
}



// STRUCTS

/**
 * This struct is used to move around certain streams information
 */
public struct Xnoise.StreamData { // meta information structure
	public string Name;
	public string Uri;
}

/**
 * This struct is used to move around certain media information
 */
public struct Xnoise.MediaData {
	public string name;
	public int id;
	public MediaType mediatype;
}





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



/**
 * ILyrics implementors should be synchrouniously looking for images
 * this is done in the ThreadFunc "fetch()"
 */
public interface Xnoise.ILyrics : GLib.Object {
	// 'fetch' is a thread function that will find the lyrics
	public abstract void* fetch();
	public abstract string get_text();
	public abstract string get_identifier();
	public abstract string get_credits();

	public signal void sign_lyrics_fetched(string text);
	// 'sign_lyrics_done' delivers the providers instance
	// for destruction after usage
	public signal void sign_lyrics_done(ILyrics instance);
}


public interface Xnoise.ILyricsProvider : GLib.Object {
	public abstract ILyrics from_tags(string artist, string title);
}




/*
 * IAlbumCoverImage implementors should be synchrouniously looking for images
 * this is done in the ThreadFunc "fetch_image()"
 */
public interface Xnoise.IAlbumCoverImage : GLib.Object {
	public abstract void* fetch_image();
	public abstract string get_image_uri();

	// delivers local image path on success, null otherwise
	public signal void sign_album_image_fetched(string artist, string album, string? image_path);

	// 'sign_album_image_done' delivers the providers instance
	// for destruction after usage
	public signal void sign_album_image_done(IAlbumCoverImage instance);
}


public interface Xnoise.IAlbumCoverImageProvider : GLib.Object {
	public abstract IAlbumCoverImage from_tags(string artist, string album);
}
