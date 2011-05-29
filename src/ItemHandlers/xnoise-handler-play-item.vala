/* xnoise-handler-play-item.vala
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
// provides the right Action for the given ActionContext/ItemType
public class Xnoise.HandlerPlayItem : ItemHandler {
	private Action a;
	private const string ainfo = "A HandlerPlayIteminfo";
	private const string aname = "A HandlerPlayItemname";
	
	private const string name = "HandlerPlayItem";
	
	public HandlerPlayItem() {
		a = new Action();
		a.action = play_uri;
		a.info = this.ainfo;
		a.name = this.aname;
		a.context = ActionContext.NONE;
		
		print("constructed HandlerPlayItem\n");
	}

	public override ItemHandlerType handler_type() {
		return ItemHandlerType.PLAY_NOW;
	}
	
	public override unowned string handler_name() {
		return name;
	}

	public override unowned Action? get_action(ItemType type, ActionContext context) {
		return a;
	}

	public override Array<Item?>? convert(Item item) {
		return null;
	}
	
	private void play_uri(Item item, GLib.Value? data) { // forward playlists to parser
		print(":: play_uri\n");
		global.player_state = PlayerState.PLAYING;
		global.current_uri = item.uri;
	}
}

