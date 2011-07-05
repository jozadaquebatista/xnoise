/* simple-xml-reader.vala
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

//TODO: take care about charsets/encodings

namespace Xnoise.SimpleMarkup {

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
			end = begin + this.xml_string.length;
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
			
			//File curr = File.new_for_commandline_arg(Environment.get_current_dir());
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
						n.attributes[s] = get_attribute(s);

					current_node.append_child(n);
					current_node = n;
				}
				if(tt == Reader.TokenType.EMPTY_ELEMENT) {
					//print("empty\n")
					//one level up in the hierarchy
					if(current_node.parent != null) {
						current_node = current_node.parent;
					}
				}
				if(tt == Reader.TokenType.END_ELEMENT) {
					//verify that end element has the same name as start
					assert(token.end - 1 > token.begin + 2);
					string? end_element_name = get_nodename(token.begin + 2, token.end);
					//print("current_node.name: %s ; end_element_name: %s\n", current_node.name, end_element_name);
					if(case_sensitive)
						if(current_node.name != end_element_name) {
							root = null;
							print("--- Exit with errors. #1 ---\n");
						}
					else
						if(current_node.name.down() != end_element_name.down()) {
							root = null;
							print("--- Exit with errors. #2 ---\n");
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
					foreach(string s in attributes.get_keys())
						n.attributes[(case_sensitive ? s : s.down())] = get_attribute(s);

					current_node.append_child(n);
					current_node = n;
				}
				if(tt == Reader.TokenType.EMPTY_ELEMENT) {
					//print("empty\n")
					//one level up in the hierarchy
					if(current_node.parent != null) {
						current_node = current_node.parent;
					}
				}
				if(tt == Reader.TokenType.END_ELEMENT) {
					//verify that end element has the same name as start
					// TODO: handle empty element
					// TODO: handle unnamed node endings
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
			return ((string)(token_begin_pos)).substring(0, (long)(token_end_pos - token_begin_pos));
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
					return ((string)(nn_begin)).substring(0, (long)(nn_current - nn_begin));
				}
			}
			return ((string)(token_begin_pos)).substring(0, (long)(token_end_pos - token_begin_pos));
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
			return((string) begin_name).substring(0, (long)(this.current - begin_name));
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
				return TokenType.EMPTY_ELEMENT;
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
					token.end = token.begin + name.length + 1;
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
						string attr_value = unescape_text(((string) attr_begin).substring(0, (long)(current - attr_begin)));
						if(this.current >= this.end || this.current[0] != '"') {
							stderr.printf("Found unquoted attribute value! \n");
							root = null;
							return TokenType.ERROR;
						}
						this.current++;
						attributes.insert(attr_name.down(), attr_value); //TODO: is it ok to do this lowercase always?
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
}




