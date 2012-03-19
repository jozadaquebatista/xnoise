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

    internal Gdk.Pixbuf artist_icon           { get; private set; }
    internal Gdk.Pixbuf album_icon            { get; private set; }
    internal Gdk.Pixbuf title_icon            { get; private set; }
    internal Gdk.Pixbuf video_icon            { get; private set; }
    internal Gdk.Pixbuf videos_icon           { get; private set; }
    internal Gdk.Pixbuf radios_icon           { get; private set; }
    internal Gdk.Pixbuf loading_icon          { get; private set; }
    internal Gdk.Pixbuf playlist_icon         { get; private set; }
    internal Gdk.Pixbuf local_collection_icon { get; private set; }

    internal signal void icon_theme_changed();
    
    construct {
        theme = IconTheme.get_default();
        theme.changed.connect(update_pixbufs);
        set_pixbufs();
    }
    
    private void update_pixbufs() {
        print("update_pixbufs\n");
        this.set_pixbufs();
        this.icon_theme_changed();
    }
    
    private void set_pixbufs() {
        try {
            Gtk.Invisible w = new Gtk.Invisible();
            
            video_icon  = w.render_icon_pixbuf(Gtk.Stock.FILE, IconSize.BUTTON);
            int iconheight = video_icon.height;
            if(theme.has_icon("xn-stream"))
                radios_icon = theme.load_icon("xn-stream", iconheight, IconLookupFlags.FORCE_SIZE);
            else
                radios_icon = w.render_icon_pixbuf(Gtk.Stock.CONNECT, IconSize.BUTTON);
            
            if(theme.has_icon("system-users")) 
                artist_icon = theme.load_icon("system-users", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("stock_person")) 
                artist_icon = theme.load_icon("stock_person", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                artist_icon = w.render_icon_pixbuf(Gtk.Stock.ORIENTATION_PORTRAIT, IconSize.BUTTON);
            
            album_icon = w.render_icon_pixbuf(Gtk.Stock.CDROM, IconSize.BUTTON);
            
            if(theme.has_icon("media-audio")) 
                title_icon = theme.load_icon("media-audio", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("audio-x-generic")) 
                title_icon = theme.load_icon("audio-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                title_icon = w.render_icon_pixbuf(Gtk.Stock.OPEN, IconSize.BUTTON);
            
            if(theme.has_icon("video-x-generic")) 
                videos_icon = theme.load_icon("video-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                videos_icon = w.render_icon_pixbuf(Gtk.Stock.MEDIA_RECORD, IconSize.BUTTON);
            
            if(theme.has_icon("xn-playlist"))
                playlist_icon = IconTheme.get_default().load_icon("xn-playlist", iconheight, IconLookupFlags.FORCE_SIZE);
            else
                playlist_icon = w.render_icon_pixbuf(Gtk.Stock.YES, IconSize.BUTTON);
            
            loading_icon = w.render_icon_pixbuf(Gtk.Stock.REFRESH , IconSize.BUTTON);
            
            if(theme.has_icon("xn-local-collection"))
                local_collection_icon = w.render_icon_pixbuf(Gtk.Stock.HOME, IconSize.BUTTON);
            else
                local_collection_icon = IconTheme.get_default().load_icon("xn-local-collection", iconheight, IconLookupFlags.FORCE_SIZE);
        }
        catch(GLib.Error e) {
            print("Error: %s\n",e.message);
        }
    }
}

