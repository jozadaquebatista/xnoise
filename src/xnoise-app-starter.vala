/* xnoise-app-starter.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
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
 
public class Xnoise.AppStarter : GLib.Object {
	public static Unique.Response on_message_received(Unique.App sender, 
	                                                  int command, 
	                                                  Unique.MessageData message_data, 
	                                                  uint time) {
		xn.main_window.window.present();
		xn.main_window.add_uris_to_tracklist(message_data.get_uris()); 
		return Unique.Response.OK;
	}

	public static Main xn;

	public static int main (string[] args) {
		var opt_context = new OptionContext("[FILE] [FILE]..."); //TODO: Do some reset options
		opt_context.set_summary("Xnoise is a media player for audio files.");
		opt_context.set_description("http://code.google.com/p/xnoise/\n");
		opt_context.set_help_enabled (true);
		try {
			opt_context.parse (ref args);
		} catch (OptionError e) {
			print("%s\n", e.message);
			print("Run '%s --help' to see a full list of available command line options.\n", Environment.get_prgname ());
			return 1;
		}
//		Gdk.threads_init();
		Gtk.init(ref args);
		Unique.App app;
		var app_starter = new AppStarter();
		app = new Unique.App.with_commands("org.gnome.xnoise", "xnoise", null);
		string[] uris = {};
		File file;
		FileType filetype;
		weak string mime;
		var psAudio = new PatternSpec("audio*");
		string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;

		for(int j=1;j<args.length;j++) { //TODO: Test this; this should handle uris and paths
			try {
				file = File.new_for_commandline_arg(args[j]);
				FileInfo info = file.query_info(
					                attr, 
					                FileQueryInfoFlags.NONE, 
					                null);
				filetype = info.get_file_type();
				string content = info.get_content_type();
				mime = g_content_type_get_mime_type(content);
			}
			catch(GLib.Error e){
				stderr.printf("argerror: %s\n", e.message);
				return 1;
			}	
			
			if((filetype==GLib.FileType.REGULAR)&
			   (psAudio.match_string(mime))) {
			   	uris += file.get_uri();
			}
		}
		uris += null;
		
		if (app.is_running) {
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
			xn = Main.instance();
			app.watch_window((Gtk.Window)xn.main_window.window);
			app.message_received += app_starter.on_message_received;

			xn.main_window.window.show_all();
			
			xn.main_window.add_uris_to_tracklist(uris);
			
			Gtk.main();
			app = null;
		}
		return 0;
	}
}
