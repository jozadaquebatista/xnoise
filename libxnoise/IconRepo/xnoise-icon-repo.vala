/* xnoise-icon-repo.vala
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */



using Gtk;

internal class Xnoise.IconRepo : GLib.Object {
    private unowned IconTheme theme = null;

    internal Gdk.Pixbuf artist_icon                 { get; private set; }
    internal Gdk.Pixbuf genre_icon                  { get; private set; }
    internal Gdk.Pixbuf folder_symbolic_icon        { get; private set; }
    internal Gdk.Pixbuf album_icon                  { get; private set; }
    internal Gdk.Pixbuf title_icon                  { get; private set; }
    internal Gdk.Pixbuf video_icon                  { get; private set; }
    internal Gdk.Pixbuf videos_icon                 { get; private set; }
    internal Gdk.Pixbuf radios_icon                 { get; private set; }
    internal Gdk.Pixbuf loading_icon                { get; private set; }
    internal Gdk.Pixbuf playlist_icon               { get; private set; }
    internal Gdk.Pixbuf local_collection_icon       { get; private set; }
    internal Gdk.Pixbuf selected_collection_icon    { get; private set; }
    internal Gdk.Pixbuf symbolic_play_icon          { get; private set; }
    internal Gdk.Pixbuf symbolic_pause_icon         { get; private set; }
    internal Gdk.Pixbuf network_symbolic_icon       { get; private set; }
    internal Gdk.Pixbuf radios_icon_menu            { get; private set; }
    internal Gdk.Pixbuf album_art_default_icon      { get; private set; }
    
    internal signal void icon_theme_changed();
    
    construct {
        theme = IconTheme.get_default();
        theme.changed.connect(update_pixbufs);
        set_pixbufs();
    }
    
    private void update_pixbufs() {
        print("update_pixbufs\n");
        theme = IconTheme.get_default();
        this.set_pixbufs();
        this.icon_theme_changed();
    }
    
