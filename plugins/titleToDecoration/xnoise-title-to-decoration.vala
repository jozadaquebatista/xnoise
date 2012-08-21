/* xnoise-title-to-decoration.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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
using Xnoise.Services;
using Xnoise.PluginModule;

public class Xnoise.TitleToDecoration : GLib.Object, IPlugin {
    private unowned PluginModule.Container _owner;
    private static const string XN_MEDIA_PLAYER = "xnoise media player";
    
    public Main xn { get; set; }
    
    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }

    public string name { 
        get {
            return "TitleToDecoration";
        } 
    }

    public bool init() {
        global.tag_changed.connect(write_title_to_decoration);
        source = 0;
        return true;
    }
    
    private uint source;
    private void write_title_to_decoration(string? uri, string? x, string? y) {
        //print("write_title_to_decoration %s %s %s\n", newuri, x, y);
        if(source != 0) {
            Source.remove(source);
            this.source = (uint)0;
        }
        if(uri == null)
            return;
        source = Idle.add( () => {
            dispatch_set_title_to_decoration(uri, x, y);
            this.source = (uint)0;
            return false;
        });
    }

    private void dispatch_set_title_to_decoration(string? newuri, string? x, string? y) {
        if(MainContext.current_source().is_destroyed()) 
            return;

        string text, album, artist, title, genre, location, organization;
        string basename = null;
        if(newuri == null) {
            main_window.title = XN_MEDIA_PLAYER;
            return;
        }
        File file = File.new_for_uri(newuri);
        if(!gst_player.is_stream)
            basename = file.get_basename();
        if(global.current_artist != null) {
            //print("global.current_artist: %s\n", global.current_artist);
            artist = remove_linebreaks(global.current_artist);
        }
        else {
            artist = UNKNOWN_ARTIST;
        }
        if(global.current_title != null) {
            title = remove_linebreaks(global.current_title);
        }
        else {
            title = UNKNOWN_TITLE;
        }
        if(global.current_album != null) {
            album = remove_linebreaks(global.current_album);
        }
        else {
            album = UNKNOWN_ALBUM;
        }
        if(global.current_organization != null) {
            organization = remove_linebreaks(global.current_organization);
        }
        else {
            organization = UNKNOWN_ORGANIZATION;
        }
        if(global.current_genre!=null) {
            genre = remove_linebreaks(global.current_genre);
        }
        else {
            genre = UNKNOWN_GENRE;
        }
        if(global.current_location != null) {
            location = remove_linebreaks(global.current_location);
        }
        else {
            location = UNKNOWN_LOCATION;
        }
        if((newuri != null) && (newuri != EMPTYSTRING)) {
            text = "%s %s %s %s %s ".printf( 
                title, 
                _("by"), 
                artist, 
                _("on"), 
                album
                );
            if(album == UNKNOWN_ALBUM && 
               artist == UNKNOWN_ARTIST && 
               title == UNKNOWN_TITLE) 
                if(organization != UNKNOWN_ORGANIZATION) 
                    text = "%s".printf(organization);
                else if(location != UNKNOWN_LOCATION) 
                    text = "%s".printf(location);
                else
                    text = XN_MEDIA_PLAYER;
        }
        else {
            if((!gst_player.playing)&&
                (!gst_player.paused)) {
                text = XN_MEDIA_PLAYER;
            }
            else {
                text = "%s %s %s %s %s ".printf( 
                    UNKNOWN_TITLE_LOCALIZED, 
                    _("by"), 
                    UNKNOWN_ARTIST_LOCALIZED,
                    _("on"), 
                    UNKNOWN_ALBUM_LOCALIZED
                    );
            }
        }
        //print("text: %s\n", text);
        if(MainContext.current_source().is_destroyed()) 
            return;
        main_window.set_title(text);
    }
    
    public void uninit() {
        main_window.set_title(XN_MEDIA_PLAYER);
    }
    
    ~TitleToDecoration() {
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return true;
    }
}

