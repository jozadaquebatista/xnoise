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
        File thumb = File.new_for_path(GLib.Path.build_filename(Environment.get_home_dir(), ".thumbnails", "normal", md5string + ".png"));
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

    internal class AlbumImageLoader : GLib.Object {
//        private static IAlbumCoverImageProvider provider;
        private static GLib.List<IAlbumCoverImageProvider> providers;
        private static Main xn;
        internal string artist;
        internal string album;
    
        public AlbumImageLoader() {
            xn = Main.instance;
            plugin_loader.sign_plugin_activated.connect(AlbumImageLoader.on_plugin_activated);
            plugin_loader.sign_plugin_deactivated.connect(AlbumImageLoader.on_backend_deactivated);
//            backend_iter = 0;
        }

        private static void on_plugin_activated(Container p) {
            if(!p.is_album_image_plugin) 
                return;
        
            IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
            if(provider == null) 
                return;
        
//            AlbumImageLoader.provider = provider;
            providers.prepend(provider);
        }
    
        //forward signal from current provider
        private void on_image_fetched(string _artist, string _album, string _image_path) {
            global.sign_album_image_fetched(_artist, _album, _image_path);
        }

        private static void on_backend_deactivated(Container p) {
            if(!p.is_album_image_plugin) 
                return;
            
            IAlbumCoverImageProvider provider = p.loaded_plugin as IAlbumCoverImageProvider;
            if(provider == null) 
                return;
            providers.remove(provider);
        }

        private uint backend_iter = 0;
        
        internal bool fetch_image() {
            if(providers == null) {
                global.sign_album_image_fetched(EMPTYSTRING, EMPTYSTRING, EMPTYSTRING);
                return false;
            }
            Idle.add( () => {
                var album_image_provider = providers.nth_data(backend_iter).from_tags(artist,
                                                                                      check_album_name(artist,
                                                                                                       album)
                                                                                      );
                if(album_image_provider == null)
                    return false;
                album_image_provider.sign_image_fetched.connect(on_image_fetched);
                album_image_provider.ref(); //prevent destruction before ready
                album_image_provider.find_image();
                return false;
            });
            return true;
        }
    }
}

