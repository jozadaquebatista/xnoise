/* xnoise-main.vala
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

public class Xnoise.Main : GLib.Object {
	public MainWindow main_window;
	public PluginLoader plugin_loader;
	internal GstPlayer gPl;
	private static Main _instance;
	public Plugin plugin;
	
	public Main() {
		check_database_and_tables();

		gPl = new GstPlayer();

		main_window = new MainWindow();

		plugin_loader = new PluginLoader();
        plugin_loader.plugin_available += on_plugin_loaded;
		plugin_loader.load();
//        plugin = (Plugin)plugin_loader.new_object();
		IPlugin plug = plugin_loader.plugin_hash.lookup("Test");
        plug.activate(ref this);
        
		connect_signals();

		Params paramter = Params.instance(); 
		paramter.read_from_file(); 
	}

	public void printa() {
		print("jjjjjjjjjjjjjjjjjj\n");
	}

	private void on_plugin_loaded (PluginLoader plugin_loader, IPlugin plugin) {
		print("plugin loaded and in main\n");
		plugin.notify["available"] += this.on_plugin_notify;
	}

	private void on_plugin_notify() {
		print("available signal\n");
	}

	private void connect_signals() {
		gPl.sign_song_position_changed += (gPl, pos, len) => {
				main_window.progressbar_set_value(pos, len);
		};
		gPl.sign_eos += () => { //handle endOfStream signal from gst player
			main_window.change_song(Direction.NEXT, true);
			main_window.progressbar_set_value(0, 0);
			main_window.songProgressBar.set_text("00:00 / 00:00");;
		};
		gPl.sign_stopped += () => { //handle stop signal from gst player
			main_window.playpause_button_set_play_picture(); 
			main_window.progressbar_set_value(0, 0);
			main_window.songProgressBar.set_text("00:00 / 00:00");;
		};
		gPl.sign_tag_changed += main_window.set_displayed_title;
		gPl.sign_tag_changed += main_window.albumimage.find_album_image;

		//TODO: if the volume change is handled from main window an unlimited number of instances of Main is created. Why?
		main_window.sign_volume_changed += (main_window, fraction) => { //handle volume slider change
			main_window.current_volume = fraction; //future
			gPl.volume = fraction; 
			gPl.playbin.set("volume", fraction); //current volume
		};
		main_window.sign_pos_changed += (main_window, fraction) => {
			gPl.gst_position = fraction;
		};
		Posix.signal(Posix.SIGQUIT, on_posix_finish); //write data to db on posix quit signal
		Posix.signal(Posix.SIGTERM, on_posix_finish); //write data to db on posix term signal
		Posix.signal(Posix.SIGKILL, on_posix_finish); //write data to db on posix kill signal
	}
	
	private string dbFileName() {
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise", "db.sqlite", null);
	}
	
	private void check_database_and_tables() {
		if(!GLib.FileUtils.test(dbFileName(), FileTest.EXISTS)) {
			stderr.printf("db file is not yet existing....\n");
			DbWriter dbw = new DbWriter(); //creating db instance and destroying it will hopefully give me a db file
			
			stderr.printf("Creating database file...");
			dbw = null;
		}
	}

	public void add_track_to_gst_player(string uri) { //TODO: maybe return bool and check for fail
		this.gPl.Uri = uri;
		this.gPl.playSong ();
		if (this.gPl.playing == false) {
			this.main_window.playpause_popup_image.set_from_stock(Gtk.STOCK_MEDIA_PAUSE, Gtk.IconSize.MENU);
			this.main_window.playpause_button_set_pause_picture ();
			this.gPl.play();
		}
	}

	public static Main instance() {
		if (_instance == null) _instance = new Main();
		return _instance;
	}

	private static void on_posix_finish(int signal_number) {
		print("Posix signal received (%d)\ncleaning up...\n", signal_number);
		instance().quit();
	}


	private string[] final_tracklist; 
	public void save_tracklist() {
		print("write tracks into db....\n");
		final_tracklist = this.main_window.trackList.get_all_tracks();	
		var dbwr = new DbWriter();
		dbwr.write_final_tracks_to_db(final_tracklist);
		final_tracklist = null;
	}

	public void quit() {
		this.gPl.stop();
		this.save_tracklist(); //TODO: use uris? restore!
		Params.instance().write_to_file();
		print ("closing...\n");
		Gtk.main_quit();
	}
}

