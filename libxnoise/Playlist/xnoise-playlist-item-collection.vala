/* pl-item-collection.vala
 *
 * Copyright (C) 2004-2005  Novell, Inc
 * Copyright (C) 2005  David Waite
 * Copyright (C) 2007-2008  Jürg Billeter
 * Copyright (C) 2009  Didier Villevalois
 * Copyright (C) 2010  Jörn Magens
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or(at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * This file uses excerpts from libgee version as of April 2010
 * Original Authors:
 * 	Jürg Billeter <j@bitron.ch>
 * 	Didier 'Ptitjes Villevalois <ptitjes@free.fr>
 * 	and others
 * 
 * Authors:
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */


namespace Xnoise.Playlist {
	public class EntryCollection {

		private Entry[] _items = {};
		private int _size;
		private int _stamp = 0;
		private HashTable<string, string> _general_info = new HashTable<string, string>(str_hash, str_equal);

		public EntryCollection() {
			this._items = new Entry[4];
		}

		public int get_size() {
			return _size;
		}

		public void add_general_info(string key, string val) {
			_general_info.insert(key, val);
		}
		
		public string[] get_general_info_keys() {
			string[] retval = {};
			List<string> list = _general_info.get_keys();
			if(list == null)
				return retval;
			
			foreach(string s in list)
				retval += s;

			return retval;
		}
		
		public string get_general_info(string key) {
			return _general_info.lookup(key);
		}
		
		public bool data_available() {
			return this.get_size() > 0;
		}

		public string[] get_found_uris() {
			string[] retval = {};
			foreach(Entry d in this) {
				if(d.get_uri() != null)
					retval += d.get_uri();
			}
			return retval;
		}
	
