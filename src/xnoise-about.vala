/* xnoise-about.vala
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

using GLib;

public class Xnoise.AboutDialog : Gtk.AboutDialog {
	const string[] _authors = {"Jörn Magens", 
	                           null
	                          };
	const string _copyright = "Copyright \xc2\xa9 2008, 2009 Jörn Magens";
	const string _program_name = "xnoise";
	const string _version = "0.01";
	const string _website = "http://code.google.com/p/xnoise/";

	public AboutDialog() {
		string contents;
		try {
			GLib.FileUtils.get_contents (GLib.Path.build_filename(Config.LICENSEDIR + "COPYING"), out contents); //TODO: add LICENSEDIR to vapi and to /src/Makefile
			license = contents;
		}
		catch(GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		try {
			var pixbuf = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_48x48.png");
			logo = pixbuf;
		}
		catch(GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		try {
			set_icon_from_file(Config.UIDIR + "xnoise_16x16.png");
		}
		catch(GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		this.authors      = _authors;
		this.program_name = _program_name;
		this.version      = _version;
		this.website      = _website;
		this.copyright    = _copyright;
	}
}

