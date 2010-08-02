/* simple-xml.vala
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

	public const string AMPERSAND_ESCAPED    = "&amp;";
	public const string GREATER_THAN_ESCAPED = "&gt;";
	public const string LOWER_THAN_ESCAPED   = "&lt;";
	public const string QUOTE_ESCAPED        = "&quot;";
	public const string APOSTROPH_ESCAPED    = "&apos;";
	
	public class Reader {
		// simple xml reader that fits with vala more than libxml 
		// TODO: Implement async reading
		private string? xml_string = null;
		private string filename;
		private GLib.MappedFile? mapped_file = null;


		private char* begin;
		private char* current;
		private char* end;

		private string name;

		private HashTable<string, string> attributes = new HashTable<string, string>(str_hash, str_equal);
		private bool empty_element;
	
		private enum TokenType {
			NONE,
			START_ELEMENT,
			END_ELEMENT,
			TEXT,
			ERROR,
			EOF;
		}

		private class Token {
			public char* begin;
			public char* end;
		}

		public Node root;

		public Reader(string filename) {
			assert(filename != null);
			this.filename = filename;
			try {
				mapped_file = new MappedFile(filename, false);
				begin = mapped_file.get_contents();
				end = begin + mapped_file.get_length();
				current = begin;
			}
			catch(FileError e) {
				stderr.printf("Unable to map file `%s': %s".printf(filename, e.message));
			}
		}
	
		public Reader.from_string(string? xml_string) {
			assert(xml_string != null);
			this.xml_string = xml_string;
			begin = this.xml_string;
			end = begin + this.xml_string.size();
			current = begin;
		}

		public void read(bool case_sensitive = true) {
			Token token;
			TokenType tt;
			root = new Node(null);
			Node current_node = root;
			while((tt = this.read_token(out token)) != Reader.TokenType.EOF) {
				if(tt == Reader.TokenType.START_ELEMENT) {
					assert(token.end > token.begin + 1);
					Node n = new Node(get_nodename(token.begin + 1, token.end));

					foreach(string s in attributes.get_keys()) //TODO copy htable ?
						n.attributes.insert(s, get_attribute(s));

					current_node.append_child(n);
					current_node = n;
				}
				if(tt == Reader.TokenType.END_ELEMENT) {
					//verify that end element has the same name as start
					// TODO: handle empty element
					assert(token.end - 1 > token.begin + 2);
					string? end_element_name = get_nodename(token.begin + 2, token.end);
					//print("current_node.name: %s ; end_element_name: %s\n", current_node.name, end_element_name);
					if(case_sensitive)
						if(current_node.name != end_element_name) {
							root = null;
							print("--- Exit with errors. ---\n");
						}
					else
						if(current_node.name.down() != end_element_name.down()) {
							root = null;
							print("--- Exit with errors. ---\n");
						}
						assert(current_node.name.down() == end_element_name.down());
					
					//one level up in the hierarchy
					if(current_node.parent != null) {
						current_node = current_node.parent;
					}
				}
				if(tt == Reader.TokenType.TEXT) {
					current_node.text = unescape_text(get_text(token.begin, token.end));
				}
				if(tt == Reader.TokenType.ERROR) {
					current_node = null;
					root = null;
					print("--- Exit with errors. ---\n");
					break;
				}
			}
		}

		private inline string? get_attribute(string attr) {
			return attributes.lookup(attr);
		}

		private inline string get_text(char* token_begin_pos, char* token_end_pos) {
			return ((string)(token_begin_pos)).ndup(token_end_pos - token_begin_pos);
		}
	
		private string get_nodename(char* token_begin_pos, char* token_end_pos) {
			//nodename may not have spaces, so we read the whole name until space or return eveything
			char* nn_begin   = token_begin_pos;
			char* nn_current = nn_begin;
			char* nn_end     = token_end_pos;
			while(nn_current < nn_end) {
				nn_current++;
				if(nn_current[0].isspace() ||
				   nn_current[0] == '>') {
					assert(nn_current > nn_begin);
					assert(nn_current < token_end_pos);
					return ((string)(nn_begin)).ndup(nn_current - nn_begin);
				}
			}
			return ((string)(token_begin_pos)).ndup(token_end_pos - token_begin_pos);
		}

		private string unescape_text(string text) {
			//replace &amp; &lt;  &gt; &quot; &apos
			string txt = text;
			txt = text.replace(AMPERSAND_ESCAPED, "&");
			txt = txt.replace(GREATER_THAN_ESCAPED, ">");
			txt = txt.replace(LOWER_THAN_ESCAPED, "<");
			txt = txt.replace(QUOTE_ESCAPED, "\"");
			txt = txt.replace(APOSTROPH_ESCAPED, "'");
			return txt;
		}

		//sets the Location behind the end of the whitespace(space, tab, newline)
		private inline void skip_space() {
			while(this.current < this.end && this.current[0].isspace()) {
				this.current++;
			}
		}
	
		private inline string read_name() {
			char* begin_name = this.current;
			while(this.current < this.end && 
				  !(this.current[0] == ' ' ||
				    this.current[0] == '>' ||
				    this.current[0] == '/' ||
				    this.current[0] == '=')) {
				unichar u =((string) this.current).get_char_validated((long)(this.end - this.current));
				if(u !=(unichar)(-1)) {
					this.current += u.to_utf8(null);
				}
				else {
					stderr.printf("invalid UTF-8 character");
				}
			}
			if(this.current == begin_name) {
				stderr.printf("invalid or non-existant name");
			}
			return((string) begin_name).ndup(this.current - begin_name);
		}

		private TokenType read_token(out Token token) {
			token = new Token();
			attributes.remove_all();

			if(empty_element) {
				empty_element = false;
				return TokenType.END_ELEMENT;
			}

			skip_space();

			TokenType type = TokenType.NONE;
			char* read_token_begin = this.current;
			token.begin = read_token_begin;

			if(this.current >= this.end) {
				type = TokenType.EOF;
			} 
			else if(current[0] == '<') {
				this.current++;
				if(this.current >= this.end) {
					stderr.printf("Error: Invalid xml file! \n");
					root = null;
					return TokenType.ERROR;
				} 
				else if(this.current[0] == '?') {
					// processing instruction
				} 
				else if(this.current[0] == '!') {
					// comment / doctype
					this.current++;
					if(this.current < end - 1 && this.current[0] == '-' && this.current[1] == '-') {
						// comment
						current += 2;
						while(this.current < this.end - 2) {
							if(this.current[0] == '-' && this.current[1] == '-' && this.current[2] == '>') {
								this.current += 3;
								break;
							}
							this.current++;
						}
						//TODO: Also store comment
						return read_token(out token);
					}
				} 
				else if(current[0] == '/') {
					type = TokenType.END_ELEMENT;
					this.current++;
					token.begin = this.current;
					name = read_name();
					token.end = token.begin + name.size() + 1;
					token.begin -= 2;
					if(this.current >= this.end || this.current[0] != '>') {
						stderr.printf("Error: Invalid xml file! Expected '>'\n");
						root = null;
						return TokenType.ERROR;
					}
					this.current++;
				} 
				else {
					type = TokenType.START_ELEMENT;
					name = read_name();
					skip_space();
					while(this.current < this.end && this.current[0] != '>' && this.current[0] != '/') {
						string attr_name = read_name();
						if(this.current >= this.end || this.current[0] != '=') {
							// error
							stderr.printf("Error: Invalid xml file! \n");
							root = null;
							return TokenType.ERROR;
						}
						this.current++;
						// FIXME allow single quotes
						if(this.current >= this.end || this.current[0] != '"') {
							// error
							stderr.printf("Error: Invalid xml file! \n");
							root = null;
							return TokenType.ERROR;
						}
						this.current++;
						char* attr_begin = this.current;
						while(this.current < this.end && current[0] != '"') {
							unichar u =((string) this.current).get_char_validated((long)(this.end - this.current));
							if(u !=(unichar)(-1)) {
								this.current += u.to_utf8(null);
							} 
							else {
								stderr.printf("invalid UTF-8 character");
							}
						}
						string attr_value = unescape_text(((string) attr_begin).ndup(current - attr_begin));
						if(this.current >= this.end || this.current[0] != '"') {
							stderr.printf("Found unquoted attribute value! \n");
							root = null;
							return TokenType.ERROR;
						}
						this.current++;
						attributes.insert(attr_name, attr_value);
						skip_space();
					}
					if(this.current[0] == '/') {
						empty_element = true;
						this.current++;
						skip_space();
					} 
					else {
						empty_element = false;
					}
					if(this.current >= this.end || this.current[0] != '>') {
						stderr.printf("Error: Invalid xml file! \n");
						root = null;
						return TokenType.ERROR;
					}
					this.current++;
				}
			}
			else {
				skip_space();
				char* text_begin = current;
				while(this.current < this.end && this.current[0] != '<') {
					unichar u =((string) this.current).get_char_validated((long)(this.end - this.current));
					if(u !=(unichar)(-1)) {
						this.current += u.to_utf8(null);
					} 
					else {
						stderr.printf("invalid UTF-8 character\n");
					}
				}
				if(text_begin == current) {
					// no text
					// read next token
					print("--- no text in node ---\n");
					return read_token(out token);
				}
				type = TokenType.TEXT;
			}

			token.end = this.current;

			return type;
		}
	}




	public class Writer {
		// simple xml writer that fits with vala more than libxml 
		// TODO: Implement async writing

		Node root;
		
		public Writer(Node root, string header_type_string = "xml", string version_string = "1.0", string encoding_string = "UTF-8") {
			this.root = root;
		}
		
		public void write(string filename) {
			File f = File.new_for_commandline_arg(filename);
			FileOutputStream stream = null;
			try {
				if(f.query_exists(null))
					f.delete(null);
				stream = f.create(FileCreateFlags.REPLACE_DESTINATION, null);
			}
			catch(Error e) {
				print("Cannot create file. %s\n", e.message);
				return;
			}
			write_header(ref stream);

			if(root == null)
				return;

			write_node_data(root, ref stream);
		}
		
		private void write_header(ref FileOutputStream stream) {
			//<?xml version="1.0" encoding="UTF-8"?>
			ssize_t size;
			ssize_t already_written = 0;
			
			string header_string = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"; //TODO
			char* header_pointer = header_string;
			try {
				while(already_written < header_string.size()) {
					size = stream.write((void*) header_pointer, header_string.size() - already_written, null);
					already_written = already_written + size;
					header_pointer += size;
				}
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		
		private int dpth = 0;
		private void do_n_spaces(ref FileOutputStream stream) {
			for(int i=0; i<dpth;i++)
				write_string_to_stream(" ", ref stream);
		}
		
		private void write_string_to_stream(string text, ref FileOutputStream stream) {
			ssize_t size;
			ssize_t already_written = 0;
			char* text_pointer = text;
			try {
				while(already_written < text.size()) {
					size = stream.write((void*) text_pointer, text.size() - already_written, null);
					already_written = already_written + size;
					text_pointer += size;
				}
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		
		private void begin_node(Node node, ref FileOutputStream stream) {
			if(node.name == null)
				return;
			write_string_to_stream("<", ref stream);
			write_string_to_stream(node.name, ref stream);
		}

		private void end_node(Node node, ref FileOutputStream stream) {
			if(node.name == null)
				return;
			write_string_to_stream("</", ref stream);
			write_string_to_stream(node.name, ref stream);
			write_string_to_stream(">\n", ref stream);
		}


		private void write_attributes(Node node, ref FileOutputStream stream) {
			if(node == null)
				return;
			
			// insert attribs into node begin
			foreach(string s in node.attributes.get_keys()) {
				write_string_to_stream(" %s=\"%s\"".printf(s, escape_text(node.attributes.lookup(s))), ref stream);
			}
		}
		
		private string escape_text(string text) {
			string? result = null;
			result =   text.replace("&", AMPERSAND_ESCAPED);
			result = result.replace(">", GREATER_THAN_ESCAPED);
			result = result.replace("<", LOWER_THAN_ESCAPED);
			result = result.replace("\"", QUOTE_ESCAPED);
			result = result.replace("'", APOSTROPH_ESCAPED);
			return result;
		}
		
		private void write_node_data(SimpleXml.Node? mrnode, ref FileOutputStream stream) {
			if(mrnode == null)
				return;

			foreach(SimpleXml.Node node in mrnode.children) {
				do_n_spaces(ref stream);
				
				begin_node(node, ref stream);
				write_attributes(node, ref stream);
				write_string_to_stream(">", ref stream);
				
				if(node.has_text())
					write_string_to_stream(escape_text(node.text), ref stream);

				if(!node.has_text()) {
					write_string_to_stream("\n", ref stream);
				}

				dpth += 2;
				
				// Recursion
				write_node_data(node, ref stream);

				dpth -= 2;

				if(!node.has_text()) {
					do_n_spaces(ref stream);
				}

				end_node(node, ref stream);
			}
		}
	}




	public class Node {
		// Represents a xml node. Can contain more nodes, text and attributes
		private string? _name = null;
		private unowned Node _parent;

		public HashTable<string, string> attributes = new HashTable<string, string>(str_hash, str_equal);

		public Children children;
	
		public Node(string? name) {
			this._name = name;
			children = new Children(this);
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

		public bool has_text() {
			return this.text != null;
		}

		public void append_child(Node child) {
			children.append(child);
		}

		public void prepend_child(Node child) {
			children.prepend(child);
		}

		public void insert_child(int pos, Node child) {
			children.insert(pos, child);
		}
	
		public unowned Node? get_child_by_name(string childname) {
			return children.get_by_name(childname);
		}
		
		public class Children {
			private int _count = 0;
		
			private Container? _first = null;
			private unowned Container? _last = null;

			private unowned Node _parent;
		
			public Node? parent { 
				get {
					return _parent;
				}
			}
		
			public Children(Node parent) {
				this._parent = parent;
			}
		
			public int count {
				get {
					return this._count;
				}
			}

			public void prepend(Node node) {
				assert(node.parent == null);
				node._parent = this._parent;
				Container c = new Container(node);
				if(this._first == null && this._last == null) {
					this._first = c;
					this._last = c;
					this._count++;
				}
				else {
					this.insert(0, node);
				}
				return;
			}

			public void append(Node node) {
				assert(node.parent == null);
				node._parent = this._parent;
				Container c = new Container(node);
				if(this._first == null && this._last == null) {
					this._first = c;
					this._last = c;
				}
				else {
					this._last.next = c;
					c.previous = this._last;
					this._last = c;
				}
				this._count++;
				return;
			}

			public void insert(int pos, Node node) {
				assert(node.parent == null);
				node._parent = this._parent;
				if(pos < 0) {
					pos = this._count - 1 - pos;
					assert(pos >= 0);
				}
			
				if(pos > this._count) {
					this.append(node);
				}
				else if(pos == 0) {
					Container c = new Container(node);
					c.next = this._first;
					this._first.previous = c;
					this._first = (owned)c; // ownership of first item needed!
					this._count++;
				}
				else {
					Container c = new Container(node);
					Container previous = this._first;
					for(int i = 0; i < pos - 1; i++) {
						previous = previous.next;
					}
					c.previous = previous;
					c.next = previous.next;
					c.next.previous = c;
					previous.next = c;
					this._count++;
				}
			}
			public unowned Node? get_by_name(string childname) {
				foreach(unowned Node n in this) {
					if(n.name == childname)
						return n;
				}
				return null;
			}
			
			public int get_idx_of_child(Node node) {
				int idx = -1;
				foreach(Node n in this) {
					if(&n == &node) {
						return idx;
					}
					idx++;
				}
				return idx;
			}

			//get node by index; don't use this to iterate over list
			public unowned Node? get(int idx) {
				if(idx > (this._count - 1))
					return null;
			
				unowned Container? c = null;;
				if(idx == 0) {
					c = this._first;
				} 
				else if(idx == this._count - 1) {
					c = this._last;
				} 
				else if(idx <= this._count / 2) { //start from begin
					c = this._first;
					int i = 0;
					while(i != idx) {
						c = c.next;
						i++;
					}
				}
				else { //start from end
					c = this._last;
					for (int i = this._count - 1; i != idx; i--) {
						c = c.previous;
					}
				}
				//check if we have a container
				if(c == null)
					return null;
				else
					return c.data;
			}

			//simply overwrite the Node
			public void set(int idx, Node node) {
				assert(node.parent == null);
				node._parent = this._parent;
				if(idx > (this._count - 1))
					return; //should I put a warning here?
				
				unowned Container? c = null;;
				if(idx == 0) {
					c = this._first;
				}
				else if(idx == this._count - 1) {
					c = this._last;
				} 
				else if(idx <= this._count / 2) { //start from begin
					int i = 0;
					c = this._first;
					while(i != idx) {
						c = c.next;
						i++;
					}
				}
				else { //start from end
					int i = this._count - 1;
					c = this._last;
					while(i != idx) {
						c = c.previous;
						i--;
					}
				}
				//check if we have a container
				return_if_fail(c != null);
			
				c.data = node;
			}

			public bool remove(Node node) {
				int idx = get_idx_of_child(node);
				if(idx >= 0) {
					return remove_child_at_idx(idx);
				}
				else {
					return false;
				}
			}
		
			public bool remove_child_at_idx(int idx) {
				if(idx > (this._count - 1))
					return false;
				
				unowned Container? c = null;;
				if(idx == 0) {
					c = this._first;
				} 
				else if(idx == this._count - 1) {
					c = this._last;
				} 
				else if(idx <= this._count / 2) { //start from begin
					c = this._first;
					int i = 0;
					while(i != idx) {
						c = c.next;
						i++;
					}
				}
				else { //start from end
					c = this._last;
					for (int i = this._count - 1; i != idx; i--) {
						c = c.previous;
					}
				}
				//check if we have a container
				if(c == null)
					return false;
				//put the list parts together
				if(c == this._first) {
					this._first = c.next;
				}
				if(c == this._last) {
					this._last = c.previous;
				}
				if (c.previous != null) {
					c.previous.next = c.next;
				}
				if (c.next != null) {
					c.next.previous = c.previous;
				}
				c.previous = null;
				c.next = null;
				this._count--;
				return true;
			}
		
			public void clear() {
				this._first = this._last = null;
				this._count = 0;
			}

			private class Container {
				public Node data;
				public unowned Container? previous = null;
				public Container? next = null;
				public Container(Node data) {
					this.data = data;
				}
			}

			public Iterator iterator() {
				return new Iterator(this);
			}

			public class Iterator {
				private bool started = false; //set to first item on first iteration
				private bool removed = false;
				private Children children;
				private int _index;

				private unowned Container? current_item;

				public Iterator(Children children) {
					this.children = children;
					this.current_item = null;
					this._index = -1;
				}

				public bool next() {
					if(this.removed && this.current_item != null) {
						this.removed = false;
						return true;
					}
					else if(!this.started && this.children._first != null) {
						this.started = true;
						this.current_item = this.children._first;
						this._index++;
						return true;
					}
					else if(this.current_item != null && this.current_item.next != null) {
						this.current_item = this.current_item.next;
						this._index++;
						return true;
					}
					return false;
				}

				public unowned Node get() {
					assert(this.current_item != null);
					return this.current_item.data;
				}

				public bool last() {
					if(children.count == 0) {
						return false;
					}
					this.current_item = this.children._last;
					this.started = true;
					this._index = this.children._count - 1;
					return this.current_item != null;
				}

				public void set(Node item) {
					assert(this.current_item != null);
					this.current_item.data = item;
				}
			}
		}
	}
}


//public void do_n_spaces(ref int dpth) {
//	for(int i = 0; i< dpth; i++)
//		print(" ");
//}

//public void show_node_data(SimpleXml.Node? mrnode, ref int dpth) {
//	if(mrnode == null)
//		return;
//	foreach(SimpleXml.Node node in mrnode.children) {
//		do_n_spaces(ref dpth);
//		print("%s ", node.name);
//		foreach(string s in node.attributes.get_keys())
//			print("A:%s=%s ", s, node.attributes.lookup(s));
//		if(node.has_text())
//			print("text=%s\n", node.text);
//		else
//			print("\n");
//		dpth += 2;
//		show_node_data(node, ref dpth);
//	}
//	dpth -= 2;
//}

//public static void main() {
//	var mr = new SimpleXml.Reader("./markup.xspf");
//	mr.read();
//	int dpth = 0;
//	show_node_data(mr.root, ref dpth);
//	var mw = new SimpleXml.Writer(mr.root);
//	mw.write("./tmp_xml.xml");
//}



