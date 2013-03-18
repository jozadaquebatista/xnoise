/* xnoise-gst-player.vala
 *
 * Copyright(C) 2009 - 2013 Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
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
 */

using Gst;
using Gst.PbUtils;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


// GstPlayFlags flags of playbin
[Flags]
private enum Gst.PlayFlag {
    VIDEO         =(1 << 0),
    AUDIO         =(1 << 1),
    TEXT          =(1 << 2),
    VIS           =(1 << 3),
    SOFT_VOLUME   =(1 << 4),
    NATIVE_AUDIO  =(1 << 5),
    NATIVE_VIDEO  =(1 << 6),
    DOWNLOAD      =(1 << 7),
    BUFFERING     =(1 << 8),
    DEINTERLACE   =(1 << 9)
}

public class Xnoise.GstPlayer : GLib.Object {
    private bool _current_has_video_track;
    private bool _current_has_subtitles;
    private bool _current_has_audiotracks;
    
    private uint cycle_time_source;
    private uint update_tags_source;
    private uint automatic_subtitles_source;
    
    private uint suburi_msg_id = 0;

    private TagList taglist_buffer = null;
    internal GstEqualizer equalizer;
    
    private enum PlaybinStreamType {
        NONE = 0,
        AUDIO,
        VIDEO,
        TEXT
    }
    
    private class TaglistWithStreamType {
        public TaglistWithStreamType(PlaybinStreamType _pst, TagList _tags) {
            this.pst = _pst; 
            this.tags = new TagList.empty();
            this.tags = this.tags.merge(_tags, TagMergeMode.REPLACE);
        }
        public PlaybinStreamType pst;
        public TagList tags;
    }

    private string? _uri = null;
    private int64 _length_nsecs;
    internal Xnoise.VideoScreen videoscreen;
    private AsyncQueue<TaglistWithStreamType?> new_tag_queue = new AsyncQueue<TaglistWithStreamType?>();
    private GLib.List<Gst.Message> missing_plugins = new GLib.List<Gst.Message>();
    private dynamic Element playbin;
    private Gst.Pipeline pipe;
    
    private dynamic Gst.Bus bus;
    private dynamic Element asink;
    private dynamic Element queue;
    private dynamic Element ac1;
    private dynamic Element ac2; 
    private dynamic Element preamp;
    private Pad pad;
     
    private dynamic Gst.Element tee;
    private dynamic Gst.Element abin;


    // Localized strings for display
    public string[]? available_subtitles   { get; private set; default = null; }
    public string[]? available_audiotracks { get; private set; default = null; }
    
    public bool current_has_video_track { // TODO: Determine this elsewhere
        get {
            return _current_has_video_track;
        }
    }

