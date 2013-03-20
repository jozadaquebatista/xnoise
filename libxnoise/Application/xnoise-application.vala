/* xnoise-application.vala
 *
 * Copyright (C) 2011 - 2013  Jörn Magens
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

public class Xnoise.Application : GLib.Application {
    
    public static Main xn;
    
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
    
    public static bool hidden_window {
        get {
            return _hidden_window;
        }
    }
    
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


    public Application() {
        Object(application_id:"org.gtk.xnoise", flags:(ApplicationFlags.HANDLES_COMMAND_LINE));
    }

    private void reset_control_options() {
        _stop = false;
        _play_pause = false;
        _prev = false;
        _next = false;
    }

    public void on_activated() {
        if(_quit_running) {
            Idle.add( () => {
                Main.instance.quit();
                return false;
            });
            reset_control_options();
            return;
        }
        if(_stop) {
            Idle.add( () => {
                global.stop();
                return false;
            });
            reset_control_options();
            return;
        }
        if(_prev) {
            Idle.add( () => {
                global.prev();
                return false;
            });
            reset_control_options();
            return;
        }
        if(_next) {
            Idle.add( () => {
                global.next();
                return false;
            });
            reset_control_options();
            return;
        }
        if(_play_pause) {
            Idle.add( () => {
                global.play(true);
                return false;
            });
            reset_control_options();
            return;
        }
        if(!_hidden_window) {
            main_window.show_all();
            main_window.present();
        }
    }
    
    public void on_startup() {
        if(!this.get_is_remote()) {
            unowned string[] args = null;
            Gtk.init(ref args);
            Gst.init(ref args);
            Xnoise.Application.xn = Xnoise.Main.instance;
            Xnoise.Main.app = this;
            main_window.hide();
        }
        else {
            this.activate();
        }
    }
    
    public int on_command_line(ApplicationCommandLine command_line) {
        if(command_line.get_is_remote()) {
            print("MI on_command_line\n");
        }
        else {
            print("New on_command_line\n");
        }
        string[] args = command_line.get_arguments();
        string[] sa_args = {};
        foreach(string arg in args) {
            sa_args += arg;
        }
        unowned string[] uargs = sa_args; // option parser needs unowned array of string
        var opt_context = new OptionContext("     Xnoise Media Player     ");
        opt_context.set_description(
           "%s %s \n%s \nhttp://www.xnoise-media-player.com/\n".printf(
              _("Xnoise is a media player for Gtk+."),
              _("It uses the gstreamer framework."),
              _("More information on the project website:")
           )
        );
        opt_context.add_main_entries(options, null);
        try {
            opt_context.parse(ref uargs);
        }
        catch(OptionError e) {
            print("%s\n", e.message);
        }
        if(_reset)      { print("Reset not implemented, yet.\n"); _reset = false; }
        if(_plugininfo) {
            if(command_line.get_is_remote()) {
                print("For the '--plugin-info' option, please restart xnoise. \n");
                _plugininfo = false;
            }
            else {
                Main.show_plugin_state = true;
            }
        }
        if(_noplugins) {
            if(command_line.get_is_remote()) {
                print("For the '--no-plugins' option, please restart xnoise. \n");
                _noplugins = false;
            }
            else {
                Main.no_plugins = true;
            }
        }
        if(_nodbus) {
            if(command_line.get_is_remote()) {
                print("For the '--no-dbus' option, please restart xnoise. \n");
                _nodbus = false;
            }
            else {
                Main.no_dbus = true;
            }
        }
        string[] uris = {};
        File f = null;
        string mime;
        setup_pattern_specs();
        string attr = FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        if(_fileargs != null) {
            var ls = new Xnoise.LocalSchemes();
            foreach(string s in _fileargs) {
                f = File.new_for_commandline_arg(s);
                if(f == null) continue;
                if(!f.query_exists(null)) continue;
                string urischeme = f.get_uri_scheme();
                string content = null;
                if(urischeme in ls) {
                    try {
                        FileInfo info = f.query_info(attr, FileQueryInfoFlags.NONE, null);
                        content = info.get_content_type();
                        mime = GLib.ContentType.get_mime_type(content);
                        
                        if(pattern_audio.match_string(mime) ||
                           pattern_video.match_string(mime) ||
                           supported_types.lookup(mime) == 1) {
                            uris += f.get_uri();
                        }
                    }
                    catch(GLib.Error e) {
                        print("Arg error: %s\n", e.message);
                        continue;
                    }
                }
            }
        }
        _fileargs = null;
        if(uris.length > 0) {
            Idle.add( () => {
                tl.tracklistmodel.add_uris(uris);
                return false;
            });
            
        }
        this.activate();
        if(!command_line.get_is_remote()) {
            this.hold();
        }
        return 0;
    }
}
