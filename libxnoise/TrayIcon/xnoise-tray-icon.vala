/* xnoise-tray-icon.vala
 *
 * Copyright (C) 2010-2012  Jörn Magens
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
 * 	Jörn Magens
 */


using Gtk;
using Xnoise.Services;

public class Xnoise.TrayIcon : StatusIcon {
	private Menu traymenu;
	private unowned Main xn;
	private Image playpause_popup_image;
	
	public TrayIcon() {
		this.icon_name = "xnoise";
		this.has_tooltip = true;
		xn = Main.instance;
		construct_traymenu();
		this.query_tooltip.connect(on_query_tooltip);
		
		popup_menu.connect(this.traymenu_popup);
		activate.connect(main_window.toggle_window_visbility);
		scroll_event.connect(this.on_scrolled);
		button_press_event.connect(this.on_clicked);
	}
	
	private void construct_traymenu() {
		traymenu = new Menu();

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
		var playpauseItem = new MenuItem();
		var playHbox = new Box(Orientation.HORIZONTAL, 1);
		playHbox.set_spacing(10);
		playHbox.pack_start(playpause_popup_image, false, true, 0);
		playHbox.pack_start(playLabel, true, true, 0);
		playpauseItem.add(playHbox);
		playpauseItem.activate.connect(main_window.playPauseButton.on_menu_clicked);
		traymenu.append(playpauseItem);

		var previousImage = new Image();
		previousImage.set_from_stock(Gtk.Stock.MEDIA_PREVIOUS, IconSize.MENU);
		var previousLabel = new Label(_("Previous"));
		previousLabel.set_alignment(0, 0);
		var previousItem = new MenuItem();
		var previousHbox = new Box(Orientation.HORIZONTAL, 1);
		previousHbox.set_spacing(10);
		previousHbox.pack_start(previousImage, false, true, 0);
		previousHbox.pack_start(previousLabel, true, true, 0);
		previousItem.add(previousHbox);
		previousItem.activate.connect( () => {
			main_window.handle_control_button_click(main_window.previousButton, ControlButton.Direction.PREVIOUS);
		});
		traymenu.append(previousItem);

		var nextImage = new Image();
		nextImage.set_from_stock(Gtk.Stock.MEDIA_NEXT, IconSize.MENU);
		var nextLabel = new Label(_("Next"));
		nextLabel.set_alignment(0, 0);
		var nextItem = new MenuItem();
		var nextHbox = new Box(Orientation.HORIZONTAL, 1);
		nextHbox.set_spacing(10);
		nextHbox.pack_start(nextImage, false, true, 0);
		nextHbox.pack_start(nextLabel, true, true, 0);
		nextItem.add(nextHbox);
		nextItem.activate.connect( () => {
			main_window.handle_control_button_click(main_window.nextButton, ControlButton.Direction.NEXT);
		});
		traymenu.append(nextItem);

		var separator = new SeparatorMenuItem();
		traymenu.append(separator);

		var exitImage = new Image();
		exitImage.set_from_stock(Gtk.Stock.QUIT, IconSize.MENU);
		var exitLabel = new Label(_("Exit"));
		exitLabel.set_alignment(0, 0);
		var exitItem = new MenuItem();
		var exitHbox = new Box(Orientation.HORIZONTAL, 1);
		exitHbox.set_spacing(10);
		exitHbox.pack_start(exitImage, false, true, 0);
		exitHbox.pack_start(exitLabel, true, true, 0);
		exitItem.add(exitHbox);
		exitItem.activate.connect(xn.quit);
		traymenu.append(exitItem);

		traymenu.show_all();
	}

	private bool on_clicked(Gdk.EventButton e) {
		switch(e.button) {
			case 2:
				//ugly, we should move play/resume code out of there.
				main_window.playPauseButton.on_clicked(new Gtk.Button());
				break;
			default:
				break;
		}
		return false;
	}

	private bool on_scrolled(Gtk.StatusIcon sender, Gdk.EventScroll event) {
		if(global.player_state != PlayerState.STOPPED) {
			if(event.direction == Gdk.ScrollDirection.DOWN) {
				main_window.change_track(ControlButton.Direction.PREVIOUS, true);
			}
			else if(event.direction == Gdk.ScrollDirection.UP) {
				main_window.change_track(ControlButton.Direction.NEXT, true);
			}
		}
		return false;
	}
	
	private void traymenu_popup(StatusIcon i, uint button, uint activateTime) {
		traymenu.popup(null, null, i.position_menu, 0, activateTime);
	}
	
	// todo: use global string constants for unknown_[title,album,artist] and state!
	// for now they are left uni18ned
	private bool on_query_tooltip(int x, int y, bool keyboard_mod, Tooltip tp) {
		string state = "";
		string? uri = global.current_uri;
		switch(global.player_state) {
			case PlayerState.STOPPED: {
				state = _("stopped");
				break;
			}
			case PlayerState.PLAYING: {
				state = _("playing");
				break;
			}
			case PlayerState.PAUSED: {
				state = _("paused");
				break;
			}
			default: {
				state = _("stopped");
				break;
			}
		}
		state = Markup.escape_text(state);
	
		if(global.player_state == PlayerState.STOPPED || uri == null || uri == "") {
			tp.set_markup(" xnoise media player \n" +
				          "<span rise=\"6000\" style =\"italic\"> %s ;)</span>".printf(_("ready to rock")));
			return true;
		}
	
		string? title = global.current_title;
		string? artist = global.current_artist;
		string? album = global.current_album;
	
		string? filename = null;
		if(uri != null) {
			File f = File.new_for_uri(uri);
			if(f != null) {
				filename = f.get_basename();
				filename = Markup.escape_text(filename);
			}
		}
	
		//if neither title nor artist are known, show filename instead
		//if there is no title, the title is the same as the filename
		//shouldn't global rather return null if there is no title?
	
		//todo: handle streams, change label layout, pack into a box with padding and use Tooltip.set_custom
		if((title == null && artist == null && filename != null) || (filename == title /*&& artist == null*/)) {
			tp.set_markup("\n<b>" + prepare_name_from_filename(filename) + " </b><span size=\"xx-small\">\n</span>" +
			              "<span size=\"small\" style=\"italic\" rise=\"6000\">" +
			              state + "</span>\n");
		}
		else {
			if(album == null)
				album = _("unknown album");
			if(artist == null)
				artist = _("unknown artist");
			if(title == null)
				title = _("unknown title");
			
			album = Markup.escape_text(album);
			artist = Markup.escape_text(artist);
			title = Markup.escape_text(title);
			
			tp.set_markup("<span weight=\"bold\">" + 
			              title +   " </span>\n<span size=\"small\" rise=\"6000\" style=\"italic\">" + 
			              state + "</span><span size=\"xx-small\">\n</span>" +
			              "<span size=\"small\" weight=\"light\">     %s </span>".printf(_("by")) + 
			              artist + " \n" +
			              "<span size=\"small\" weight=\"light\">     %s </span> ".printf(_("on")) + 
			              album);
		}
		
		return true;
	}
}
