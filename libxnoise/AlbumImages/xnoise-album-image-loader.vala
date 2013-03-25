/* xnoise-album-image-loader.vala
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
 *     softshaker  softshaker googlemail.com
 *     Jörn Magens
 */

using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;
using Xnoise.PluginModule;


namespace Xnoise {
    public static File? get_albumimage_for_artistalbum(string? artist, string? album, string? size) {
        if(album == null)
            return null;
        if(artist == null)
            return null;
        if(artist == UNKNOWN_ARTIST)
            return null;
        if(album == UNKNOWN_ALBUM)
            return null;
        if(size == null || size == EMPTYSTRING)
            size = "medium";
        string escaped_artist = (escape_for_local_folder_search(artist.down()));      //.normalize();
        string escaped_album = (escape_album_for_local_folder_search(artist, album)); //.normalize();
        File f = File.new_for_path(data_folder() + "/album_images/" +
                                   escaped_artist + "/" +
                                   escaped_album + "/" +
                                   escaped_album +
                                   "_" +
                                   size
                                   );
//        print("path: %s\n", f.get_path());
        return f;
    }
    
    public static bool thumbnail_available(string uri, out File? _thumb) {
        string md5string = Checksum.compute_for_string(ChecksumType.MD5, uri);
        File thumb = File.new_for_path(GLib.Path.build_filename(Environment.get_home_dir(), 
                                                                ".thumbnails", 
                                                                "normal", 
                                                                md5string + ".png")
        );
        if(thumb.query_exists(null)) {
            _thumb = thumb;
            return true;
        }
        _thumb = null;
        return false;
    }

    private static string escape_for_local_folder_search(string? _val) {
        // transform the name to match the naming scheme
        string val = _val;
        string tmp = EMPTYSTRING;
        if(val == null)
            return (owned)tmp;
        
        tmp = val.strip().down(); //check_album_name(artist, album_name);
        
        replace_accents(ref tmp);
        
        if(tmp.contains("/")) {
            string[] a = tmp.split("/", 20);
            tmp = EMPTYSTRING;
            foreach(string s in a) {
              tmp = tmp + s;
            }
        }
        return (owned)tmp;
    }

    public static string escape_album_for_local_folder_search(string artist, string? album_name) {
        // transform the name to match the naming scheme
//        string artist = _artist;
        string tmp = EMPTYSTRING;
        if(album_name == null)
            return (owned)tmp;
        if(artist == null)
            return (owned)tmp;
        
        tmp = check_album_name(artist, album_name);
        replace_accents(ref tmp);
        
        try {
            var r = new GLib.Regex("\n");
            tmp = r.replace(tmp, -1, 0, "_");
            r = new GLib.Regex(" ");
            tmp = r.replace(tmp, -1, 0, "_");
        }
        catch(RegexError e) {
            print("%s\n", e.message);
            return album_name;
        }
        if(tmp.contains("/")) {
            string[] a = tmp.split("/", 20);
            tmp = EMPTYSTRING;
            foreach(string s in a) {
                tmp = tmp + s;
            }
        }
        return (owned)tmp;
    }
    
    private static void replace_accents(ref string str) {
        str = str.replace("\n", "_")
                 .replace("é", "e")
                 .replace("í", "i")
                 .replace("à", "a")
                 .replace("å", "a")
                 .replace("ç", "c")
                 .replace("ñ", "n")
                 .replace("è", "e")
                 .replace("ö", "o")
                 .replace("ü", "u")
                 .replace("â", "a")
                 .replace("û", "u")
                 .replace("ß", "ss")
                 .replace("ø", "o")
                 .replace(" ", "_");
    }

    public static string check_album_name(string? artistname, string? albumname) {
        if(albumname == null || albumname == EMPTYSTRING)
            return EMPTYSTRING;
        if(artistname == null || artistname == EMPTYSTRING)
            return EMPTYSTRING;
        
        string _artistname = artistname.strip().down();
        string _albumname = albumname.strip().down();
        string[] self_a = {
            "self titled",
            "self-titled",
            "s/t"
        };
        string[] media_a = {
            "cd",
            "ep",
            "7\"",
            "10\"",
            "12\"",
            "7inch",
            "10inch",
            "12inch"
        };
        foreach(string selfs in self_a) {
            if(_albumname == selfs) 
                return (owned)_artistname;
            foreach(string media in media_a) {
                if(_albumname == (selfs + " " + media)) 
                    return (owned)_artistname;
            }
        }
        return (owned)_albumname;
    }

    public class AlbumImageLoader : GLib.Object {
        private static GLib.List<IAlbumCoverImageProvider> providers = 
            new List<IAlbumCoverImageProvider>();
        
        public signal void image_path_large_changed();
        public signal void image_path_small_changed();
        public signal void image_path_embedded_changed();
        
        public Gdk.Pixbuf? image_small      { get; set; }
        public Gdk.Pixbuf? image_large      { get; set; }
        public Gdk.Pixbuf? image_embedded   { get; set; }
        
        private string? _image_path_small = null;
        public string? image_path_small { 
            get {
                return _image_path_small;
            }
            set {
                if(_image_path_small == value)
                    return;
                _image_path_small = value;
                image_path_small_changed();
            }
        }
        
        private string? _image_path_large = null;
        public string? image_path_large { 
            get {
                return _image_path_large;
            }
            set {
                if(_image_path_large == value)
                    return;
                _image_path_large = value;
                image_path_large_changed();
            }
        }
        
