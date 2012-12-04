/* xnoise-play-pause-button.vala
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

using Xnoise;
using Xnoise.Resources;



/**
* A PlayPauseButton is a Gtk.Button that accordingly pauses, unpauses or starts playback
*/
private class Xnoise.PlayPauseButton: Gtk.ToolItem {
    private unowned Main xn;
    private Pixbuf play  = null;
    private Pixbuf pause = null;
    private Gtk.Image image;
    private int iconwidth;
    private unowned IconTheme theme = null;
    
    public signal void clicked();
    
    
    public PlayPauseButton() {
        xn = Main.instance;
        this.can_focus = false;
        
        theme = IconTheme.get_default();
        var button = new Gtk.Button();
        var w = new Gtk.Invisible();
        play = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PLAY, IconSize.LARGE_TOOLBAR);
        iconwidth = play.width;
        if(theme.has_icon("media-playback-start-symbolic")) {
            try {
                play = theme.load_icon("media-playback-start-symbolic",
                                     iconwidth,
                                     IconLookupFlags.FORCE_SIZE
                );
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
        }
        if(theme.has_icon("media-playback-pause-symbolic")) {
            try {
                pause = theme.load_icon("media-playback-pause-symbolic",
                                     iconwidth,
                                     IconLookupFlags.FORCE_SIZE
                );
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
        }
        else {
            pause = w.render_icon_pixbuf(Gtk.Stock.MEDIA_PAUSE, IconSize.LARGE_TOOLBAR);
        }
        image = new Gtk.Image.from_pixbuf(play);
        button.add(image);
        this.add(button);
        button.can_focus = false;
        this.can_focus = false;

        this.update_picture();
        
        button.clicked.connect(this.on_clicked);
        gst_player.sign_paused.connect(this.update_picture);
        gst_player.sign_stopped.connect(this.update_picture);
        gst_player.sign_playing.connect(this.update_picture);
    }

    public void on_menu_clicked(Gtk.MenuItem sender) {
        handle_click();
    }

    public void on_clicked(Gtk.Widget sender) {
        handle_click();
    }

    /**
     * This method is used to handle play/pause commands from different signal handler sources
     */
    private void handle_click() {
        Idle.add(handle_click_async);
        this.clicked();
    }
    
    private bool handle_click_async() {
        if(global.current_uri == null) {
            string uri = tl.tracklistmodel.get_uri_for_current_position();
            
            if((uri != null) && (uri != EMPTYSTRING)) {
                global.in_preview = false;
                global.current_uri = uri;
            }
            else {
                return false;
            }
        }
        if(global.in_preview) {
            if(gst_player.playing) {
                gst_player.pause();
            }
            else {
                gst_player.play();
            }
            return false;
        }
        if(global.player_state == PlayerState.PLAYING) {
            global.player_state = PlayerState.PAUSED;
        }
        else {
            global.player_state = PlayerState.PLAYING;
        }
        return false;
    }

    public void update_picture() {
        if(gst_player.playing == true)
            image.pixbuf = pause;
        else
            image.pixbuf = play;
    }
}


