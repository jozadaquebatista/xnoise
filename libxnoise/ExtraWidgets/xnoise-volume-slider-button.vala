/* xnoise-volume-slider-button.vala
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
 *     softshaker
 */


using Gtk;

using Xnoise;

/**
* A VolumeSliderButton is a Gtk.VolumeButton used to change the volume
*/
internal class Xnoise.VolumeSliderButton : Gtk.VolumeButton {
    
    private unowned GstPlayer player;
    private uint src = 0;
    
    public VolumeSliderButton(GstPlayer player) {
        this.player = player;
        this.size = Gtk.IconSize.LARGE_TOOLBAR;
        this.can_focus = false;
        this.relief = Gtk.ReliefStyle.NONE;
        this.set_value(0.1);
        this.value_changed.connect(on_change);
        Idle.add( () => {
            this.set_value(Params.get_double_value("volume"));
            return false;
        });
        player.notify["volume"].connect(on_player_volume_change);
    }
    
    private void on_player_volume_change() {
        this.freeze_notify();
        this.set_value(player.volume);
        this.thaw_notify();
    }
    
    private void on_change() {
        //print("vol on changed\n");
        player.volume = this.get_value();
        
        // store
        if(src != 0)
            Source.remove(src);
        src = Idle.add( () => {
            Params.set_double_value("volume", this.get_value());
            src = 0;
            return false;
        });
    }
}

