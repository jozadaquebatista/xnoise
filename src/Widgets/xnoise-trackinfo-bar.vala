using Gtk;

public class Xnoise.TrackInfobar : Gtk.VBox {
	private Label title_label;
	private Label time_label;
	private ProgressBar progress;
	private EventBox ebox;
	private unowned GstPlayer player;
	
	public string title_text {
		get { return title_label.label;  }
		set { 
			title_label.label = value;
			title_label.set_use_markup(true);
		}
	}
	
	public TrackInfobar(Xnoise.GstPlayer _player) {
		GLib.Object(homogeneous:false, spacing:5);
		assert(_player != null);
		this.player = _player;
		setup_widgets();
		
		this.ebox.button_press_event.connect(this.on_title_press);
		this.ebox.button_release_event.connect(this.on_title_release);
		this.ebox.scroll_event.connect(this.on_title_scroll);
		
		this.progress.set_events(Gdk.EventMask.SCROLL_MASK |
		                         Gdk.EventMask.BUTTON1_MOTION_MASK |
		                         Gdk.EventMask.BUTTON_PRESS_MASK |
		                         Gdk.EventMask.BUTTON_RELEASE_MASK
		                         );
		this.progress.button_press_event.connect(this.on_progress_press);
		this.progress.button_release_event.connect(this.on_progress_release);
		this.progress.scroll_event.connect(this.on_progress_scroll);
		
		this.player.sign_song_position_changed.connect(set_value);
		global.caught_eos_from_player.connect(on_eos);
		this.player.sign_stopped.connect(on_stopped);
	}

	private bool on_progress_press(Gdk.EventButton e) {
		if((this.player.playing)|(this.player.paused)) {
			this.player.seeking = true;
			this.progress.motion_notify_event.connect(on_progress_motion_notify);
		}
		return false;
	}

	private bool on_progress_release(Gdk.EventButton e) {
		if((this.player.playing)||(this.player.paused)) {
			double thisFraction;
			
			double mouse_x, mouse_y;
			mouse_x = e.x;
			mouse_y = e.y;
			
			Allocation progress_loc;
			this.progress.get_allocation(out progress_loc);
			thisFraction = mouse_x / progress_loc.width;
			thisFraction = invert_if_rtl(thisFraction);
			
			this.progress.motion_notify_event.disconnect(on_progress_motion_notify);
			
			this.player.seeking = false;
			if(thisFraction < 0.0) thisFraction = 0.0;
			if(thisFraction > 1.0) thisFraction = 1.0;
			this.progress.set_fraction(thisFraction);
			this.player.gst_position = thisFraction;
			
			set_value((uint)((thisFraction * this.player.length_time) / 1000000), (uint)(this.player.length_time / 1000000));
		}
		return false;
	}
	
	private bool on_progress_scroll(Gdk.EventScroll event) {
		if(global.player_state != PlayerState.STOPPED) {
			this.player.request_time_offset_seconds((event.direction == Gdk.ScrollDirection.DOWN) ? -10 : 10);
		}
		return false;
	}

	private bool on_progress_motion_notify(Gdk.EventMotion e) {
		double thisFraction;
		double mouse_x, mouse_y;
		mouse_x = e.x;
		mouse_y = e.y;
		Allocation progress_loc;
		this.progress.get_allocation(out progress_loc);
		thisFraction = mouse_x / progress_loc.width;
		thisFraction = invert_if_rtl(thisFraction);

		if(thisFraction < 0.0) thisFraction = 0.0;
		if(thisFraction > 1.0) thisFraction = 1.0;
		this.progress.set_fraction(thisFraction);
		this.player.gst_position = thisFraction;
		return false;
	}

	private bool on_title_press(Gdk.EventButton e) {
	print("on_title_press\n");
		if((this.player.playing)|(this.player.paused)) {
			this.player.seeking = true;
			this.ebox.motion_notify_event.connect(on_title_motion_notify);
		}
		return false;
	}

