/* xnoise-app-indicator.vala
 *
 * Copyright (C) 2013  Jörn Magens
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
using AppIndicator;

using Xnoise;
using Xnoise.PluginModule;

public class Xnoise.AppIndicator : GLib.Object, IPlugin {
    private Indicator indicator;
    private Gtk.Menu menu;
    private Image playpause_popup_image;
    
    private unowned PluginModule.Container _owner;
    
    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }
    
    public Xnoise.Main xn { get; set; }
    
    public string name { 
        get {
            return "AppIndicator";
        } 
    }

    public bool init() {
        print("init AppIndicator plugin\n");
        if(indicator == null) {
            indicator = new Indicator("xnoise",
                                      "xnoise-panel",
                                      IndicatorCategory.APPLICATION_STATUS);
        }
        indicator.set_icon_full("xnoise-panel", "XN");
        indicator.set_status(IndicatorStatus.ACTIVE);
        menu = construct_traymenu();
        indicator.set_menu(menu);
        if(indicator != null)
            return true;
        else
            return false;
    }

    public void uninit() {
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }

    private Gtk.Menu construct_traymenu() {
        var traymenu = new Gtk.Menu();
        
        playpause_popup_image = new Image();
        playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
        gst_player.sign_playing.connect( () => {
            this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PAUSE, IconSize.MENU);
        });
        gst_player.sign_stopped.connect( () => {
            if(this.playpause_popup_image==null) print("this.playpause_popup_image == null\n");
            this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
        });
        gst_player.sign_paused.connect( () => {
            this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
        });

        var playLabel = new Label(_("Play/Pause"));
        playLabel.set_alignment(0, 0);
        playLabel.set_width_chars(20);
        var playpauseItem = new Gtk.MenuItem();
        var playHbox = new Box(Orientation.HORIZONTAL, 1);
        playHbox.set_spacing(10);
        playHbox.pack_start(playpause_popup_image, false, true, 0);
        playHbox.pack_start(playLabel, true, true, 0);
        playpauseItem.add(playHbox);
        playpauseItem.activate.connect( () => {
            global.play(true);
        });
        traymenu.append(playpauseItem);
        
        var previousImage = new Image();
        previousImage.set_from_stock(Gtk.Stock.MEDIA_PREVIOUS, IconSize.MENU);
        var previousLabel = new Label(_("Previous"));
        previousLabel.set_alignment(0, 0);
        var previousItem = new Gtk.MenuItem();
        var previousHbox = new Box(Orientation.HORIZONTAL, 1);
        previousHbox.set_spacing(10);
        previousHbox.pack_start(previousImage, false, true, 0);
        previousHbox.pack_start(previousLabel, true, true, 0);
        previousItem.add(previousHbox);
        previousItem.activate.connect( () => {
            global.prev();
        });
        traymenu.append(previousItem);
        
        var nextImage = new Image();
        nextImage.set_from_stock(Gtk.Stock.MEDIA_NEXT, IconSize.MENU);
        var nextLabel = new Label(_("Next"));
        nextLabel.set_alignment(0, 0);
        var nextItem = new Gtk.MenuItem();
        var nextHbox = new Box(Orientation.HORIZONTAL, 1);
        nextHbox.set_spacing(10);
        nextHbox.pack_start(nextImage, false, true, 0);
        nextHbox.pack_start(nextLabel, true, true, 0);
        nextItem.add(nextHbox);
        nextItem.activate.connect( () => {
            global.next();
        });
        traymenu.append(nextItem);
        
        var separator = new SeparatorMenuItem();
        traymenu.append(separator);
        
        var raiseImage = new Image();
        raiseImage.set_from_stock(Gtk.Stock.LEAVE_FULLSCREEN, IconSize.MENU);
        var raiseLabel = new Label(_("Show xnoise"));
        raiseLabel.set_alignment(0, 0);
        var raiseItem = new Gtk.MenuItem();
        var raiseHbox = new Box(Orientation.HORIZONTAL, 1);
        raiseHbox.set_spacing(10);
        raiseHbox.pack_start(raiseImage, false, true, 0);
        raiseHbox.pack_start(raiseLabel, true, true, 0);
        raiseItem.add(raiseHbox);
        raiseItem.activate.connect( () => {
            main_window.show_window();
            main_window.present();
        });
        traymenu.append(raiseItem);
        
        traymenu.append(new SeparatorMenuItem());
        
        var exitImage = new Image();
        exitImage.set_from_stock(Gtk.Stock.QUIT, IconSize.MENU);
        var exitLabel = new Label(_("Exit"));
        exitLabel.set_alignment(0, 0);
        var exitItem = new Gtk.MenuItem();
        var exitHbox = new Box(Orientation.HORIZONTAL, 1);
        exitHbox.set_spacing(10);
        exitHbox.pack_start(exitImage, false, true, 0);
        exitHbox.pack_start(exitLabel, true, true, 0);
        exitItem.add(exitHbox);
        exitItem.activate.connect(xn.quit);
        traymenu.append(exitItem);
        
        traymenu.show_all();
        return traymenu;
    }
}

