/* xnoise-about.vala
 *
 * Copyright (C) 2009  Jörn Magens
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

using GLib;

public class Xnoise.AboutDialog : Gtk.AboutDialog {
	const string COPYRIGHT = "Copyright \xc2\xa9 2008, 2009 Jörn Magens";
	const string PROGRAM_NAME = "xnoise";
//	const string VERSION = "0.01"; //TODO: This should be dynamic
	const string WEBSITE = "http://code.google.com/p/xnoise/";

	public AboutDialog() {
		string contents;
		try {
			GLib.FileUtils.get_contents(GLib.Path.build_filename(Config.LICENSEDIR + "COPYING"), out contents); 
			license = contents;
		}
		catch(GLib.Error e) {
			stderr.printf("%s\n", e.message);
		}

		string _authors;
		try {
			GLib.FileUtils.get_contents(GLib.Path.build_filename(Config.LICENSEDIR + "AUTHORS"), out _authors); 
			this.authors = _authors.split("\n", 500);
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

		this.program_name = PROGRAM_NAME;
//		this.version      = VERSION;
		this.website      = WEBSITE;
		this.copyright    = COPYRIGHT;
	}
}

