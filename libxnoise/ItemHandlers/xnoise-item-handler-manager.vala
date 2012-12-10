/* xnoise-item-handler-manager.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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


using Xnoise;
using Xnoise.Utilities;

namespace Xnoise {

    public class ItemHandlerManager : Object {
        private Array<ItemHandler?> _handlers 
          = new Array<ItemHandler>(true, true, sizeof(ItemHandler));
        
        private HashTable<ItemHandlerType, unowned ItemHandler?> handler_type_map 
          = new HashTable<ItemHandlerType, unowned ItemHandler?>(direct_hash, direct_equal);
    
        private HashTable<string, unowned ItemHandler?> handler_name_map 
          = new HashTable<string, unowned ItemHandler?>(str_hash, str_equal);
    
    
        public Array<unowned Action?> get_actions(ItemType type, ActionContext context, ItemSelectionType selection) {
            //check if ItemType is supported
            //return right action for context and handlers
            
            //TODO: return unique entries
            
            //print("uhm get_actions : %s, %s\n", type.to_string(), context.to_string());
            Array<unowned Action?> item_actions = new Array<unowned Action?>(true, true, sizeof(Action));
            for(int i = 0; i< _handlers.length; i++) {
                ItemHandler current_handler = _handlers.index(i);
                unowned Action? tmp = current_handler.get_action(type, context, selection);
                if(tmp != null)
                    item_actions.append_val(tmp);
            }
            return item_actions;
        }
    
        public void add_handler(ItemHandler handler) {
            assert(handler.set_manager(this) == true);
            _handlers.append_val(handler);
            if(handler.handler_type() != ItemHandlerType.OTHER && 
               handler.handler_type() != ItemHandlerType.UNKNOWN && 
               handler.handler_type() != ItemHandlerType.MENU_PROVIDER)
                handler_type_map.insert(handler.handler_type(), handler);
            handler_name_map.insert(handler.handler_name(), handler);
        }
        
        public void remove_handler(ItemHandler handler) {
            for(int i = 0; i< _handlers.length; i++) {
                if(handler == _handlers.index(i)) {
                    print("removing item handler: %s\n", _handlers.index(i).handler_name());
                    handler_type_map.remove(_handlers.index(i).handler_type());
                    handler_name_map.remove(_handlers.index(i).handler_name());
                    _handlers.remove_index_fast(i);
                    break;
                }
            }
        }

        public ItemHandler? get_handler_by_type(ItemHandlerType type) {
            ItemHandler? hndl = null;
            hndl = handler_type_map.lookup(type);
            if(hndl == null) {
                for(int i = 0; i< _handlers.length; i++) {
                    hndl = _handlers.index(i);
                    if(hndl.handler_type() == type) {
                        return hndl;
                    }
                }
            }
            else {
                return hndl;
            }
            return null;
        }
        
        public ItemHandler get_handler_by_name(string name) {
            return handler_name_map.lookup(name);
        }
        
        private int cnt = 0;
        public void test_func() {
            print("testfunc %d\n", cnt++);
        }
        
        private static string attr = FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE;
        
        public static Item? create_item(string? uri) {
            if(uri == null)
                return Item(ItemType.UNKNOWN);
            Item? item = Item(ItemType.UNKNOWN, uri);
            item.stamp = get_current_stamp(0); // dummy
            File f = File.new_for_uri(uri);
            string scheme = f.get_uri_scheme();
            if(scheme in get_remote_schemes()) {
                // no general check for media extension because often streams are lacking these
                if(Playlist.is_playlist_extension(get_suffix_from_filename(f.get_uri()))) {
                    item.type = Xnoise.ItemType.PLAYLIST;
                }
                else if(scheme in get_media_stream_schemes()) {
                    item.type = Xnoise.ItemType.STREAM;
                }
                else {
                    string u = f.get_uri();
                    if(Playlist.Reader.is_playlist(ref u)) {
                        item.type = Xnoise.ItemType.PLAYLIST;
                    }
                    else {
                        item.type = Xnoise.ItemType.STREAM;
                    }
                }
                return item;
            }
            if(!f.query_exists(null))
                return Item(ItemType.UNKNOWN);
            FileInfo info = null;
            try {
                info = f.query_info(attr, FileQueryInfoFlags.NONE , null);
            }
            catch(Error e) {
                print("Error creating item from uri %s: %s", uri, e.message);
                return item;
            }
            if(info == null)
                return item;
            string content = info.get_content_type();
            string mime = GLib.ContentType.get_mime_type(content);
            setup_pattern_specs();
            bool is_playlist = Playlist.is_playlist_extension(get_suffix_from_filename(f.get_uri()));
            if(pattern_audio.match_string(mime)|| is_playlist == true || supported_types.lookup(mime) == 1 ) {
                if(is_playlist == true) {
                    item.type = Xnoise.ItemType.PLAYLIST;
                }
                else {
                    if(scheme in get_local_schemes()) {
                        item.type = Xnoise.ItemType.LOCAL_AUDIO_TRACK;
                    }
                    else {
                        item.type = ItemType.STREAM;
                    }
                }
            }
            else if(pattern_video.match_string(mime)) {
                    if(scheme in get_local_schemes()) {
                        item.type = ItemType.LOCAL_VIDEO_TRACK;
                    }
                    else {
                        item.type = ItemType.STREAM;
                    }
            }
            else if(info.get_file_type() == FileType.DIRECTORY) {
                if(scheme in get_local_schemes()) { //local scheme
                    item.type = ItemType.LOCAL_FOLDER;
                }
            }
            return item;
        }
        
        public void execute_actions_for_item(Item item, ActionContext context, GLib.Value? data, ItemSelectionType selection) {
            Array<Action?> item_actions = this.get_actions(item.type, context, selection);
            //print("item_actions.length: %u\n", item_actions.length);
            for(int i = 0; i < item_actions.length; i++) {
                unowned Action current = item_actions.index(i);
                if(current.action != null) {
                    print("  %s\n", current.name);
                    current.action(item, data, null);
                }
            }
        }
    }
}
