/* xnoise-dockable-media.vala
 *
 * Copyright (C) 2012  Jörn Magens
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


public abstract class Xnoise.DockableMedia : GLib.Object {
    public enum Category {
        UNKNOWN = 0,
        MEDIA_COLLECTION,
        PLAYLIST,
        STORES,
        DEVICES;
        
        public string? to_string() {
            switch(this) {
                case DockableMedia.Category.MEDIA_COLLECTION:
                    return _("Media Collections");
                case DockableMedia.Category.PLAYLIST:
                    return _("Playlists");
                case DockableMedia.Category.STORES:
                    return _("Stores");
                case DockableMedia.Category.DEVICES:
                    return _("Devices");
                case DockableMedia.Category.UNKNOWN:
                default:
                    return null;
            }
        }
    }
    
    public unowned Gtk.Widget? widget = null;
    
    public abstract string name();
    public abstract string headline();
    public abstract DockableMedia.Category category();
    public abstract string get_icon_name();
    public abstract Gtk.Widget? create_widget(Xnoise.MainWindow window);
    public abstract void remove_main_view();
}

