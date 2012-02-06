/* pl-general.vala
 *
 * Copyright (C) 2010  Jörn Magens
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



namespace Xnoise.Playlist {

	public errordomain ReaderError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}

	private errordomain InternalReaderError {
		UNKNOWN_TYPE,
		INVALID_FILE,
		SOMETHING_ELSE
	}

	//Type of playlist
	public enum ListType {
		UNKNOWN = 0,
		IGNORED,
		M3U,
		PLS,
		ASX,
		XSPF,
		WPL
	}
	
	public enum Result {
		UNHANDLED = 0, //Playlist could not be handled
		ERROR,         //Error reading playlist
		IGNORED,       //Playlist was ignored for some reason
		SUCCESS,       //Playlist was read successfully
		EMPTY,         //Reding returned no data
		DOUBLE_WRITE   //There was already a write in progress for current writer instance
	}
	
	public enum TargetType {
		URI,           // a uri is a uri
		REL_PATH,      // path relative to the location of the playlist
		ABS_PATH       // absolute path (local only !)
	}
	
	private static const string[] known_playlist_extensions = { "asx", "pls", "m3u", "wpl", "xspf" };
	
	public static bool is_playlist_extension(string ext) {
		for(int i = 0; i < known_playlist_extensions.length; i++) {
			if(known_playlist_extensions[i] == ext)
				return true;
		}
		return false;
	}
	
	// string constants for content types
	private class ContentType {
		public static const string ASX         = "audio/x-ms-asx";
		public static const string PLS         = "audio/x-scpls";
		public static const string APPLE_MPEG  = "application/vnd.apple.mpegurl";
		public static const string X_MPEG      = "audio/x-mpegurl";
		public static const string MPEG        = "audio/mpegurl";
		public static const string XSPF        = "application/xspf+xml";
		public static const string WPL         = "application/vnd.ms-wpl";
	}
	
	//put some debug messages into the code
	public bool debug = false;
	
	public const string[] remote_schemes = { "http", "ftp", "mms" }; // TODO: add more
	
	public static bool is_known_playlist_extension(ref string ext) {
		foreach(string s in known_playlist_extensions) {
			if(ext == s)
				return true;
		}
		return false;
	}
	
	public static string? get_extension(File? f) {
		if(f == null)
			return null;
		string uri = f.get_uri();
		assert(uri != null);
		if(uri.contains(".")) {
			long offset = (long)(uri.last_index_of(".", 0)) + ".".length;
			string? ext = uri.substring(offset, uri.length - offset);
			return ext;
		}
		return null;
	}
}

