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
        
        var button = new Gtk.Button();
        
        switch(function) {
            case Function.NEXT: {
                image = IconRepo.get_themed_image_icon("media-skip-forward-symbolic", IconSize.LARGE_TOOLBAR);
                break;
            }
            case Function.PREVIOUS: {
                image = IconRepo.get_themed_image_icon("media-skip-backward-symbolic", IconSize.LARGE_TOOLBAR);
                break;
            }
            case Function.STOP: {
                image = IconRepo.get_themed_image_icon("media-playback-stop-symbolic", IconSize.LARGE_TOOLBAR);
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
    }
    
    private void on_clicked() {
        this.sign_clicked(function);
    }
}

