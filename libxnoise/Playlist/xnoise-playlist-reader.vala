/* pl-reader.vala
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


namespace Xnoise.Playlist {
	public class Reader : GLib.Object {
		
		// _data_collection is the collection of data entries in one playlist
		private EntryCollection _data_collection;
		private File? file = null;
		private ListType _ptype;
		private AbstractFileReader? plfile_reader = null;
		private string? _playlist_uri = null;
		//use this to protect running reading process
		//it shall not be possible to run async and sync reading in parallel'
		private Mutex read_in_progress_mutex;
		
		//Public Properties
		public ListType ptype {
			get {
				return _ptype;
			}
		}
		
		public string playlist_uri { 
			get {
				return _playlist_uri;
			} 
		}
		
		public EntryCollection data_collection {
			get {
				return _data_collection;
			} 
		}
		
		
		//Signals
		public signal void started(string playlist_uri);
		public signal void finished(string playlist_uri);
		
		
		//Constructor
		public Reader() {
			_data_collection = new EntryCollection();
			read_in_progress_mutex = new Mutex();
		}
		
		public Result read(string list_uri, Cancellable? cancellable = null) throws ReaderError {
			Result ret = Result.UNHANDLED;
			read_in_progress_mutex.lock();
			_playlist_uri = list_uri;
			file = File.new_for_uri(_playlist_uri);
			
			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri, ref _ptype);
			
			if(plfile_reader == null) {
				read_in_progress_mutex.unlock();
				return Result.ERROR;
			}
			
			ret = this.read_internal();
			read_in_progress_mutex.unlock();
			return ret;
		}


		public async Result read_asyn(string list_uri, Cancellable? cancellable = null) throws ReaderError {
			Result ret = Result.UNHANDLED;
			read_in_progress_mutex.lock();
			_playlist_uri = list_uri;
			this.file = File.new_for_commandline_arg(_playlist_uri);

			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri, ref _ptype); 
			plfile_reader.finished.connect( (s, u) => {
				this.finished(u);
			});
			
			if(plfile_reader == null) {
				read_in_progress_mutex.unlock();
				return Result.ERROR;
			}

//			ret = yield this.read_async_internal();
			this.read_async_internal.begin();
			read_in_progress_mutex.unlock();
			return ret;
		}

		private Result read_internal() {
			try {
				_data_collection = plfile_reader.read(file);
			}
			catch(Error e) {
				print("%sn", e.message);
				return Result.ERROR;
			}
			if(_data_collection == null)
				return Result.EMPTY;
			else
				return Result.SUCCESS;
		}

		private async Result read_async_internal() {
			try {
				assert(file != null);
				_data_collection = yield plfile_reader.read_asyn(file);
			}
			catch(InternalReaderError e) {
				print("%sn", e.message);
				return Result.ERROR;
			}
			if(_data_collection == null)
				return Result.EMPTY;
			else
				return Result.SUCCESS;
		}


		//static factory function to setup reader, also sets up ListType
		private static AbstractFileReader? get_playlist_file_reader_for_uri(ref string uri_ , ref ListType current_type) {
			current_type = get_playlist_type_for_uri(ref uri_);
			switch(current_type) {
				case ListType.ASX:
					AbstractFileReader ret = new Asx.FileReader();
					return ret;
				case ListType.M3U:
					AbstractFileReader ret = new M3u.FileReader();
					return ret;
				case ListType.PLS:
					AbstractFileReader ret = new Pls.FileReader();
					return ret;
				case ListType.XSPF:
					AbstractFileReader ret = new Xspf.FileReader();
					return ret;
				case ListType.WPL:
					AbstractFileReader ret = new Wpl.FileReader();
					return ret;
				
			}
			return null;
		}

		public bool data_available() {
			return _data_collection.data_available();
		}

		public int get_number_of_entries() {
			return _data_collection.get_size();
		}

		public string[] get_found_uris() {
			return _data_collection.get_found_uris();
		}
	
		public string? get_title_for_uri(ref string uri_needle) {
			return _data_collection.get_title_for_uri(ref uri_needle);
		}

		public string? get_author_for_uri(ref string uri_needle) {
			return _data_collection.get_author_for_uri(ref uri_needle);
		}
		
		public string? get_genre_for_uri(ref string uri_needle) {
			return _data_collection.get_genre_for_uri(ref uri_needle);
		}
		
		public string? get_album_for_uri(ref string uri_needle) {
			return _data_collection.get_album_for_uri(ref uri_needle);
		}
		
		public string? get_copyright_for_uri(ref string uri_needle) {
			return _data_collection.get_copyright_for_uri(ref uri_needle);
		}

		public string? get_duration_string_for_uri(ref string uri_needle) {
			return _data_collection.get_duration_string_for_uri(ref uri_needle);
		}

		public long get_duration_for_uri(ref string uri_needle) {
			return _data_collection.get_duration_for_uri(ref uri_needle);
		}

		public bool get_is_remote_for_uri(ref string uri_needle) {
			return _data_collection.get_is_remote_for_uri(ref uri_needle);
		}

		public bool get_is_playlist_for_uri(ref string uri_needle) {
			return _data_collection.get_is_playlist_for_uri(ref uri_needle);
		}
	}
	
	
	public static ListType get_playlist_type_for_uri(ref string uri_) {
		//What is more reliable? extension or data? 
		//What shall happen if the extension is wrong?
		ListType retval = get_type_by_extension(ref uri_);
		
		if(retval != ListType.UNKNOWN) {
			return retval;
		}
		
		//TODO shall we use the found ListType and do some checks, if the file is valid or has a different format?
		retval = get_type_by_data(ref uri_);
		
		return retval;
	}

	public static ListType get_type_by_extension(ref string uri_) {
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
			else if(uri_down.has_suffix(".wpl")) {
				return ListType.WPL;
			}
			else {
				return ListType.UNKNOWN;
			}
		}
		else {
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
			//string mime = GLib.ContentType.get_mime_type(content_type);
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
			else if(content_type == ContentType.WPL) {
				return ListType.WPL;
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
	public static File get_file_for_location(string adr, ref string base_path, out TargetType tt) {
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
}