	private bool on_title_release(Gdk.EventButton e) {
		if((this.player.playing)||(this.player.paused)) {
			double thisFraction;
			
			double mouse_x, mouse_y;
			mouse_x = e.x;
			mouse_y = e.y;
			
			Allocation progress_loc;
			this.title_label.get_allocation(out progress_loc);
			thisFraction = mouse_x / progress_loc.width;
			thisFraction = invert_if_rtl(thisFraction);
			
			this.ebox.motion_notify_event.disconnect(on_title_motion_notify);
			
			this.player.seeking = false;
			if(thisFraction < 0.0) thisFraction = 0.0;
			if(thisFraction > 1.0) thisFraction = 1.0;
			this.progress.set_fraction(thisFraction);
			if(this.player != null)
				this.player.gst_position = thisFraction;
			
			set_value((uint)((thisFraction * this.player.length_time) / 1000000), (uint)(this.player.length_time / 1000000));
		}
		return false;
	}
	
	private bool on_title_scroll(Gdk.EventScroll event) {
		if(global.player_state != PlayerState.STOPPED) {
			this.player.request_time_offset_seconds((event.direction == Gdk.ScrollDirection.DOWN) ? -10 : 10);
		}
		return false;
	}

	private bool on_title_motion_notify(Gdk.EventMotion e) {
		double thisFraction;
		double mouse_x, mouse_y;
		mouse_x = e.x;
		mouse_y = e.y;
		Allocation progress_loc;
		this.title_label.get_allocation(out progress_loc);
		thisFraction = mouse_x / progress_loc.width;
		thisFraction = invert_if_rtl(thisFraction);

		if(thisFraction < 0.0) thisFraction = 0.0;
		if(thisFraction > 1.0) thisFraction = 1.0;
		this.progress.set_fraction(thisFraction);
		this.player.gst_position = thisFraction;
		return false;
	}

	private double invert_if_rtl(double to_invert) {
		if(Widget.get_default_direction() == TextDirection.RTL)
			return 1.0 - to_invert;
		return to_invert;
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
			this.progress.set_fraction(fraction);
			
			this.progress.set_sensitive(true);
			
			dur_min = (int)(len / 60000);
			dur_sec = (int)((len % 60000) / 1000);
			pos_min = (int)(pos / 60000);
			pos_sec = (int)((pos % 60000) / 1000);
			string timeinfo = "%02d:%02d / %02d:%02d".printf(pos_min, pos_sec, dur_min, dur_sec);
			this.time_label.set_text(timeinfo);
		}
		else {
			this.progress.set_fraction(0.0);
			this.time_label.set_text("00:00 / 00:00");
			this.progress.set_sensitive(false);
		}
	}
	
	private void setup_widgets() {
		title_label = new Label("xnoise - ready to rock! ;)");
		title_label.set_single_line_mode(true);
		title_label.set_alignment(0.0f, 0.5f);
		
		ebox = new EventBox(); 
		ebox.set_events(Gdk.EventMask.SCROLL_MASK |
		                Gdk.EventMask.BUTTON1_MOTION_MASK |
		                Gdk.EventMask.BUTTON_PRESS_MASK |
		                Gdk.EventMask.BUTTON_RELEASE_MASK
		                );
		
		ebox.add(title_label);
		
		this.pack_start(ebox, false, true, 0);
		
		var hbox = new Gtk.HBox(false, 2);
		var vbox = new Gtk.VBox(false, 0);
		
		progress = new ProgressBar();
		progress.set_size_request(-1, 10);
		vbox.pack_start(progress, false, true, 0);
		
		hbox.pack_start(vbox, true, true, 0);
		
		time_label = new Label("00:00 / 00:00");
		time_label.set_single_line_mode(true);
		time_label.width_chars = 12;
		hbox.pack_start(time_label, false, false, 0);
		this.pack_start(hbox, false, false, 0);
	}
}
