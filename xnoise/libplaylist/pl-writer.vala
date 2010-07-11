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
		private Data? _pl_data = null;
		private AbstractFileWriter? plfile_writer = null;
		private string? _uri = null;
		private Mutex write_in_progress_mutex;
		
		public string uri { 
			get {
				return _uri;
			} 
		}
		
		private Data? pl_data { 
			get {
				return _pl_data;
			} 
			set {
				_pl_data = value;
			}
		}

		public Writer(ListType ptype) {
			plfile_writer = get_playlist_file_writer_for_type();
		}
		
		public Result write_to_file() {
			return Result.UNHANDLED;
		}

		public async Result write_asyn(){
			return Result.UNHANDLED;
		}
		
		private AbstractFileWriter? get_playlist_file_writer_for_type() {
			return null;
		}
	}
}
