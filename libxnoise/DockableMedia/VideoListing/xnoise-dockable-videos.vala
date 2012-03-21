/* xnoise-dockable-videos.vala
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

using Gtk;


private class Xnoise.DockableVideos : DockableMedia {
    
    public override string name() {
        return "DockableVideos";
    }
    
    public override string headline() {
        return _("Videos");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.MEDIA_COLLECTION;
    }

    public override Gtk.Widget? get_widget(MainWindow window) {
        var sw = new ScrolledWindow(null, null);
        var tv = new TreeViewVideos(window, (Widget)sw);
        sw.set_shadow_type(ShadowType.IN);
        sw.add(tv);
        return sw;
    }

    public override Gdk.Pixbuf get_icon() {
        return icon_repo.videos_icon;
    }
}

