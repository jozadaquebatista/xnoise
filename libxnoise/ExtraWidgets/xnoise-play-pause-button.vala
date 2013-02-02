/* xnoise-play-pause-button.vala
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
    private Gtk.Image? play  = null;
    private Gtk.Image? pause = null;
    private int iconwidth;
    private Gtk.Button button;
    
    public signal void clicked();
    
    
    public PlayPauseButton() {
        xn = Main.instance;
        this.can_focus = false;
        var box = new Gtk.Box(Orientation.VERTICAL, 0);
        button = new Gtk.Button();
        button.set_relief(ReliefStyle.NORMAL);
        button.set_size_request(48, -1);
        var eb = new Gtk.EventBox();
        eb.visible_window = false;
        box.pack_start(eb, true, true, 0);
        box.pack_start(button, false, false, 0);
        eb = new Gtk.EventBox();
        eb.visible_window = false;
        box.pack_start(eb, true, true, 0);
        
        unowned IconTheme theme = IconTheme.get_default();
        
        // use standard icon theme or local fallback
        if(theme.has_icon("media-playback-start-symbolic"))
            play = IconRepo.get_themed_image_icon("media-playback-start-symbolic",
                                                  IconSize.LARGE_TOOLBAR);
        else
            play = IconRepo.get_themed_image_icon("xn-media-playback-start-symbolic",
                                                  IconSize.LARGE_TOOLBAR);
        play.show();
        
        if(theme.has_icon("media-playback-pause-symbolic"))
            pause = IconRepo.get_themed_image_icon("media-playback-pause-symbolic",
                                                  IconSize.LARGE_TOOLBAR);
        else
            pause = IconRepo.get_themed_image_icon("xn-media-playback-pause-symbolic",
                                                  IconSize.LARGE_TOOLBAR);
        pause.show();
        
        button.add(play);
        this.add(box);
        button.can_focus = false;
        this.can_focus = false;
        
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
        if(gst_player.playing == true) {
            if(play.get_parent() != null)
                button.remove(play);
            if(pause.get_parent() != null)
                button.remove(pause);
            button.add(pause);
        }
        else {
            if(pause.get_parent() != null)
                button.remove(pause);
            if(play.get_parent() != null)
                button.remove(play);
            button.add(play);
        }
    }
}


