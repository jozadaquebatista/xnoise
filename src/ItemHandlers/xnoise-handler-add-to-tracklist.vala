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
	private Action add;
	private const string binfo = "B HandlerAddToTracklistinfo";
	private const string bname = "B HandlerAddToTracklistname";
	
	private const string name = "HandlerAddToTracklist";
	
	public HandlerAddToTracklist() {
		//action for adding item(s)
		add = new Action(); 
		add.action = add_action;
		add.info = this.binfo;
		add.name = this.bname;// (char[])"HandlerAddToTracklist";
		add.context = ActionContext.MEDIABROWSER_ITEM_ACTIVATED;
		print("constructed HandlerAddToTracklist\n");
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.TRACKLIST_ADDER;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context) {
		if(context == ActionContext.MEDIABROWSER_ITEM_ACTIVATED
			return add;
		
		return null;
	}

	private void add_action(Item item, GLib.Value? data) {
		// Maybe convert to tracks and forward this to some other action ?
		
	}
}

