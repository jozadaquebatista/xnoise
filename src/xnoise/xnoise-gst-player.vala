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
	private uint timeout;
	private string? _Uri = null;
	private TagList _taglist;
	public VideoScreen videoscreen;
	public dynamic Element playbin2;

	public bool current_has_video { // TODO: Determine this elsewhere
		get {
			return _current_has_video;
		}
		set {
			_current_has_video = value;
			if(!_current_has_video) {
				videoscreen.trigger_expose();
			}
		}
	}

	public double volume {
		get {
			double val;
			this.playbin2.get("volume", out val);
			return val;
		}
		set {
			double val;
			this.playbin2.get("volume", out val);
			if(val!=value) {
				this.playbin2.set("volume", value);
				sign_volume_changed(value);
			}
		}
	}

	public bool playing           { get; set; }
	public bool paused            { get; set; }
	public bool seeking           { get; set; } //TODO
	public int64 length_time      { get; set; }
	public bool is_stream         { get; private set; default = false; }
	public string currentartist   { get; private set; }
	public string currentalbum    { get; private set; }
	public string currenttitle    { get; private set; }
	public string currentgenre    { get; private set; }
	public string currentorg      { get; private set; }
	public string currentlocation { get; private set; }

	public TagList taglist {
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
			print("NEW Uri: %s\n", value);
			is_stream = false; //reset
			_Uri = value;
			if((value=="")||(value==null)) {
				playbin2.set_state(State.NULL); //stop
				playing = false;
				paused = false;
			}
			this.current_has_video = false;
			taglist = null;  //reset
			length_time = 0; //reset
			if(value!=null) {
				this.playbin2.uri = value;
				File file = File.new_for_commandline_arg(value);

				// TODO: Maybe there is a better way to check this?
				if(file.get_uri_scheme() == "http") 
					is_stream = true;
			}
			sign_song_position_changed((uint)0, (uint)0); //immediately reset song progressbar
		}
	}

	public double gst_position {
		set {
			if(seeking == false) {
				playbin2.seek(1.0, Gst.Format.TIME,
				             Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
				             Gst.SeekType.SET, (int64)(value * length_time),
							 Gst.SeekType.NONE, -1);
			}
		}
	}

	public signal void sign_song_position_changed(uint msecs, uint ms_total);
	public signal void sign_playing();
	public signal void sign_paused();
	public signal void sign_stopped();
	public signal void sign_video_playing();
	public signal void sign_tag_changed(ref string newuri, string? tagname, string? tagvalue);
