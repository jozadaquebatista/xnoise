/* xnoise-global-access.vala
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


/**
 * This class is used to hold application wide states like if the application is playing, the uri of the current title...
 * All these are properties, so that changes can be tracked application wide.
 */

using Xnoise;
using Xnoise.Resources;


public class Xnoise.GlobalAccess : GLib.Object {
    
    construct {
        main_cancellable = new Cancellable();
        
        uri_changed.connect( (s,v) => {
        //print("uri_changed\n");
            current_artist = null;
            current_album = null;
            current_title = null;
            current_location = null;
            current_genre = null;
            current_organization = null;
        });
        
        this.notify.connect( (s, p) => {
            //print("p.name: %s\n", p.name);
            switch(p.name) {
                case "current-artist":
                    this.tag_changed(this._current_uri, "artist", this._current_artist);
                    break;
                case "current-album":
                    this.tag_changed(this._current_uri, "album", this._current_album);
                    break;
                case "current-title":
                    this.tag_changed(this._current_uri, "title", this._current_title);
                    break;
                case "current-location":
                    this.tag_changed(this._current_uri, "location", this._current_location);
                    break;
                case "current-genre":
                    this.tag_changed(this._current_uri, "genre", this._current_genre);
                    break;
                case "current-org":
                    this.tag_changed(this._current_uri, "organization", this._current_organization);
                    break;
            }
            
            if(check_image_for_current_track_source != 0) {
                Source.remove(check_image_for_current_track_source);
                check_image_for_current_track_source = 0;
            }
            check_image_for_current_track_source = Timeout.add(200, () => {
                if(MainContext.current_source().is_destroyed())
                    return false;
                check_image_for_current_track();
                check_image_for_current_track_source = 0;
                return false;
            });
        });
    }

    
    // SIGNALS

    // TreeRowReference for current track changed
    public signal void position_reference_changed();
    // TreeRowReference for current track changed, triggered before change
    public signal void before_position_reference_changed();
    public signal void before_position_reference_next_changed();
    public signal void position_reference_next_changed();
    // state changed to playing, paused or stopped
    public signal void player_state_changed();
    public signal void uri_changed(string? uri);
    public signal void uri_repeated(string? uri);
    public signal void tag_changed(string? newuri, string? tagname, string? tagvalue);
    
    public signal void sign_searchtext_changed(string text);
    
    public signal void caught_eos_from_player();
    //signal to be triggered after a change of the media folders
    public signal void sig_media_path_changed();
    public signal void sig_item_imported(string uri);
    
    public signal void sign_restart_song();
    public signal void sign_song_info_required();
    
    public signal void sign_image_path_large_changed();
    public signal void sign_image_path_small_changed();
    public signal void sign_image_path_embedded_changed();
    
    public signal void sign_main_view_changed(string new_view_name);

    public signal void player_in_shutdown();

    // PRIVATE FIELDS
    private PlayerState _player_state = PlayerState.STOPPED;
    private string? _current_uri = null;
    private Gtk.TreeRowReference? _position_reference = null;
    private Gtk.TreeRowReference? _position_reference_next = null;
    private string _searchtext = "";
    private uint check_image_for_current_track_source = 0;
    
    // PROPERTIES
    
    //searchtext shall be changed by the searchentry, only!
    //searchtext is without trailing or leading white space
    //serachtext is always lower case
    public string searchtext { 
        get {
            return _searchtext;
        }
        set {
            string stval = value.strip().down();
            if(_searchtext == stval)
                return;
            _searchtext = stval;
            sign_searchtext_changed(_searchtext);
        }
    }
    
    public string active_dockable_media_name { get; set; default = ""; }
    
    public int fontsize_dockable { get; set; default = 10; }
    
    public PlayerState player_state {
        get {
            return _player_state;
        }
        set {
            if(_player_state != value) {
                _player_state = value;
                // signal changed
                player_state_changed();
            }
        }
    }

    public string? current_uri {
        get {
            return _current_uri;
        }
        set {
            if(_current_uri != value) {
                _current_uri = value;
                // signal changed
                uri_changed(value);
            }
        }
    }

    // position_reference is pointing to the current row in the tracklist
    public Gtk.TreeRowReference position_reference {
        get {
            return _position_reference;
        }
        set {
            if(_position_reference != value) {
                before_position_reference_changed();
                _position_reference = value;
                // signal changed
                position_reference_changed();
            }
        }
    }

