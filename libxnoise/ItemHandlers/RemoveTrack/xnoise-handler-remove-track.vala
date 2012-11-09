/* xnoise-handler-remove-track.vala
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
 *     Jörn Magens
 */

// ItemHandler Implementation 
// provides the right Action for the given ActionContext/ItemType
internal class Xnoise.HandlerRemoveTrack : ItemHandler {
    private Action a;
    private const string ainfo = _("Remove selected track");
    private const string aname = "HandlerRemoveTrack";
    
    private const string name = "HandlerRemoveTrack";
    
    public HandlerRemoveTrack() {
        a = new Action();
        a.action     = remove_track_from_tracklist;
        a.info       = this.ainfo;
        a.name       = this.aname;
        a.stock_item = Gtk.Stock.DELETE;
        a.context    = ActionContext.TRACKLIST_MENU_QUERY;
        
        //print("constructed HandlerRemoveTrack\n");
    }

    public override ItemHandlerType handler_type() {
        return ItemHandlerType.OTHER;
    }
    
    public override unowned string handler_name() {
        return name;
    }

    public override unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection = ItemSelectionType.NOT_SET) {
        if(context == ActionContext.TRACKLIST_MENU_QUERY)
            return a;
        else
            return null;
    }

    private void remove_track_from_tracklist(Item item, GLib.Value? data, GLib.Value? data2) { // forward playlists to parser
        print("remove_track    %s\n", item.type.to_string());
        tl.remove_selected_rows();
    }
}

