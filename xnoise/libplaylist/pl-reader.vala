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
		private File? file = null;
		private Data? _pl_data = null;
		private AbstractFileReader? plfile_reader = null;
		private string? _uri = null;
		
		//use this to protect running reading process
		private Mutex read_in_progress_mutex;
		private ListType _ptype;
		
		public ListType ptype {
			get {
				return _ptype;
			}
		}
		
		public string uri { 
			get {
				return _uri;
			} 
		}
		
		private Data? pl_data{ 
			get {
				return _pl_data;
			} 
		}
		
		public Reader(string playlist_uri) {
			_uri = playlist_uri;
			_pl_data = new Data();
			read_in_progress_mutex = new Mutex();
		}
		
		public void read() throws ReaderError {
			read_in_progress_mutex.lock();
			plfile_reader = get_playlist_file_reader_for_current_uri();
			
			if(plfile_reader == null) {
				throw new ReaderError.UNKNOWN_TYPE("File type unknown or not a playlist.");
			}
			
			this.read_internal();
			read_in_progress_mutex.unlock();
		}

		public async void read_async() throws ReaderError {
			plfile_reader = get_playlist_file_reader_for_current_uri();
			
			if(plfile_reader == null) {
				throw new ReaderError.UNKNOWN_TYPE("File type unknown or not a playlist.");
			}

			read_in_progress_mutex.lock();
			yield this.read_async_internal();
			read_in_progress_mutex.unlock();
		}

		private void read_internal() {
			file = File.new_for_uri(_uri);
			try {
				_pl_data = plfile_reader.read(file);
			}
			catch(Error e) {
				print("%sn", e.message);
			}
		}

		private async void read_async_internal() {
			file = File.new_for_uri(_uri);
			try {
				_pl_data = yield plfile_reader.read_asyn(file);
			}
			catch(Error e) {
				print("%sn", e.message);
			}
		}
		
		private AbstractFileReader? get_playlist_file_reader_for_current_uri() {
			//TODO: return the right implementation of PlaylistReader
			ListType current_type = get_playlist_type_for_current_uri();
			switch(current_type) {
				case ListType.M3U:
					AbstractFileReader ret = new M3u.FileReader();
					return ret;
//				case ListType.PLS:
//					AbstractFileReader ret = new Pls.FileReader();
//					return ret;
//				case ListType.ASX:
//					AbstractFileReader ret = new Asx.FileReader();
//					return ret;
			}
			return null;
		}

		private ListType get_playlist_type_for_current_uri() {
			//What is more reliable? extension or data?
			ListType retval = get_type_by_extension();
			if(retval != ListType.UNKNOWN) {
				return retval;
			}
			
			retval = get_type_by_data();
			//if(retval != ListType.UNKNOWN) {
			//	return retval;
			//}
			
			return retval;
		}

		private ListType get_type_by_extension() {
			//TODO: Determine filetype by extension
			return ListType.M3U;
		}

		private ListType get_type_by_data() {
			//TODO: Determine filetype by content
			return ListType.M3U;
		}


		// Content forwarding from reader implementation
		public string[]? get_uris() {
			return _pl_data.urls;
		}
		
		public string? get_title() {
			return _pl_data.title;
		}
		
		public string? get_author() {
			return _pl_data.author;
		}
		
		public string? get_genre() {
			return _pl_data.genre;
		}
		
		public string? get_album () {
			return _pl_data.album;
		}
		
		public string? get_volume () {
			return _pl_data.volume;
		}
		
		public string? get_duration() {
			return _pl_data.duration;
		}
		
		public string? get_starttime() {
			return _pl_data.starttime;
		}
		
		public string? get_copyright() {
			return _pl_data.copyright;
		}
	}
}

