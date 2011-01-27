/* xnoise-fullscreen-toolbar.vala
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

public class Xnoise.FullscreenToolbar {
	private unowned Main xn;
	private const uint hide_delay = 4;
	private Gtk.Window window;
	private Gtk.Window fullscreenwindow;
	private TrackProgressBar bar;
	private uint hide_event_id;
	private bool hide_lock;
	private Gdk.Cursor invisible_cursor;
	
	private void handle_control_button_click(ControlButton sender, ControlButton.Direction dir) {
		if(xn == null) return;
		if(xn.main_window == null) return;
		if(dir == ControlButton.Direction.NEXT || dir == ControlButton.Direction.PREVIOUS)
			xn.main_window.change_track(dir);
		else if(dir == ControlButton.Direction.STOP)
			xn.main_window.stop();
	}

	public FullscreenToolbar(Gtk.Window fullscreenwindow) {
		xn = Main.instance;
		this.hide_lock = false;
		this.fullscreenwindow = fullscreenwindow;
		window = new Gtk.Window (Gtk.WindowType.POPUP);

		var mainbox = new Gtk.HBox(false,8);

		var nextbutton      = new ControlButton(ControlButton.Direction.NEXT);
		nextbutton.sign_clicked.connect(handle_control_button_click);
		var previousbutton  = new ControlButton(ControlButton.Direction.PREVIOUS);
		previousbutton.sign_clicked.connect(handle_control_button_click);
		var plpabutton      = new PlayPauseButton();
		var leavefullscreen = new LeaveVideoFSButton();
		var volume          = new VolumeSliderButton();

		bar = new TrackProgressBar();
		var vp = new Gtk.Alignment(0,0.5f,0,0);
		vp.add (bar);

		mainbox.pack_start(previousbutton,false,false,0);
		mainbox.pack_start(plpabutton,false,false,0);
		mainbox.pack_start(nextbutton,false,false,0);
		mainbox.pack_start(vp,true,false,0);
		//mainbox.pack_start(ai_frame,false,false,0);
		mainbox.pack_start(leavefullscreen,false,false,0);
		mainbox.pack_start(volume,false,false,0);


		window.add(mainbox);
		fullscreenwindow.motion_notify_event.connect(on_pointer_motion);
		window.enter_notify_event.connect(on_pointer_enter_toolbar);
		fullscreenwindow.enter_notify_event.connect(on_pointer_enter_fswindow);
		fullscreenwindow.key_release_event.connect(this.on_key_released);
		resize ();
		
		invisible_cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
	}

	private const int SPACE_KEY = 0x0020;
	private const int KEY_ESC   = 0xFF1B;
	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
		switch(e.keyval) {
			case KEY_ESC: {
				this.xn.main_window.toggle_fullscreen();
				return true;
			}
			case SPACE_KEY: {
				this.xn.main_window.playPauseButton.clicked();
				return true;
			}
			default: 
				break;
		}
		return false;
	}

	public void resize() {
		Gdk.Screen screen;
		Gdk.Rectangle rect;

		screen = fullscreenwindow.get_screen();
		screen.get_monitor_geometry (screen.get_monitor_at_window (fullscreenwindow.get_window()),out rect);

		this.window.resize(rect.width, 30);
		bar.set_size_request(rect.width/2,18);
	}

	private bool hide_timer_elapsed () {
		if(!this.hide_lock) this.hide();
		return false;
	}

	public void launch_hide_timer () {
		hide_event_id = Timeout.add_seconds (hide_delay, hide_timer_elapsed);
	}


	private bool on_pointer_enter_fswindow (Gdk.EventCrossing ev) {
		this.hide_lock = false;
		fullscreenwindow.motion_notify_event.connect(on_pointer_motion);
		return false;
	}

	private bool on_pointer_enter_toolbar (Gdk.EventCrossing ev) {
		this.hide_lock = true;
		if(hide_event_id != 0) {
			GLib.Source.remove (hide_event_id);
			hide_event_id = 0;
		}
		fullscreenwindow.motion_notify_event.disconnect(on_pointer_motion);
		return false;
	}
	
	public bool on_pointer_motion (Gdk.EventMotion ev) {
		if(!window.get_window().is_visible())show();
		if(hide_lock == true) return false;
		if(hide_event_id != 0) {
			 GLib.Source.remove (hide_event_id);
			 hide_event_id = 0;
		}
		launch_hide_timer();
		return false;
	}


	public void show() {
		window.show_all();
		//show the default cursor
		Gdk.Window w = fullscreenwindow.get_window();
		w.set_cursor(null);
		launch_hide_timer();
	}

	public void hide() {
		window.hide();
		//hide cursor
		Gdk.Window w = fullscreenwindow.get_window();
		w.set_cursor(invisible_cursor);
				
		if(hide_event_id != 0) {
			 GLib.Source.remove (hide_event_id);
			 hide_event_id = 0;
		}
	}

	/**
	* A LeaveVideoFSButton is a Gtk.Button that switches off the fullscreen state of the video fullscreen window
	* The only occurance for now is here. So it's placed in the FullscreenToolbar class
	*/
	public class LeaveVideoFSButton : Gtk.Button {
		private unowned Main xn;
		public LeaveVideoFSButton() {
			this.xn = Main.instance;
			var img = new Gtk.Image.from_stock(Gtk.STOCK_LEAVE_FULLSCREEN , Gtk.IconSize.SMALL_TOOLBAR);
			this.set_image(img);
			this.relief = Gtk.ReliefStyle.NONE;
			this.can_focus = false;
			this.clicked.connect(this.on_clicked);
			this.set_tooltip_text(_("Leave fullscreen"));
		}

		public void on_clicked() {
			this.xn.main_window.videoscreen.get_window().unfullscreen();
			this.xn.main_window.videoscreen.reparent(this.xn.main_window.videovbox);
			this.xn.main_window.fullscreenwindow.hide_all();
			this.xn.main_window.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
			this.xn.main_window.fullscreenwindowvisible = false;
			this.xn.main_window.videovbox.show();
			this.xn.main_window.fullscreentoolbar.hide();
		}
	}
}

