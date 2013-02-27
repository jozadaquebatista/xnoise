/* xnoise-album-image.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
 *     Jörn Magens
 *     softshaker  softshaker googlemail.com
 *     fsistemas
 */

using Gtk;
using Cairo;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;

private class Xnoise.AlbumImage : Gtk.EventBox {
    internal static const int SIZE = 48;
    private uint clicker_source = 0;
    private AlbumImageLoader loader = null;
    private string artist = EMPTYSTRING;
    private string album = EMPTYSTRING;
    private static uint timeout = 0;
    private string default_size = "medium";
    private string? current_path = null;
    private bool _selected = false;
    private Gdk.Pixbuf? pixbuf = null;
    
    public signal void sign_selected();
    
    internal bool selected { 
        get {
            return _selected;
        } 
        set {
            if(_selected != value) {
                _selected = value;
                Idle.add(() => {
                    queue_draw();
                    this.sign_selected();
                    return false;
                });
            }
        }
    }
    
    
    public AlbumImage() {
        //this.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
        this.set_size_request(SIZE, SIZE);
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.ENTER_NOTIFY_MASK |
                        Gdk.EventMask.LEAVE_NOTIFY_MASK
        );
        this.set_tooltip_text(_("Toggle visibility of album art view") +
                              "\n" +
                              _("<Ctrl+B>")
        );
        this.load_default_image();
        loader = new AlbumImageLoader();
        global.sign_album_image_fetched.connect(on_album_image_fetched);
        global.uri_changed.connect(on_uri_changed);
        global.sign_image_path_large_changed.connect( () => {
            set_image_via_idle(global.image_path_large);
            using_thumbnail = false;
        });
        gst_player.sign_found_embedded_image.connect(load_embedded);
        this.set_visible_window(false);
        this.button_press_event.connect( (s,e) => {
            if(e.button == 1 && e.type == Gdk.EventType.@2BUTTON_PRESS) {
                if(clicker_source != 0)
                    Source.remove(clicker_source);
                clicker_source = 0;
                main_window.toggle_fullscreen();
                return true;
            }
            if(e.button == 1 && e.type == Gdk.EventType.BUTTON_PRESS) {
                if(clicker_source != 0)
                    Source.remove(clicker_source);
                clicker_source = Timeout.add(300, () => {
                    clicker_source = 0;
                    this.selected = !this.selected;
                    return false;
                });
                return true;
            }
            //if(e.button == 3) {
            //    print("open context menu\n");
            //    return false;
            //}
            return false;
        });
        this.enter_notify_event.connect( (s, e) => {
            StateFlags flags = this.get_state_flags();
            flags |= StateFlags.PRELIGHT;
            this.set_state_flags(flags|StateFlags.PRELIGHT, false);
            queue_draw();
            return false;
        });
        this.leave_notify_event.connect( (s, e) => {
            this.unset_state_flags(StateFlags.PRELIGHT);
            queue_draw();
            return false;
        });
    }
    
    private void load_embedded(Object sender, string uri, string _artist, string _album) {
        if(uri != global.current_uri)
            return;
        
        File? pf = get_albumimage_for_artistalbum(_artist, _album, "embedded");
        
        if(!pf.query_exists(null)) 
            return;
        
        global.check_image_for_current_track();
        set_image_via_idle(pf.get_path());
        using_thumbnail = false;
    }

    private void on_uri_changed(string? uri) {
        global.check_image_for_current_track();
        Timeout.add(200, () => {
            var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.handle_uri_changed_job);
            job.set_arg("uri", uri);
            io_worker.push_job(job);
            return false;
        });
    }
    
    private bool handle_uri_changed_job(Worker.Job job) {
        assert(io_worker.is_same_thread());
        string current_uri = (string)job.get_arg("uri");
        if(global.image_path_small == null) {
            File f = get_albumimage_for_artistalbum(global.current_artist, global.current_album, "embedded");
            if(f != null && f.query_exists(null)) {
                return false;
            }
            else {
                f = get_albumimage_for_artistalbum(global.current_artist, global.current_album, "medium");
                if(f != null && f.query_exists(null)) {
                    return false;
                }
            }
            string current_uri1 = current_uri;
            load_default_image();
            Idle.add(() => {
                if(timeout != 0) {
                    Source.remove(timeout);
                    timeout = 0;
                }
                timeout = Timeout.add_seconds(1, () => {
                    search_image(current_uri1);
                    return false;
                });
                return false;
            });
        }
        else {
            File f = File.new_for_path(global.image_path_small);
            if(!f.query_exists(null)) {
                load_default_image();
            }
            else {
                set_image_via_idle(global.image_path_small);
                using_thumbnail = false;
            }
        }
        return false;
    }
    
    private const double radius = SIZE / 2.4;
    private Gdk.Pixbuf? prelit_image = null;
    private Gdk.Pixbuf? seleted_image = null;
    private Gdk.Pixbuf? prelitseleted_image = null;
    private const int WSYM = 28;
    private const int ipos = (int)((SIZE / 2.0) - (WSYM / 2.0));
    
    public override bool draw(Cairo.Context cr) {
        Allocation allocation;
        assert(icon_repo.album_art_default_icon != null);
        this.get_allocation(out allocation);
        cr.set_source_rgb(0.0, 0.0, 0.0);
        cr.set_line_width(0);
        cr.arc(SIZE / 2.0, 
               SIZE / 2.0,
               radius + 1, 
               0.0, 
               2.0 * Math.PI);
        cr.fill();
        cr.arc(SIZE / 2.0, 
               SIZE / 2.0,
               radius, 
               0.0, 
               2.0 * Math.PI);
        cr.clip ();
        cr.new_path();
        if(this.pixbuf == null) {
            Gdk.cairo_set_source_pixbuf(cr, icon_repo.album_art_default_icon, 0, 0);
        }
        else {
            Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
        }
        StateFlags flags = this.get_state_flags();
        if((flags & StateFlags.PRELIGHT) == StateFlags.PRELIGHT && !_selected) {
            cr.paint();
            if(prelit_image == null)
                prelit_image = IconTheme.get_default().load_icon("xn-grid-prelit",
                                                                 WSYM, 
                                                                 IconLookupFlags.USE_BUILTIN);
            if(prelit_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, prelit_image, ipos, ipos);
            }
            else {
                print("grid pix1 is null!\n");
            }
        }
        else if((flags & StateFlags.PRELIGHT) != StateFlags.PRELIGHT && _selected) {
            cr.paint();
            if(seleted_image == null)
                seleted_image = IconTheme.get_default().load_icon("xn-grid", 
                                                                   WSYM, 
                                                                   IconLookupFlags.USE_BUILTIN);
            if(seleted_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, seleted_image, ipos, ipos);
            }
            else {
                print("grid pix2 is null!\n");
            }
        }
        else if((flags & StateFlags.PRELIGHT) == StateFlags.PRELIGHT && _selected) {
            cr.paint();
            if(prelitseleted_image == null)
                prelitseleted_image = IconTheme.get_default().load_icon("xn-grid-prelitselected", 
                                                                   WSYM, 
                                                                   IconLookupFlags.USE_BUILTIN);
            if(prelitseleted_image != null) {
                Gdk.cairo_set_source_pixbuf(cr, prelitseleted_image, ipos, ipos);
            }
            else {
                print("grid pix3 is null!\n");
            }
        }
        cr.paint();
        return false;
