/* pl-item.vala
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

// an instance of this Entry object represents one entry in the list. An entry contains one or more data fields, at least the uri to the target
namespace Xnoise.Playlist {
	public class Entry {
		private HashTable<Field, string> htable = null;
		
		public enum Field {
			URI = 0,           // Target uri
			TITLE,             // Title, if available, null otherwise
			AUTHOR,            // Author, if available, null otherwise
			GENRE,             // Genre, if available, null otherwise
			ALBUM,             // Album, if available, null otherwise
			COPYRIGHT,         // Copyright, if available, null otherwise
			DURATION,          // Duration, if available, -1 otherwise
			PARAM_NAME,        // Asx parameter name
			PARAM_VALUE,       // Asx parameter value
			IS_REMOTE,         // whether the target is remote : "0" = local, "1" = remote
			IS_PLAYLIST        // whether the target is another playlist : "0" = false, "1" = true
		}
		
		public TargetType target_type { get; set; default = TargetType.URI; }
		public string? base_path      { get; set; default = null; }
		
		public Entry() {
			htable = new HashTable<Field, string>(direct_hash, direct_equal);
		}
		
		~Entry() {
			htable = null;
		}
		
		public void add_field(Field field, string val) {
			htable.insert(field, val);
		}
		
		public Field[] get_contained_fields() {
			Field[] retval = {};
			List<Field> list = htable.get_keys();
			if(list == null)
				return retval;
			
			foreach(Field f in list)
				retval += f;

			return retval;
		}
		
		public string get_field(Field field) {
			return htable.lookup(field);
		}


		// Convenience functions to get data of the playlist entry
		
		public string? get_uri() {
			return htable.lookup(Field.URI);
		}

		public string? get_rel_path() {
			string? s = htable.lookup(Field.URI);
			if(s == null)
				return null;

			File f = File.new_for_uri(s);

			if(base_path == null)
				return null;

			File bp = File.new_for_path(base_path);
			if(bp == null)
				return null;
			
			return bp.get_relative_path(f);
		}

		public string? get_abs_path() {
			//this will work for locally mounted files only
			//return null for remote uri schemes like 'http', 'ftp' 
			string? s = htable.lookup(Field.URI);
			if(s == null)
				return null;
			
			File f = File.new_for_uri(s);

			if(f.get_uri_scheme() in remote_schemes)
				return null;
			
			return f.get_path();
		}

		public string? get_title() {
			return htable.lookup(Field.TITLE);
		}
		
		public string? get_author() {
			return htable.lookup(Field.AUTHOR);
		}
		
		public string? get_genre() {
			return htable.lookup(Field.GENRE);
		}
		
		public string? get_album() {
			return htable.lookup(Field.ALBUM);
		}
		
		public string? get_copyright() {
			return htable.lookup(Field.COPYRIGHT);
		}

		public string? get_duration_string() {
			return htable.lookup(Field.DURATION);
		}

		public string? get_param_name() {
			return htable.lookup(Field.PARAM_NAME);
		}

		public string? get_param_value() {
			return htable.lookup(Field.PARAM_VALUE);
		}

		public long get_duration() {
			string? s = htable.lookup(Field.DURATION);
			if(s == null)
				return -1;
			
			return get_duration_from_string(ref s);
		}

		public bool is_remote() {
			string? s = htable.lookup(Field.IS_REMOTE);
			if(s == "1")
				return true;
			
			return false;
		}

		public bool is_playlist() {
			string? s = htable.lookup(Field.IS_PLAYLIST);
			if(s == "1")
				return true;
			
			return false;
		}
	}
}

