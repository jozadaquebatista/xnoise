/* xnoise-album-image.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
 *     softshaker  softshaker googlemail.com
 *     fsistemas
 */

using Gtk;
using Cairo;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;

private class Xnoise.AlbumImage : Gtk.EventBox {
    internal static const int SIZE = 44;
    private const double SELECTED_BACKGROUND_ALPHA = 0.4;
    private Gdk.Pixbuf? prelit_image = null;
    private Gdk.Pixbuf? seleted_image = null;
    private Gdk.Pixbuf? prelitseleted_image = null;
    private const int WSYM = 28;
    private const int ipos = (int)((SIZE / 2.0) - (WSYM / 2.0));
    
    private bool _selected = false;
    
    private Gdk.Pixbuf? pixbuf = null;
    
    public signal void sign_selected();
    
    internal bool selected { 
        get {
            return _selected;
        } 
        set {
            if(_selected != value) {
                _selected = value;
                Idle.add(() => {
                    queue_draw();
                    this.sign_selected();
                    return false;
                });
            }
        }
    }
    
    
    public AlbumImage() {
        this.pixbuf = null;
        this.set_size_request(SIZE, SIZE);
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.ENTER_NOTIFY_MASK |
                        Gdk.EventMask.LEAVE_NOTIFY_MASK
        );
        this.set_tooltip_text(_("Toggle visibility of album art view") +
                              "\n" +
                              _("<Ctrl+B>")
        );
        global.image_loader.notify["image-small"].connect(on_image_changed);
        global.image_loader.notify["image-embedded"].connect(on_image_changed);
        this.set_visible_window(false);
        
