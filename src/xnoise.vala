/* xnoise.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
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

    [CCode (array_length = false, array_null_terminated = true)]
    private static string[] _fileargs;

    private const OptionEntry[] options = {
        { "version",     'V', 0, OptionArg.NONE, ref _version,    "Show the application's version.",                 null },
        { "plugin-info", 'p', 0, OptionArg.NONE, ref _plugininfo, "Show loaded and activated plugins on app start.", null },
        { "no-plugins",  'N', 0, OptionArg.NONE, ref _noplugins,  "Start without loding any plugins.",               null },
        { "no-dbus",     'D', 0, OptionArg.NONE, ref _nodbus,     "Start without using the onboard dbus interface.", null },
        { "reset",       'R', 0, OptionArg.NONE, ref _reset,      "Reset all settings.",                             null },
        { "", 0, 0, OptionArg.FILENAME_ARRAY,    ref _fileargs,   null,                                      "[FILE ...]" },
        {null}
    };

    public static int main(string[] args) {
        //Environment.atexit(mem_profile); This can be used if xnoise is compiled with new memory statistic switch
        GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
        GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
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
        if(_plugininfo) sa_args += "-p";
        if(_reset)      sa_args += "-R";
        if(_noplugins)  sa_args += "-N";
        if(_nodbus)     sa_args += "-D";
        string mime;
        var psVideo = new PatternSpec("video*");
        var psAudio = new PatternSpec("audio*");
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
                    try {
                        FileInfo info = current_file.query_info(attr, FileQueryInfoFlags.NONE, null);
                        content = info.get_content_type();
                        mime = GLib.ContentType.get_mime_type(content);
                        
                        if((psAudio.match_string(mime))||
                           (psVideo.match_string(mime))) {
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
        if(app.get_is_remote() && _fileargs == null) {
            app.activate();
            return 0;
        }
        return app.run(sa_args);
    }
}

