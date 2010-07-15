/* pl-general.vala
 *
 * Copyright (C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */


namespace Pl {

	public errordomain ReaderError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}

	public errordomain WriterError {
		UNKNOWN_TYPE,
		NO_DATA,
		NO_DEST_URI,
		DEST_REMOTE
	}
	
	private errordomain InternalReaderError {
		UNKNOWN_TYPE,
		INVALID_FILE,
		SOMETHING_ELSE
	}

	private errordomain InternalWriterError {
		UNKNOWN_TYPE,
		SOMETHING_ELSE
	}
	
	//Type of playlist
	public enum ListType {
		UNKNOWN = 0,
		IGNORED,
		M3U,
		PLS,
		ASX,
		XSPF
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
	
	// string constants for content types
	private static class ContentType {
		public const string ASX         = "audio/x-ms-asx";
		public const string PLS         = "audio/x-scpls";
		public const string APPLE_MPEG  = "application/vnd.apple.mpegurl";
		public const string X_MPEG      = "audio/x-mpegurl";
		public const string MPEG        = "audio/mpegurl";
		public const string XSPF        = "application/xspf+xml";
	}
	
	//put some debug messages into the code
	public bool debug = false;
	
	
	public const string[] remote_schemes = { "http", "ftp" }; // TODO: add more
	
	
	// Static helper functions
	
	// duration in seconds
	public static long get_duration_from_string(ref string? duration_string) {
		
		if(duration_string == null)
			return -1;
		
		long duration = 0;
		int hours = 0; 
		int minutes = 0; 
		int seconds = 0; 
		int fractions_of_seconds = 0;
		
		// Try scanning different formats
		
		if(duration_string.scanf("%d:%d:%d.%d", ref hours, ref minutes, ref seconds, ref fractions_of_seconds) == 4) {
			duration = hours * 3600 + minutes * 60 + seconds;
			return (duration == 0 && fractions_of_seconds > 0) ? 1 : duration;
		}
		
		if(duration_string.scanf("%d:%d.%d", ref minutes, ref seconds, ref fractions_of_seconds) == 3) {
			duration = minutes * 60 + seconds;
			return (duration == 0 && fractions_of_seconds > 0) ? 1 : duration;
		}
		
		if(duration_string.scanf("%d:%d:%d", ref hours, ref minutes, ref seconds) == 3) 
			return hours * 3600 + minutes * 60 + seconds;
		
		if(duration_string.scanf("%d.%d", ref minutes, ref seconds) == 2) 
			return minutes * 60 + seconds;
		
		if(duration_string.scanf("%d:%d", ref minutes, ref seconds) == 2) 
			return minutes * 60 + seconds;
		
		if(duration_string.scanf("%d", ref seconds) == 1) 
			return seconds;
		
		return -1; // string didn't match the scanning formats
	}
	
	// create a File for the absolute/relative path or uri
	public static File get_file_for_location(string adr, ref string base_path = "", out TargetType tt) {
		string adress = adr; //work on a copy
		char* p = adress;

		tt = TargetType.URI; // source was of this target type
		
		if(p[0] == '\\' && p[1] != '\\') {
			p++;
			adress = ((string)p);
		}
		
		adress._delimit("\\", '/'); //make slashes from backslashes in place
		
		if((p[0].isalpha() && (!((string)(p + 1)).contains("://"))) || (p[0] == '/' && p[1] != '/')) {
			//relative paths
			if(p[0] != '/') { // Could a path starting with / also be relative path
				adress = base_path + "/" + adress;
				tt = TargetType.REL_PATH; // source was of this target type
			}
		}
		else if((p[0].isalpha()) && ((string)(p + 1)).has_prefix("://")) {
			// relative to a windows drive letter
			File base_path_file = File.new_for_commandline_arg(base_path);
			File tmp = base_path_file.get_child(((string)p[2]));
			adress = tmp.get_uri();
			tt = TargetType.ABS_PATH; // source was of this target type
		}
		else if(p[0] == '/' && p[1] == '/') {
			adress = "smb:" + adress;
			tt = TargetType.ABS_PATH; // source was of this target type
		}
		
		// check if target was a regular absolute path
		p = adress;
		if(p[0] == '/' && p[1] != '/') {
			// if it looks like an absolute path here it is an absolute path
			tt = TargetType.ABS_PATH;
		}
		
		
		File retval = File.new_for_commandline_arg(adress);
		return retval;
	}
	
	public static ListType get_playlist_type_for_uri(ref string uri_) {
		//What is more reliable? extension or data? 
		//What shall happen if the extension is wrong?
		ListType retval = get_type_by_extension(ref uri_);
		
		if(retval != ListType.UNKNOWN) {
			return retval;
		}
		
		retval = get_type_by_data(ref uri_);
		
		return retval;
	}

	public static ListType get_type_by_extension(ref string uri_) {
		try {
			if(uri_ != null) {
				string uri_down = uri_.down();
				if(uri_down.has_suffix(".asx")) {
					return ListType.ASX;
				}
				else if(uri_down.has_suffix(".pls")) {
					return ListType.PLS;
				}
				else if(uri_down.has_suffix(".m3u")) {
					return ListType.M3U;
				}
				else if(uri_down.has_suffix(".xspf")) {
					return ListType.XSPF;
				}
				else {
					return ListType.UNKNOWN;
				}
			}
			else {
				return ListType.UNKNOWN;
			}
		}
		catch(Error e) {
			print("Error: %s\n",e.message);
			return ListType.UNKNOWN;
		}
	}

	public static ListType get_type_by_data(ref string uri_) {
		string content_type = "";
		File f = File.new_for_uri(uri_);
		try {
			var file_info = f.query_info("*", FileQueryInfoFlags.NONE, null);
			//print("File size: %lld bytes\n", file_info.get_size());
			content_type = file_info.get_content_type();
			//string mime = g_content_type_get_mime_type(content_type);
			//print("Mime type: %s\n",mime);
			
			//audio/x-ms-asx => asx
			if(content_type == ContentType.ASX) { //"audio/x-ms-asx"
				//print("Content type asx: %s\n", content_type);
				return ListType.ASX;
			}
			//audio/x-scpls	 => pls
			else if(content_type == ContentType.PLS) { //"audio/x-scpls"
				//print("Content type pls: %s\n", content_type);
				return ListType.PLS;
			}
			//application/vnd.apple.mpegurl
			//audio/x-mpegurl => m3u
			//audio/mpegurl
			else if(content_type == ContentType.APPLE_MPEG || content_type == ContentType.X_MPEG || content_type == ContentType.MPEG) { //MPEG
				//print("Content type m3u: %s\n", content_type);
				return ListType.M3U;
			}
			else if(content_type == ContentType.XSPF) {
				//print("Content type xspf: %s\n", content_type);
				return ListType.XSPF;
			}
			else {
				print("Other Content type: %s\n", content_type);
				return ListType.UNKNOWN;
			}
		}
		catch(Error e) {
			print("Error: %s\n", e.message);
			return ListType.UNKNOWN;
		}
	}
}