        private string? _image_path_embedded = null;
        public string? image_path_embedded { 
            get {
                return _image_path_embedded;
            }
            set {
                if(_image_path_embedded == value)
                    return;
                _image_path_embedded = value;
                image_path_embedded_changed();
            }
        }
        
        
        public AlbumImageLoader() {
            connect_signals();
        }
        
        
        private void connect_signals() {
            plugin_loader.sign_plugin_activated.connect(AlbumImageLoader.on_plugin_activated);
            plugin_loader.sign_plugin_deactivated.connect(AlbumImageLoader.on_backend_deactivated);
            
            global.notify["current-artist"].connect(on_tag_changed);
            global.notify["current-albumartist"].connect(on_tag_changed);
            global.notify["current-album"].connect(on_tag_changed);
            
            gst_player.sign_found_embedded_image.connect(load_embedded);
        }
        
        private void load_embedded(Object sender, string uri, string _artist, string _album) {
            File? pf = get_albumimage_for_artistalbum(_artist, _album, "embedded");
            if(pf == null || !pf.query_exists(null)) 
                return;
            Idle.add(() => {
                on_tag_changed();
                return false;
            });
            AlbumArtView.icon_cache.handle_image(pf.get_path());
//            using_thumbnail = false;
        }

        private uint local_source  = 0;
        private uint remote_source = 0;
        
        private void on_tag_changed() {
            File f;
            if(!check_image_for_current_tags(out f)) {
                if(local_source != 0)
                    Source.remove(local_source);
                local_source = Timeout.add_seconds(1, () => {
                    image_path_small = null;
                    image_path_large = null;
                    image_path_embedded = null;
                    image_small = null;
                    image_large = null;
                    image_embedded = null;
                    local_source = 0;
                    return false;
                });
                return;
            }
            else {
                if(remote_source != 0) {
                    Source.remove(remote_source);
                    remote_source = 0;
                }
                if(local_source != 0)
                    Source.remove(local_source);
                local_source = Timeout.add(100, () => {
                    var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, setup_images_job);
                    io_worker.push_job(job);
                    local_source = 0;
                    return false;
                });
            }
        }
        
        private int backend_iter = 0;
        
        private IAlbumCoverImage? create_provider() {
            string? artist = global.current_albumartist != null ? 
                                global.current_albumartist : 
                                global.current_artist;
            string? album = global.current_album;
            IAlbumCoverImage? prov =
                providers.nth_data(backend_iter).from_tags(artist, check_album_name(artist, album));
            if(prov == null)
                return null;
            prov.sign_image_fetched.connect(on_image_fetched);
            prov.ref(); //prevent destruction before ready
            prov.find_image();
            return prov;
        }
        
        private bool setup_images_job(Worker.Job job) {
            assert(io_worker.is_same_thread());
            File? fmedium = null, flarge = null, fembedded = null;
            fmedium = get_albumimage_for_artistalbum((global.current_albumartist != null ? 
                                                         global.current_albumartist :
                                                         global.current_artist),
                                                     global.current_album,
                                                     "medium");
            if(fmedium != null && fmedium.query_exists(null)) {
                image_small = create_image_from_file(ref fmedium);
                image_path_small = image_small != null ? fmedium.get_path() : null;
            }
            else {
                image_small = null;
                image_path_small = null;
                if(remote_source != 0) {
                    Source.remove(remote_source);
                    remote_source = 0;
                }
                remote_source = Timeout.add_seconds(1, () => {
                    var provider = create_provider();
                    remote_source = 0;
                    return false;
                });
            }
            
            flarge = 
                get_albumimage_for_artistalbum((global.current_albumartist != null ? 
                                                    global.current_albumartist :
                                                    global.current_artist),
                                                global.current_album,
                                                "extralarge");
            if(flarge != null && flarge.query_exists(null)) {
                image_large = create_image_from_file(ref flarge);
                image_path_large = image_large != null ? flarge.get_path() : null;
            }
            else {
                image_large = null;
                image_path_large = null;
            }
            
            fembedded =
                get_albumimage_for_artistalbum((global.current_albumartist != null ? 
                                                    global.current_albumartist :
                                                    global.current_artist),
                                                global.current_album,
                                                "embedded");
            if(fembedded != null && fembedded.query_exists(null)) {
                image_embedded = create_image_from_file(ref fembedded);
                image_path_embedded = image_embedded != null ? fembedded.get_path() : null;
            }
            else {
                image_embedded = null;
                image_path_embedded = null;
            }
            
            return false;
        }
        
        private Pixbuf? create_image_from_file(ref File file) {
            Pixbuf pb = null;
            try {
                pb = new Pixbuf.from_file(file.get_path());
            }
            catch(Error e) {
                return null;
            }
            return pb;
        }
        
        private bool check_image_for_current_tags(out File? f) {
            f = null;
            if((global.current_albumartist == null && global.current_artist == null) || 
               global.current_album == null)
                return false;
            
            f = get_albumimage_for_artistalbum((global.current_albumartist != null ? 
                                                    global.current_albumartist :
                                                    global.current_artist),
                                               global.current_album,
                                               "medium");
            if(f != null)
                return true;
            return false;
        }
        
        private static void on_plugin_activated(Container p) {
            if(!p.is_album_image_plugin) 
                return;
            IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
            if(provider == null) 
                return;
            providers.prepend(provider);
        }
        
        private static void on_backend_deactivated(Container p) {
            if(!p.is_album_image_plugin) 
                return;
            IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
            if(provider == null) 
                return;
            providers.remove(provider);
        }
        
        private void on_image_fetched(string _artist, string _album, string _image_path) {
            //print("called on_image_fetched %s - %s : %s\n", _artist, _album, _image_path);
            if(_image_path == EMPTYSTRING) 
                return;
            
            Idle.add(() => {
                on_tag_changed();
                return false;
            });
            
            File f = File.new_for_path(_image_path);
            if(f == null || f.get_path() == null)
                return;
            AlbumArtView.icon_cache.handle_image(f.get_path());
        }
    }
}

