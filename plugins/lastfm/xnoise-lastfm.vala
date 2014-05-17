/* xnoise-mpris.vala
 *
 * Copyright (C) 2011-2012 Jörn Magens
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
 * Jörn Magens
 */

using Gtk;
using Lastfm;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;
using Xnoise.PluginModule;


public class Xnoise.Lfm : GLib.Object, IPlugin, IAlbumCoverImageProvider {
    public Main xn { get; set; }
    private unowned PluginModule.Container _owner;
    private Session session;
    private uint scrobble_source = 0;
    private uint now_play_source = 0;
    private int WAIT_TIME_BEFORE_SCROBBLE = 25;
    private int WAIT_TIME_BEFORE_NOW_PLAYING = 5;
    
    private ulong c = 0;
    private ulong d = 0;
    
    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }
    
    public string name { get { return "lastfm"; } }
    
    public signal void login_state_change();
    
    public bool init() {
        owner.sign_deactivated.connect(clean_up);
        
        session = new Lastfm.Session(
           Lastfm.Session.AuthenticationType.MOBILE,   // session authentication type
           "a39db9ab0d1fb9a18fabab96e20b0a34",         // xnoise api_key for noncomercial use
           "55993a9f95470890c6806271085159a3",         // secret
           null//"de"                                  // language TODO
        );
        c = session.notify["logged-in"].connect( () => {
            Idle.add( () => {
                login_state_change();
                return false;
            });
        });
        d = session.login_successful.connect( (sender, un) => {
            print("Lastfm plugin logged in %s successfully\n", un); // TODO: real feedback needed
        });
        string username = Xnoise.Params.get_string_value("lfm_user");
        string password = Xnoise.Params.get_string_value("lfm_pass");
        if(username != EMPTYSTRING && password != EMPTYSTRING)
            this.login(username, password);
        
        global.notify["current-title"].connect(on_current_track_changed);
        global.notify["current-artist"].connect(on_current_track_changed);
        global.uri_changed.connect(on_current_uri_changed);
        global.player_in_shutdown.connect( () => { clean_up(); });
        return true;
    }
    
    public void uninit() {
        clean_up();
    }

    private void clean_up() {
        if(session != null) {
            session.abort();
            if(c > 0)
                session.disconnect(c);
            if(d > 0)
                session.disconnect(d);
            session = null;
        }
        scrobble_track = null;
        now_play_track = null;
    }
    
    ~Lfm() {
    }

    public Gtk.Widget? get_settings_widget() {
        var w = new LfmWidget(this);
        return w;
    }

    public bool has_settings_widget() {
        return true;
    }
    
    public void login(string username, string password) {
        Idle.add( () => {
            if(!GlobalAccess.main_cancellable.is_cancelled())
                session.login(username, password);
            return false;
        });
    }
    
    public bool logged_in() {
        return this.session.logged_in;
    }
    
    private Track scrobble_track;
    private Track now_play_track;
    
    private struct ScrobbleData {
        public string? uri;
        public string? artist;
        public string? album;
        public string? title;
        public int64 playtime;
    }
    
    private ScrobbleData sd_last;
    
    private void on_current_uri_changed(GLib.Object sender, string? p) {
        //scrobble
        if(sd_last.title != null && sd_last.artist != null) {
            if(session == null || !session.logged_in)
                return;
            if(scrobble_source != 0)
                Source.remove(scrobble_source);
            scrobble_source = Timeout.add(500, () => {
                var dt = new DateTime.now_utc();
                int64 pt = dt.to_unix();
                if((pt - sd_last.playtime) < WAIT_TIME_BEFORE_SCROBBLE)
                    return false;
                // Use session's 'factory method to get Track
                scrobble_track = session.factory_make_track(sd_last.artist, sd_last.album, sd_last.title);
                // SCROBBLE TRACK
                scrobble_track.scrobble(sd_last.playtime);
                sd_last.artist = sd_last.album = sd_last.title = sd_last.uri = null;
                sd_last.playtime = 0;
                scrobble_source = 0;
                return false;
            });
        }
    }
    
    private void on_current_track_changed(GLib.Object sender, ParamSpec p) {
        if(global.current_title != null && global.current_artist != null) {
            if(session == null || !session.logged_in)
                return;
            //updateNowPlaying
            if(now_play_source != 0) 
                Source.remove(now_play_source);
            now_play_source = Timeout.add_seconds(WAIT_TIME_BEFORE_NOW_PLAYING, () => {
                // Use session's 'factory method to get Track
                if(global.current_title == null || global.current_artist == null) {
                    now_play_source = 0;
                    return false;
                }
                now_play_track = session.factory_make_track(global.current_artist, global.current_album, global.current_title);
                sd_last = ScrobbleData();
                sd_last.uri    = global.current_uri;
                sd_last.artist = global.current_artist;
                sd_last.album  = global.current_album;
                sd_last.title  = global.current_title;
                var dt = new DateTime.now_utc();
                sd_last.playtime = dt.to_unix();
                // UPDATE NOW PLAYING TRACK
                now_play_track.updateNowPlaying();
                now_play_source = 0;
                return false;
            });
        }
    }
    
    public Xnoise.IAlbumCoverImage from_tags(AlbumImageLoader loader, string artist, string album) {
        return new LastFmCovers(loader, artist, album, this.session);
    }
}