    private void set_pixbufs() {
        try {
            Gtk.Invisible w = new Gtk.Invisible();
            
            video_icon  = w.render_icon_pixbuf(Gtk.Stock.FILE, IconSize.BUTTON);
            int iconheight = video_icon.height;
            radios_icon_menu = w.render_icon_pixbuf(Gtk.Stock.CONNECT, IconSize.MENU);
            if(theme.has_icon("xn-stream")) {
                radios_icon = theme.load_icon("xn-stream", iconheight, IconLookupFlags.USE_BUILTIN);
                radios_icon_menu = theme.load_icon("xn-stream",
                                                   radios_icon_menu.height,
                                                   IconLookupFlags.USE_BUILTIN);
            }
            else {
                radios_icon = w.render_icon_pixbuf(Gtk.Stock.CONNECT, IconSize.BUTTON);
            }
            
            if(theme.has_icon("system-users")) 
                artist_icon = theme.load_icon("system-users", iconheight, IconLookupFlags.USE_BUILTIN);
            else if(theme.has_icon("stock_person")) 
                artist_icon = theme.load_icon("stock_person", iconheight, IconLookupFlags.USE_BUILTIN);
            else 
                artist_icon = w.render_icon_pixbuf(Gtk.Stock.ORIENTATION_PORTRAIT, IconSize.BUTTON);
            
            genre_icon = w.render_icon_pixbuf(Gtk.Stock.COPY, IconSize.BUTTON);
            
            album_icon = w.render_icon_pixbuf(Gtk.Stock.CDROM, IconSize.BUTTON);
            
            if(theme.has_icon("media-audio")) 
                title_icon = theme.load_icon("media-audio", iconheight, IconLookupFlags.USE_BUILTIN);
            else if(theme.has_icon("audio-x-generic")) 
                title_icon = theme.load_icon("audio-x-generic", iconheight, IconLookupFlags.USE_BUILTIN);
            else 
                title_icon = w.render_icon_pixbuf(Gtk.Stock.OPEN, IconSize.BUTTON);
            
            if(theme.has_icon("video-x-generic")) 
                videos_icon = theme.load_icon("video-x-generic", iconheight, IconLookupFlags.USE_BUILTIN);
            else 
                videos_icon = w.render_icon_pixbuf(Gtk.Stock.MEDIA_RECORD, IconSize.BUTTON);
            
            if(theme.has_icon("xn-playlist"))
                playlist_icon = theme.load_icon("xn-playlist", iconheight, IconLookupFlags.USE_BUILTIN);
            else
                playlist_icon = w.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
            
            loading_icon = w.render_icon_pixbuf(Gtk.Stock.REFRESH , IconSize.BUTTON);
            
            if(theme.has_icon("xn-local-collection"))
                local_collection_icon = theme.load_icon("xn-local-collection",
                                                        iconheight,
                                                        IconLookupFlags.USE_BUILTIN);
            else
                local_collection_icon = w.render_icon_pixbuf(Gtk.Stock.HOME, IconSize.BUTTON);
            
            if(theme.has_icon("xn-current-position"))
                selected_collection_icon = theme.load_icon("xn-current-position",
                                                           iconheight,
                                                           IconLookupFlags.USE_BUILTIN);
            else
                selected_collection_icon = w.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
            
            if(theme.has_icon("media-playback-start-symbolic"))
                symbolic_play_icon = theme.load_icon("media-playback-start-symbolic",
                                                     iconheight,
                                                     IconLookupFlags.USE_BUILTIN);
            else
                symbolic_play_icon = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PLAY, IconSize.BUTTON);
            
            if(theme.has_icon("media-playback-pause-symbolic"))
                symbolic_pause_icon = theme.load_icon("media-playback-pause-symbolic",
                                                      iconheight,
                                                      IconLookupFlags.USE_BUILTIN);
            else
                symbolic_pause_icon = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PAUSE, IconSize.BUTTON);
            if(theme.has_icon("folder-symbolic"))
                folder_symbolic_icon = theme.load_icon("folder-symbolic",
                                                       iconheight,
                                                       IconLookupFlags.USE_BUILTIN);
            else
                folder_symbolic_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.BUTTON);
            if(theme.has_icon("network-transmit-symbolic"))
                network_symbolic_icon = theme.load_icon("network-transmit-symbolic",
                                                        iconheight,
                                                        IconLookupFlags.USE_BUILTIN);
            else
                network_symbolic_icon = w.render_icon_pixbuf(Gtk.Stock.CONNECT, IconSize.BUTTON);
            
            if(theme.has_icon("xnoise-grey"))
                album_art_default_icon = theme.load_icon("xnoise-grey",
                                                        AlbumImage.SIZE,
                                                        IconLookupFlags.USE_BUILTIN);
        }
        catch(GLib.Error e) {
            print("Error: %s\n",e.message);
        }
    }

    internal static Gtk.Image? get_themed_image_icon(string name, IconSize size, int pixelsize = -1) {
        Gtk.Image? image = null;
        GLib.Icon gicon = new ThemedIcon(name);
        if(name != null)
            image = new Gtk.Image.from_icon_name (name, size);
        else
            image = new Gtk.Image.from_gicon (gicon, size);
        
        if(pixelsize != -1)
            image.set_pixel_size(pixelsize);
        
        return image;
    }
    
    internal static Gdk.Pixbuf? get_themed_pixbuf_icon(string name,
                                                       int pixel_size,
                                                       Gtk.StyleContext? style_context = null) {
        Gtk.Image? image = null;
        GLib.Icon gicon = new ThemedIcon(name);
        assert(gicon != null);
        int width, height;
        Gdk.Pixbuf? pix = null;
        unowned IconTheme theme = IconTheme.get_default();
        try {
            var icon_info = theme.lookup_by_gicon(gicon, pixel_size, Gtk.IconLookupFlags.USE_BUILTIN);
            
            if(icon_info != null) {
                if (style_context != null) {
                    pix = icon_info.load_symbolic_for_context(style_context);
                }
                else {
                    pix = icon_info.load_icon();
                }
            }
            if(pix == null) {
                pix = theme.load_icon(Gtk.Stock.MISSING_IMAGE,
                                      pixel_size,
                                      Gtk.IconLookupFlags.GENERIC_FALLBACK
                );
            }
        }
        catch (Error e) {
            print("%s", e.message);
            if(pix == null) {
                pix = theme.load_icon(Gtk.Stock.MISSING_IMAGE,
                                      pixel_size,
                                      Gtk.IconLookupFlags.GENERIC_FALLBACK
                );
            }
        }
        return pix;
    }
}

