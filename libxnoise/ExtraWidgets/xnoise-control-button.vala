/* xnoise-control-button.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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
 *     softshaker
 */

using Gtk;
using Gdk;


/**
 * A ControlButton is a Gtk.Button that initiates playback of the previous or next item or stop
 */
private class Xnoise.ControlButton : Gtk.ToolItem {
    
    private unowned IconTheme theme = null;
    private Image image;
    private int iconwidth = 24;
    private Function function;
    
    public enum Function {
        NEXT = 0,
        PREVIOUS,
        STOP
    }
    
    public signal void sign_clicked(Function dir);
    
    
    public ControlButton(Function _function) {
        function = _function;
        theme = IconTheme.get_default();
        
        var button = new Gtk.Button();
        var w = new Gtk.Invisible();
        
        switch(function) {
            case Function.NEXT: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_NEXT, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-skip-forward-symbolic")) {
                    try {
                        px = theme.load_icon("media-skip-forward-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                image = new Gtk.Image.from_pixbuf(px);
                break;
            }
            case Function.PREVIOUS: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PREVIOUS, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-skip-backward-symbolic")) {
                    try {
                        px = theme.load_icon("media-skip-backward-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                image = new Gtk.Image.from_pixbuf(px);
                break;
            }
            case Function.STOP: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_STOP, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-playback-stop-symbolic")) {
                    try {
                        px = theme.load_icon("media-playback-stop-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                assert(px != null);
                image = new Gtk.Image.from_pixbuf(px);
                break;
            }
            default:
                assert_not_reached();
                break;
        }
        button.add(image);
        this.add(button);
        button.can_focus = false;
        this.can_focus = false;
        button.clicked.connect(this.on_clicked);
        theme.changed.connect(update_pixbufs);
    }
    
    private void update_pixbufs() {
        print("update_pixbufs control button %s\n", function.to_string());
        theme = IconTheme.get_default();
        var w = new Gtk.Invisible();
        
        switch(function) {
            case Function.NEXT: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_NEXT, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-skip-forward-symbolic")) {
                    try {
                        px = theme.load_icon("media-skip-forward-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                image.pixbuf = px;
                break;
            }
            case Function.PREVIOUS: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PREVIOUS, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-skip-backward-symbolic")) {
                    try {
                        px = theme.load_icon("media-skip-backward-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                image.pixbuf = px;
                break;
            }
            case Function.STOP:
            default: {
                Pixbuf px = null;
                px = w.render_icon_pixbuf(Gtk.Stock.MEDIA_STOP, IconSize.LARGE_TOOLBAR);
                iconwidth = px.width;
                if(theme.has_icon("media-playback-stop-symbolic")) {
                    try {
                        px = theme.load_icon("media-playback-stop-symbolic",
                                             iconwidth,
                                             IconLookupFlags.FORCE_SIZE
                        );
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                    }
                }
                image.pixbuf = px;
                break;
            }
        }
        this.queue_draw();
    }
    
    private void on_clicked() {
        this.sign_clicked(function);
    }
}


