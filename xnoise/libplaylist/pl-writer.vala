/* pl-writer.vala
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
	public class Writer : GLib.Object {
		private Data? pl_data = null;
		private AbstractFileWriter? plfile_writer = null;
		private File file = null;
		private Mutex write_in_progress_mutex;
		private string? _uri = null;
		public string? uri { 
			get {
				return _uri;
			} 
		}
		
		public Writer(ListType ptype) {
			plfile_writer = get_playlist_file_writer_for_type(ptype);
			write_in_progress_mutex = new Mutex();
		}
		
		// write playlist data to file
		public Result write(Data? data, string playlist_uri, bool overwrite = true) {
			if(pl_data == null)
				return Result.UNHANDLED;
			write_in_progress_mutex.lock();
			pl_data = data;
			
			_uri = playlist_uri;
			file = File.new_for_uri(playlist_uri);
			//TODO: check if local, check if exist,...
			write_in_progress_mutex.unlock();
			return Result.UNHANDLED;
		}

		// write playlist data to file (async version)
		public async Result write_asyn(Data? data, string playlist_uri, bool overwrite = true) {
			if(pl_data == null)
				return Result.UNHANDLED;
			write_in_progress_mutex.lock();
			
			pl_data = data;
			
			_uri = playlist_uri;
			file = File.new_for_uri(playlist_uri);
			//TODO: check if local, check if exist,...
			write_in_progress_mutex.unlock();
			return Result.UNHANDLED;
		}
		
		private static AbstractFileWriter? get_playlist_file_writer_for_type(ListType ptype) {
			switch(ptype) {
				case ListType.ASX:
					return new Asx.FileWriter();
				case ListType.M3U:
					return new M3u.FileWriter();
				case ListType.PLS:
					return new Pls.FileWriter();
				case ListType.XSPF:
					return new Xspf.FileWriter();
				default:
					return null;
			}
		}
	}
}
