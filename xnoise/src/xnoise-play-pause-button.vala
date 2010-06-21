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
 * 	Jörn Magens
 * 	softshaker
 */


using Gtk;

/**
* A PlayPauseButton is a Gtk.Button that accordingly pauses, unpauses or starts playback
*/
public class Xnoise.PlayPauseButton: Gtk.Button {
	private unowned Main xn;
	private Gtk.Image playImage;
	private Gtk.Image pauseImage;

	public PlayPauseButton() {
		xn = Main.instance;
		this.can_focus = false;
		this.relief = Gtk.ReliefStyle.NONE;

		this.playImage = new Image.from_stock(STOCK_MEDIA_PLAY, IconSize.LARGE_TOOLBAR);
		this.pauseImage = new Image.from_stock(STOCK_MEDIA_PAUSE, IconSize.LARGE_TOOLBAR);
		this.update_picture();

		this.clicked.connect(this.on_clicked);
		xn.gPl.sign_paused.connect(this.update_picture);
		xn.gPl.sign_stopped.connect(this.update_picture);
		xn.gPl.sign_playing.connect(this.update_picture);
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
		Idle.add(
			handle_click_async
		);
	}
	
	private bool handle_click_async() {
		if(global.current_uri == null) {
			string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
			if((uri != "")&&(uri != null)) 
				global.current_uri = uri;
		}

		if(global.track_state == GlobalInfo.TrackState.PLAYING) {
			global.track_state = GlobalInfo.TrackState.PAUSED;
		}
		else {
			global.track_state = GlobalInfo.TrackState.PLAYING;
		}
		return false;
	}

	public void update_picture() {
		if(xn.gPl.playing == true)
			this.set_play_picture();
		else
			this.set_pause_picture();
	}

	public void set_play_picture() {
		this.set_image(pauseImage);
	}

	public void set_pause_picture() {
		this.set_image(playImage);
	}
}


