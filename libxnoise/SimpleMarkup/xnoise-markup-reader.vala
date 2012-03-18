/* simple-xml-reader.vala
 *
 * Copyright (C) 2010  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens
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
               mp,
               0,
               this,
               destroy
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
            
            if (!file.query_exists ()) {
                print("File '%s' doesn't exist.\n", file.get_path ());
                return;
            }
            
            var content_builder = new StringBuilder ();
            try {
                var dis = new DataInputStream(file.read());
                string line;
                while((line = yield dis.read_line_async(Priority.DEFAULT)) != null) {
                    content_builder.append(line);
                    content_builder.append_c('\n');
                }
            }
            catch(Error e) {
                print("%s", e.message);
            }
            content = content_builder.str;
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
        
        private void start_cb(MarkupParseContext ctx, string name, string[] attribute_keys, string[] attribute_values) throws MarkupError {
            Node n = new Node(name);
            for(int i = 0; i < attribute_keys.length; i++)
                n.attributes[attribute_keys[i]] = attribute_values[i];
            
            current_node.append_child(n);
            current_node = n;
        }
        
        private void end_cb(MarkupParseContext ctx, string name) throws MarkupError {
            //one level up in the hierarchy
            if(current_node.parent != null) {
                current_node = current_node.parent;
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




