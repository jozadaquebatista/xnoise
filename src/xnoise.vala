/* xnoise.vala
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
 */


namespace Xnoise {

    private static bool _plugininfo;
    private static bool _noplugins;
    private static bool _nodbus;
    private static bool _reset;
    private static bool _version;
    private static bool _play_pause;
    private static bool _stop;
    private static bool _prev;
    private static bool _next;
    private static bool _quit_running;
    private static bool _hidden_window;

    [CCode (array_length = false, array_null_terminated = true)]
    private static string[] _fileargs;

    private const OptionEntry[] options = {
        { "version",
          'V',
          0,
          OptionArg.NONE,
          ref _version,
          "Show the application's version.",
          null 
        },
        { "hidden-window",
          'h',
          0,
          OptionArg.NONE,
          ref _hidden_window,
          "Start the application with hidden window.",
          null
        },
        { "plugin-info",
          'p',
          0,
          OptionArg.NONE,
          ref _plugininfo,
          "Show loaded and activated plugins on app start.",
          null
        },
        { "no-plugins",
          'N',
          0,
          OptionArg.NONE,
          ref _noplugins,
          "Start without loding any plugins.",
          null
        },
        { "no-dbus",
          'D',
          0,
          OptionArg.NONE,
          ref _nodbus,
          "Start without using the onboard dbus interface.",
          null
        },
        { "reset",
          'R',
          0,
          OptionArg.NONE,
          ref _reset,
          "Reset all settings.",
          null
        },
        { "play-pause",
          't',
          0,
          OptionArg.NONE,
          ref _play_pause,
          "Toggle Playback.",
          null
        },
        { "stop",
          's',
          0,
          OptionArg.NONE,
          ref _stop,
          "Stop playback.",
          null
        },
        { "next",
          'n',
          0,
          OptionArg.NONE,
          ref _next,
          "Goto next track.",
          null
        },
        { "previous",
          'e',
          0,
          OptionArg.NONE,
          ref _prev,
          "Goto previous track.",
          null
        },
        { "quit",
          'q',
          0,
          OptionArg.NONE,
          ref _quit_running,
          "Quit a running instance of xnoise.",
          null
        },
        { "",
          0,
          0,
          OptionArg.FILENAME_ARRAY, 
          ref _fileargs,
          null,
          "[FILE ...]" },
        { null }
    };

    public static int main(string[] args) {
        //Environment.atexit(mem_profile); This can be used if xnoise is compiled with new memory statistic switch
        GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.XN_LOCALE_DIR);
        Environment.set_application_name(Config.GETTEXT_PACKAGE);
        string[] sa_args = {};
        sa_args += Config.GETTEXT_PACKAGE;
        var opt_context = new OptionContext("     Xnoise Media Player     ");
        opt_context.set_description(
           "%s %s \n%s \nhttp://www.xnoise-media-player.com/\n".printf(
              _("Xnoise is a media player for Gtk+."),
              _("It uses the gstreamer framework."),
              _("More information on the project website:"))
        );
        opt_context.set_help_enabled(true);
        opt_context.add_main_entries(options, null);
        try {
            opt_context.parse(ref args);
        }
        catch(OptionError e) {
            print("%s\n", e.message);
            print(_("Run 'xnoise --help' to see a full list of available command line options.\n"));
            return 0;
        }
        if(_version) {
            print("xnoise %s\n", Config.PACKAGE_VERSION);
            return 0;
        }
        if(_play_pause)    sa_args += "-t";
        if(_stop)          sa_args += "-s";
        if(_next)          sa_args += "-n";
        if(_prev)          sa_args += "-e";
        if(_quit_running)  sa_args += "-q";
        if(_hidden_window) sa_args += "-h";
        string mime;
        var psVideo = new PatternSpec("video*");
        var psAudio = new PatternSpec("audio*");
        HashTable<string,int> supported_types = 
            new HashTable<string,int>(str_hash, str_equal);
        supported_types.insert("application/vnd.rn-realmedia", 1);
        supported_types.insert("application/ogg", 1);
        supported_types.insert("application/x-extension-m4a", 1);
        supported_types.insert("application/x-extension-mp4", 1);
        supported_types.insert("application/x-flac", 1);
        supported_types.insert("application/x-flash-video", 1);
        supported_types.insert("application/x-matroska", 1);
        supported_types.insert("application/x-ogg", 1);
        supported_types.insert("application/x-troff-msvideo", 1);
        supported_types.insert("application/xspf+xml", 1);
        string attr = FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        if(_fileargs != null) {
            var ls = new Xnoise.LocalSchemes();
            foreach(string s in _fileargs) {
                File current_file;
                current_file = File.new_for_commandline_arg(s);
                if(current_file == null)             continue;
                if(!current_file.query_exists(null)) continue;
                
                string urischeme = current_file.get_uri_scheme();
                string content = null;
                if(urischeme in ls) {
                    //print("current_file.get_uri(): %s\n", current_file.get_uri());
                    try {
                        FileInfo info = current_file.query_info(attr, FileQueryInfoFlags.NONE, null);
                        content = info.get_content_type();
                        mime = GLib.ContentType.get_mime_type(content);
                        
                        if(psAudio.match_string(mime)||
                           psVideo.match_string(mime) ||
                           supported_types.lookup(mime) == 1) {
                            //print("%s is supported\n", current_file.get_uri());
                            sa_args += current_file.get_uri();
                        }
                    }
                    catch(GLib.Error e) {
                        print("Arg error: %s\n", e.message);
                        continue;
                    }
                }
            }
        }
        Xnoise.Application app = new Xnoise.Application();
        app.activate.connect(app.on_activated);
        app.startup.connect(app.on_startup);
        app.command_line.connect(app.on_command_line);
        try {
            app.register(null);
        }
        catch(Error e) {
            print("AppError: %s\n", e.message);
            return -1;
        }
        
        if(_reset)      { print("Reset not implemented, yet.\n"); _reset = false; }
        
        if(_plugininfo) {
            if(!app.get_is_remote()) {
                sa_args += "-p";
                _plugininfo = false;
            }
            else {
                print("For the '--plugin-info' option, please restart xnoise. \n");
            }
        }
        if(_noplugins) {
            if(!app.get_is_remote()) {
                sa_args += "-N";
                _noplugins = false;
            }
            else {
                print("For the '--no-plugins' option, please restart xnoise. \n");
            }
        }
        if(_nodbus) {
            if(!app.get_is_remote()) {
                sa_args += "-D";
                _nodbus = false;
            }
            else {
                print("For the '--no-dbus' option, please restart xnoise. \n");
            }
        }
        int re = app.run(sa_args);
#if REF_TRACKING_ENABLED
        print("dumping\n");
        BaseObject.print_object_dump();
#endif
        return re;
    }
}