//        if(this.pixbuf == null) {
//            Gdk.cairo_set_source_pixbuf(cr, icon_repo.album_art_default_icon, 0, 0);
//        }
//        else {
//            cr.set_source_rgb(0.8, 0.8, 0.8);
//            cr.set_line_width(0);
//            cr.rectangle(0, 0, SIZE, SIZE);
//            cr.fill();
//            cr.set_source_rgb(0.0, 0.0, 0.0);
//            cr.rectangle(1, 1, SIZE - 2, SIZE - 2);
//            cr.fill();
//            Gdk.cairo_set_source_pixbuf(cr, pixbuf, 2, 2);
//        }
//        cr.paint();
//        return true;
    }

    // Startes via timeout because gst_player is sending the tag_changed signals
    // sometimes very often at the beginning of a track.
    private void search_image(string? uri) {
        if(MainContext.current_source().is_destroyed())
            return;
        
        if(uri == null || uri == EMPTYSTRING)
            return;
        string _artist = EMPTYSTRING;
        string _album = EMPTYSTRING;
        string _artist_raw = EMPTYSTRING;
        string _album_raw = EMPTYSTRING;
        
        if((global.current_artist != null && global.current_artist != UNKNOWN_ARTIST) && 
           (global.current_album != null && global.current_album != UNKNOWN_ALBUM)) {
            _artist_raw = global.current_artist;
            _album_raw  = global.current_album;
            _artist = escape_for_local_folder_search(_artist_raw);
            _album  = escape_album_for_local_folder_search(_artist, _album_raw );
        }
        else {
            File? thumb = null;
            if(thumbnail_available(global.current_uri, out thumb)) {
                set_image_via_idle(thumb.get_path());
                using_thumbnail = true;
            }
            return;
        }
        
        if(set_local_image_if_available(ref _artist_raw, ref _album_raw)) 
            return;
        
        artist = remove_linebreaks(global.current_artist);
        album  = remove_linebreaks(global.current_album );
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.fetch_trackdata_job);
        job.set_arg("artist", artist);
        job.set_arg("album", album);
        job.set_arg("uri", gst_player.uri);
        db_worker.push_job(job);
    }
    
    
    private bool fetch_trackdata_job(Worker.Job job) {
        string jartist = (string)job.get_arg("artist");
        string jalbum  = (string)job.get_arg("album");
        //string uri    = (string)job.get_arg("uri");
        
        if((jartist==EMPTYSTRING)||(jartist==null)||(jartist==UNKNOWN_ARTIST)||
           (jalbum ==EMPTYSTRING)||(jalbum ==null)||(jalbum ==UNKNOWN_ALBUM )) {
            return false;
        }
        var fileout = get_albumimage_for_artistalbum(jartist, jalbum, "embedded");
        
        if(fileout.query_exists(null)) {
            global.check_image_for_current_track();
        }
        else {
            fileout = get_albumimage_for_artistalbum(jartist, jalbum, default_size);
            if(fileout.query_exists(null)) {
                global.check_image_for_current_track();
            }
            Idle.add( () => {
                loader.artist = jartist;
                loader.album  = check_album_name(jartist, jalbum);
                loader.fetch_image();
                return false;
            });
        }
        return false;
    }

    private bool set_local_image_if_available(ref string _artist, ref string _album) {
        var fileout = get_albumimage_for_artistalbum(_artist, _album, "embedded");
        if(fileout.query_exists(null)) {
            set_image_via_idle(fileout.get_path());
            using_thumbnail = false;
            return true;
        }
        else {
            fileout = get_albumimage_for_artistalbum(_artist, _album, default_size);
            if(fileout.query_exists(null)) {
                set_image_via_idle(fileout.get_path());
                using_thumbnail = false;
                return true;
            }
        }
        return false;
    }
    
    internal void load_default_image() {
        this.pixbuf = null;
        Idle.add(() => {
            this.set_size_request(SIZE, SIZE);
//            this.set_from_icon_name("xnoise-grey", Gtk.IconSize.DIALOG);
            current_path = "default";
            queue_draw();
            return false;
        });
    }

    private void set_albumimage_from_path(string? image_path) {
        if(MainContext.current_source().is_destroyed())
            return;
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_albumimage_file_job);
        job.set_arg("image_path", image_path);
        io_worker.push_job(job);
        
    }
    
    private bool load_albumimage_file_job(Worker.Job job) {
        string? image_path = (string?)job.get_arg("image_path");
        if(image_path == null || image_path == EMPTYSTRING) {
            load_default_image();
            return false;
        }
        File f = File.new_for_path(image_path);
        if(!f.query_exists(null)) {
            load_default_image();
            return false;
        }
        Gdk.Pixbuf? px = null;
        try {
            px = new Gdk.Pixbuf.from_file(image_path);
        }
        catch(Error e) {
            print("%s\n", e.message);
            this.pixbuf = null;
            image_path = "default";
            return false;
        }
        
        px = px.scale_simple(SIZE, SIZE, Gdk.InterpType.HYPER);
        
        Idle.add(() => {
            this.pixbuf = px;
            current_path = image_path;
            queue_draw();
            return false;
        });
        if(!using_thumbnail) {
            Timeout.add_seconds(1, () => {
                var fileout  = get_albumimage_for_artistalbum(global.current_artist,
                                                              global.current_album,
                                                              "medium");
                var fileout2 = get_albumimage_for_artistalbum(global.current_artist,
                                                              global.current_album,
                                                              "embedded");
                if(fileout == null && fileout2 == null) {
                    //print("image not fitting. set default\n");
                    if(current_path != "default") {
                        load_default_image();
                    }
                    return false;
                }
                if(fileout.get_path() != current_path && fileout2.get_path() != current_path) {
                    //print("this.file not fitting curren album image (%s). redoing search\n", current_path);
                    string _artist_raw = global.current_artist;
                    string _album_raw  = global.current_album;
                    if(!set_local_image_if_available(ref _artist_raw, ref _album_raw)) {
                        if(current_path != "default")
                            load_default_image();
                    }
                    return false;
                }
                return false;
            });
        }
        return false;
    }

    private uint source = 0;
    
    private void on_album_image_fetched(string _artist, string _album, string image_path) {
        //print("\ncalled on_image_fetched %s - %s : %s", _artist, _album, image_path);
        if(image_path == EMPTYSTRING) 
            return;
        
        if((prepare_for_comparison(artist) != prepare_for_comparison(_artist))||
           (prepare_for_comparison(check_album_name(artist, album))  != 
                prepare_for_comparison(check_album_name(_artist, _album)))) 
            return;
        
        File f = File.new_for_path(image_path);
        
        if(f == null || f.get_path() == null)
            return;
        
        var fjob = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.read_file_job);
        fjob.set_arg("file", f);
        io_worker.push_job(fjob);
        
        AlbumArtView.icon_cache.handle_image(f.get_path());
    }
    
    private bool read_file_job(Worker.Job job) {
        File f = (File)job.get_arg("file");
        
        if(f == null || !f.query_exists(null)) 
            return false;
        
        Idle.add(() => {
            global.check_image_for_current_track();
            set_image_via_idle(f.get_path());
            return false;
        });
        using_thumbnail = false;
        return false;
    }
    
    private bool using_thumbnail = false;
    
    private void set_image_via_idle(string? image_path) {
        if(image_path == null || image_path == EMPTYSTRING)
            return;
        
        if(source != 0) {
            Source.remove(source);
            source = 0;
        }
            
        source = Timeout.add(200, () => {
            this.set_albumimage_from_path(image_path);
            source = 0;
            return false;
        });
    }
}
