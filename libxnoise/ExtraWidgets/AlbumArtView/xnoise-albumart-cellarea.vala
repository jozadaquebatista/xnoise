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


private class Xnoise.AlbumArtCellArea : Gtk.CellAreaBox {
    public AlbumArtCellArea() {
        var renderer_pixbuf = new CellRendererPixbuf();
        var renderer_text   = new CellRendererText();
        renderer_text.alignment = Pango.Alignment.CENTER;
        renderer_text.width = IconsModel.ICONSIZE;
        renderer_text.wrap_mode = Pango.WrapMode.WORD;
        renderer_text.wrap_width = IconsModel.ICONSIZE;
        renderer_text.xalign = 0.5f;
        renderer_text.yalign = 0.0f;
        
        this.pack_start(renderer_pixbuf, false);
        this.pack_start(renderer_text, false);
        this.attribute_connect(renderer_pixbuf, "pixbuf", IconsModel.Column.ICON);
        this.attribute_connect(renderer_text, "markup", IconsModel.Column.TEXT);
    }
    
    public override void get_preferred_width(Gtk.CellAreaContext context,
                                             Gtk.Widget widget,
                                             out int minimum_width,
                                             out int natural_width) {
        //print("get_preferred_width\n");
        minimum_width = natural_width = IconsModel.ICONSIZE;
    }
}

