using GLib;

public class Xnoise.AboutDialog : Gtk.AboutDialog {
	const string[] _authors = {"Jörn Magens", 
	                           null
	                          };
	const string   _copyright = "Copyright \xc2\xa9 2008 Jörn Magens";
	const string   _program_name = "xnoise";
	const string   _version = "0.01";
	const string   _website = "website: not existing";

	public AboutDialog() {
		string contents;
		try {
			GLib.FileUtils.get_contents (GLib.Path.build_filename ("COPYING"), out contents);
			license = contents;
		}
		catch (GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		try {
			var pixbuf = new Gdk.Pixbuf.from_file (Config.UIDIR + "/ente.png");
			logo = pixbuf;
		}
		catch (GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		try {
			set_icon_from_file (Config.UIDIR + "/ente.png");
		}
		catch (GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		this.authors        = _authors;
		this.program_name   = _program_name;
		this.version        = _version;
		this.website        = _website;
		this.copyright      = _copyright;
	}
}