/**
 * The LastFmCovers class tries to find cover images on 
 * lastFm.
 * The images are downloaded to a local folder below ~/.xnoise
 * The download folder is returned via a signal together with
 * the artist name and the album name for identification.
 * 
 */
public class Xnoise.LastFmCovers : GLib.Object, IAlbumCoverImage {

    private const int SECONDS_FOR_TIMEOUT = 12;
    
    private string artist;
    private string album;
    private File f = null;
//    private string image_path;
    private string[] sizes;
    private File[] image_sources;
    private uint timeout;
    private bool timeout_done;
    private unowned Lastfm.Session session;
    private Lastfm.Album alb;
    private ulong sign_no;
    private unowned AlbumImageLoader loader;
    
    public LastFmCovers(AlbumImageLoader loader, string _artist, string _album, Lastfm.Session session) {
        this.loader = loader;
        this.artist = _artist;
        this.album  = _album;
        this.session = session;
        
        image_sources = {};
        sizes = {"medium", "extralarge"}; //Two are enough
        timeout = 0;
        timeout_done = false;
        alb = this.session.factory_make_album(artist, album);
        sign_no = alb.received_info.connect( (sender, al) => {
            print("got album info: %s , %s\n", sender.artist_name, al);
            alb.disconnect(sign_no);
            sign_no = 0;
            //print("image extralarge: %s\n", sender.image_uris.lookup("extralarge"));
            string default_size = "medium";
            string uri_image;
            foreach(string s in sizes) {
                f = get_albumimage_for_artistalbum(artist, album, s);
                if(default_size == s)
                    uri_image = f.get_path();
                
//                string pth = EMPTYSTRING;
                File f_path = f.get_parent();
                if(!f_path.query_exists(null)) {
                    try {
                        f_path.make_directory_with_parents(null);
                    }
                    catch(GLib.Error e) {
                        print("Error with create image directory: %s\npath: %s", e.message, f_path.get_path());
                        remove_timeout();
                        this.unref();
                        return;
                    }
                }
                
                if(!f.query_exists(null)) {
                    var remote_file = File.new_for_uri(sender.image_uris.lookup(s));
                    image_sources += remote_file;
                }
                else {
                    //print("Local file already exists\n");
                    continue; //Local file exists
                }
            }
            var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_covers_job, Worker.Priority.HIGH);
            job.set_arg("reply_artist", sender.reply_artist.down());
            job.set_arg("reply_album",  sender.reply_album.down());
            io_worker.push_job(job);
        });
    }
    
    ~LastFmCovers() {
        if(timeout != 0)
            Source.remove(timeout);
        if(sign_no != 0)
            alb.disconnect(sign_no);
        alb = null;
    }

    private void remove_timeout() {
        if(timeout != 0)
            Source.remove(timeout);
    }
    
    public void find_image() {
        //print("find_lastfm_image to %s - %s\n", artist, album);
        if((artist==UNKNOWN_ARTIST)||
           (album==UNKNOWN_ALBUM)) {
            Idle.add(() => {
                if(loader != null)
                    loader.on_image_fetched(artist, album, EMPTYSTRING);
                this.unref();
                return false;
            });
            return;
        }
        
        alb.get_info(); // no login required
        //Add timeout for response
        timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
    }
    
    private bool timeout_elapsed() {
        this.timeout_done = true;
        this.unref();
        timeout = 0;
        return false;
    }
    

    private bool copy_covers_job(Worker.Job job) {
        string? _reply_artist = job.get_arg("reply_artist") as string;
        string? _reply_album  = job.get_arg("reply_album")  as string;
        File destination;
        bool buf = false;
        string default_path = EMPTYSTRING;
        int i = 0;
        //string reply_artist = _reply_artist;
        //string reply_album = _reply_album;

        if((prepare_for_comparison(artist) != prepare_for_comparison(_reply_artist))||
           (prepare_for_comparison(check_album_name(artist, album))  != 
                prepare_for_comparison(check_album_name(_reply_artist, _reply_album)))) 
            return false;
        
        foreach(File f in image_sources) {
            var s = sizes[i];
            destination = get_albumimage_for_artistalbum(artist, album, s);
            try {
                if(f.query_exists(null)) { //remote file exist
                    
                    buf = f.copy(destination, FileCopyFlags.OVERWRITE, null, null);
                }
                else {
                    continue;
                }
                if(sizes[i] == "medium")
                    default_path = destination.get_path();
                i++;
            }
            catch(GLib.Error e) {
                print("Error: %s\n", e.message);
                i++;
                continue;
            }
        }
        Idle.add( () => {
            // signal finish with artist, album in order to identify the sent image
            if(loader != null)
                loader.on_image_fetched(artist, album, default_path);
            remove_timeout();
            
            if(!this.timeout_done) {
                this.unref(); // After this point LastFmCovers downloader can safely be removed
            }
            return false;
        });
        return false;
    }
}


