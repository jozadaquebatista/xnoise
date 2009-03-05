public class Xnoise.AppStarter : GLib.Object {
	public static Unique.Response message_received_cb(Unique.App sender, int command, 
	                                                  Unique.MessageData message_data, uint time) {
		Main.instance().main_window.window.present();
		Main.instance().main_window.add_uris_to_tracklist(message_data.get_uris()); 
		return Unique.Response.OK;
	}

	public static int main (string[] args) {
		var opt_context = new OptionContext ("xnoise");
		opt_context.set_description("xnoise is a media player for audio files. \nIt is always running in a unique instance and if music files are clicked, these can be automatically added to xnoise. \nIt is also possible to add songs via commandline.\n");
		opt_context.set_help_enabled (true);
		
		try {
			opt_context.parse (ref args);
		} catch (OptionError e) {
			print("%s\n", e.message);
			print("Run '%s --help' to see a full list of available command line options.\n", Environment.get_prgname ());
			return 1;
		}

		Gtk.init(ref args);
		Unique.App app;
		AppStarter app_starter = new AppStarter();
		app = new Unique.App.with_commands("org.gnome.xnoise", "xnoise", null);
		int i = 0;

		string[] uris = new string[args.length-1];
		PatternSpec psOgg = new PatternSpec("*.ogg");
		PatternSpec psMp3 = new PatternSpec("*.mp3"); 
		PatternSpec psWav = new PatternSpec("*.wav"); 

		foreach(string arg in args) { //TODO: Test this; this should handle uris and paths
			if(GLib.FileUtils.test(arg, GLib.FileTest.IS_REGULAR) & 
			  (i>0) & //arg 0 is xnoise
			  (psWav.match_string(arg) | psOgg.match_string(arg) | psMp3.match_string(arg))) {
				uris[i-1] = arg;
			}
			i++;
		}

		if (app.is_running) {
			if(uris.length > 0) {
				print("Adding tracks to the running instance of xnoise!\n");
			}
			else {
				print("There is already an instance of xnoise running!\n");
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
			Main vPl = Main.instance();
			app.watch_window((Gtk.Window)vPl.main_window.window);
			app.message_received += app_starter.message_received_cb;

			vPl.main_window.window.show_all();
			
			vPl.main_window.add_uris_to_tracklist(uris);
			
			Gtk.main();
			app = null;
		}
		return 0;
	}
}
