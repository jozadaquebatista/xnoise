/* xnoise-title-to-decoration.vala
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
 
using Xnoise;
using Gtk;

public class TitleToDecoration : GLib.Object, IPlugin {
	public Xnoise.Main xn { get; set; }
	private Gtk.Button b;
	public string name { 
		get {
			return "TitleToDecoration";
		} 
	}
//    construct { // In this case it has to be a "construct" method
//    	print("TestPlugin construction\n");
//    }
    
	public bool init() {
		xn.gPl.sign_tag_changed += write_title_to_decoration;
    	return true;
    }

	private void write_title_to_decoration(string newuri) {
		string text, album, artist, title;
		string basename = null;
		File file = File.new_for_uri(newuri);
		basename = file.get_basename();
		if(xn.gPl.currentartist!=null) {
			artist = xn.gPl.currentartist;
		}
		else {
			artist = "unknown artist";
		}
		if (xn.gPl.currenttitle!=null) {
			title = xn.gPl.currenttitle;
		}
		else {
			title = "unknown title";
		}
		if (xn.gPl.currentalbum!=null) {
			album = xn.gPl.currentalbum;
		}
		else {
			album = "unknown album";
		}
		if((newuri!=null) && (newuri!="")) {
			text = "%s %s %s %s %s ".printf( 
				title, 
				_("by"), 
				artist, 
				_("on"), 
				album
				);
			if(album=="unknown album" && 
			   artist=="unknown artist" && 
			   title=="unknown title") 
			   	text = Markup.printf_escaped("%s", basename);
		}
		else {
			if((!xn.gPl.playing)&&
				(!xn.gPl.paused)) {
				text = "xnoise media player";
			}
			else {
				text = "%s %s %s %s %s ".printf( 
					_("unknown title"), 
					_("by"), 
					_("unknown artist"),
					_("on"), 
					_("unknown album")
					);
			}
		}
		xn.main_window.window.set_title(text);
	}
	
	~TitleToDecoration() {
		xn.main_window.window.set_title("xnoise media player");
	}

	private void on_b_clicked(Gtk.Button sender) {
		sender.label = sender.label + "_1";
	}

	public Gtk.Widget? get_settings_widget() {
		b = new Gtk.Button.with_label("bingo");
		b.clicked+=on_b_clicked;
		return b;
	}

	public bool has_settings_widget() {
		return true;
	} 
}

