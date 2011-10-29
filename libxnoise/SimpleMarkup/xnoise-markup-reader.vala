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

	public class Reader : Object {
	
		private const GLib.MarkupParser mp = {
			start_cb,       // when an element opens
			end_cb,         // when an element closes
			text_cb,        // when text is found
			null,           // when comments are found
			null            // when errors occur
		};
	
		private MarkupParseContext ctx;
		private int depth = 0;
		private File file;
		private string content;
		private bool parse_from_string = false;
		private bool locally_buffered = false;

		
		public Node root;
		
		// Signals
		public signal void started();
		public signal void finished();
	
		public Reader(File file) {
			assert(file != null);
			this.file = file;
			setup_ctx();
		}
		
		public Reader.from_string(string? xml_string) {
			assert(xml_string != null);
			this.content = xml_string;
			setup_ctx();
			parse_from_string = true;
		}
		
		private void setup_ctx() {
			ctx = new MarkupParseContext(
			   mp,       // the structure with the callbacks
			   0, // MarkupParseFlags
			   this,     // extra argument for the callbacks, methods in this case
			   destroy   // when the parsing ends
			);
		}
	
		private void destroy() {
		}
		
		private unowned Node current_node = null;
		
		
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
			try {
				FileUtils.get_contents(file.get_path(), out content, null);
			}
			catch(FileError e) {
				print("Unable to get file content: %s", e.message);
			}
		}
		
		private async void load_markup_file_asyn() {
			if(!file.has_uri_scheme("file"))
				file = yield buffer_locally_asyn();
			load_markup_file(); //TODO
		}
		
		public void read() {
			started();
			if(!parse_from_string)
				load_markup_file();
			
			if(ctx == null)
				setup_ctx();
			root = new Node(null);
			current_node = root;
			try {
				ctx.parse(content, -1);
			}
			catch(MarkupError e) {
				print("%s\n", e.message);
			}
			if(locally_buffered)
				remove_locally_buffered_file(); //cleanup
			finished();
		}
		
		public async void read_asyn(Cancellable? cancellable = null) {
			started();
			if(!parse_from_string)
				yield load_markup_file_asyn();
			if(ctx == null)
				setup_ctx();
			root = new Node(null);
			current_node = root;
			Idle.add( () => {
				try {
					if(cancellable != null && cancellable.is_cancelled())
						return false;
					ctx.parse(content, -1);
				}
				catch(MarkupError e) {
					print("%s\n", e.message);
					return false;
				}
				Idle.add( () => {
					if(cancellable != null && cancellable.is_cancelled())
						return false;
					finished();
					return false;
				});
			
				if(locally_buffered) {
					Idle.add( () => {
						remove_locally_buffered_file(); //cleanup
						return false;
					});
				}
				return false;
			});
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
		
		private void start_cb(MarkupParseContext ctx, string name,
			                   string[] attr_keys, string[] attr_values) throws MarkupError {
			Node n = new Node(name);
			for(int i = 0; i < attr_keys.length; i++) {
				n.attributes[attr_keys[i]] = attr_values[i];
			}
			current_node.append_child(n);
			current_node = n;
			depth ++;
		}
	
		private void end_cb(MarkupParseContext ctx, string name) throws MarkupError {
			//one level up in the hierarchy
			if(current_node.parent != null) {
				current_node = current_node.parent;
				depth --;
			}
			else {
				print("reached root end\n");
				finished();
			}
		}
	
		private void text_cb(MarkupParseContext ctx, string text, size_t text_len) throws MarkupError {
			current_node.text = text; //unescape_text(text);
		}
	}
}




