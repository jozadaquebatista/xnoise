/* xnoise-track-progressbar.vala
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
 */


using Gtk;

/**
* A SongProgressBar is a Gtk.ProgressBar that shows the playback position in the
* currently played item and changes it upon user input
*/
public class Xnoise.TrackProgressBar : Gtk.ProgressBar {
	private unowned Main xn;
	private const double SCROLL_POS_CHANGE = 0.02;

	public TrackProgressBar() {
		xn = Main.instance;

		this.discrete_blocks = 10;
//		this.set_size_request(180, 18);

		this.set_events(Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.BUTTON1_MOTION_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
		this.button_press_event.connect(this.on_press);
		this.button_release_event.connect(this.on_release);
		this.scroll_event.connect(this.on_scroll);

		xn.gPl.sign_song_position_changed.connect(set_value);
		global.caught_eos_from_player.connect(on_eos);
		xn.gPl.sign_stopped.connect(on_stopped);

		//this.set_text("00:00 / 00:00");
//xn.main_window.timelabel.label = "00:00 / 00:00";
		this.fraction = 0.0;
	}

	private bool on_press(Gdk.EventButton e) {
		if((xn.gPl.playing)|(xn.gPl.paused)) {
			xn.gPl.seeking = true;
			this.motion_notify_event.connect(on_motion_notify);
		}
		return false;
	}

	private bool on_release(Gdk.EventButton e) {
		if((xn.gPl.playing)|(xn.gPl.paused)) {
			double thisFraction;

			double mouse_x, mouse_y;
			mouse_x = e.x;
			mouse_y = e.y;

			Allocation progress_loc;
			this.get_allocation(out progress_loc);
			thisFraction = mouse_x / progress_loc.width;

			this.motion_notify_event.disconnect(on_motion_notify);

			xn.gPl.seeking = false;
			if(thisFraction < 0.0) thisFraction = 0.0;
			if(thisFraction > 1.0) thisFraction = 1.0;
			this.set_fraction(thisFraction);
			this.xn.main_window.sign_pos_changed(thisFraction);

			set_value((uint)((thisFraction * xn.gPl.length_time) / 1000000), (uint)(xn.gPl.length_time / 1000000));
		}
		return false;
	}
	
	private bool on_scroll(Gdk.EventScroll event) {
		if(global.player_state != PlayerState.STOPPED) {
			xn.gPl.request_time_offset_seconds((event.direction == Gdk.ScrollDirection.DOWN) ? -10 : 10);
		}
		return false;
	}
	
	private bool on_motion_notify(Gdk.EventMotion e) {
		double thisFraction;
		double mouse_x, mouse_y;
		mouse_x = e.x;
		mouse_y = e.y;
		Allocation progress_loc;
		this.get_allocation(out progress_loc);
		thisFraction = mouse_x / progress_loc.width;

		if(thisFraction < 0.0) thisFraction = 0.0;
		if(thisFraction > 1.0) thisFraction = 1.0;

		this.set_fraction(thisFraction);
		this.xn.main_window.sign_pos_changed(thisFraction);

		return false;
	}

	private void on_eos() {
		set_value(0,0);
	}

	private void on_stopped() {
		set_value(0,0);
	}

	public void set_value(uint pos, uint len) {
		if(len > 0) {
			int dur_min, dur_sec, pos_min, pos_sec;
			double fraction = (double)pos/(double)len;
			if(fraction<0.0) fraction = 0.0;
			if(fraction>1.0) fraction = 1.0;
			this.set_fraction(fraction);

			this.set_sensitive(true);

			dur_min = (int)(len / 60000);
			dur_sec = (int)((len % 60000) / 1000);
			pos_min = (int)(pos / 60000);
			pos_sec = (int)((pos % 60000) / 1000);
			string timeinfo = "%02d:%02d / %02d:%02d".printf(pos_min, pos_sec, dur_min, dur_sec);
			xn.main_window.timelabel.label = timeinfo;
//			this.set_text(timeinfo);
		}
		else {
			this.set_fraction(0.0);
//			this.set_text("00:00 / 00:00");
xn.main_window.timelabel.label = "00:00 / 00:00";
			this.set_sensitive(false);
		}
	}
}


