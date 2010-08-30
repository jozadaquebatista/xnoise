/* simple-xml-node.vala
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


namespace SimpleXml {

	public class Node {
		// Represents a xml node. Can contain more nodes, text and attributes
		// For convenient usage with vala iteration
		private unowned Node _parent;
		private unowned Node? _previous = null;
		private Node? _next = null;
		private int _children_count = 0;
			
		private string? _name = null;

		public Attributes attributes = new Attributes();

		public Node(string? name) {
			this._name = name;
		}
	
		public string? text { get; set; default = null; }
	
		public string? name {
			get {
				return _name;
			}
		}

		public Node? parent { 
			get {
				return _parent;
			}
		}

		public Node? previous { 
			get {
				return _previous;
			}
		}

		public Node? next { 
			get {
				return _next;
			}
		}

		public class Attributes {
		
			private GLib.HashTable<string, string> table = 
			   new GLib.HashTable<string, string>(str_hash, str_equal);
	
			public Keys keys;
			public Values values;
	
			public Attributes() {
				keys = new Keys(this);
				values = new Values(this);
			}

			~Attributes() {
				table.remove_all();
				table = null;
			}
	
			public class Keys {
				private unowned Attributes attrib;
		
				public Keys(Attributes _attrib) {
					attrib = _attrib;
				}
		
				public bool contains(string needle_key) {
					foreach(string current_key in attrib.key_list) {
						if(str_equal(needle_key, current_key))
							return true;
					}
					return false;
				}
		
				public Iterator iterator() {
					return new Iterator(this.attrib);
				}
	
				public class Iterator {
					private unowned Attributes iter_attib;
					private List<unowned string> key_list = null;
					private unowned List<string> curr_key;
			
					public Iterator(Attributes _iter_attib) {
						this.iter_attib = _iter_attib;
					}
			
					public bool next() {
						if(this.key_list == null) {
							this.key_list = iter_attib.key_list;
							if(this.key_list == null)
								return false;
							this.curr_key = this.key_list.first();
					
							if(this.curr_key.data != null) 
								return true;
							else 
								return false;
						}
						else {
							if(this.curr_key.next == null)
								return false;
					
							this.curr_key = this.curr_key.next;
							return true;
						}
					}
			
					public string? get() {
						if(this.curr_key == null)
							return null;
						return this.curr_key.data;
					}
				}
			}

			public class Values {
				private unowned Attributes attrib;
		
				public Values(Attributes _attrib) {
					attrib = _attrib;
				}
		
				public bool contains(string needle_value) {
					foreach(string current_val in attrib.value_list) {
						if(str_equal(needle_value, current_val))
							return true;
					}
					return false;
				}
		
				public Iterator iterator() {
					return new Iterator(this.attrib);
				}
	
				public class Iterator {
					private unowned Attributes iter_attrib;
					private List<unowned string> value_list = null;
					private unowned List<string> curr_value = null;
		
					public Iterator(Attributes _iter_attrib) {
						this.iter_attrib = _iter_attrib;
					}

					public bool next() {
						if(this.value_list == null) {
							this.value_list = iter_attrib.value_list;
							if(this.value_list == null)
								return false;
							this.curr_value = this.value_list.first();
					
							if(this.curr_value.data != null) {
								return true;
							}
							else {
								return false;
							}
						}
						else {
							if(this.curr_value.next == null) {
								return false;
							}
							this.curr_value = this.curr_value.next;
							return true;
						}
					}

					public string? get() {
						if(this.curr_value == null)
							return null;
						return this.curr_value.data;
					}
				}
			}

			public void add(string key, string val) {
				assert(table != null);
				table.insert(key, val);
			}
	
			public void replace(string key, string val) {
				assert(table != null);
				table.replace(key, val);
			}
	
			public void remove(string key) {
				assert(table != null);
				table.remove(key);
			}
	
			public void clear() {
				assert(table != null);
				table.remove_all();
			}
	
			public int item_count {
				get {
					return (int)table.size();
				}
			}

			public List<unowned string> key_list {
				owned get {
					return table.get_keys();
				}
			}

			public List<unowned string> value_list {
				owned get {
					return table.get_values();
				}
			}

			public string? get(string key) {
				return table.lookup(key);
			}

			public void set(string key, string? val) {
				if(val == null) {
					table.remove(key);
				}
				else {
					table.insert(key, val);
				}
			}
		}
		
		public bool has_text() {
			return this.text != null;
		}
		
		public bool has_children() {
			return _children_count > 0 && this._first != null;
		}

		public bool has_attributes() {
			return attributes.item_count > 0;
		}

		private Node? _first = null;
		private unowned Node? _last = null;

		public int children_count {
			get {
				return this._children_count;
			}
		}

		public void prepend_child(Node node) {
			assert(node.parent == null);
			node._parent = this;
			if(this._first == null && this._last == null) {
				this._first = node;
				this._last = node;
				this._children_count++;
			}
			else {
				this.insert_child(0, node);
			}
			return;
		}

		public void append_child(Node node) {
			assert(node.parent == null);
			node._parent = this;
			if(this._first == null && this._last == null) {
				this._first = node;
				this._last = node;
			}
			else {
				this._last._next = node;
				node._previous = this._last;
				this._last = node;
			}
			this._children_count++;
			return;
		}

		public void insert_child(int pos, Node node) {
			assert(node.parent == null);
			node._parent = this;
			if(pos < 0) {
				pos = this._children_count - 1 - pos;
				assert(pos >= 0);
			}
		
			if(pos > this._children_count) {
				this.append_child(node);
			}
			else if(pos == 0) {
				node._next = this._first;
				this._first._previous = node;
				this._first = node;
				this._children_count++;
			}
			else {
				Node prev = this._first;
				int i = 0;
				while(i < pos - 1) {
					i++;
					prev = prev.next;
				}
				node._previous = prev;
				node._next = prev.next;
				node.next._previous = node;
				prev._next = node;
				this._children_count++;
			}
		}
		
		// returns the first appearance only !!!
		//TODO: method that returns all children with a certain name
		public unowned Node? get_child_by_name(string childname) {
			foreach(unowned Node n in this) {
				if(n.name == childname)
					return n;
			}
			return null;
		}
		
		public Node[] get_children_by_name(string childname) {
			Node[] nds = {};
			foreach(unowned Node n in this) {
				if(n.name == childname)
					nds += n;
			}
			return nds;
		}

		public int get_idx_of_child(Node node) {
			int idx = -1;
			foreach(Node n in this) {
				if(&n == &node) { //adress compare
					return idx;
				}
				idx++;
			}
			return idx;
		}

		//get node by index; don't use this to iterate over list
		public unowned Node? get(int idx) {
			if(idx > (this._children_count - 1))
				return null;
		
			unowned Node? nd = null;;
			if(idx == 0) {
				nd = this._first;
			} 
			else if(idx == this._children_count - 1) {
				nd = this._last;
			} 
			else if(idx <= this._children_count / 2) { //start from begin
				nd = this._first;
				int i = 0;
				while(i != idx) {
					nd = nd.next;
					i++;
				}
			}
			else { //start from end
				nd = this._last;
				for (int i = this._children_count - 1; i != idx; i--) {
					nd = nd.previous;
				}
			}
			//check if we have a container
			if(nd == null)
				return null;
			else
				return nd;
		}

		//simply overwrite the Node
		public void set(int idx, Node node) {
			assert(node.parent == null);
			node._parent = this;
			if(idx > (this._children_count - 1))
				return; //should I put a warning here?
			
			unowned Node? nd = null;;
			if(idx == 0) {
				nd = this._first;
			}
			else if(idx == this._children_count - 1) {
				nd = this._last;
			} 
			else if(idx <= this._children_count / 2) { //start from begin
				int i = 0;
				nd = this._first;
				while(i != idx) {
					nd = nd.next;
					i++;
				}
			}
			else { //start from end
				int i = this._children_count - 1;
				nd = this._last;
				while(i != idx) {
					nd = nd.previous;
					i--;
				}
			}
			return_if_fail(nd != null);
		
			Node prev = nd.previous;
			Node nxt = nd.next;
			
			node._previous = prev;
			node._next = prev.next;
			if(nxt != null)
				nxt._previous = node;
			if(prev != null)
				prev._next = node;
			if(nd == this._first)
				this._first = node;
			if(nd == this._last)
				this._last = node;
		}

		public bool remove_child(Node node) {
			int idx = get_idx_of_child(node);
			if(idx >= 0) {
				return remove_child_at_idx(idx);
			}
			else {
				return false;
			}
		}
	
		public bool remove_child_at_idx(int idx) {
			if(idx > (this._children_count - 1))
				return false;
			
			unowned Node? nd = null;;
			if(idx == 0) {
				nd = this._first;
			} 
			else if(idx == this._children_count - 1) {
				nd = this._last;
			} 
			else if(idx <= this._children_count / 2) { //start from begin
				nd = this._first;
				int i = 0;
				while(i != idx) {
					nd = nd.next;
					i++;
				}
			}
			else { //start from end
				nd = this._last;
				for(int i = this._children_count - 1; i != idx; i--) {
					nd = nd.previous;
				}
			}
			//check if we have a container
			if(nd == null)
				return false;
			//put the list parts together
			if(nd == this._first) {
				this._first = nd.next;
			}
			if(nd == this._last) {
				this._last = nd.previous;
			}
			if(nd.previous != null) {
				nd.previous._next = nd.next;
			}
			if(nd.next != null) {
				nd.next._previous = nd.previous;
			}
			nd._previous = null;
			nd._next = null;
			this._children_count--;
			return true;
		}
	
		public void clear() {
			this._first = this._last = null;
			this._children_count = 0;
		}

		public Iterator iterator() {
			return new Iterator(this);
		}

		public class Iterator {
			private bool started = false; //set to first item on first iteration
			private bool removed = false;
			private unowned Node parent_node;
			private int _index;

			//a pointer to the current child for the Iterator of the node
			private unowned Node? current_child;

			public Iterator(Node parent_node) {
				this.parent_node = parent_node;
				this.current_child = null;
				this._index = -1;
			}

			public bool next() {
				if(this.removed && this.current_child != null) {
					this.removed = false;
					return true;
				}
				else if(!this.started && this.parent_node._first != null) {
					this.started = true;
					this.current_child = this.parent_node._first;
					this._index++;
					return true;
				}
				else if(this.current_child != null && this.current_child.next != null) {
					this.current_child = this.current_child.next;
					this._index++;
					return true;
				}
				return false;
			}

			public unowned Node get() {
				assert(this.current_child != null);
				return this.current_child;
			}

			public void set(Node node) {
				assert(this.current_child != null);
				
				Node? prev = this.current_child.previous;
				Node? nxt = this.current_child.next;
				
				node._previous = prev;
				node._next = prev.next;
				if(nxt != null)
					nxt._previous = node;
				if(prev != null)
					prev._next = node;

				if(this.current_child == this.parent_node._first)
					this.parent_node._first = node;
				if(this.current_child == this.parent_node._last)
					this.parent_node._last = node;
			}
		}
	}
}
