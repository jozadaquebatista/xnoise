/* xnoise-about.vala
 *
 * Copyright (C) 2009  ert
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

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

