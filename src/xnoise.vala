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
 * 	Jörn Magens
 */


namespace Xnoise {

	private static bool _plugininfo;
	private static bool _noplugins;
	private static bool _reset;
	private static bool _version;

	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] _fileargs;

	private const OptionEntry[] options = {
		{ "version",     'V', 0, OptionArg.NONE, ref _version,    "Show the application's version.",                 null },
		{ "plugin-info", 'p', 0, OptionArg.NONE, ref _plugininfo, "Show loaded and activated plugins on app start.", null },
		{ "no-plugins",  'N', 0, OptionArg.NONE, ref _noplugins,  "Start without loding any plugins.",               null },
		{ "reset",       'R', 0, OptionArg.NONE, ref _reset,      "Reset all settings.",                             null },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY,    ref _fileargs,   null,                                      "[FILE ...]" },
		{null}
	};

	public static int main(string[] args) {
		//Environment.atexit(mem_profile); This can be used if xnoise is compiled with new memory statistic switch
print("args len: %d\n", args.length);
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
print("++1\n");
		if(_version) {
			print("xnoise %s\n", Config.PACKAGE_VERSION);
			return 0;
		}
print("++2\n");
		Xnoise.Application app = new Xnoise.Application();
		app.activate.connect(app.on_activated);
		app.startup.connect(app.on_startup);
		app.command_line.connect(app.on_command_line);
print("++3\n");
		try {
			app.register(null);
print("++4\n");
		}
		catch(Error e) {
			print("AppError: %s\n", e.message);
			return -1;
		}
//		if(app.get_is_remote() && _fileargs == null) {
//			app.activate();
//			return 0;
//		}
print("++5\n");
		return app.run(args);
print("++6\n");
	}
}

