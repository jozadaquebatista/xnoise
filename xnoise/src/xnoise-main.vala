/* xnoise-main.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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
	private static Main _instance = null;

	public MainWindow main_window;
	public TrackList tl;
	public TrackListModel tlm;
	public PluginLoader plugin_loader;
	public GstPlayer gPl;
	public static bool show_plugin_state;
	public static bool no_plugins;

	public Main() {
		bool is_first_start;
		Xnoise.initialize(out is_first_start);

		check_database_and_tables();

		_instance = this;

		gPl = new GstPlayer();

		plugin_loader = new PluginLoader();
		tlm = new TrackListModel();
		tl = new TrackList();
		main_window = new MainWindow();

		userinfo = new UserInfo(main_window.show_status_info);

		if(!no_plugins) {
			plugin_loader.load_all();

			foreach(string name in par.get_string_list_value("activated_plugins")) {
				if(!plugin_loader.activate_single_plugin(name)) {
					print("\t%s plugin failed to activate!\n", name);
				}
			}

			if(show_plugin_state) print(" PLUGIN INFO:\n");
			foreach(string name in plugin_loader.plugin_htable.get_keys()) {
				if((show_plugin_state)&&(plugin_loader.plugin_htable.lookup(name).loaded))
					if(show_plugin_state) print("\t%s loaded\n", name);
				else {
					print("\t%s NOT loaded\n\n", name);
					continue;
				}
				if((show_plugin_state)&&(plugin_loader.plugin_htable.lookup(name).activated)) {
					print("\t%s activated\n", name);
				}
				else {
					if(show_plugin_state) print("\t%s NOT activated\n", name);
				}

				if(show_plugin_state) print("\n");
			}
		}

		connect_signals();

		par.set_start_parameters_in_implementors();
		
		if(is_first_start)
			main_window.ask_for_initial_media_import();
	}

	private void connect_signals() {
		Posix.signal(Posix.SIGQUIT, on_posix_finish); // write data to db on posix quit signal
		Posix.signal(Posix.SIGTERM, on_posix_finish); // write data to db on posix term signal
		Posix.signal(Posix.SIGKILL, on_posix_finish); // write data to db on posix kill signal
	}

	private void check_database_and_tables() {
		//creating db instance and destroying it will create a database and the tables
		DbCreator dbc = null;
		try {
			dbc = new DbCreator();
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
		dbc = null;
	}

	public void add_track_to_gst_player(string uri) {
		// TODO: update this function
		print("add_track_to_gst_player\n");
		global.current_uri = uri;
		global.track_state = GlobalAccess.TrackState.PLAYING;
		//this.gPl.playSong();
	}

	public static Main instance {
		get {
			if(_instance == null)
				_instance = new Main();
			return _instance;
		}
	}

	private static void on_posix_finish(int signal_number) {
		//print("Posix signal received (%d)\ncleaning up...\n", signal_number);
		instance.quit();
	}

	private void save_activated_plugins() {
		//print("\nsaving activated plugins...\n");
		string[]? activatedplugins = {};
		foreach(string name in this.plugin_loader.plugin_htable.get_keys()) {
			if(this.plugin_loader.plugin_htable.lookup(name).activated)
				activatedplugins += name;
		}
		if(activatedplugins.length <= 0)
			activatedplugins = null;
		par.set_string_list_value("activated_plugins", activatedplugins);
	}

	private string[] final_tracklist = null;
	public void save_tracklist() {
		final_tracklist = this.main_window.trackList.tracklistmodel.get_all_tracks();
		DbWriter dbw = null;
		try {
			dbw = new DbWriter();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		
		try {
			dbw.write_final_tracks_to_db(final_tracklist);
		}
		catch(Error err) {
			print("%s\n", err.message);
		}
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
