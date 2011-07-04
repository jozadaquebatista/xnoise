/* xnoise-notifications.vala
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
 * 	fsistemas
 */
 
using Gtk;
using Notify;

using Xnoise;
using Xnoise.Services;
using Xnoise.PluginModule;


public class Xnoise.Notifications : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private unowned PluginModule.Container _owner;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	
	public string name { 
		get {
			return "notifications";
		} 
	}
	
	private const int IMAGE_SIZE = 64;
	private Notification notification = null;
	private uint timeout;

	construct {
		timeout = 0;
	}

	public bool init() {
		if(!Notify.init("Xnoise media player")) {
			print("libnotify initialization failed\n");
			return false;
		}
		global.uri_changed.connect(on_uri_changed);
		global.sign_restart_song.connect(on_restart);
		global.sign_song_info_required.connect(on_song_info_required);
		global.sign_image_path_small_changed.connect(update_image);
		return true;
	}

	public void uninit() {
		cleanup();
	}

	private void update_image() {
		Gdk.Pixbuf image_pixb = null;
		if(notification == null)
			return;
		if(global.image_path_small != null) { // f.query_exists()) {
			try {
				image_pixb = new Gdk.Pixbuf.from_file(global.image_path_small);//f.get_path());
				if(image_pixb != null) {
					image_pixb = image_pixb.scale_simple(IMAGE_SIZE, IMAGE_SIZE, Gdk.InterpType.BILINEAR);
				}
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		else {
			try {
				image_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_48x48.png");
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		if(image_pixb != null)
			notification.set_icon_from_pixbuf(image_pixb);
	}

	private void on_song_info_required() {
		if(global.current_uri == "" || global.current_uri == null) {
			try {
				if(notification != null) {
					notification.clear_hints();
					notification.close();
				}
				return;
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		show_notification(global.current_uri);
	}
	
	private void on_restart() {
		Idle.add( () => {
			on_uri_changed(global.current_uri);
			return false;
		});
	}
	
	private void on_uri_changed(string? uri) {
		if(timeout != 0) {
			Source.remove(timeout);
			timeout = 0;
		}

		if(uri == "" || uri == null) {
			try {
				if(notification != null) {
					notification.clear_hints();
					notification.close();
				}
				return;
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}

		timeout = Timeout.add_seconds(1, () => {
			show_notification(uri);
			return false;
		});
	}
	
	private void show_notification(string newuri) {
		string uri = newuri;
		string album, artist, title;
		Gdk.Pixbuf image_pixb = null;
		string basename = null;
		File file = File.new_for_uri(newuri);
		
		if(!gst_player.is_stream)
			basename = file.get_basename();
		
		if(global.current_artist != null) {
			artist = remove_linebreaks(global.current_artist);
		}
		else {
			artist = "unknown artist";
		}
		
		if(global.current_title != null) {
			title = remove_linebreaks(global.current_title);
		}
		else {
			title = "unknown title";
		}
		
		if(global.current_album != null) {
			album = remove_linebreaks(global.current_album);
		}
		else {
			album = "unknown album";
		}
		
		File f = get_albumimage_for_artistalbum(artist, album, "medium");
		string summary = title;
		string body = _("by") +
		              " " + Markup.printf_escaped("%s", artist) + " \n" +
		              _("on") + 
		              " " + Markup.printf_escaped("%s", album);
		if(notification == null) {
			notification = new Notification(summary, body, null, null);
		}
		else {
			notification.clear_hints();
			notification.update(summary, body, "");
		}
		if(f.query_exists()) {
			try {
				image_pixb = new Gdk.Pixbuf.from_file(f.get_path());
				if(image_pixb != null) {
					image_pixb = image_pixb.scale_simple(IMAGE_SIZE, IMAGE_SIZE, Gdk.InterpType.BILINEAR);
				}
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		else {
			try {
				image_pixb = new Gdk.Pixbuf.from_file(Config.UIDIR + "xnoise_48x48.png");
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
		if(image_pixb != null) {
			notification.set_icon_from_pixbuf(image_pixb);
		}
		notification.set_urgency(Notify.Urgency.NORMAL);
		notification.set_timeout(2000);
		show();
	}

	public void show() {
		try {	
			notification.show();
		}
		catch(GLib.Error e) {
			 print("%s\n", e.message); 
		}
	}

	private void cleanup() {
		if(notification != null) {
			try {
				notification.close();
				notification = null;
			}
			catch(GLib.Error e) {
				print("%s\n", e.message);
			}
		}
	}

	~Notifications() {
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
}

