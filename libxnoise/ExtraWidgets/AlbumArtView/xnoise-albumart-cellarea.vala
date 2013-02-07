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
    private Pango.FontDescription font_description;
    
    public string font_family    { get; set; default = "Sans"; }
    public double font_size      { get; set; default = 10; }
    
    
    public AlbumArtCellArea() {
        GLib.Object();
        var cells = new List<CellRenderer>();
        
        this.@foreach( (cellr) => {
            cells.prepend(cellr);
            return false;
        });
        
        
        foreach(var cell in cells)
            this.remove(cell);

        font_description = new Pango.FontDescription();
        font_description.set_family(font_family);
        font_description.set_size((int)(font_size * Pango.SCALE));

        var renderer_thumb = new CellRendererThumb(font_description);
        
        this.pack_start(renderer_thumb, false);
        this.attribute_connect(renderer_thumb, "pixbuf", IconsModel.Column.ICON);
        this.attribute_connect(renderer_thumb, "markup", IconsModel.Column.TEXT);
    }
    
    public override void get_preferred_width(Gtk.CellAreaContext context,
                                             Gtk.Widget widget,
                                             out int minimum_width,
                                             out int natural_width) {
        //print("get_preferred_width\n");
        minimum_width = natural_width = IconsModel.ICONSIZE;
    }
}

private class Xnoise.CellRendererThumb : Gtk.CellRendererPixbuf {
    private unowned Pango.FontDescription font_description;
    public string markup { get; set; }
    
    public CellRendererThumb(Pango.FontDescription font_description) {
        this.font_description = font_description;
        this.set_fixed_size(IconsModel.ICONSIZE, IconsModel.ICONSIZE);
        ypad = 0;
    }
    
    
    public override void render(Cairo.Context cr, Widget widget,
                                Gdk.Rectangle background_area,
                                Gdk.Rectangle cell_area,
                                CellRendererState flags) {
        //print("render for %s\n", markup);
        int x_offset = background_area.x + 1;
        int y_offset = background_area.y + 1;
        int wi, he = 0;
        
        // IMAGE
        Gdk.cairo_set_source_pixbuf(cr, pixbuf, x_offset, y_offset);
        cr.paint();
        
        //PANGO LAYOUT
        int layout_width  = background_area.width - 2;
        var pango_layout = Pango.cairo_create_layout(cr);
        pango_layout.set_markup(markup , -1);
        pango_layout.set_alignment(Pango.Alignment.CENTER);
        pango_layout.set_font_description(font_description);
        pango_layout.set_width( (int)(layout_width  * Pango.SCALE));
        pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
        pango_layout.get_pixel_size(out wi, out he);
        
        int rect_offset = y_offset + (int)((2.0 * IconsModel.ICONSIZE) / 3.0);
        int rect_height = (int)(IconsModel.ICONSIZE / 3.0);
        bool was_to_large = false;
        if(he > rect_height) {
            was_to_large = true;
            pango_layout.set_ellipsize(Pango.EllipsizeMode.END);
            pango_layout.set_height( (int)((IconsModel.ICONSIZE / 3.0) * Pango.SCALE));
            pango_layout.get_pixel_size(out wi, out he);
        }
        //RECTANGLE
        if((flags & CellRendererState.PRELIT) == CellRendererState.PRELIT ||
           (flags & CellRendererState.SELECTED) == CellRendererState.SELECTED ||
           (flags & CellRendererState.FOCUSED) == CellRendererState.FOCUSED)
            cr.set_source_rgba(0.0, 0.0, 0.0, 0.6);
        else
            cr.set_source_rgba(0.0, 0.0, 0.0, 0.3);
        cr.set_line_width(0);
        cr.rectangle(x_offset, 
                     rect_offset,
                     background_area.width - 2,
                     rect_height);
        cr.fill();
        
        // DRAW FONT
        cr.set_source_rgba(1.0, 1.0, 1.0, 1.0);
        cr.move_to(x_offset,
                   y_offset 
                    + 2.0 * IconsModel.ICONSIZE / 3.0 
                    + (((IconsModel.ICONSIZE/3.0) -  he) / 2.0)
        );
        Pango.cairo_show_layout(cr, pango_layout);
    }
}
