/* xnoise-handler-add-to-tracklist.vala
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

// ItemHandler Implementation 
// provides the right Action for the given ActionContext
// has one or more Actions
public class Xnoise.HandlerAddToTracklist : ItemHandler {
	private Action a;
	private const string ainfo = "A HandlerAddToTracklistinfo";
	private const string aname = "A HandlerAddToTracklistname";
	private Action b;
	private const string binfo = "B HandlerAddToTracklistinfo";
	private const string bname = "B HandlerAddToTracklistname";
	
	private const string name = "HandlerAddToTracklist";
	
	public HandlerAddToTracklist() {
		a = new Action();
		a.action = playlist_action;
		a.info = this.ainfo;
		a.name = this.aname;// (char[])"HandlerAddToTracklist";
		a.context = ActionContext.MEDIABROWSER_ITEM_ACTIVATED;
		
		b = new Action();
		b.action = tracklist_drop_action;
		b.info = this.binfo;
		b.name = this.bname;// (char[])"HandlerAddToTracklist";
		b.context = ActionContext.TRACKLIST_DROP;
		print("constructed HandlerAddToTracklist\n");
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TRACKLIST_ADDER;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context) {
		if((context == ActionContext.MEDIABROWSER_ITEM_ACTIVATED ||
		    context == ActionContext.TRACKLIST_DROP
		    ) &&
		   (type == ItemType.LOCAL_AUDIO_TRACK ||
		    type == ItemType.LOCAL_FOLDER ||
		    type == ItemType.LOCAL_VIDEO_TRACK
		    )
		   )
			return b;
			
		if((context == ActionContext.MEDIABROWSER_ITEM_ACTIVATED ||
		    context == ActionContext.TRACKLIST_DROP
		    ) &&
		   (type == ItemType.PLAYLIST)
		   )
			return a;

		return null;
	}

	public override Array<Item?>? convert(Item item) {
		return null;
	}
	
	// Action Payload
	private void playlist_action(Item item, GLib.Value? data) { // forward playlists to parser
//		print(":: playlist adder\n");
//		ItemHandler? tmp = this.uhm.get_handler_by_type(ItemHandlerType.PLAYLIST_PARSER);
//		if(tmp == null)
//			return;
//		Array<Item?>? playlist_content = tmp.convert(item);
//		if(playlist_content != null) {
//			for(int i = 0; i < playlist_content.length; i++) {
//				unowned Item current_item = playlist_content.index(i);
//				this.uhm.execute_actions_for_item(current_item, ActionContext.TRACKLIST_DROP, data);
//			}
//		}
	}
//			Array<string> stringarray = new Array<string>(true, true, sizeof(string));
//			string s1 = "stringarray1";
//			string s2 = "stringarray2";
//			string s3 = "stringarray3";
//			stringarray.append_val(s1);
//			stringarray.append_val(s2);
//			stringarray.append_val(s3);
	private void tracklist_drop_action(Item item, GLib.Value? data) {
		print("%s triggered tracklist_drop_action for %s\n", item.uri, item.type.to_string());
		if(data != null) {
			Array<string> dar = (Array<string>)data;
			print("dar.length = %u\n", dar.length);
			for(int i = 0; i < dar.length; i++) {
				print("%s\n", dar.index(i));
			}
		}
	}
}

