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
private class Xnoise.PlayPauseButton: Gtk.Box {
    private const int PIXELSIZE = 32	;
    private unowned Main xn;
    private Gtk.Image? play  = null;
    private Gtk.Image? pause = null;
    private int iconwidth;
    private Gtk.Button button;
    
    public signal void clicked();
    
    
    public PlayPauseButton() {
        xn = Main.instance;
        this.can_focus = false;
        button = new Gtk.Button();
        button.set_relief(ReliefStyle.NONE);
        
        unowned IconTheme theme = IconTheme.get_default();
        
        bool rtl = get_direction() == Gtk.TextDirection.RTL;
        
        // use standard icon theme or local fallback
        if(theme.has_icon("media-playback-start-symbolic"))
            play = IconRepo.get_themed_image_icon(rtl ? "media-playback-start-rtl-symbolic" : "media-playback-start-symbolic",
                                                  IconSize.LARGE_TOOLBAR, PIXELSIZE);
        else
            play = IconRepo.get_themed_image_icon(rtl ? "xn-media-playback-start-rtl-symbolic" : "xn-media-playback-start-symbolic",
                                                  IconSize.LARGE_TOOLBAR, PIXELSIZE);
        play.show();
        
        if(theme.has_icon("media-playback-pause-symbolic"))
            pause = IconRepo.get_themed_image_icon("media-playback-pause-symbolic",
                                                  IconSize.LARGE_TOOLBAR, PIXELSIZE);
        else
            pause = IconRepo.get_themed_image_icon("xn-media-playback-pause-symbolic",
                                                  IconSize.LARGE_TOOLBAR, PIXELSIZE);
        pause.show();
        
        button.add(play);
        this.add(button);
        button.can_focus = false;
        this.can_focus = false;
        
        button.clicked.connect(this.on_clicked);
        gst_player.sign_paused.connect(this.update_picture);
        gst_player.sign_stopped.connect(this.update_picture);
        gst_player.sign_playing.connect(this.update_picture);
    }

    private void on_clicked(Gtk.Widget sender) {
        Idle.add(handle_click_async);
    }

    private bool handle_click_async() {
        main_window.handle_playpause_action();
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


