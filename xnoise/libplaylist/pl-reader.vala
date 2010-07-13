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
		private DataCollection _data_collection;
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
		
		public DataCollection data_collection {
			get {
				return _data_collection;
			} 
		}
		
		
		//Constructor
		public Reader() {
			_data_collection = new DataCollection();
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
}

