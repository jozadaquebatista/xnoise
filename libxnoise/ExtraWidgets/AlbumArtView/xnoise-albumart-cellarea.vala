/* xnoise-albumart-cellarea.vala
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

using Xnoise;
using Xnoise.Resources;


private class Xnoise.AlbumArtCellArea : Gtk.CellAreaBox {
    private Pango.FontDescription font_description;
    
    public string font_family    { get; set; default = "Sans"; }
    public double font_size      { get; set; default = 10; }
    
    
    public AlbumArtCellArea() {
        GLib.Object();
        var cells = new List<CellRenderer>();
        
        font_description = new Pango.FontDescription();
        font_description.set_family(font_family);
        font_description.set_size((int)(font_size * Pango.SCALE));
        
        // Add own cellrenderer
        var renderer_thumb = new CellRendererThumb(font_description);
        
        this.pack_start(renderer_thumb, false);
        this.attribute_connect(renderer_thumb, "pixbuf",     IconsModel.Column.ICON);
        this.attribute_connect(renderer_thumb, "markup",     IconsModel.Column.TEXT);
        this.attribute_connect(renderer_thumb, "extra-info", IconsModel.Column.EXTRA_INFO);
    }
    
    public override void get_preferred_width(Gtk.CellAreaContext context,
                                             Gtk.Widget widget,
                                             out int minimum_width,
                                             out int natural_width) {
        //print("get_preferred_width\n");
        minimum_width = natural_width = ICON_LARGE_PIXELSIZE + 1;
    }
}

