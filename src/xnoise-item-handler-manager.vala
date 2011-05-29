/* xnoise-item-handler-manager.vala
 *
 * Copyright (C) 2011  Jörn Magens
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
 * 	Jörn Magens
 */

namespace Xnoise {

	public class ItemHandlerManager : Object {
		private Array<ItemHandler?> _handlers 
		  = new Array<ItemHandler>(true, true, sizeof(ItemHandler));
		
		private HashTable<ItemHandlerType, unowned ItemHandler?> handler_type_map 
		  = new HashTable<ItemHandlerType, unowned ItemHandler?>(direct_hash, direct_equal);
	
		private HashTable<string, unowned ItemHandler?> handler_name_map 
		  = new HashTable<string, unowned ItemHandler?>(str_hash, str_equal);
	
	
		public Array<unowned Action?> get_actions(ItemType type, ActionContext context) {
			//check if ItemType is supported
			//return right action for context and handlers
			
			//print("uhm get_actions : %d, %s\n", (int)type, context.to_string());
			Array<unowned Action?> item_actions = new Array<unowned Action?>(true, true, sizeof(Action));
			for(int i = 0; i< _handlers.length; i++) {
				ItemHandler current_handler = _handlers.index(i);
				unowned Action? tmp = current_handler.get_action(type, context);
				if(tmp != null)
					item_actions.append_val(tmp);
			}
			return item_actions;
		}
	
		public void add_handler(ItemHandler handler) {
			assert(handler.set_manager(this) == true);
			_handlers.append_val(handler);
			if(handler.handler_type() != ItemHandlerType.OTHER && handler.handler_type() != ItemHandlerType.UNKNOWN)
				handler_type_map.insert(handler.handler_type(), handler);
			handler_name_map.insert(handler.handler_name(), handler);
		}
		
		public ItemHandler get_handler_by_type(ItemHandlerType type) {
			return handler_type_map.lookup(type);
		}
		
		public ItemHandler get_handler_by_name(string name) {
			return handler_name_map.lookup(name);
		}
		
		private int cnt = 0;
		public void test_func() {
			print("testfunc %d\n", cnt++);
		}
		
		
		private string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," + FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;

		private PatternSpec psVideo = new PatternSpec("video*");
		private PatternSpec psAudio = new PatternSpec("audio*");
		
		public Item create_uri_item(string uri) {
			Item item = Item(ItemType.UNKNOWN, uri);
			
			File f = File.new_for_uri(uri);
			string scheme = f.get_uri_scheme();
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
			if(psAudio.match_string(mime)) {
				if(uri.has_suffix("m3u") ||
				   uri.has_suffix("asx") || 
				   uri.has_suffix("xspf")||
				   uri.has_suffix("pls") ||
				   uri.has_suffix("wpl")) {
					item = Item(Xnoise.ItemType.PLAYLIST, uri);
				}
				else {
					if(scheme == "file" || scheme == "cdda") {
						item = Item(Xnoise.ItemType.LOCAL_AUDIO_TRACK, uri);
					}
					else {
						item = Item(Xnoise.ItemType.STREAM, uri);
					}
				}
			}
			else if(psVideo.match_string(mime)) {
					if(scheme == "file" || scheme == "dvd") {
						item  = Item(Xnoise.ItemType.LOCAL_VIDEO_TRACK, uri);
					}
					else {
						item = Item(Xnoise.ItemType.STREAM, uri);
					}
			}
			else if(info.get_file_type() == FileType.DIRECTORY) {
				if(scheme == "file" || scheme == "dvd") {
					item = Item(Xnoise.ItemType.LOCAL_FOLDER, uri);
				}
			}
			return item;
		}
		
		public static void execute_actions_for_item(Item item, ActionContext context, GLib.Value? data) {
			Array<Action?> item_actions = uri_handler_manager.get_actions(item.type, context);
			//print("item_actions.length: %u\n", item_actions.length);
			for(int i = 0; i < item_actions.length; i++) {
				unowned Action current = item_actions.index(i);
				if(current.action != null) {
					print("  %s\n", current.name);
					current.action(item, data);
				}
			}
		}
	}
}
