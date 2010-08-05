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
	
	public class Reader : Object {
		// simple xml reader that fits with vala more than libxml 
		// TODO: Implement async reading
		private string? xml_string = null;
		private File file;
		private GLib.MappedFile? mapped_file = null;


		private char* begin;
		private char* current;
		private char* end;
		
		private bool parse_from_string = false;
		private bool locally_buffered = false;

		private string name;

		private HashTable<string, string> attributes = new HashTable<string, string>(str_hash, str_equal);
		private bool empty_element;
	
		public signal void started();
		public signal void finished();
		
		private enum TokenType {
			NONE,
			START_ELEMENT,
			END_ELEMENT,
			EMPTY_ELEMENT,
			TEXT,
			ERROR,
			NOTHING,
			EOF;
		}

		private class Token {
			public char* begin;
			public char* end;
		}

		public Node root;

		public Reader(File file) {
			assert(file != null);
			this.file = file;
		}
	
		public Reader.from_string(string? xml_string) {
			assert(xml_string != null);
			this.xml_string = xml_string;
			begin = this.xml_string;
			end = begin + this.xml_string.size();
			current = begin;
			parse_from_string = true;
		}
		
	private File? buffer_locally() {
		bool buf = false;
		File dest;
		locally_buffered = true;
		var rnd = new Rand();
		try {
			string tmp_dir = Environment.get_tmp_dir();
			dest = File.new_for_path(GLib.Path.build_filename(tmp_dir, ".simple_xml", file.get_basename() + rnd.next_int().to_string()));
			if(!dest.get_parent().query_exists(null))
				dest.get_parent().make_directory_with_parents(null);
			
			buf = this.file.copy(dest, 
			                     FileCopyFlags.OVERWRITE, 
			                     null, 
			                     null); 
		}
		catch(GLib.Error e) {
			print("ERROR: %s\n", e.message);
			return null;
		}
		return dest;
	}

	private async File? buffer_locally_asyn() {
		bool buf = false;
		File dest;
		locally_buffered = true;
		var rnd = new Rand();
		try {
			string tmp_dir = Environment.get_tmp_dir();
			dest = File.new_for_path(GLib.Path.build_filename(tmp_dir, ".simple_xml", file.get_basename() + rnd.next_int().to_string()));
			if(!dest.get_parent().query_exists(null))
				dest.get_parent().make_directory_with_parents(null);

			buf = yield file.copy_async(dest, 
			                            FileCopyFlags.OVERWRITE, 
			                            Priority.DEFAULT, 
			                            null, 
			                            null); 
		}
		catch(GLib.Error e) {
			print("ERROR: %s\n", e.message);
			return null;
		}
		return dest;
	}

		private void load_markup_file() {
			
			if(!file.has_uri_scheme("file"))
				file = buffer_locally();
			
			File curr = File.new_for_commandline_arg(Environment.get_current_dir());
			string rel_path = curr.get_relative_path(file);
			try {
				mapped_file = new MappedFile("./" + rel_path, false);
				begin = mapped_file.get_contents();
				end = begin + mapped_file.get_length();
				current = begin;
			}
			catch(FileError e) {
				stderr.printf("Unable to map file `%s': %s".printf(file.get_uri(), e.message));
			}
		}
	
		private async void load_markup_file_asyn() {
			
			if(!file.has_uri_scheme("file"))
				file = yield buffer_locally_asyn();
			
			File curr = File.new_for_commandline_arg(Environment.get_current_dir());
//			string rel_path = curr.get_relative_path(file);
			try {
				mapped_file = new MappedFile(file.get_path(), false);//("./" + rel_path, false);
				begin = mapped_file.get_contents();
				end = begin + mapped_file.get_length();
				current = begin;
			}
			catch(FileError e) {
				stderr.printf("Unable to map file `%s': %s".printf(file.get_uri(), e.message));
			}
		}
	
		public void read(bool case_sensitive = true, Cancellable? cancellable = null) {
			if(!parse_from_string)
				load_markup_file();

			//TODO: error handling
			started();
			Token token;
			TokenType tt;
			root = new Node(null);
			Node current_node = root;
			while((tt = this.read_token(out token, case_sensitive)) != Reader.TokenType.EOF) {
				if(cancellable != null && cancellable.is_cancelled())
					break;
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
					// TODO: handle unnamed node endings
//					assert(token.end - 1 > token.begin + 2);
//					string? end_element_name = get_nodename(token.begin + 2, token.end);
//					//print("current_node.name: %s ; end_element_name: %s\n", current_node.name, end_element_name);
//					if(case_sensitive)
//						if(current_node.name != end_element_name) {
//							root = null;
//							print("--- Exit with errors. ---\n");
//						}
//					else
//						if(current_node.name.down() != end_element_name.down()) {
//							root = null;
//							print("--- Exit with errors. ---\n");
//						}
//						assert(current_node.name.down() == end_element_name.down());
					
					//one level up in the hierarchy
					if(current_node.parent != null) {
						current_node = current_node.parent;
					}
				}
				if(tt == Reader.TokenType.TEXT) {
					current_node.text = unescape_text(get_text(token.begin, token.end));
				}
				if(tt == Reader.TokenType.NOTHING) {
					//do nothing
				}
				if(tt == Reader.TokenType.ERROR) {
					current_node = null;
					root = null;
					print("--- Exit with errors. ---\n");
					break;
				}
			}
			if(locally_buffered)
				remove_locally_buffered_file(); //cleanup
			finished();
		}

		public async void read_asyn(bool case_sensitive = true, Cancellable? cancellable = null) {
			if(!parse_from_string)
				yield load_markup_file_asyn();
			//TODO: error handling
			started();
			Token token;
			TokenType tt;
			root = new Node(null);
			Node current_node = root;
			while(true) {
				tt = yield this.read_token_asyn(out token, case_sensitive);
				if(tt == Reader.TokenType.EOF)
					break;
				
				if(cancellable != null && cancellable.is_cancelled()){
					current_node = null;
					root = null;
					print("--- cancelled ---\n");
					break;
				}
				if(tt == Reader.TokenType.START_ELEMENT) {
					assert(token.end > token.begin + 1);
					string nn = get_nodename(token.begin + 1, token.end);
					Node n = new Node((case_sensitive ? nn : nn.down()));
					//print("node name: %s\n", nn);
					foreach(string s in attributes.get_keys()) //TODO copy htable ?
						n.attributes.insert((case_sensitive ? s : s.down()), get_attribute(s));

					current_node.append_child(n);
					current_node = n;
				}
				if(tt == Reader.TokenType.END_ELEMENT) {
					//verify that end element has the same name as start
					// TODO: handle empty element
					// TODO: handle unnamed node endings
//					assert(token.end - 1 > token.begin + 2);
//					string? end_element_name = get_nodename(token.begin + 2, token.end);
//					//print("current_node.name: %s ; end_element_name: %s\n", current_node.name, end_element_name);
//					if(case_sensitive)
//						if(current_node.name != end_element_name) {
//							root = null;
//							print("--- Exit with errors. ---\n");
//						}
//					else
//						if(current_node.name.down() != end_element_name.down()) {
//							root = null;
//							print("--- Exit with errors. ---\n");
//						}
//						assert(current_node.name.down() == end_element_name.down());
					
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
			Idle.add( () => {
				finished();
				return false;
			});

			if(locally_buffered) {
				Idle.add( () => {
					remove_locally_buffered_file(); //cleanup
					return false;
				});
			}
		}

		private void remove_locally_buffered_file() {
			if(locally_buffered) {
				try {
					file.delete(null);
				}
				catch(Error e) {
					print("Error cleaning up: %s\n", e.message);
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

		private async TokenType read_token_asyn(out Token token, bool case_sensitive) {
			return read_token(out token, case_sensitive);
		}
		
		private TokenType read_token(out Token token, bool case_sensitive) {
			//based on function from vala markup reader
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
						return TokenType.NOTHING;
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
						stderr.printf("Error end element: Invalid xml file! Expected '>'\n");
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
							stderr.printf("Error start element 1: Invalid xml file! \n");
							root = null;
							return TokenType.ERROR;
						}
						this.current++;
						skip_space();
						// FIXME allow single quotes
						if(this.current >= this.end || (this.current[0] != '"' && this.current[0] != '\'')) {
							// error
							stderr.printf("Error start element 2: Invalid xml file! \n");
							root = null;
							return TokenType.ERROR;
						}
						char quot_character = this.current[0];
						this.current++;
						char* attr_begin = this.current;
						while(this.current < this.end && current[0] != quot_character) {
							unichar uy =((string) this.current).get_char_validated((long)(this.end - this.current));
							if(uy !=(unichar)(-1)) {
								this.current += uy.to_utf8(null);
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
						stderr.printf("Error 4: Invalid xml file! \n");
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
					unichar ux =((string) this.current).get_char_validated((long)(this.end - this.current));
					if(ux !=(unichar)(-1)) {
						this.current += ux.to_utf8(null);
					} 
					else {
						stderr.printf("invalid UTF-8 character\n");
					}
				}
				if(text_begin == current) {
					// no text
					// read next token
					print("--- no text in node ---\n");
					return TokenType.NOTHING;
				}
				type = TokenType.TEXT;
			}

			token.end = this.current;

			return type;
		}
	}




	public class Writer : Object {
		// simple xml writer that fits with vala more than libxml 
		// TODO: Implement async writing

		private Node root;
		private string header_string;
		
		public Writer(Node root, string header_string = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n") {
			this.header_string = header_string;
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
			ssize_t size;
			ssize_t already_written = 0;
			header_string._strip();
			
			if(header_string.size() < 4)
				return;
			
			write_string_to_stream(header_string, ref stream);
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

			foreach(SimpleXml.Node node in mrnode) {
				do_n_spaces(ref stream);
				
				begin_node(node, ref stream);
				write_attributes(node, ref stream);
				
				if(!node.has_text() && node.children_count == 0)
					write_string_to_stream(" />", ref stream);
				else
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

				if(!node.has_text() && node.children_count > 0) 
					do_n_spaces(ref stream);
				
				if(node.has_text() || node.children_count > 0)
					end_node(node, ref stream);
			}
		}
	}




	public class Node {
		// Represents a xml node. Can contain more nodes, text and attributes
		private unowned Node _parent;
		private unowned Node? _previous = null;
		private Node? _next = null;
		private int _children_count = 0;
			
		private string? _name = null;


		public HashTable<string, string> attributes = new HashTable<string, string>(str_hash, str_equal);

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
		
		public bool has_text() {
			return this.text != null;
		}
		
		public bool has_children() {
			return _children_count > 0 && this._first != null;
		}

		public bool has_attributes() {
			return attributes.size() > 0;
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
				for(int i = 0; i < pos - 1; i++) {
					prev = prev.next;
				}
				node._previous = prev;
				node._next = prev.next;
				node.next._previous = node;
				prev._next = node;
				this._children_count++;
			}
		}
		
		public unowned Node? get_child_by_name(string childname) {
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