    // The next_position_reference is used to hold a position in the tracklist,
    // in case the row position_reference is pointing to is removed and the next
    // song has not yet been started.
    public Gtk.TreeRowReference position_reference_next {
        get {
            return _position_reference_next;
        }
        set {
            if(_position_reference_next != value) {
                before_position_reference_next_changed();
                _position_reference_next = value;
                // signal changed
                position_reference_next_changed();
            }
        }
    }

    private bool _media_import_in_progress;
    public bool media_import_in_progress {
        get {
            return _media_import_in_progress;
        }
        set {
            _media_import_in_progress = value;
        }
    }

    // Current track's meta data
    public string current_artist { get; set; default = null; }
    public string current_album { get; set; default = null; }
    public string current_title { get; set; default = null; }
    public string current_location { get; set; default = null; }
    public string current_genre { get; set; default = null; }
    public string current_organization { get; set; default = null; }
    
    private string? _image_path_small = null;
    public string? image_path_small { 
        get {
            return _image_path_small;
        }
        set {
            if(_image_path_small == value)
                return;
            _image_path_small = value;
            sign_image_path_small_changed();
        }
    }

    private string? _image_path_large = null;
    public string? image_path_large { 
        get {
            return _image_path_large;
        }
        set {
            if(_image_path_large == value)
                return;
            _image_path_large = value;
            sign_image_path_large_changed();
        }
    }

    private string? _image_path_embedded = null;
    public string? image_path_embedded { 
        get {
            return _image_path_embedded;
        }
        set {
            if(_image_path_embedded == value)
                return;
            _image_path_embedded = value;
            sign_image_path_embedded_changed();
        }
    }
    
    public bool cellrenderer_in_edit = false;
    
    // PUBLIC GLOBAL FUNCTIONS
    public void reset_position_reference() {
        this._position_reference = null;
    }

    public void do_restart_of_current_track() {
        sign_restart_song();
    }
    
    public static Cancellable main_cancellable;
    
    public unowned GstPlayer player;
    public bool in_preview { get; set; }
    
    public void handle_eos() {
        if(in_preview) {
            in_preview = false;
            stop();
            player.stop();
        }
        else {
            //emmit signal
            caught_eos_from_player();
        }
    }
    
    public void preview_uri(string uri) {
        stop();         // if playing from tracklist
        player.stop();  // for tracklist-less playing
        in_preview = true;
        global.current_uri = uri;
        gst_player.play();
    }
    
    public void check_image_for_current_track() {
        string? small_name = null;
        string? large_name = null; 
        string? embedded_name = null; 
        File f = get_albumimage_for_artistalbum(current_artist, current_album, "medium");
        small_name = f != null ? f.get_path() : EMPTYSTRING;
        if((small_name == EMPTYSTRING) || (small_name == null)) {
            image_path_small = null;
            image_path_large = null;
            image_path_embedded = null;
            return;
        }
        
        File f2 = get_albumimage_for_artistalbum(current_artist, current_album, "embedded");
        embedded_name = f2 != null ? f2.get_path() : EMPTYSTRING;
        
        large_name = small_name.substring(0, small_name.length - "medium".length);
        large_name = large_name + "extralarge";
        File small = File.new_for_path(small_name);
        File large = File.new_for_path(large_name);
        File embedded = File.new_for_path(embedded_name);
        if(!small.query_exists(null))
            small_name = null;
        if(!large.query_exists(null))
            image_path_large = small_name;
        else
            image_path_large = large_name;
        
        if(!embedded.query_exists(null))
            image_path_embedded = null;
        else
            image_path_embedded = embedded_name;
        
        image_path_small = small_name;
    }
    
    public void prev() {
        if(player_state == PlayerState.STOPPED)
            return;
        main_window.change_track(Xnoise.ControlButton.Direction.PREVIOUS);
    }

    public void play(bool pause_if_playing) {
        if(current_uri == null) {
            string uri = tl.tracklistmodel.get_uri_for_current_position();
            if((uri != EMPTYSTRING) && (uri != null)) 
                current_uri = uri;
        }
        if(player_state == PlayerState.PLAYING && pause_if_playing) 
            player_state = PlayerState.PAUSED;
        else 
            player_state = PlayerState.PLAYING;
    }

    public void pause() {
        if(current_uri == null) {
            string uri = tl.tracklistmodel.get_uri_for_current_position();
            if((uri != EMPTYSTRING) && (uri != null)) 
                current_uri = uri;
        }
        player_state = PlayerState.PAUSED;
    }

    public void next() {
        if(global.player_state == PlayerState.STOPPED)
            return;
        main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
    }

    public void stop() {
        main_window.stop();
    }
}