public class Xnoise.LfmWidget: Gtk.Box {
    private unowned Main xn;
    private unowned Xnoise.Lfm lfm;
    private Entry user_entry;
    private Entry pass_entry;
    private CheckButton use_scrobble_check;
    private Label feedback_label;
    private Button b;
    private string username_last;
    private string password_last;
    
    
    public LfmWidget(Xnoise.Lfm lfm) {
        GLib.Object(orientation:Gtk.Orientation.VERTICAL, spacing:10);
        this.lfm = lfm;
        this.xn = Main.instance;
        setup_widgets();
        
        this.lfm.login_state_change.connect(do_user_feedback);
        this.set_vexpand(true);
        this.set_hexpand(true);
        user_entry.text = Xnoise.Params.get_string_value("lfm_user");
        pass_entry.text = Xnoise.Params.get_string_value("lfm_pass");
        use_scrobble_check.set_active(Xnoise.Params.get_int_value("lfm_use_scrobble") != 0);
        
        use_scrobble_check.toggled.connect(on_use_scrobble_toggled);
        b.clicked.connect(on_entry_changed);
    }

    //show if user is logged in
    private void do_user_feedback() {
        //print("do_user_feedback\n");
        if(this.lfm.logged_in()) {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
            feedback_label.set_use_markup(true);
        }
        else {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
            feedback_label.set_use_markup(true);
        }
    }
    
    private void on_use_scrobble_toggled(ToggleButton sender) {
        if(sender.get_active())
            Xnoise.Params.set_int_value("lfm_use_scrobble", 1);
        else
            Xnoise.Params.set_int_value("lfm_use_scrobble", 0);
    }
    
    private void on_entry_changed() {
        //print("take over entry\n");
        string username = EMPTYSTRING, password = EMPTYSTRING;
        if(user_entry.text != null)
            username = user_entry.text.strip();
        if(pass_entry.text != null)
            password = pass_entry.text.strip();
        if(username_last == user_entry.text.strip() && password_last == pass_entry.text.strip())
            return; // no need to spam!
        if(username != EMPTYSTRING && password != EMPTYSTRING) {
            //print("got login data\n");
            Xnoise.Params.set_string_value("lfm_user", username);
            Xnoise.Params.set_string_value("lfm_pass", password);
            username_last = username;
            password_last = password;
            Idle.add( () => {
                Xnoise.Params.write_all_parameters_to_file();
                return false;
            });
            do_user_feedback();
            lfm.login(username, password);
        }
    }
    
