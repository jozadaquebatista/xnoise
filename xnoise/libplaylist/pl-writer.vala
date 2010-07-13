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
		private Data[] pl_data = null;
		private AbstractFileWriter? plfile_writer = null;
		private File file = null;
		private Mutex write_in_progress_mutex;
		private string? _uri = null;
		private bool _use_absolute_uris = true;
		private bool _overwrite_if_exists = true;
		
		public string? uri { 
			get {
				return _uri;
			} 
		}
		
		public bool use_absolute_uris { 
			get {
				return _use_absolute_uris;
			} 
		}
		
		public bool overwrite_if_exists { 
			get {
				return _overwrite_if_exists;
			} 
		}

		// if no absolute uris are used, then files are relative to containing playlist folder
		public Writer(ListType ptype, bool overwrite = true, bool absolute_uris = true) {
			_overwrite_if_exists = overwrite;
			_use_absolute_uris = absolute_uris;

			write_in_progress_mutex = new Mutex();

			plfile_writer = get_playlist_file_writer_for_type(ptype, overwrite, absolute_uris);
		}
	
	
		// write playlist data to file
		public Result write(Data[] data_collection, string playlist_uri) throws WriterError { // TODO: handle overwrite
			
			if(data_collection == null)
				throw new WriterError.NO_DATA("No data was provided. Playlist cannot be created.");

			
			if(playlist_uri == null || playlist_uri == "")
				throw new WriterError.NO_DEST_URI("No destation for playlist file was specified. Playlist cannot be created.");
			
			// now start
			write_in_progress_mutex.lock();
			pl_data = data_collection;
			
			_uri = playlist_uri;
			file = File.new_for_uri(playlist_uri);
			try {
				plfile_writer.write(file, pl_data);
			}
			catch(Error e) {
				print("Error writing playlist: %s\n", e.message);
			}
			finally {
				write_in_progress_mutex.unlock();
			}
			//TODO: check if local, check if exist,...
			return Result.UNHANDLED;
		}

		// write playlist data to file (async version)
		public async Result write_asyn(Data[] data_collection, string playlist_uri) throws WriterError {
			
			if(data_collection == null)
				throw new WriterError.NO_DATA("No data was provided. Playlist cannot be created.");

			
			if(playlist_uri == null || playlist_uri == "")
				throw new WriterError.NO_DEST_URI("No destation for playlist file was specified. Playlist cannot be created.");
			
			// now start
			write_in_progress_mutex.lock();
			
			pl_data = data_collection;
			
			_uri = playlist_uri;
			file = File.new_for_uri(playlist_uri);
			//TODO: check if local, check if exist,...
			write_in_progress_mutex.unlock();
			return Result.UNHANDLED;
		}
		
		private static AbstractFileWriter? get_playlist_file_writer_for_type(ListType ptype, bool overwrite, bool abs_uris) {
			switch(ptype) {
				case ListType.ASX:
					return new Asx.FileWriter(overwrite, abs_uris);
				case ListType.M3U:
					return new M3u.FileWriter(overwrite, abs_uris);
				case ListType.PLS:
					return new Pls.FileWriter(overwrite, abs_uris);
				case ListType.XSPF:
					return new Xspf.FileWriter(overwrite, abs_uris);
				default:
					return null;
			}
		}
	}
}
