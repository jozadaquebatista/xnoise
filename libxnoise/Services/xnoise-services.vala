/* xnoise-services.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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
 */


using Xnoise;
using Xnoise.Resources;


namespace Xnoise.Services {

    public static RemoteSchemes get_remote_schemes() { 
        return _remote_schemes;
    }
    
    public static LocalSchemes get_local_schemes() { 
        return _local_schemes;
    }
    
    public static MediaExtensions get_media_extensions() { 
        return _media_extensions;
    }
    
    public static MediaStreamSchemes get_media_stream_schemes() { 
        return _media_stream_schemes;
    }
    
    //http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
    private static string _settings_folder = null; 
    public static string settings_folder() {
        if(_settings_folder == null)
            _settings_folder = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(),
                                                        "xnoise",
                                                        null);
        return (owned)_settings_folder;
    }

    //http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
    private static string _data_folder = null; 
    public static string data_folder() {
        if(_data_folder == null)
            _data_folder = GLib.Path.build_filename(GLib.Environment.get_user_data_dir(),
                                                    "xnoise",
                                                    null);
        return (owned)_data_folder;
    }
    
    public static bool verify_xnoise_directories() {
        File f = File.new_for_path(settings_folder());
        if(f == null) {
            print("Failed to get xnoise directories! \n");
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to get xnoise directories! \n");
            msg.run();
            return false;
        }
        
        if(f == null) {
            print("xnoise settings folder error\n");
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to get xnoise directories! \n" + "xnoise settings folder error\n");
            msg.run();
            return false;
        }
        
        if(!f.query_exists(null)) {
            try {
                f.make_directory_with_parents();
            }
            catch(Error e) {
                print("%s", e.message);
                var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                                Gtk.ButtonsType.OK,
                                                "Failed to get xnoise directories! \n" + e.message);
                msg.run();
                return false;
            }
        }
        
        f = File.new_for_path(data_folder());
        if(f == null) {
            print("Failed to get xnoise directories! \n");
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to get xnoise directories! \n");
            msg.run();
            return false;
        }
        
        if(f == null) {
            print("xnoise data folder error\n");
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to xnoise directories! \n" + "xnoise data folder error\n");
            msg.run();
            return false;
        }
        
        if(!f.query_exists(null)) {
            try {
                f.make_directory_with_parents();
            }
            catch(Error e) {
                print("%s", e.message);
                var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                                Gtk.ButtonsType.OK,
                                                "Failed to xnoise directories! \n" + e.message);
                msg.run();
                return false;
            }
        }
        return true;
    }

    private string[] characters_not_used_in_comparison__escaped = null;
    
    public static string prepare_for_comparison(string? value) {
        // transform strings to make it easier to compare them
        if(value == null)
            return EMPTYSTRING;
        
        if(characters_not_used_in_comparison__escaped == null) {
            string[] characters_not_used_in_comparison = {
               "/", 
               " ", 
               "\\", 
               ".", 
               ",", 
               ";", 
               ":", 
               "\"", 
               "'", 
               "'", 
               "`", 
               "´", 
               "!", 
               "_", 
               "+", 
               "*", 
               "#", 
               "?", 
               "(", 
               ")", 
               "[", 
               "]", 
               "{", 
               "}", 
               "&", 
               "§", 
               "$", 
               "%", 
               "=", 
               "ß", 
               "ä", 
               "ö", 
               "ü", 
               "|", 
               "µ", 
               "@", 
               "~"
            };
            
            characters_not_used_in_comparison__escaped = {};
            foreach(unowned string s in characters_not_used_in_comparison)
                characters_not_used_in_comparison__escaped += GLib.Regex.escape_string(s);
        }
        string result = value != null ? value.strip().down() : EMPTYSTRING;
        try {
            foreach(unowned string s in characters_not_used_in_comparison__escaped) {
                var regex = new GLib.Regex(s);
                result = regex.replace_literal(result, -1, 0, EMPTYSTRING);
            }
        }
        catch (GLib.RegexError e) {
            GLib.assert_not_reached ();
        }
        return (owned)result;
    }

    public static string prepare_for_search(string? val) {
        // transform strings to improve searches
        if(val == null)
            return EMPTYSTRING;
        
        string result = val.strip().down();
        
        result = remove_linebreaks(result);
        
        result.replace("_", " ");
        result.replace("%20", " ");
        result.replace("@", " ");
        result.replace("<", " ");
        result.replace(">", " ");
        return (owned)result;
    }

    public static string remove_linebreaks(string? val) {
        // unexpected linebreaks do not look nice
        if(val == null)
            return EMPTYSTRING;
        
        try {
            GLib.Regex r = new GLib.Regex("\n");
            return (owned)r.replace(val, -1, 0, " ");
        }
        catch(GLib.RegexError e) {
            print("%s\n", e.message);
        }
        return val;
    }

    public static string remove_suffix_from_filename(string? val) {
        if(val == null)
            return EMPTYSTRING;
        unowned string name = val;
        string prep;
        if(name.last_index_of(".") != -1) 
            prep = name.substring(0, name.last_index_of("."));
        else
            prep = name;
        return (owned)prep;
    }

    public static string get_suffix_from_filename(string? val) {
        if(val == null)
            return EMPTYSTRING;
        unowned string name = val;
        string prep = EMPTYSTRING;
        int inx = -1;
        if((inx = name.last_index_of(".")) != -1) 
            prep = name.substring(inx + 1, name.length - inx -1);
        else
            return EMPTYSTRING;
        return (owned)prep;
    }

    public static string prepare_name_from_filename(string? val) {
        if(val == null)
            return EMPTYSTRING;
        string prep = val;
        
        int start_idx = -1;
        int end_idx   = -1;
        
        if((start_idx = prep.last_index_of("/", 0)) == -1)
            start_idx = 0;
        else
            start_idx = start_idx + 1;
        
        if((end_idx = prep.last_index_of(".", start_idx)) == -1) 
            end_idx = prep.length;
        
        if(end_idx < start_idx)
            end_idx = prep.length;
        
        prep = prep.substring(start_idx, end_idx - start_idx).replace("_", " ").replace("%20", " ");
        return (owned)prep;
    }

    public static string replace_underline_with_blank_encoded(string value) {
        try {
            GLib.Regex r = new GLib.Regex("_");
            return (owned)r.replace(value, -1, 0, "%20");
        }
        catch(GLib.RegexError e) {
            print("%s\n", e.message);
        }
        return value;
    }

    public static string make_time_display_from_seconds(int length) {
        string lengthString = EMPTYSTRING;
        if(length > 0) {
            // convert seconds to a user convenient mm:ss display
            int dur_min, dur_sec;
            dur_min = (int)(length / 60);
            dur_sec = (int)(length % 60);
            lengthString = "%02d:%02d".printf(dur_min, dur_sec);
        }
        return (owned)lengthString;
    }
    
    public static int32 length_string_to_int(string s) {
        int32 j = 0;
        if(s == null || s == EMPTYSTRING)
            return j;
        
        string[] sa = s.split(":");
        
        if(sa.length == 1)
            return int.parse(s);
        
        int c = 0;
        for(int i = sa.length - 1; i >= 0; i--) {
            j = j + (int)(int.parse(sa[i]) * Math.pow(60.0, (double)c));
            c++;
        }
        return j;
    }
}
