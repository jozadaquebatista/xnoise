/* xnoise-gst-player.vala
 *
 * Copyright (C) 2009 - 2010 Jörn Magens
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

using Gst;

public class Xnoise.GstPlayer : GLib.Object {
	private bool _current_has_video;
	private uint cycle_time_source;
	private uint update_tags_source;
	private uint check_for_video_source;
	private string? _Uri = null;
	private Gst.TagList _taglist;
	public VideoScreen videoscreen;
	private GLib.List<Gst.Message> missing_plugins = new GLib.List<Gst.Message>();
	private dynamic Element playbin;
	
	public bool current_has_video { // TODO: Determine this elsewhere
		get {
			return _current_has_video;
		}
		set {
			_current_has_video = value;
			if(!_current_has_video) 
				videoscreen.trigger_expose();
			else
				sign_video_playing();
		}
	}

	public double volume {
		get {
			double val;
			val = this.playbin.volume;
			return val;
		}
		set {
			double val;
			val = this.playbin.volume;
			if(val!=value) {
				this.playbin.volume = value;
				
				//signal is used in mainwindow to update volume slider
				sign_volume_changed(value); 
			}
		}
	}

	public bool playing           { get; set; }
	public bool paused            { get; set; }
	public bool seeking           { get; set; }
	public int64 length_time      { get; set; }
	public bool is_stream         { get; private set; default = false; }
	public bool buffering         { get; private set; default = false; }
	

	private Gst.TagList taglist {
		get {
			return _taglist;
		}
		private set {
			if (value != null) {
				_taglist = value.copy();
			} else
				_taglist = null;
		}
	}

	public string? Uri {
		get {
			return _Uri;
		}
		set {
			is_stream = false; //reset
			_Uri = value;
			if((value == "")||(value == null)) {
				playbin.set_state(State.NULL); //stop
				print("Uri = null or '' -> set to stop\n");
				playing = false;
				paused = false;
			}
			this.current_has_video = false;
			
			//reset
			taglist = null;
			length_time = 0;
			this.playbin.uri = (value == null ? "" : value);
			if(value != null) {
				File file = File.new_for_commandline_arg(value);
				if(file.get_uri_scheme() == "http") // TODO: Maybe there is a better way to check this?
					is_stream = true;
			}
			sign_song_position_changed((uint)0, (uint)0); //immediately reset song progressbar
		}
	}

	public double gst_position {
		set {
			if(seeking == false) {
				playbin.seek(1.0, Gst.Format.TIME,
				             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
				             Gst.SeekType.SET, (int64)(value * length_time),
				             Gst.SeekType.NONE, -1);
			}
		}
		
		get {
			int64 pos;
			Gst.Format format = Gst.Format.TIME;
			playbin.query_position(ref format, out pos);
			return (double)pos/(double)length_time;
		}
	}

	public signal void sign_song_position_changed(uint msecs, uint ms_total);
	public signal void sign_playing();
	public signal void sign_paused();
	public signal void sign_stopped();
	public signal void sign_video_playing();
	public signal void sign_buffering(int percent);
	public signal void sign_volume_changed(double volume);

	private signal void sign_missing_plugins();

	public GstPlayer() {
		videoscreen = new VideoScreen();
		create_elements();
		cycle_time_source = GLib.Timeout.add_seconds(1, on_cyclic_send_song_position);
		update_tags_source = 0;
		check_for_video_source = 0;

		global.uri_changed.connect( () => {
			this.request_location(global.current_uri);
		});

		global.track_state_changed.connect( () => {
			if(global.track_state == GlobalInfo.TrackState.PLAYING)
				this.play();
			else if(global.track_state == GlobalInfo.TrackState.PAUSED)
				this.pause();
			else if(global.track_state == GlobalInfo.TrackState.STOPPED)
				this.stop();
		});
		
		global.sign_restart_song.connect( () => {
			playbin.seek(1.0, Gst.Format.TIME,
			             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
			             Gst.SeekType.SET, (int64)(0.0 * length_time),
			             Gst.SeekType.NONE, -1);
			this.playSong();
		});
		sign_missing_plugins.connect(on_sign_missing_plugins); 
	}

	private void request_location(string? uri) {
		bool playing_buf = playing;
		playbin.set_state(State.READY);
		
		this.Uri = uri;

		if(playing_buf)
			playbin.set_state(State.PLAYING);
	}

	private void handle_eos_via_idle() {
		Idle.add ( () => { 
			global.handle_eos();
			return false;
		});
	}
	
	private void on_about_to_finish() {
		handle_eos_via_idle();
	}

	private void create_elements() {
		playbin = ElementFactory.make("playbin2", "playbin");
		taglist = null;
		var bus = new Gst.Bus ();
		bus = playbin.get_bus();
		bus.add_signal_watch();
		playbin.connect("swapped-object-signal::about-to-finish", on_about_to_finish, this, null);
		playbin.connect("swapped-object-signal::audio-tags-changed", on_audio_tags_changed, this, null);
		bus.message.connect(this.on_bus_message);
		bus.enable_sync_message_emission();
		bus.sync_message.connect(this.on_sync_message);
	}
	
	private void on_audio_tags_changed(int stream_number) {
		TagList tags = null;
		Signal.emit_by_name(playbin, "get-audio-tags", stream_number, ref tags);
		if(taglist == null && tags != null) {
			taglist = tags;
		}
		else if(tags != null){
			taglist.merge(tags, TagMergeMode.REPLACE);
		}
		
		if(this.taglist == null) 
			return;
		
		if(update_tags_source != 0)
			Source.remove(update_tags_source);
		
		update_tags_source = Idle.add(update_tags);
	}

	private bool update_tags() {
		if(taglist == null)
			return false;
		taglist.@foreach(foreachtag);
		return false;
	}

	private void on_bus_message(Gst.Message msg) {
		if((msg == null)||(msg.get_structure() == null)) 
			return;
		switch(msg.type) {
			case Gst.MessageType.STATE_CHANGED: {
				State newstate;
				State oldstate;
				
				if(msg.src != playbin) // only look for playbin state changes
					break;
					
				msg.parse_state_changed(out oldstate, out newstate, null);
				if((newstate == State.PLAYING)&&((oldstate == State.PAUSED)||(oldstate == State.READY))) {
					this.check_for_video();
				}
				//if((oldstate == State.PLAYING)&&((newstate == State.NULL)||(newstate == State.PAUSED)||(newstate == State.READY))) {
				//	print("stopped/paused message\n");
				//}
				break;
			}
			case Gst.MessageType.ELEMENT: {
				string type = null;
				string source;

				source = msg.src.get_name();
				type   = msg.get_structure().get_name();

				if(type == null)
					break;

				if(type == "missing-plugin") {
					print("missing plugins msg for element\n");
					print("src_name: %s; type_name: %s\n", source, type);
					missing_plugins.prepend(msg);
					return;
				}
				break;
			}
			case Gst.MessageType.ERROR: {
				Error err;
				string debug;
				msg.parse_error(out err, out debug);
				print("GstError: %s\n", err.message);
				//print("Debug: %s\n", debug);
				if(!is_missing_plugins_error(msg)) {
					print("Error is not missing plugin error\n");
					handle_eos_via_idle(); //this is used to go to the next track
				}
				break;
			}
			case Gst.MessageType.EOS: {
				handle_eos_via_idle();
				break;
			}
			default: break;
		}
	}

	private bool is_missing_plugins_error(Gst.Message msg) {
		//print("in is_missing_plugins_error?\n");
		bool retval = false;
		Error err = null;
		string debug;
		
		if(missing_plugins == null) {
			//print("messages is null and therefore no missing_plugin message\n");
			return false;
		}
		msg.parse_error(out err, out debug);
		
		//print("err.code: %d\n", (int)err.code);
		
		if(err is Gst.CoreError && ((int)(err.code) == (int)(Gst.StreamError.CODEC_NOT_FOUND))) {
			//print("is missing plgins error \n");
			sign_missing_plugins();
		} 
		return retval;
	}
	
	private void on_sign_missing_plugins() {
		//print("sign_missing_plugins!!!!\n");
		stop();
		return;
	}
	
	private void check_for_video() {
		if(check_for_video_source != 0)
			Source.remove(check_for_video_source);
		
		check_for_video_source = Idle.add( () => {
			int n_video = 0;
			playbin.get("n-video", out n_video);
			if(n_video > 0) {
				this.current_has_video = true;
			}
			else {
				this.current_has_video = false;
			}
			return false;
		});
	}

	/**
	 * For video synchronization and activation of video screen
	 */
	private void on_sync_message(Gst.Message msg) {
		if((msg == null)||(msg.get_structure() == null)) 
			return;
		string message_name = msg.get_structure().get_name();
		if(message_name=="prepare-xwindow-id") {
			var imagesink = (XOverlay)(msg.src);
			imagesink.set_property("force-aspect-ratio", true);
			imagesink.set_xwindow_id(Gdk.x11_drawable_get_xid(videoscreen.window));
		}
	}

	private void foreachtag(TagList list, string tag) {
		if(list == null)
			return;
		string val = null;
		//print("tag: %s\n", tag);
		switch(tag) {
		case "artist":
			if(list.get_string(tag, out val))
				if(val != global.current_artist) global.current_artist = val;
			break;
		case "album":
			if(list.get_string(tag, out val))
				if(val != global.current_album) global.current_album = val;
			break;
		case "title":
			if(list.get_string(tag, out val))
				if(val != global.current_title) global.current_title = val;
			break;
		case "location":
			if(list.get_string(tag, out val))
				if(val != global.current_location) global.current_location = val;
			break;
		case "genre":
			if(list.get_string(tag, out val))
				if(val != global.current_genre) global.current_genre = val;
			break;
		case "organization":
			if(list.get_string(tag, out val))
				if(val != global.current_organization) global.current_organization = val;
			break;
		default:
			break;
		}
	}

	private bool on_cyclic_send_song_position() {
		if(!is_stream) {
			Gst.Format fmt = Gst.Format.TIME;
			int64 pos, len;
			if((playbin.current_state == State.PLAYING)&&(playing == false)) {
				playing = true;
				paused  = false;
			}
			if((playbin.current_state == State.PAUSED)&&(paused == false)) {
				paused = true;
				playing = false;
			}
			if(seeking == false) {
				playbin.query_duration(ref fmt, out len);
				length_time = (int64)len;
				if(playing == false) return true;
				playbin.query_position(ref fmt, out pos);
				sign_song_position_changed((uint)(pos/1000000), (uint)(len/1000000));
			}
	//		print("current:%s \n",playbin.current_state.to_string());
		}
		return true;
	}

	public void play() {
		playbin.set_state(Gst.State.PLAYING);
		playing = true;
		paused = false;
		sign_playing();
	}

	public void pause() {
		playbin.set_state(State.PAUSED);
		playing = false;
		paused = true;
		sign_paused();
	}

	public void stop() {
		playbin.set_state(State.NULL); //READY
		playing = false;
		paused = false;
		sign_stopped();
	}

	// This is a pause-play action to take over the new uri for the playbin
	// It recovers the original state or can be forced to play
	public void playSong(bool force_play = false) {
		bool buf_playing = ((global.track_state == GlobalInfo.TrackState.PLAYING)||force_play);
		playbin.set_state(State.READY);
		if(buf_playing == true) {
			Idle.add( () => {
				play();
				return false;
			});
		}
		else {
			sign_paused();
		}
		playbin.volume = volume; // TODO: Volume should have a global representation
	}
}

