/* taginfo_c.vapi
 *
 * Copyright (C) 2012 Jörn Magens
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

[CCode (cprefix = "TagInfo_", lower_case_cprefix = "taginfo_", cheader_filename = "taginfo_c.h")]
namespace TagInfo
{
	[CCode (free_function = "taginfo_info_free")]
	[Compact]
	public class Info
	{
		public Info (string filename);
		
		public static Info factory_make (string filename);
		
		public bool read ();
		
		public bool write ();
		
		public string artist {
			[CCode (cname = "taginfo_info_get_artist")]
			owned get;
			[CCode (cname = "taginfo_info_set_artist")]
			set;
		}
		public string albumartist {
			[CCode (cname = "taginfo_info_get_albumartist")]
			owned get;
			[CCode (cname = "taginfo_info_set_albumartist")]
			set;
		}
		public string album {
			[CCode (cname = "taginfo_info_get_album")]
			owned get;
			[CCode (cname = "taginfo_info_set_album")]
			set;
		}
		public string title {
			[CCode (cname = "taginfo_info_get_title")]
			owned get;
			[CCode (cname = "taginfo_info_set_title")]
			set;
		}
		public string genre {
			[CCode (cname = "taginfo_info_get_genre")]
			owned get;
			[CCode (cname = "taginfo_info_set_genre")]
			set;
		}
		public int tracknumber {
			[CCode (cname = "taginfo_info_get_tracknumber")]
			get;
			[CCode (cname = "taginfo_info_set_tracknumber")]
			set;
		}
		public int year {
			[CCode (cname = "taginfo_info_get_year")]
			get;
			[CCode (cname = "taginfo_info_set_year")]
			set;
		}
		public bool is_compilation {
			[CCode (cname = "taginfo_info_get_is_compilation")]
			get;
			[CCode (cname = "taginfo_info_set_is_compilation")]
			set;
		}
		public int length {
			[CCode (cname = "taginfo_info_get_length")]
			get;
		}
		public int bitrate {
			[CCode (cname = "taginfo_info_get_bitrate")]
			get;
		}
		// A quick lookup sais that there is something. 
		//   But this is not guaranteed!
		public bool has_image {
			[CCode (cname = "taginfo_info_get_has_image")]
			get;
		}
		// Returns success
		public bool get_image (out uint8[] data);
	}
}

