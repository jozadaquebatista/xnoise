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
		// _data_collection is the collection of data entries in one playlist
		private Data[] _data_collection;
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
		
		public Data[] data_collection {
			get {
				return _data_collection;
			} 
		}
		
		
		//Constructor
		public Reader() {
			_data_collection = {};
			read_in_progress_mutex = new Mutex();
		}
		
		public Result read(string list_uri) throws ReaderError {
			Result ret = Result.UNHANDLED;
			_playlist_uri = list_uri;
			file = File.new_for_uri(_playlist_uri);
			
			read_in_progress_mutex.lock();
			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri, ref _ptype);
			
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

			plfile_reader = get_playlist_file_reader_for_uri(ref _playlist_uri, ref _ptype);
			
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
			}
			return null;
		}


		// functions to retrieve found data
		
		public bool data_available() {
			return _data_collection.length > 0;
		}
		
		public string[] get_found_uris() {
			string[] retval = {};
			foreach(Data d in _data_collection) {
				if(d.get_uri() != null)
					retval += d.get_uri();
			}
			return retval;
		}
	
		public string? get_title_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_title();
					break;
				}
			}
			return retval;
		}
		public string? get_author_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_author();
					break;
				}
			}
			return retval;
		}
		
		public string? get_genre_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_genre();
					break;
				}
			}
			return retval;
		}
		
		public string? get_album_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_album();
					break;
				}
			}
			return retval;
		}
		
		public string? get_copyright_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_copyright();
					break;
				}
			}
			return retval;
		}

		public string? get_duration_string_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration_string();
					break;
				}
			}
			return retval;
		}

		public long get_duration_for_uri(ref string uri_needle) {
			long retval = -1;
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration();
					break;
				}
			}
			return retval;
		}

		public bool get_is_remote_for_uri(ref string uri_needle) {
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					return d.is_remote();
				}
			}
			return false;
		}

		public bool get_is_playlist_for_uri(ref string uri_needle) {
			foreach(Data d in _data_collection) {
				if(d.get_uri() == uri_needle) {
					return d.is_playlist();
				}
			}
			return false;
		}
		
		public int get_number_of_entries() {
			return _data_collection.length;
		}
	}
}