        this.button_press_event.connect( (s,e) => {
            if(e.button == 3 && e.type == Gdk.EventType.@2BUTTON_PRESS) {
                main_window.toggle_fullscreen();
                return true;
            }
            if(e.button == 1 && e.type == Gdk.EventType.BUTTON_PRESS) {
                this.selected = !this.selected;
                return true;
            }
            return false;
        });
        this.enter_notify_event.connect( (s, e) => {
            StateFlags flags = this.get_state_flags();
            flags |= StateFlags.PRELIGHT;
            this.set_state_flags(flags|StateFlags.PRELIGHT, false);
            queue_draw();
            return false;
        });
        this.leave_notify_event.connect( (s, e) => {
            this.unset_state_flags(StateFlags.PRELIGHT);
            queue_draw();
            return false;
        });
        Gtk.StyleContext context = this.get_style_context();
        context.add_class(STYLE_CLASS_BUTTON);
    }
    
    
    private void on_image_changed() {
        if(global.image_loader.image_embedded != null) {
            this.pixbuf = global.image_loader.image_embedded.scale_simple(SIZE, SIZE, Gdk.InterpType.BILINEAR);
        }
        else if(global.image_loader.image_small != null) {
            this.pixbuf = global.image_loader.image_small.scale_simple(SIZE, SIZE, Gdk.InterpType.BILINEAR);
        }
        else
            this.pixbuf = null;
        queue_draw();
    }
    
    private double x = 0.0;
    private double y = 0.0;
    private double radius = 6.0;
    private double width  = SIZE * 1.0;
    private double height = SIZE * 1.0;
    private double degrees = Math.PI / 180.0;
    
    public override bool draw(Cairo.Context cr) {
        Gtk.StyleContext context = this.get_style_context();
        Gdk.RGBA col = context.get_color(StateFlags.NORMAL);
        assert(icon_repo.album_art_default_icon != null);
        
        //Background
        cr.set_source_rgb(col.red, col.green, col.blue);
        cr.set_line_width(0);
        cr.arc(x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
        cr.arc(x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
        cr.arc(x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
        cr.arc(x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
        cr.close_path ();
        cr.fill();
        //---------
        
        cr.arc(x + width - radius - 0.8, y + radius + 0.8, radius, -90 * degrees, 0 * degrees);
        cr.arc(x + width - radius -0.8, y + height - radius -0.8, radius, 0 * degrees, 90 * degrees);
        cr.arc(x + radius +0.8, y + height - radius -0.8, radius, 90 * degrees, 180 * degrees);
        cr.arc(x + radius +0.8, y + radius +0.8, radius, 180 * degrees, 270 * degrees);
        cr.close_path ();
        cr.clip ();
        cr.new_path();
        if(this.pixbuf == null) {
            Gdk.cairo_set_source_pixbuf(cr, icon_repo.album_art_default_icon, 0, 0);
        }
        else {
            Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
        }
        StateFlags flags = this.get_state_flags();
        if((flags & StateFlags.PRELIGHT) == StateFlags.PRELIGHT && !_selected) {
            cr.paint();
            cr.set_source_rgba(col.red, col.green, col.blue, 2.0 * SELECTED_BACKGROUND_ALPHA / 3.0);
            cr.set_line_width(0);
            
            cr.arc(x + width - radius - 0.8, y + radius + 0.8, radius, -90 * degrees, 0 * degrees);
            cr.arc(x + width - radius -0.8, y + height - radius -0.8, radius, 0 * degrees, 90 * degrees);
            cr.arc(x + radius +0.8, y + height - radius -0.8, radius, 90 * degrees, 180 * degrees);
            cr.arc(x + radius +0.8, y + radius +0.8, radius, 180 * degrees, 270 * degrees);
            cr.close_path ();
            cr.fill();
            cr.paint();
            if(prelit_image == null)
                prelit_image = IconTheme.get_default().load_icon("xn-grid-prelit",
                                                                 WSYM, 
                                                                 IconLookupFlags.USE_BUILTIN);
            if(prelit_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, prelit_image, ipos, ipos);
            }
            else {
                print("grid pix1 is null!\n");
            }
        }
        else if((flags & StateFlags.PRELIGHT) != StateFlags.PRELIGHT && _selected) {
            cr.paint();
            cr.set_source_rgba(col.red, col.green, col.blue, SELECTED_BACKGROUND_ALPHA);
            cr.set_line_width(0);
            
            cr.arc(x + width - radius - 0.8, y + radius + 0.8, radius, -90 * degrees, 0 * degrees);
            cr.arc(x + width - radius -0.8, y + height - radius -0.8, radius, 0 * degrees, 90 * degrees);
            cr.arc(x + radius +0.8, y + height - radius -0.8, radius, 90 * degrees, 180 * degrees);
            cr.arc(x + radius +0.8, y + radius +0.8, radius, 180 * degrees, 270 * degrees);
            cr.close_path ();
            cr.fill();
            cr.paint();
            if(seleted_image == null)
                seleted_image = IconTheme.get_default().load_icon("xn-grid", 
                                                                   WSYM, 
                                                                   IconLookupFlags.USE_BUILTIN);
            if(seleted_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, seleted_image, ipos, ipos);
            }
            else {
                print("grid pix2 is null!\n");
            }
        }
        else if((flags & StateFlags.PRELIGHT) == StateFlags.PRELIGHT && _selected) {
            cr.paint();
            cr.set_source_rgba(col.red, col.green, col.blue, SELECTED_BACKGROUND_ALPHA);
            cr.set_line_width(0);
            
            cr.arc(x + width - radius - 0.8, y + radius + 0.8, radius, -90 * degrees, 0 * degrees);
            cr.arc(x + width - radius -0.8, y + height - radius -0.8, radius, 0 * degrees, 90 * degrees);
            cr.arc(x + radius +0.8, y + height - radius -0.8, radius, 90 * degrees, 180 * degrees);
            cr.arc(x + radius +0.8, y + radius +0.8, radius, 180 * degrees, 270 * degrees);
            cr.close_path ();
            cr.fill();
            cr.paint();
            if(prelitseleted_image == null)
                prelitseleted_image = IconTheme.get_default().load_icon("xn-grid-prelitselected", 
                                                                   WSYM, 
                                                                   IconLookupFlags.USE_BUILTIN);
            if(prelitseleted_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, prelitseleted_image, ipos, ipos);
            }
            else {
                print("grid pix3 is null!\n");
            }
        }
        cr.paint();
        return false;
    }
}
