/* xnoise-app-starter.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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

public class Xnoise.AppStarter {
	public static Unique.Response on_message_received(Unique.App sender,
	                                                  int command,
	                                                  Unique.MessageData message_data,
	                                                  uint time) {
		xn.main_window.present();
		xn.tl.tracklistmodel.add_uris(message_data.get_uris());
		return Unique.Response.OK;
	}

	public static Main xn;

	static bool _plugininfo;
	static bool _noplugins;
	static bool _reset;
	static bool _version;
	[CCode (array_length = false, array_null_terminated = true)]
	[NoArrayLength]
	static string[] _fileargs;

	const OptionEntry[] options = {
		{ "version", 'V', 0, OptionArg.NONE, ref _version, "Show the application's version.", null },
		{ "plugin-info", 'p', 0, OptionArg.NONE, ref _plugininfo, "Show loaded and activated plugins on app start.", null },
		{ "no-plugins", 'N', 0, OptionArg.NONE, ref _noplugins, "Start without loding any plugins.", null },
		{ "reset", 'R', 0, OptionArg.NONE, ref _reset, "Reset all settings.", null },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref _fileargs, null, "FILE..." },
		{null}
	};

	public static int main(string[] args) {
		//		Gdk.threads_init();
		GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
		GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
		Environment.set_application_name(Config.GETTEXT_PACKAGE);
		//Environment.atexit(mem_profile); This can be used if xnoise is compiled with new memory statistic switch

		var opt_context = new OptionContext("- Xnoise Media Player");
		opt_context.set_description("Xnoise is a media player for Gtk+. It uses the gstreamer framework. \nMore information on the project website: \nhttp://code.google.com/p/xnoise/\n");
		opt_context.set_help_enabled(true);
		opt_context.add_main_entries(options, null);
		try {
			opt_context.parse(ref args);
		}
		catch(OptionError e) {
			print("%s\n", e.message);
			print("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 0;
		}
		if(_reset) {
			print("Reset not implemented, yet.\n");
			return 0;
		}
		if(_version) {
			print("xnoise %s\n", Config.PACKAGE_VERSION);
			return 0;
		}
		if(_plugininfo) {
			Main.show_plugin_state = true;
		}
		if(_noplugins) {
			Main.no_plugins = true;
		}
		Gtk.init(ref args);
		Gst.init(ref args);
		Unique.App app;
		var app_starter = new AppStarter();
		app = new Unique.App.with_commands("org.gnome.xnoise", "xnoise", null);
		string[] uris = {};
		File f = null;
		string mime;
		var psVideo = new PatternSpec("video*");
		var psAudio = new PatternSpec("audio*");
		string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		if(_fileargs != null) {
			foreach(string s in _fileargs) {
				f = File.new_for_commandline_arg(s); //fileargs[i]);
				if(f == null) continue;
				if(!f.query_exists(null)) continue;
				string urischeme = f.get_uri_scheme();
				string content = null;
				if(urischeme=="file") {
					try {
						FileInfo info = f.query_info(attr,
													 FileQueryInfoFlags.NONE,
													 null);
						content = info.get_content_type();
						mime = g_content_type_get_mime_type(content);

						if((psAudio.match_string(mime))||
						   (psVideo.match_string(mime))) {
							uris += f.get_uri();
						}
					}
					catch(GLib.Error e) {
						print("Argerror: %s\n", e.message);
						continue;
					}
				}
			}
		}
		uris += null; //Null terminated array. Is adding null necessary?

		if(app.is_running) {
			if(uris.length > 0) {
				print("Adding tracks to the running instance of xnoise!\n");
			}
			else {
				print("Showing the running instance of xnoise.\n");
			}
			Unique.Command command;
			Unique.Response response;
			Unique.MessageData message_data = new Unique.MessageData();
			command = Unique.Command.ACTIVATE;
			message_data.set_uris(uris);
			response = app.send_message(command, message_data);
			app = null;

			if (response != Unique.Response.OK)
				print("singleton app response fail.\n");
		}
		else {
			xn = Main.instance;
			app.watch_window((Gtk.Window)xn.main_window);
			app.message_received.connect(app_starter.on_message_received);

			xn.main_window.show_all();

			xn.tl.tracklistmodel.add_uris(uris);

			//Gdk.threads_enter();
			Gtk.main();
			//Gdk.threads_leave();
			app = null;
		}
		return 0;
	}
}
