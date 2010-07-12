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


namespace Pl {
	public class Reader : GLib.Object {
		// _pl_data is the collection of data entries in one playlist
		private Data[] _pl_data;
		private File? file = null;
		private ListType _ptype;
		private AbstractFileReader? plfile_reader = null;
		private string? _playlist_uri = null;
		//use this to protect running reading process
		//it shall not be possible to run async and sync reading in parallel'
		private Mutex read_in_progress_mutex;
		
		//Properties
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
		
		public Reader() {
			_pl_data = {};
			read_in_progress_mutex = new Mutex();
		}
		
		//Constructor
		public Result read(string list_uri) throws ReaderError {
			Result ret = Result.UNHANDLED;
			_playlist_uri = list_uri;
			file = File.new_for_uri(_playlist_uri);
			
			read_in_progress_mutex.lock();
			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri);
			
			if(plfile_reader == null) {
				return Result.ERROR;
			}
			
			ret = this.read_internal();
			read_in_progress_mutex.unlock();
			return ret;
		}


		public async Result read_async(string list_uri) throws ReaderError {
			Result ret = Result.UNHANDLED;
			_playlist_uri = list_uri;
			file = File.new_for_uri(_playlist_uri);

			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri);
			
			if(plfile_reader == null) {
				return Result.ERROR;
			}

			read_in_progress_mutex.lock();
			ret = yield this.read_async_internal();
			read_in_progress_mutex.unlock();
			return ret;
		}

		private Result read_internal() {
			try {
				_pl_data = plfile_reader.read(file);
			}
			catch(Error e) {
				print("%sn", e.message);
				return Result.ERROR;
			}
			if(_pl_data == null)
				return Result.EMPTY;
			else
				return Result.SUCCESS;
		}

		private async Result read_async_internal() {
			try {
				_pl_data = yield plfile_reader.read_asyn(file);
			}
			catch(InternalReaderError e) {
				print("%sn", e.message);
				return Result.ERROR;
			}
			if(_pl_data == null)
				return Result.EMPTY;
			else
				return Result.SUCCESS;
		}


		//static functions to setup reader
		
		private static AbstractFileReader? get_playlist_file_reader_for_uri(ref string uri_) {
			//TODO: return the right implementation of PlaylistReader
			ListType current_type = get_playlist_type_for_uri(ref uri_);
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
			}
			return null;
		}

		private static ListType get_playlist_type_for_uri(ref string uri_) {
			//What is more reliable? extension or data?
			ListType retval = get_type_by_extension(ref uri_);
			if(retval != ListType.UNKNOWN) {
				return retval;
			}
			
			retval = get_type_by_data(ref uri_);
			
			return retval;
		}

		private static ListType get_type_by_extension(ref string uri_) {
			//TODO: Determine filetype by extension
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

		private static ListType get_type_by_data(ref string uri_) {
			//TODO: Determine filetype by content
			string content_type = "";
			File f = File.new_for_uri(uri_);
			try {
				var file_info = f.query_info("*", FileQueryInfoFlags.NONE, null);
				//print("File size: %lld bytes\n", file_info.get_size());
				content_type = file_info.get_content_type();
				string mime = g_content_type_get_mime_type(content_type);
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


		// functions to retrieve found data
		
		public bool data_available() {
			return _pl_data.length > 0;
		}
		
		public string[] get_found_uris() {
			string[] retval = {};
			foreach(Data d in _pl_data) {
				if(d.get_uri() != null)
					retval += d.get_uri();
			}
			return retval;
		}
	
		public string? get_tile_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_title();
					break;
				}
			}
			return retval;
		}
		public string? get_author_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_author();
					break;
				}
			}
			return retval;
		}
		
		public string? get_genre_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_genre();
					break;
				}
			}
			return retval;
		}
		
		public string? get_album_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_album();
					break;
				}
			}
			return retval;
		}
		
		public string? get_copyright_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_copyright();
					break;
				}
			}
			return retval;
		}

		public string? get_duration_string_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration_string();
					break;
				}
			}
			return retval;
		}

		public long get_duration_for_uri(ref string uri_needle) {
			long retval = -1;
			foreach(Data d in _pl_data) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration();
					break;
				}
			}
			return retval;
		}
	}
}