    public bool current_has_subtitles { 
        get {
            return _current_has_subtitles;
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
            }
        }
    }
    
    public double preamplification {
        get {
            double val = 0.0;
            preamp.get("volume", out val);
            return val;
        }
        set {
            if(value < 0.0) {
                preamp.set("volume", 0.0);
            }
            else if(value > 10.0) {
                preamp.set("volume", 10.0);
            }
            else {
                preamp.set("volume", value);
            }
        }
    }

    public bool playing           { get; set; }
    public bool paused            { get; set; }
    public bool seeking           { get; set; }
    public bool is_stream         { get; private set; default = false; }
    public bool buffering         { get; private set; default = false; }
    
    public int64 length_nsecs { 
        get {
            return _length_nsecs;
        } 
        set {
            _length_nsecs = value;
        }
    }

    public string? uri {
        get {
            return _uri;
        }
        set {
            is_stream = false; //reset
            _uri = value;
            if((value == EMPTYSTRING)||(value == null)) {
                playbin.set_state(State.NULL); //stop
                //print("uri = null or '' -> set to stop\n");
                playing = false;
                paused = false;
            }
            this._current_has_video_track = false;
            Idle.add(() => {
                videoscreen.trigger_expose();
                return false;
            }); 
            
            
            //reset
            taglist_buffer = null;
            available_subtitles = null;
            available_audiotracks = null;
            this.playbin.suburi = null;
            length_nsecs = 0;
            this.playbin.uri =(value == null ? EMPTYSTRING : value);
            // set_automatic_subtitles();
            if(value != null) {
                File file = File.new_for_commandline_arg(value);
                if(file.get_uri_scheme() in get_remote_schemes())
                    is_stream = true;
            }
            sign_position_changed(0, 0); //immediately reset song progressbar
        }
    }
    
    public string? suburi { 
        get { return playbin.suburi; }
        set {
            if(this.suburi == value)
                return;
            
            // check if suburi file name matches video file name
            File sf = File.new_for_uri(value);
            File uf = File.new_for_uri(this._uri);
            string sb = sf.get_basename();
            string ub = uf.get_basename();
            if(ub.contains("."))
                ub = ub.substring(0, ub.last_index_of("."));
            if(!sb.has_prefix(ub)) { // not matching, inform user
                //print("The subtitle name is not matching the video name! Not using subtitle file.\n");
                if(suburi_msg_id != 0) {
                    userinfo.popdown(suburi_msg_id);
                    suburi_msg_id = 0;
                }
                Timeout.add_seconds(1,() => {
                    this.suburi_msg_id = userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                         UserInfo.ContentClass.WARNING,
                                         _("The subtitle name is not matching the video name! Not using subtitle file."),
                                         false,
                                         12,
                                         null);
                    return false;
                });    
                return;
            }
            playbin.set_state(State.READY);
            playbin.suburi = value;
            // print("got suburi: %s\n", value);
            this.play();
        }
    }
    
    public int current_text { 
        get { return playbin.current_text; }
        set {
            Gst.PlayFlag flags =(Gst.PlayFlag)0;
            playbin.get("flags", out flags);
            if(value == -2) {
                flags &= ~Gst.PlayFlag.TEXT;
                playbin.set("flags", flags,
                            "current-text", -1
                            );
            }
            else {
                flags |= Gst.PlayFlag.TEXT;
                playbin.set("flags", flags,
                            "current-text", value
                            );
            }
        }
    }

    public int current_audio {
        get { return playbin.current_audio; }
        set { playbin.current_audio = value; }
    }

    public int current_video {
        get { return playbin.current_video; }
        set { playbin.current_video = value; }
    }

    public int n_text {
        get { return playbin.n_text; }
    }

    public int n_audio {
        get { return playbin.n_audio; }
    }

    public int n_video {
        get { return playbin.n_video; }
    }

    public int64 abs_position_microseconds {
        get {
            int64 pos;
            Gst.Format format = Gst.Format.TIME;
            if(!playbin.query_position(format, out pos))
                if(!playbin.query_position(format, out pos))
                    return -1;
            return pos / Gst.USECOND;
        }
    }

    public double position {
        get {
            print("gst position get\n");
            int64 pos;
            Gst.Format format = Gst.Format.TIME;
            if(!playbin.query_position(format, out pos))
                if(!playbin.query_position(format, out pos))
                    return 0.0;
            if(_length_nsecs == 0.0)
                return 0.0;
            return(double)pos/(double)_length_nsecs;
        }
        set {
            if(seeking == false) {
                if(value > 1.0)
                    value = 1.0;
                int64 len;
                Gst.Format fmt = Gst.Format.TIME;
                if(!playbin.query_duration(fmt, out len))
                    if(!playbin.query_duration(fmt, out len))
                        return;
                _length_nsecs =(this._uri == null || this._uri == EMPTYSTRING ? 0 : len);
                if(_length_nsecs > 0) {
                    playbin.seek_simple(Gst.Format.TIME,
                                        Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
                                        (int64)(value * _length_nsecs));
                }
            }
        }
    }

    public signal void sign_position_changed(int64 msecs, int64 ms_total);
    public signal void sign_playing();
    public signal void sign_paused();
    public signal void sign_stopped();
    
    public signal void sign_video_playing();
    public signal void sign_subtitles_available();
    public signal void sign_audiotracks_available();
    public signal void sign_found_embedded_image(string track_uri, string artist, string album);
    public signal void sign_buffering(int percent);


    public GstPlayer() {
        videoscreen = new Xnoise.VideoScreen(this);
        create_elements();
        missing_plugins_user_message = MissingPluginsUserInfo();
        cycle_time_source = GLib.Timeout.add_seconds(1, on_cyclic_send_song_position);
        update_tags_source = 0;
        automatic_subtitles_source = 0;

        global.uri_changed.connect((s,u) => {
            this.request_location(u);
        });

        global.player_state_changed.connect(() => {
            if(global.player_state == PlayerState.PLAYING)
                this.play();
            else if(global.player_state == PlayerState.PAUSED)
                this.pause();
            else if(global.player_state == PlayerState.STOPPED)
                this.stop();
        });
        
        global.sign_restart_song.connect(() => {
            playbin.seek_simple(Gst.Format.TIME,
                                Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
                                0);
            this.playSong();
        });
//        eq_active = !Params.get_bool_value("not_use_eq");
    }

    private Gdk.Pixbuf? extract_embedded_image(Gst.TagList taglist) {
        Gst.Sample sample2 = null;
        Gdk.PixbufLoader pbloader;
        Gdk.Pixbuf? pixbuf = null;
        Gst.Sample sample;
        Gst.MapInfo mapinfo;
        uint i = 0;
        for(;;i++) {
            string media_type;
            Gst.Structure cstruct;
            int imgtype;
            taglist.get_sample_index(Gst.Tags.IMAGE, i, out sample);
            if(sample == null)
                break;
            
            if(sample == null)
                continue;
            
            var caps = sample.get_caps();
            cstruct = caps.get_structure(0);
            media_type = cstruct.get_name();
            
            if(media_type == "text/uri-list")
                continue;
            
            cstruct.get_int("image-type", out imgtype); // get_enum doesn't work with vala
            //cstruct.get_enum("image-type", typeof(Gst.TagImageType), out imgtype);
            if(imgtype == 0) {      // UNDEFINED
                if(sample2 == null)
                    sample2 = sample;
            }
            else if(imgtype == 1) { //FRONT_COVER
                print("FRONT_COVER\n");
                sample2 = sample;
            }
        }
        if(sample2 == null)
            return null;
        
        pbloader = new Gdk.PixbufLoader();
        
        sample2.get_buffer().map (out mapinfo, MapFlags.READ);
        
        try {
            if(pbloader.write(mapinfo.data) == false);
        }
        catch(Error e) {
            try { pbloader.close(); } catch(Error e) {}
            return null;
        }
        pixbuf = pbloader.get_pixbuf();
        try { pbloader.close(); } catch(Error e) {}
        print("extracted image\n");
        return pixbuf;
    }

    private void request_location(string? xuri) {
        bool playing_buf = playing;
        playbin.set_state(State.READY);
        
        this.uri = xuri;
        
        if(playing_buf)
            playbin.set_state(State.PLAYING);
    }
    
    private void handle_eos_via_idle() {
        Idle.add(() => { 
            global.handle_eos();
            return false;
        });
    }
    
    public void set_subtitle_uri(string s_uri) {
        if(this._uri == null)
            return;
        if(!current_has_video_track)
            return;
        File f = File.new_for_uri(s_uri);
        this.suburi = f.get_uri();
    }

    private void create_elements() {
        taglist_buffer = null;
        pipe = new Gst.Pipeline("pipeline");
        
        playbin   = ElementFactory.make("playbin", null);
        assert(playbin != null);
        
        asink     = ElementFactory.make("autoaudiosink", null);
        if(asink == null) {
            print("autoaudiosink is not available. Maybe you are mising an installation of gstreamer1.0-plugins-good.\n");
        }
        assert(asink != null);
        
        ac1       = ElementFactory.make("audioconvert", null);
        if(ac1 == null) {
            print("audioconvert is not available. Maybe you are mising an installation of gstreamer1.0-plugins-base.\n");
        }
        assert(ac1 != null);
        
        ac2       = ElementFactory.make("audioconvert", null);
        if(ac2 == null) {
            print("audioconvert is not available. Maybe you are mising an installation of gstreamer1.0-plugins-base.\n");
        }
        assert(ac2 != null);
        
        preamp    = ElementFactory.make("volume", null);
        assert(preamp != null);
        
        tee       = ElementFactory.make("tee", null);
        assert(tee != null);
        
        queue     = ElementFactory.make("queue", null);
        assert(queue != null);
        
        abin = new Gst.Bin("audiobin");
        assert(abin != null);
        
        this.equalizer = new GstEqualizer();
        if(equalizer.eq != null && equalizer.available) {
            print("eq created ok\n");
            ((Gst.Bin)abin).add_many(
                preamp,
                equalizer.eq,
                ac1,
                ac2
            );
        }
        else {
            print("eq damaged!\n");
        }
        
        ((Gst.Bin)abin).add_many(
            tee,
            queue,
            asink
        );
        var tsink = tee.get_static_pad("sink");
        assert(tsink != null);
        var gp = new GhostPad("sink", tsink);
        abin.add_pad(gp);
        
        if(equalizer.eq == null || !equalizer.available) {
            print("eq not available\n");
            queue.link_many(asink);
        }
        else {
            queue.link_many(ac1, preamp, equalizer.eq, ac2, asink);
        }
        playbin.set("audio-sink", abin); 
        bus = playbin.get_bus();
        Gst.Pad sinkpad = queue.get_static_pad("sink");
        pad = tee.get_request_pad("src_%u");
        tee.set("alloc-pad", pad);
        pad.link(sinkpad);
        
        
        queue.link_many(
                ac1,
                preamp,
                equalizer.eq,
                ac2,
                asink
        );
        
        playbin.text_changed.connect(() => {
            //print("text_changed\n");
            Timeout.add_seconds(1,() => {
                //print("playbin2 got text-changed signal. number of texts = %d\n", playbin.n_text);
                available_subtitles = get_available_languages(PlaybinStreamType.TEXT);
                return false;
            });
            Idle.add(() => {
                int n_text = 0;
                n_text = playbin.n_text;
                if(n_text > 0) {
                    this._current_has_subtitles = true;
                    sign_subtitles_available();
                }
                else {
                    this._current_has_subtitles = false;
                }
                return false;
            });
        });
        
        playbin.audio_changed.connect(() => {
            //print("audio_changed\n");
            Timeout.add_seconds(1,() => {
                //print("playbin2 got audio-changed signal. number of audio = %d\n", playbin.n_audio);
                available_audiotracks = get_available_languages(PlaybinStreamType.AUDIO);
                return false;
            });
            Idle.add(() => {
                int n_audio = 0;
                n_audio = playbin.n_audio;
                if(n_audio > 0) { // TODO maybe more than 1 ?
                    this._current_has_audiotracks = true;
                    sign_audiotracks_available();
                }
                else {
                    this._current_has_audiotracks = false;
                }
                return false;
            });
        });
        
        playbin.video_changed.connect(() => {
            Idle.add(() => {
                int n_video = 0;
                n_video = playbin.n_video;
                if(n_video > 0) {
                    this._current_has_video_track = true;
                    sign_video_playing();
                }
                else {
                    this._current_has_video_track = false;
                    videoscreen.trigger_expose();
                }
                return false;
            });
        });
        
        playbin.audio_tags_changed.connect(on_audio_tags_changed);
        playbin.text_tags_changed.connect(on_text_tags_changed);
        playbin.video_tags_changed.connect(on_video_tags_changed);

        Gst.Bus bus;
        bus = playbin.get_bus();
        bus.set_flushing(true);
        bus.add_signal_watch();
        bus.message.connect(this.on_bus_message);
        bus.enable_sync_message_emission();
        bus.sync_message.connect(this.on_sync_message);
    }
    
    private bool tag_update_func() {
        TaglistWithStreamType? tlwst;
        while((tlwst = this.new_tag_queue.try_pop()) != null) {
            // merge with taglist_buffer. taglist_buffer is set to null as soon as new uri is set
            if(taglist_buffer == null) {
                taglist_buffer = new TagList.empty();
                taglist_buffer = taglist_buffer.merge(tlwst.tags, TagMergeMode.REPLACE);
            }
            else
                taglist_buffer = taglist_buffer.merge(tlwst.tags, TagMergeMode.REPLACE);
            taglist_buffer.@foreach(foreachtag);
        }
        lock(update_tags_source) {
            update_tags_source = 0;
        }
        return false;
    }

    private void update_tags_in_idle(TagList _tags, PlaybinStreamType _pst) {
        // box data for the async queue
        TaglistWithStreamType tlwst = new TaglistWithStreamType(_pst, _tags);
        
        this.new_tag_queue.push(tlwst); //push with locking
        
        lock(update_tags_source) {
            if(update_tags_source == 0)
                update_tags_source = Idle.add(tag_update_func);
        }
    }

    private void on_video_tags_changed(Gst.Element sender, int stream_number) {
        TagList tags = null;
        if(((int)playbin.current_video) != stream_number)
            return;
        Signal.emit_by_name(playbin, "get-video-tags", stream_number, ref tags);
        if(tags != null)
            update_tags_in_idle(tags, PlaybinStreamType.VIDEO);
    }

    private void on_audio_tags_changed(Gst.Element sender, int stream_number) {
        TagList tags = null;
        if(((int)playbin.current_audio) != stream_number)
            return;
        Signal.emit_by_name(playbin, "get-audio-tags", stream_number, ref tags);
        if(tags != null)
            update_tags_in_idle(tags, PlaybinStreamType.AUDIO);
    }

    private void on_text_tags_changed(Gst.Element sender, int stream_number) {
        TagList tags = null;
        if(((int)playbin.current_text) != stream_number)
            return;
        Signal.emit_by_name(playbin, "get-text-tags", stream_number, ref tags);
        if(tags != null)
            update_tags_in_idle(tags, PlaybinStreamType.TEXT);
    }

    private uint send_user_info_message(string message_string) {
            return userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                  UserInfo.ContentClass.INFO,
                                  message_string,
                                  false,
                                  5,
                                  null);
    }
    
    private uint send_user_error_message(string message_string) {
            return userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                  UserInfo.ContentClass.CRITICAL,
                                  message_string,
                                  false,
                                  20,
                                  null);
    }
    
    private void install_plugins_res_func(Gst.PbUtils.InstallPluginsReturn result) {
        //print("InstallPluginsReturn: %d\n",(int)result);
        if(missing_plugins_user_message.id != 0) {
            userinfo.popdown(missing_plugins_user_message.id);
        }
        switch(result) {
            case Gst.PbUtils.InstallPluginsReturn.SUCCESS:
            case Gst.PbUtils.InstallPluginsReturn.PARTIAL_SUCCESS:
                send_user_info_message("%s: %s".printf(_("Success on installing missing gstreamer plugin"), 
                                                       missing_plugins_user_message.info_text));
                break;
            case Gst.PbUtils.InstallPluginsReturn.USER_ABORT:
                send_user_error_message("%s: %s".printf(_("User aborted installation of missing gstreamer plugin"), 
                                                        missing_plugins_user_message.info_text));
                break;
            case Gst.PbUtils.InstallPluginsReturn.NOT_FOUND:
                send_user_error_message("%s: %s".printf(_("Gstreamer plugin not found in repositories"), 
                                                        missing_plugins_user_message.info_text));
                break;
            case Gst.PbUtils.InstallPluginsReturn.ERROR:
            case Gst.PbUtils.InstallPluginsReturn.CRASHED:
            default:
                send_user_error_message("%s: %s".printf(_("Critical error while installation of missing gstreamer plugin"),
                                                        missing_plugins_user_message.info_text));
                break;
        }
    }
    
    private MissingPluginsUserInfo missing_plugins_user_message;
    
    private struct MissingPluginsUserInfo {
        public uint id;
        public string info_text;
    }
    
    private void on_bus_message(Gst.Message msg) {
        //print("msg arrived %s\n", msg.type.to_string());
        if(msg == null) 
            return;
        switch(msg.type) {
            case Gst.MessageType.ELEMENT: {
                string type = null;
                string source;
                
                source = msg.src.get_name();
                type   = msg.get_structure().get_name();
                
                if(type == null)
                    break;
                
                if(type == "missing-plugin") {
                    //print("missing plugins msg for element\n");
                    //print("src_name: %s; type_name: %s\n", source, type);
                    missing_plugins.prepend(msg);
                    var install_context = new InstallPluginsContext();
                    string[] details = {};
                    details += Gst.PbUtils.missing_plugin_message_get_installer_detail(msg);
                    
                    Gst.PbUtils.InstallPluginsReturn retval = Gst.PbUtils.install_plugins_async(details, install_context, install_plugins_res_func);
                    
                    if(retval != Gst.PbUtils.InstallPluginsReturn.STARTED_OK) {
                        if(retval == Gst.PbUtils.InstallPluginsReturn.HELPER_MISSING) {
                            if(missing_plugins_user_message.id != 0) {
                                userinfo.popdown(missing_plugins_user_message.id);
                                missing_plugins_user_message = MissingPluginsUserInfo();
                            }
                            missing_plugins_user_message.info_text = Gst.PbUtils.missing_plugin_message_get_description(msg);
                            missing_plugins_user_message.id = send_user_error_message("%s: %s \n%s".printf(_("Missing gstreamer plugin"), 
                                                                         missing_plugins_user_message.info_text,
                                                                         _("Automatic missing codec installation not supported"))
                                                   );
                        }
                        else {
                            if(missing_plugins_user_message.id != 0) {
                                userinfo.popdown(missing_plugins_user_message.id);
                                missing_plugins_user_message = MissingPluginsUserInfo();
                            }
                            missing_plugins_user_message.info_text = Gst.PbUtils.missing_plugin_message_get_description(msg);
                            missing_plugins_user_message.id = send_user_error_message("%s: %s \n%s".printf(_("Missing gstreamer plugin"), 
                                                                         missing_plugins_user_message.info_text,
                                                                         _("Failed to start automatic gstreamer plugin installation."))
                                                   );
                        }
                        
                    }
                    else {
                        if(missing_plugins_user_message.id != 0) {
                            userinfo.popdown(missing_plugins_user_message.id);
                            missing_plugins_user_message = MissingPluginsUserInfo();
                        }
                        missing_plugins_user_message.info_text = Gst.PbUtils.missing_plugin_message_get_description(msg);
                        missing_plugins_user_message.id = send_user_info_message("%s: %s \n%s".printf(_("Missing gstreamer plugin"), 
                                                                     missing_plugins_user_message.info_text,
                                                                     _("Trying to install missing gstreamer plugin"))
                                               );
                    }
                    stop();
                    return;
                }
                break;
            }
            case Gst.MessageType.ERROR: {
                Error err;
                string debug;
                msg.parse_error(out err, out debug);
                print("GstError parsed: %s\n", err.message);
                //print("Debug: %s\n", debug);
                if(!is_missing_plugins_error(msg)) {
                    if(err.message != "Cancelled") {
                        send_user_error_message("GstError parsed: %s".printf(err.message));
                        stop();
                    }
                }
                break;
            }
            case Gst.MessageType.STREAM_STATUS: {
                //Gst.StreamStatusType sst;
                //unowned Gst.Element owner;
                //msg.parse_stream_status(out sst, out owner);
                //print("GstStreamStatus parsed: %s from %s\n", sst.to_string(), msg.src.get_name());
                break;
            }
            case Gst.MessageType.EOS: {
                handle_eos_via_idle();
                print("EOS\n");
                break;
            }
            default: break;
        }
    }

    private bool is_missing_plugins_error(Gst.Message msg) {
        //print("in is_missing_plugins_error?\n");
        bool retval = false;
        //TODO !!!
        GLib.Error err = null;
        string debug;
        
        if(missing_plugins == null) {
            //print("messages is null and therefore no missing_plugin message\n");
            return false;
        }
        msg.parse_error(out err, out debug);
        
        //print("err.code: %d\n",(int)err.code);
        
        if(err is Gst.StreamError.CODEC_NOT_FOUND) {//.matches(Gst.StreamError.quark(), (int)Gst.StreamError.CODEC_NOT_FOUND)) { //err.domain == Gst.StreamError.quark() && err.code == Gst.StreamError.CODEC_NOT_FOUND) {
            print("...is missing plgins error \n");
            Idle.add(() => {
                userinfo.popup(UserInfo.RemovalType.CLOSE_BUTTON,
                               UserInfo.ContentClass.WARNING,
                               "Missing plugins error",
                               true,
                               5,
                               null);
                return false;
            });
            print("sign_missing_plugins!!!!\n");
            stop();
        }
        return retval;
    }
    
    // helper function of get_available_languages()
    private string? extract_language(ref TagList? tags, string substitute_prefix, int stream_number = 1) {
        string? result = null;
        if(tags != null) {
            string language_code = null;
            tags.get_string(Gst.Tags.LANGUAGE_CODE, out language_code);
            if(language_code != null) {
                result = "%s%d: %s".printf(substitute_prefix, stream_number, language_code);
            }
            else {
                result = "%s%d".printf(substitute_prefix, stream_number);
            }
        }
        else {
            result = null; // "%s%d".printf(substitute_prefix, stream_number);
        }
        return(owned)result;
    }
    
    private string[]? get_available_languages(PlaybinStreamType selected) {
        //print("playbin.n_audio: %d    playbin.n_text: %d\n",(int)playbin.n_audio,(int)playbin.n_text);
        string[]? result = null;
        TagList? tags = null;
        switch(selected) {
            case PlaybinStreamType.TEXT: {
                if(((int)playbin.n_text) == 0)
                    return null;
                
                for(int i = 0; i <((int)playbin.n_text); i++) {
                    Signal.emit_by_name(playbin, "get-text-tags", i, ref tags);
                    string? buf = extract_language(ref tags, _("Subtitle #"), i + 1);
                    if(buf != null)
                        result += buf;
                }
                break;
            }
            case PlaybinStreamType.AUDIO: {
                if(((int)playbin.n_audio) == 0)
                    return null;
                
                for(int i = 0; i <((int)playbin.n_audio); i++) {
                    Signal.emit_by_name(playbin, "get-audio-tags", i, ref tags);
                    string? buf = extract_language(ref tags, _("Audio Track #"), i + 1);
                    if(buf != null)
                        result += buf; //extract_language(ref tags, _("Audio Track #"), i + 1);
                }
                break;
            }
            default: {
                print("Invalid selection %s\n", selected.to_string());
                return null;
            }
        }
        return result;
    }

    /**
     * For video synchronization and activation of video screen
     */
    private void on_sync_message(Gst.Message msg) {
        if((msg == null)||(msg.get_structure() == null)) 
            return;
        if(!Gst.Video.is_video_overlay_prepare_window_handle_message(msg))
            return;
        var imagesink =(Gst.Video.Overlay)(msg.src);
        imagesink.set_property("force-aspect-ratio", true);
        imagesink.set_window_handle((uint*)(Gdk.X11Window.get_xid(videoscreen.get_window())));
    }

    private void foreachtag(TagList list, string tag) {
        string? val = null;
        //print("tag: %s\n", tag);
        switch(tag) {
            case Gst.Tags.ARTIST:
                if(list.get_string(tag, out val))
                    if(val != global.current_artist) global.current_artist = remove_linebreaks(val);
                break;
            case Gst.Tags.ALBUM:
                if(list.get_string(tag, out val))
                    if(val != global.current_album) global.current_album = remove_linebreaks(val);
                break;
            case Gst.Tags.ALBUM_ARTIST:
                if(list.get_string(tag, out val))
                    if(val != global.current_albumartist) global.current_albumartist = remove_linebreaks(val);
                break;
            case Gst.Tags.TITLE:
                if(list.get_string(tag, out val))
                    if(val != global.current_title) global.current_title = remove_linebreaks(val);
                break;
            case Gst.Tags.LOCATION:
                if(list.get_string(tag, out val))
                    if(val != global.current_location) global.current_location = remove_linebreaks(val);
                break;
            case Gst.Tags.GENRE:
                if(list.get_string(tag, out val))
                    if(val != global.current_genre) global.current_genre = remove_linebreaks(val);
                break;
            case Gst.Tags.ORGANIZATION:
                if(list.get_string(tag, out val))
                    if(val != global.current_organization) global.current_organization = remove_linebreaks(val);
                break;
            case Gst.Tags.IMAGE:
                if(imarge_src != 0)
                    Source.remove(imarge_src);
                imarge_src = Timeout.add(500,() => { // TODO: move to io worker
                    string ar = null;
                    string al = null;
                    if(taglist_buffer == null)
                        return false;
                    taglist_buffer.get_string(Gst.Tags.ARTIST, out ar);
                    taglist_buffer.get_string(Gst.Tags.ALBUM, out al);
                    Gdk.Pixbuf pix = extract_embedded_image(taglist_buffer);
                    if(pix != null) {
                        File? pf2 = null;
                        File? pf = get_albumimage_for_artistalbum(ar, al, "embedded");
                        if(pf == null) {
                            print("could not save embedded image\n");
                            imarge_src = 0;
                            return false;
                        }
                        if(!pf.query_exists(null)) {
                            try {
                                File parentpath = pf.get_parent();
                                if(!parentpath.query_exists(null))
                                    parentpath.make_directory_with_parents(null);
                                pix.save(pf.get_path(), "jpeg");
                                pf2 =
                                    File.new_for_path(pf.get_path().replace("_embedded", "_extralarge"));
                                if(!pf2.query_exists(null)) {
                                    pix.save(pf2.get_path(), "jpeg");
                                }
                            }
                            catch(Error e) {
                                print("%s\n", e.message);
                                imarge_src = 0;
                                return false;
                            }
                        }
                        sign_found_embedded_image(this.uri, ar, al);
                        Idle.add( () => {
                            if(pf2 != null) 
                                global.sign_album_image_fetched(ar, al, pf2.get_path());
                            return false;
                        });
                    }
                    imarge_src = 0;
                    return false;
                });
                break;
            default: break;
        }
    }

    private uint imarge_src = 0;
    
    private bool on_cyclic_send_song_position() {
        //print("current:%s \n",playbin.current_state.to_string());
        if(global.player_state == PlayerState.PLAYING && playbin.current_state != State.PLAYING)
            playbin.set_state(Gst.State.PLAYING);
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
                playbin.query_duration(fmt, out len);
                length_nsecs = (this._uri == null || this._uri == EMPTYSTRING ? 0 : len);
                if(playing == false) return true;
                if(!playbin.query_position(fmt, out pos))
                    return true;
                pos /= Gst.MSECOND;
                len /= Gst.MSECOND;
                sign_position_changed(pos, len);
            }
        }
        //print("flags: %d\n",(int)playbin.flags);
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
        global.stop();
        tlm.reset_state(); // dirty
        sign_stopped();
    }

    // This is a pause-play action to take over the new uri for the playbin
    // It recovers the original state or can be forced to play
    public void playSong(bool force_play = false) {
        bool buf_playing =((global.player_state == PlayerState.PLAYING)||force_play);
        playbin.set_state(State.READY);
        if(buf_playing == true) {
            Idle.add(() => {
                play();
                return false;
            });
        }
        else {
            sign_paused();
        }
        playbin.volume = volume; // TODO: Volume should have a global representation
    }
    
    private uint pos_changed_source = 0;
    public void request_micro_time_offset(int64 micro_seconds) {
        if(playing == false && paused == false)
            return;
        if(!is_stream) {
            if(seeking == false) {
                Gst.Format fmt = Gst.Format.TIME;
                int64 pos, new_pos;
                if(!playbin.query_position(fmt, out pos))
                    return;
                new_pos = pos + (micro_seconds * Gst.USECOND);
                //print("%lli %lli %lli %lli\n", pos, new_pos, _length_nsecs,(int64)((int64)seconds *(int64)1000000000));
            
                if(new_pos > _length_nsecs) new_pos = _length_nsecs;
                if(new_pos < 0)            new_pos = 0;
                
                playbin.seek_simple(Gst.Format.TIME,
                                    Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
                                    new_pos);
                new_pos /= Gst.MSECOND;
                if(pos_changed_source != 0)
                    Source.remove(pos_changed_source);
                pos_changed_source = Idle.add(() => {
                    pos_changed_source = 0;
                    sign_position_changed(new_pos, (_length_nsecs/Gst.MSECOND));
                    return false;
                });
            }
        }
    }

    public void request_time_offset(int seconds) {
        if(playing == false && paused == false)
            return;
        if(!is_stream) {
            if(seeking == false) {
                Gst.Format fmt = Gst.Format.TIME;
                int64 pos, new_pos;
                if(!playbin.query_position(fmt, out pos))
                    return;
                new_pos = pos + (seconds * Gst.SECOND);
                //print("%lli %lli %lli %lli\n", pos, new_pos, _length_nsecs,(int64)((int64)seconds *(int64)1000000000));
            
                if(new_pos > _length_nsecs) new_pos = _length_nsecs;
                if(new_pos < 0)            new_pos = 0;
                
                playbin.seek_simple(Gst.Format.TIME,
                                    Gst.SeekFlags.FLUSH|Gst.SeekFlags.ACCURATE,
                                    new_pos);
                new_pos /= Gst.MSECOND;
                if(pos_changed_source != 0)
                    Source.remove(pos_changed_source);
                pos_changed_source = Idle.add(() => {
                    pos_changed_source = 0;
                    sign_position_changed(new_pos, (_length_nsecs/Gst.MSECOND));
                    return false;
                });
            }
        }
    }
}

