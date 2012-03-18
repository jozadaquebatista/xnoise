/* xnoise-item-handler.vala
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

namespace Xnoise {
    public enum ActionContext {
        NONE,
        REQUESTED,
        TRACKLIST_ITEM_ACTIVATED,
        TRACKLIST_MENU_QUERY,
        TRACKLIST_DROP,
        MEDIABROWSER_ITEM_ACTIVATED,
        MEDIABROWSER_MENU_QUERY,
        MEDIABROWSER_LOAD,
        VIDEOSCREEN_ACTIVATED,
        VIDEOSCREEN_MENU_QUERY,
        TRACKLIST_COLUMN_HEADER_MENU_QUERY
    }
    
    [Flags]
    public enum ItemSelectionType {
        NOT_SET = 0,
        SINGLE = 1 << 0,
        MULTIPLE = 1 << 1
    }
    
    public enum ItemHandlerType {
        UNKNOWN,
        OTHER,
        TRACKLIST_ADDER,
        PLAYLIST_PARSER,
        VIDEO_THUMBNAILER,
        TAG_EDITOR,
        MENU_PROVIDER,
        PLAY_NOW
    }


    [Compact]
    public class Action {
        public unowned ItemHandler.ActionType? action = null;
        public unowned string name;
        public unowned string info;
        public unowned string text;    // text used in the context of the Action, e.g. a menu entry text
        public unowned string stock_item = Gtk.Stock.MISSING_IMAGE;
        public ActionContext context;  // ActionContext the Action was created for
    }



    // base class
    // ItemHandler provides the right Action for the given ActionContext
    public abstract class ItemHandler : Object {
        public delegate void ActionType(Item item, GLib.Value? data);
        
        protected unowned ItemHandlerManager uhm = null;
        
        public bool set_manager(ItemHandlerManager _uhm) {
            if(this.uhm != null && this.uhm != _uhm)
                return false;
            this.uhm = _uhm;
            return true;
        }
        
        public abstract ItemHandlerType handler_type(); 
        public abstract unowned string handler_name();
        // TODO: Maybe return more than one Action
        public abstract unowned Action? get_action(ItemType type, ActionContext context, ItemSelectionType selection); 
    }
}