//	public signal void sign_tag_changed(string newuri);
	public signal void sign_uri_changed(string newuri);
	public signal void sign_volume_changed(double volume);

	public GstPlayer() {
		videoscreen = new VideoScreen();
		create_elements();
		timeout = GLib.Timeout.add_seconds(1, on_cyclic_send_song_position); //once per second is enough?
		this.notify.connect( (s, p) => {
			switch(p.name) {
				case "Uri": {
					this._currentartist   = "unknown artist";
					this._currentalbum    = "unknown album";
					this._currenttitle    = "unknown title";
					this._currentlocation = "unknown location";
					this._currentgenre    = "unknown genre";
					this._currentorg      = "unknown organization";
					
					this.sign_uri_changed(this.Uri);
					this.sign_tag_changed(ref this._Uri, null, null);
					
					break;
				}
				case "currentartist": {
					this.sign_tag_changed(ref this._Uri, "artist", this._currentartist);
					break;
				}
				case "currentalbum": {
					this.sign_tag_changed(ref this._Uri, "album", this._currentalbum);
					break;
				}
				case "currenttitle": {
					this.sign_tag_changed(ref this._Uri, "title", this._currenttitle);
					break;
				}
				case "currentlocation": {
					this.sign_tag_changed(ref this._Uri, "location", this._currentlocation);
					break;
				}
				case "currentgenre": {
					this.sign_tag_changed(ref this._Uri, "genre", this._currentgenre);
					break;
				}
				case "currentorg": {
					this.sign_tag_changed(ref this._Uri, "organization", this._currentorg);
					break;
				}
				case "taglist": {
					if(this.taglist == null) return;
					taglist.foreach(foreachtag);
					break;
				}
				default: break;
			}
		});

		global.current_uri_changed.connect( () => {
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
	}

	public void request_location(string? uri) {
		bool playing_buf = playing;
		playbin2.set_state(State.READY);
		
		this.Uri = uri;

		if(playing_buf)
			playbin2.set_state(State.PLAYING);
	}

	public signal void sign_about_to_finish();

	private void on_about_to_finish() {
		Idle.add ( () => { 
			print("about to finish\n");
			this.sign_about_to_finish ();
			global.handle_eos();
			return false;
		});
	}

	private void create_elements() {
		playbin2 = ElementFactory.make("playbin2", "playbin2");
        taglist = null;
		var bus = new Bus ();
		bus = playbin2.get_bus();
		bus.add_signal_watch();
		playbin2.connect("swapped-object-signal::about-to-finish", on_about_to_finish, this, null);
		bus.message.connect(this.on_bus_message);
		bus.enable_sync_message_emission();
		bus.sync_message.connect(this.on_sync_message);
	}

	private void on_bus_message(Gst.Message msg) {
		switch(msg.type) {
			case Gst.MessageType.STATE_CHANGED: {
				State newstate;
				State oldstate;
				msg.parse_state_changed(out oldstate, out newstate, null);
				if((newstate==State.PLAYING)&&((oldstate==State.PAUSED)||(oldstate==State.READY))) {
					this.check_for_video();
		        }
				break;
			}
			case Gst.MessageType.ERROR: {
				Error err;
				string debug;
				msg.parse_error(out err, out debug);
				stdout.printf("Error: %s\n", err.message);
//				global.handle_eos(); //this is used to go to the next track
				break;
			}
//			case Gst.MessageType.EOS: {
//				global.handle_eos();
//				break;
//			}
			case Gst.MessageType.TAG: {
				print("message tag\n");
				TagList tag_list;
				msg.parse_tag(out tag_list);
				if(taglist == null && tag_list != null) {
					taglist = tag_list;
				}
				else {
					taglist.merge(tag_list, TagMergeMode.REPLACE);
				}
				break;
			}
			default: break;
		}
	}

	private void check_for_video() {
		int n_video;
		playbin2.get("n-video", out n_video);
		if(n_video > 0) {
			this.current_has_video = true;
		}
		else {
			this.current_has_video = false;
		}
	}

	/**
	 * For video synchronization and activation of video screen
	 */
	private void on_sync_message(Gst.Message msg) {
		if(msg.structure==null) return;
		string message_name = msg.structure.get_name();
		if(message_name=="prepare-xwindow-id") {
			if(msg == null) return;
			var imagesink = (XOverlay)msg.src;
			imagesink.set_property("force-aspect-ratio", true);
			imagesink.set_xwindow_id(Gdk.x11_drawable_get_xid(videoscreen.window));
		}
	}

	private void foreachtag(TagList list, string tag) {
		string val = null;
		//print("tag: %s\n", tag);
		switch (tag) {
		case "artist":
			if(list.get_string(tag, out val))
				if(val!=this.currentartist) this.currentartist = val;
			break;
		case "album":
			if(list.get_string(tag, out val))
				if(val!=this.currentalbum) this.currentalbum = val;
			break;
		case "title":
			if(list.get_string(tag, out val))
				if(val!=this.currenttitle) this.currenttitle = val;
			break;
		case "location":
			if(list.get_string(tag, out val))
				if(val!=this.currentlocation) this.currentlocation = val;
			break;
		case "genre":
			if(list.get_string(tag, out val))
				if(val!=this.currentgenre) this.currentgenre = val;
			break;
		case "organization":
			if(list.get_string(tag, out val))
				if(val!=this.currentorg) this.currentorg = val;
			break;
		default:
			break;
		}
	}

	private bool on_cyclic_send_song_position() {
		if(!is_stream) {
			Gst.Format fmt = Gst.Format.TIME;
			int64 pos, len;
			if((playbin2.current_state == State.PLAYING)&&(playing == false)) {
				playing = true;
				paused  = false;
			}
			if((playbin2.current_state == State.PAUSED)&&(paused == false)) {
				paused = true;
				playing = false;
			}
			if(seeking == false) {
				playbin2.query_duration(ref fmt, out len);
				length_time = (int64)len;
				if(playing == false) return true;
				playbin2.query_position(ref fmt, out pos);
				sign_song_position_changed((uint)(pos/1000000), (uint)(len/1000000));
			}
	//		print("current:%s \n",playbin2.current_state.to_string());
		}
		return true;
	}

	private void wait() {
		State stateOld, stateNew;
		playbin2.get_state(out stateOld, out stateNew, (Gst.ClockTime)50000000);
	}

	public void play() {
		playbin2.set_state(Gst.State.PLAYING);
		wait();
		playing = true;
		paused = false;
		sign_playing();
	}

	public void pause() {
		playbin2.set_state(State.PAUSED);
		wait();
		playing = false;
		paused = true;
		sign_paused();
	}

	public void stop() {
		playbin2.set_state(State.NULL); //READY
		print("gst stop\n");
//		wait();
		playing = false;
		paused = false;
		sign_stopped();
	}

	// This is a pause-play action to take over the new uri for the playbin2
	// It recovers the original state orcan be forces to play
	public void playSong(bool force_play = false) {
		bool buf_playing = ((global.track_state == GlobalInfo.TrackState.PLAYING)||force_play);
		playbin2.set_state(State.READY);
		if(buf_playing == true) {
			Idle.add( () => {
				play();
				return false;
			});
		}
		else {
			sign_paused();
		}
		playbin2.volume = volume; // TODO: Volume should have a global representation
	}
}

