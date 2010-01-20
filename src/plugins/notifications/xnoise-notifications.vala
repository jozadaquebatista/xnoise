/* xnoise-notifications.vala
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
 * 	fsistemas
 */
 
using Notify;
using Gtk;

public class Xnoise.Notifications : GLib.Object, IPlugin {
	public Main xn { get; set; }
	public string name { 
		get {
			return "notifications";
		} 
	}
	private static Notification popup;

	public Notifications() { //string title, string artist, string album,Gdk.Pixbuf icon
//		this.title = title;
//		this.artist = artist;
//		this.album = album;
//		this.icon = icon;
		timeout = 0;
		xn.gPl.sign_uri_changed += on_uri_changed;
	}

	public bool init() {
		return true;
	}
	
	uint timeout;
	
	private void on_uri_changed(string uri) {
		if(timeout != 0)
			Source.remove(timeout);

		timeout = Timeout.add_seconds(1, () => {
			show_notification(uri);
			return false;
		});
	}
	
	private void show_notification(string newuri) {
		string text, album, artist, title, genre, location, organization;
		string basename = null;
		File file = File.new_for_uri(newuri);
		if(!xn.gPl.is_stream)
			basename = file.get_basename();
		if(xn.gPl.currentartist!=null) {
			artist = remove_linebreaks(xn.gPl.currentartist);
		}
		else {
			artist = "unknown artist";
		}
		if(xn.gPl.currenttitle!=null) {
			title = remove_linebreaks(xn.gPl.currenttitle);
		}
		else {
			title = "unknown title";
		}
		if(xn.gPl.currentalbum!=null) {
			album = remove_linebreaks(xn.gPl.currentalbum);
		}
		else {
			album = "unknown album";
		}
		if(xn.gPl.currentorg!=null) {
			organization = remove_linebreaks(xn.gPl.currentorg);
		}
		else {
			organization = "unknown organization";
		}
		if(xn.gPl.currentgenre!=null) {
			genre = remove_linebreaks(xn.gPl.currentgenre);
		}
		else {
			genre = "unknown genre";
		}
		if(xn.gPl.currentlocation!=null) {
			location = remove_linebreaks(xn.gPl.currentlocation);
		}
		else {
			location = "unknown location";
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
				if(organization!="unknown organization") 
					text = "%s".printf(organization);
				else if(location!="unknown location") 
					text = "%s".printf(location);
				else
					text = "%s".printf("xnoise media player");
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
		print("%s\n", text);
		string sumary = "<b>" + title + "</b>";
		string body = "by <b>" + artist + "</b> <br /> of <b>" + album + "</b>";

		if(popup == null) {
			popup = new Notification(sumary,body,null,null);
		}
		else {
			popup.update(sumary,body,"");
		}
//		popup.set_icon_from_pixbuf( icon );
		popup.set_urgency(Notify.Urgency.NORMAL);
		popup.set_timeout(1000);
		show();
	}

//	string title; //title of song  
//	string artist; //artist name  
//	string album; //album	
//	Gdk.Pixbuf icon;
	
	
		
	public void show() {
		try {	
			popup.show();
		}
		catch(GLib.Error e) {
			 print("%s\n", e.message); 
		}
	}
	
	~Notifications() {
		print("destruct notifications\n");
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public Gtk.Widget? get_singleline_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public bool has_singleline_settings_widget() {
		return false;
	}
}

