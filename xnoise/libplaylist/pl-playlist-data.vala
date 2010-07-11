/* pl-playlist-data.vala
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
	public class Data {
		//TODO: check if this kind of data object is suitable for all kinds of playlists
		public Data() {
			this.urls = {};
		}
		//use this to handle data
		public string[] urls;//        { get; set; default = null; }
		public string? title;//         { get; set; default = null; }
		public string? author;//        { get; set; default = null; }
		public string? genre;//         { get; set; default = null; }
		public string? album;//         { get; set; default = null; }
		public string? volume;//        { get; set; default = null; }
		public string? duration;//      { get; set; default = null; }
		public string? starttime;//     { get; set; default = null; }
		public string? copyright;//     { get; set; default = null; }
		public ListType playlist_type;//   { get; set; default = ListType.UNKNOWN; }
		
		public string? get_next_url() {
			//TODO
			return "";
		}

//		public void append_url(string? url) {
//			//TODO : maybe check if uri is already in list?
//			this.urls += url;
//		}
	}
}

