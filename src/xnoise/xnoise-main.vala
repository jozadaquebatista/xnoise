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
	private static Main _instance;

	public MainWindow main_window;
	public TrackList tl;
	public TrackListModel tlm;
	public PluginLoader plugin_loader;
	public GstPlayer gPl;

	public Main() {

		Xnoise.initialize();

		check_database_and_tables();

		_instance = this;

		gPl = new GstPlayer();

		plugin_loader = new PluginLoader(ref this);
		tlm = new TrackListModel();
		tl = new TrackList();
		main_window = new MainWindow(ref this);

		plugin_loader.load_all();

		foreach(string name in par.get_string_list_value("activated_plugins")) {
			if(plugin_loader.activate_single_plugin(name))
				print("%s plugin is activated.\n", name);
		}

		connect_signals();

		par.set_start_parameters_in_implementors();
	}

	private void connect_signals() {
		gPl.sign_eos.connect(() => { // handle endOfStream signal from gst player
			global.handle_eos();
			/*
			main_window.change_song(Direction.NEXT, true);
			*/
		});
		gPl.sign_tag_changed.connect(main_window.set_displayed_title);
		gPl.sign_video_playing.connect( () => { //handle stop signal from gst player
			if(!main_window.fullscreenwindowvisible)
				main_window.tracklistnotebook.set_current_page(1);
		});

		main_window.sign_pos_changed.connect((main_window, fraction) => {
			gPl.gst_position = fraction;
		});
		Posix.signal(Posix.SIGQUIT, on_posix_finish); // write data to db on posix quit signal
		Posix.signal(Posix.SIGTERM, on_posix_finish); // write data to db on posix term signal
		Posix.signal(Posix.SIGKILL, on_posix_finish); // write data to db on posix kill signal
	}

	private void check_database_and_tables() {
		//creating db instance and destroying it will create a db file and tables
		var dbc = new DbCreator();
		dbc = null;
	}

	public void add_track_to_gst_player(string uri) {
		print("add_track_to_gst_player\n");
		global.current_uri = uri;
		global.track_state = TrackState.PLAYING;
		//this.gPl.playSong();
	}

	public static Main instance() {
		if (_instance == null)
			_instance = new Main();
		return _instance;
	}

	private static void on_posix_finish(int signal_number) {
		//print("Posix signal received (%d)\ncleaning up...\n", signal_number);
		instance().quit();
	}

	private void save_activated_plugins() {
		//print("\nsaving activated plugins...\n");
		string[]? activatedplugins = {};
		foreach(string name in this.plugin_loader.plugin_htable.get_keys()) {
			if(this.plugin_loader.plugin_htable.lookup(name).activated)
				activatedplugins += name;
		}
		if(activatedplugins.length<=0)
			activatedplugins = null;
		par.set_string_list_value("activated_plugins", activatedplugins);
	}

	private string[] final_tracklist = null;
	public void save_tracklist() {
		final_tracklist =
		    this.main_window.trackList.tracklistmodel.get_all_tracks();
		var dbwr = new DbWriter();
		dbwr.write_final_tracks_to_db(final_tracklist);
		final_tracklist = null;
	}

	public void quit() {
		if(main_window.is_fullscreen) //TODO: Make this work right
			this.main_window.window.unfullscreen();
		this.gPl.stop();
		this.save_tracklist();
		this.save_activated_plugins();
		par.write_all_parameters_to_file();
		par = null;
		print ("closing...\n");
		Gtk.main_quit();
	}
}
