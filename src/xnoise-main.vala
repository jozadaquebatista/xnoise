/* xnoise-main.vala
 *
 * Copyright (C) 2009  Jörn Magens
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

public class Xnoise.Main : GLib.Object {
	public MainWindow main_window;
	internal GstPlayer gPl;
	private static Main _instance;

	public Main() {
		check_database_and_tables();

		gPl = new GstPlayer();

		main_window = new MainWindow();

		connect_signals();

		Params paramter = Params.instance(); 
		paramter.read_from_file(); 
	}

	private void connect_signals() {
		gPl.sign_song_position_changed += (gPl, pos, len) => {
				main_window.progressbar_set_value(pos, len);
		};
		gPl.sign_eos += () => { //handle endOfStream signal from gst player
			main_window.change_song(Direction.NEXT);
			main_window.progressbar_set_value(0, 0);
			main_window.songProgressBar.set_text("00:00 / 00:00");;
		};
		gPl.sign_stopped += () => { //handle stop signal from gst player
			main_window.playpause_button_set_play_picture(); 
			main_window.progressbar_set_value(0, 0);
			main_window.songProgressBar.set_text("00:00 / 00:00");;
		};
		gPl.sign_uri_changed += (s, uri) => {
			main_window.set_displayed_title(uri); //TODO: maybe change this to a gst parsed 
			                                      //      version so also streams will be handled right
		};
//		gPl.sign_state_changed += (s, newstate) => {
//			switch(newstate) {
//				case (GstPlayerState.PLAY):
//					main_window.trackList.update_play_status_for_playlisttitle(false); 
//					break;
//				case (GstPlayerState.PAUSE):
//					main_window.trackList.update_play_status_for_playlisttitle(true); 
//					break;
//			} 
//			print("update tracklist\n");
//		};

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
		DbWriter dbw;
		if(!GLib.FileUtils.test(dbFileName(), FileTest.EXISTS)) {
			dbw = new DbWriter(); //creating db instance and destroying it will give me a db file
			stderr.printf("Creating database file...");
			dbw = null;
		}
		dbw = new DbWriter();
		dbw.check_db_and_tables_exist();
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

	private GLib.List<string> final_tracklist; 
	public void save_tracklist() { //TODO: use uris??
		final_tracklist = new GLib.List<string>();
		print("write tracks into db....\n");
		main_window.trackList.get_track_ids(ref final_tracklist);	
		var dbwr = new DbWriter();
		dbwr.write_final_track_ids_to_db(ref final_tracklist);
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

