/* simple-xml-writer.vala
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
}