		public string? get_title_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_title();
					break;
				}
			}
			return retval;
		}
		public string? get_author_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_author();
					break;
				}
			}
			return retval;
		}
		
		public string? get_genre_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_genre();
					break;
				}
			}
			return retval;
		}
		
		public string? get_album_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_album();
					break;
				}
			}
			return retval;
		}
		
		public string? get_copyright_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_copyright();
					break;
				}
			}
			return retval;
		}

		public string? get_duration_string_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration_string();
					break;
				}
			}
			return retval;
		}

		public long get_duration_for_uri(ref string uri_needle) {
			long retval = -1;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_duration();
					break;
				}
			}
			return retval;
		}

		public string? get_param_name_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_param_name();
					break;
				}
			}
			return retval;
		}

		public string? get_param_value_for_uri(ref string uri_needle) {
			string? retval = null;
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					retval = d.get_param_value();
					break;
				}
			}
			return retval;
		}

		public bool get_is_remote_for_uri(ref string uri_needle) {
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					return d.is_remote();
				}
			}
			return false;
		}

		public bool get_is_playlist_for_uri(ref string uri_needle) {
			foreach(Entry d in this) {
				if(d.get_uri() == uri_needle) {
					return d.is_playlist();
				}
			}
			return false;
		}
		
		public int get_number_of_entries() {
			return this.get_size();
		}

		//in operator: bool b = needle in obj
		public bool contains(Entry d) {
			for(int index = 0; index < _size; index++) {
				if(direct_equal(_items[index], d))
					return true;
			}
			return false;
		}

		//find Entry with certain field content
		public bool contains_field(Entry.Field field, string value) {
			for(int index = 0; index < _size; index++) {
				if(_items[index].get_field(field) == value)
					return true;
			}
			return false;
		}

		public Playlist.Entry.Field[] get_contained_fields_for_idx(int idx) {
			return _items[idx].get_contained_fields();
		}
		
		public Playlist.Entry.Field[] get_contained_fields_for_uri(ref string uri) {
			for(int index = 0; index < _size; index++) {
				if(_items[index].get_uri() == uri)
					return _items[index].get_contained_fields();
			}
			return new Playlist.Entry.Field[0];
		}
		
		public Iterator iterator() {
			return new Iterator(this);
		}

		public int index_of(Entry d) {
			for(int index = 0; index < _size; index++) {
				if(direct_equal(_items[index], d))
					return index;
			}
			return -1;
		}

		//index access: obj[index]
		public Entry get(int index) {
			assert(index >= 0);
			assert(index < _size);
			return _items[index];
		}

		//index assignment: obj[index] = item
		public void set(int index, Entry item) {
			assert(index >= 0);
			assert(index < _size);
			_items[index] = item;
		}

		public bool append(Entry item) {
			if(_size == _items.length) {
				grow_if_needed(1);
			}
			_items[_size++] = item;
			_stamp++;
			return true;
		}

		public void insert(int index, Entry item) {
			assert(index >= 0);
			assert(index <= _size);

			if(_size == _items.length) {
				grow_if_needed(1);
			}
			shift(index, 1);
			_items[index] = item;
			_stamp++;
		}

		public bool remove(Entry item) {
			for(int index = 0; index < _size; index++) {
				if(direct_equal(_items[index], item)) {
					remove_at(index);
					return true;
				}
			}
			return false;
		}

		public Entry remove_at(int index) {
			assert(index >= 0);
			assert(index < _size);
			Entry item = _items[index];
			_items[index] = null;
			shift(index + 1, -1);
			_stamp++;
			return item;
		}

		public void clear() {
			for(int index = 0; index < _size; index++)
				_items[index] = null;
			
			_size = 0;
			_stamp++;
		}

		public void merge(EntryCollection data_collection) {
			if(data_collection.get_size() == 0) 
				return;
			
			grow_if_needed(data_collection.get_size());
			foreach(Entry item in data_collection)
				_items[_size++] = item;
			
			_stamp++;
			return;
		}

		private void shift(int start, int delta) {
			assert(start >= 0);
			assert(start <= _size);
			assert(start >= -delta);
			_items.move(start, start + delta, _size - start);
			_size += delta;
		}

		private void grow_if_needed(int grow_number) {
			assert(grow_number >= 0);
			int minimum_size = _size + grow_number;
			if(minimum_size > _items.length) {
				set_capacity(grow_number > _items.length ? minimum_size : 2 * _items.length);
			}
		}

		private void set_capacity(int value) {
			assert(value >= _size);
			_items.resize(value);
		}

		public class Iterator {
			private EntryCollection _dc;
			private int _index = -1;
			private bool _removed = false;

			// concurrent modification protection
			private int _stamp = 0;

			public Iterator(EntryCollection dc) {
				_dc = dc;
				_stamp = _dc._stamp;
			}

			public bool next() {
				assert(_stamp == _dc._stamp);
				if(_index + 1 < _dc._size) {
					_index++;
					_removed = false;
					return true;
				}
				return false;
			}

			public bool first() {
				assert(_stamp == _dc._stamp);
				if(_dc.get_size() == 0) {
					return false;
				}
				_index = 0;
				_removed = false;
				return true;
			}

			public Entry get() {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				assert(! _removed);
				return _dc._items[_index];
			}

			public void remove() {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				assert(! _removed);
				_dc.remove_at(_index);
				_index--;
				_removed = true;
				_stamp = _dc._stamp;
			}

			public bool previous() {
				assert(_stamp == _dc._stamp);
				if(_index > 0) {
					_index--;
					return true;
				}
				return false;
			}

			public bool has_previous() {
				assert(_stamp == _dc._stamp);
				return(_index - 1 >= 0);
			}

			public void set(Entry item) {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				_dc._items[_index] = item;
				_stamp = ++_dc._stamp;
			}

			public void insert(Entry item) {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				_dc.insert(_index, item);
				_index++;
				_stamp = _dc._stamp;
			}

			public void append(Entry item) {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				_dc.insert(_index + 1, item);
				_index++;
				_stamp = _dc._stamp;
			}

			public int index() {
				assert(_stamp == _dc._stamp);
				assert(_index >= 0);
				assert(_index < _dc._size);
				return _index;
			}
		}
	}
}