    private void setup_widgets() {
        var headline_label = new Gtk.Label("");
        headline_label.margin_top    = 5;
        headline_label.margin_bottom = 5;
        headline_label.set_alignment(0.0f, 0.5f);
        headline_label.set_markup("<span size=\"xx-large\"><b> LastFM </b></span>");
        headline_label.use_markup= true;
        this.pack_start(headline_label, false, false, 0);
        
        Gdk.Pixbuf image;
        unowned IconTheme theme = IconTheme.get_default();
        try {
            if(theme.has_icon("xn-lastfm")) {
                image = theme.load_icon("xn-lastfm", 42, IconLookupFlags.FORCE_SIZE);
                var b = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                b.pack_start(new Gtk.Image.from_pixbuf(image), false, false, 0);
                b.pack_start(new Gtk.Label(""), true, true, 0);
                this.pack_start(b, false, false, 2);
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
            image = null;
        }
        
        var lb = new LinkButton.with_label("http://www.lastfm.com", _("Visit LastFm for an account."));
        lb.margin_top    = 1;
        lb.margin_bottom = 1;
        lb.set_alignment(0.0f, 0.5f);
        var bx2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        bx2.pack_start(lb, false, false, 0);
        bx2.pack_start(new Gtk.Label(""), true, true, 0);
        this.pack_start(bx2, false, false, 2);

        var title_label = new Label("<b>%s</b>".printf(_("Please enter your lastfm username and password.")));
        title_label.set_use_markup(true);
        title_label.set_single_line_mode(true);
        title_label.set_alignment(0.0f, 0.5f);
        title_label.set_ellipsize(Pango.EllipsizeMode.END);
        title_label.ypad = 8;
        this.pack_start(title_label, false, false, 0);
        
        var hbox1 = new Box(Orientation.HORIZONTAL, 2);
        var user_label = new Label("%s".printf(_("Username:")));
        user_label.xalign = 0.0f;
        hbox1.pack_start(user_label, false, false, 0);
        user_entry = new Entry();
        user_entry.set_width_chars(35);
        hbox1.pack_start(user_entry, false, false, 0);
        hbox1.pack_start(new Label(""), false, false, 0);
        
        var hbox2 = new Box(Orientation.HORIZONTAL, 2);
        var pass_label = new Label("%s".printf(_("Password:")));
        pass_label.xalign = 0.0f;
        hbox2.pack_start(pass_label, false, false, 0);
        pass_entry = new Entry();
        pass_entry.set_width_chars(35);
        pass_entry.set_visibility(false);
        
        hbox2.pack_start(pass_entry, false, false, 0);
        hbox2.pack_start(new Label(""), false, false, 0);
        
        var sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
        sizegroup.add_widget(user_label);
        sizegroup.add_widget(pass_label);
        
        this.pack_start(hbox1, false, false, 2);
        this.pack_start(hbox2, false, false, 2);
        
        use_scrobble_check = new CheckButton.with_label(_("'Scrobble' played tracks on lastfm"));
        this.pack_start(use_scrobble_check, false, false, 0);
        
        var hbox3 = new Box(Orientation.HORIZONTAL, 2);
        b = new Button.from_stock(Gtk.Stock.APPLY);
        hbox3.pack_start(b, false, false, 0);
        hbox3.pack_start(new Label(""), true, true, 0);
        this.pack_start(hbox3, false, false, 0);
        this.border_width = 4;
        
        //feedback
        feedback_label = new Label("<b><i>%s</i></b>".printf(_("User not logged in!")));
        if(this.lfm.logged_in()) {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User logged in!")));
        }
        else {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(_("User not logged in!")));
        }
        feedback_label.set_use_markup(true);
        feedback_label.set_single_line_mode(true);
        feedback_label.set_alignment(0.1f, 0.5f);
        feedback_label.ypad = 8;
        this.pack_start(feedback_label, false, false, 0);
    }
}

