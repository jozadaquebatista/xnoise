/* xnoise-mediawatcher.vala
 *
 * Copyright (C) 2010 softshaker
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
 */


// Mediawatcher is a Plugin that monitors media directories 
// for changes and updates the db respectively

/* TODO
	* handle symlinks
	* test performance, maybe switch to inotify as an option for linux
	* find a well performing facility to automatically add files that were created in the media 
		path while xnoise was not monitoring/running (i have no solution here)
	* handle directory deletions
	* disconnect signal handlers when plugin is unloaded
*/

using Gtk;

public class Xnoise.MediawatcherPlugin : GLib.Object, IPlugin {
	public Mediawatcher watcher;

	public Main xn { get; set; }
	public string name {
		get {
			return "Mediawatcher";
		}
	}

	public bool init() {
		watcher = new Mediawatcher();	
		return true;
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


public class Xnoise.Mediawatcher : GLib.Object {
	private List<DataPair> monitor_list = null;
	private ImportInfoBar iib;
	private Queue<string> queue;
	// the frequency limit to check monitored directories for changes
	private const int monitoring_frequency = 2000;
	
	public Mediawatcher() {
		queue = new Queue<string>();
		
		global.sig_media_path_changed.connect(media_path_changed_cb);
		
		iib = new ImportInfoBar();
		
		setup_monitors();
	}
	
	private class DataPair : GLib.Object{
		public DataPair(string path, FileMonitor monitor) {
			this.path = path;
			this.monitor = monitor;
		}
		
		public FileMonitor monitor;
		public string path;
	}

	/* creates file monitors for all directories in the media path */ 
	private void setup_monitors() {
		monitor_list = new List<DataPair>();
		DbBrowser dbb = null;
		try {
			dbb = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		var mfolders = dbb.get_media_folders();
		
		foreach(string mfolder in mfolders)
			setup_monitor_for_path(mfolder);
	}
	
	private void media_path_changed_cb() {
		//in future, when we are informed of path changes item by item
		//we will be able to remove and add specific monitors 
		if(monitor_list != null) {
			unowned List<DataPair> iter = monitor_list;
			while((iter = iter.next) != null) {
				iter.data.monitor.cancel(); //This seems to necessary
				iter.data.monitor.unref();
			}
			monitor_list.data.monitor.cancel(); //This seems to necessary
			monitor_list.data.monitor.unref();
			monitor_list = null;
		}
		setup_monitors();
	}
	
	/* setup file monitors for a directory and all its subdirectories, reference them and
	 store them in monitor_list */
	private void setup_monitor_for_path(string path) {
		//print("setup_monitor_for_path : %s\n", path);
		try {
			var dir = File.new_for_path(path);
			var monitor = dir.monitor_directory(FileMonitorFlags.NONE);
			monitor.changed.connect(file_changed_cb);
			monitor.set_rate_limit(monitoring_frequency);
			var d = new DataPair(path, monitor);
			monitor.ref();
			monitor_list.append(d);

			monitor_all_subdirs(dir);
		}
		catch(IOError e) {
			print("Could not setup file monitoring for \'%s\': Error %s\n", path, e.message);
		}
	}

	private void remove_dir_monitors(string path) {
		monitor_list.foreach((data) => {
			unowned List<DataPair> iter = monitor_list;
			while(iter != null) {	
				if(iter.data.path.has_prefix(path)) {
					print("removed monitor %s", iter.data.path);
					iter.data.monitor.cancel(); //This seems to necessary
					iter.data.monitor.unref();
					unowned List<DataPair> temp = iter.next;
					iter.delete_link(iter);
					iter = temp;
					print("REMOVE\n");
				}
				else iter = iter.next;
			}
		});
	}
	
	private bool monitor_in_list(string path) {
		bool success = false;
		monitor_list.foreach((data) => {
			unowned List<DataPair> iter = monitor_list;
			while(iter != null) {
				//print("!!%s\n", iter.data.path);
				if(iter.data.path == path) success = true;
				iter = iter.next;
			}
		});
		return success;
	}
			
	private void handle_deleted_file(File file) {
		//if the file was a directory it is in monitor_list
		//search for filepath in monitor list and remove it
		//remove all its subdirs from monitor list
		//in the course of that try to remove the uri of every file 
		//that was in those directories from the db 
		//(we might need to store the directory of files in the db)
		
		print("File deleted: \'%s\'\n", file.get_path());
//		DbWriter dbw = null;
		if(dbw == null) {
			try {
				dbw = new DbWriter();
			
			}
			catch(Error e) {
				print("%s\n", e.message);
				return;
			}
		}
		if(monitor_in_list(file.get_path())) {
			print("%s was a directory\n", file.get_path());
			DbBrowser dbb = null;
			try {
				dbb = new DbBrowser();
			}
			catch(Error e) {
				print("%s\n", e.message);
				return;
			}
			

			var search_string = file.get_uri();
			search_string = search_string.replace("%", "\\%");
			search_string = search_string.replace("_", "\\_");
			search_string += "/%";
			var results = dbb.get_uris(search_string);
			foreach (string a in results) {
				print("deleting %s from db\n", a);
				dbw.delete_uri(a);
			}
		}
			
		dbw.delete_uri(file.get_uri());
		remove_dir_monitors(file.get_path());
	
		if(Main.instance.main_window.mediaBr != null)
			Main.instance.main_window.mediaBr.change_model_data();
		Idle.add( () => {
			dbw = null;
			return false;
		});
	}

	private void handle_created_file(File file) {
//		print("\'%s\' has been created recently, updating db...\n", file.get_path());
		string buffer = file.get_path();
//		Timer t = new Timer();
//		t.reset();
//		ulong microseconds;
//		t.start();
		queue.push_tail(buffer);
//		t.stop();
//		double buf = t.elapsed(out microseconds);
//		print("\nelapsed: %lf ; %u\n", buf, (uint)microseconds);
		if(queue.length > 0)
			starter_method_async();
	}
	
	private DbWriter dbw = null;
	
	private async void starter_method_async() {
		if(async_running == true)
			return;

//print("entering loop\n");
		while(queue.length > 0) {
			async_running = true;
			yield async_worker();
		}
		Idle.add( () => {
			dbw = null;
			return false;
		});
		Idle.add( () => {
			if(Main.instance.main_window.mediaBr != null)
				Main.instance.main_window.mediaBr.change_model_data();
			return false;
		});
//print("leaving loop\n");
		async_running = false;
	}

	private bool async_running = false;

	private async void async_worker() {
		// todo : this seems to be a blocker for the gui
		// doing this async in a source function and taking data from a queue improved the situation slightly
		string? path = queue.peek_head();
		if(path == null)
			return;
		print("\nHANDLE QUEUE for %s\n", path);
		File file = File.new_for_path(path);
		queue.pop_head();
		if(dbw == null) {
			try {
				dbw = new DbWriter();
			}
			catch(Error e1) {
				print("%s\n", e1.message);
				return;
			}
		}
		var mi = new MediaImporter();
		try {
			var info = file.query_info(FILE_ATTRIBUTE_STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
		
			if(info.get_file_type() == FileType.REGULAR) mi.add_single_file(file.get_uri(), ref dbw);	
			else if (info.get_file_type() == FileType.DIRECTORY) {
				mi.add_local_tags(file, ref dbw);
				setup_monitor_for_path(file.get_path());
			}
		} 
		catch(Error e2) {
			print("Adding of \'%s\' failed: Error: %s\n", file.get_path(), e2.message);
		}
	}

//	private void async_worker() {
//		// todo : this seems to be a blocker for the gui
//		// doing this async in a source function and taking data from a queue improved the situation slightly
//		string? path = queue.peek_head();
//		if(path == null)
//			return;
//		print("\nHANDLE QUEUE for %s\n", path);
//		File file = File.new_for_path(path);
//		queue.pop_head();
//		DbWriter dbw = null;
//		try {
//			dbw = new DbWriter();
//		}
//		catch(Error e) {
//			print("%s\n", e.message);
//			return;
//		}
//		var mi = new MediaImporter();
//		try {
//			var info = file.query_info(FILE_ATTRIBUTE_STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
//		
//			if(info.get_file_type() == FileType.REGULAR) mi.add_single_file(file.get_uri(), ref dbw);	
//			else if (info.get_file_type() == FileType.DIRECTORY) {
//				mi.add_local_tags(file, ref dbw);
//				setup_monitor_for_path(file.get_path());
//			}
//			Idle.add( () => {
//				if(Main.instance.main_window.mediaBr != null)
//					Main.instance.main_window.mediaBr.change_model_data();
//				return false;
//			});
//		} 
//		catch(Error e) {
//			print("Adding of \'%s\' failed: Error: %s\n", file.get_path(), e.message);
//		}
//	}

	private void file_changed_cb(FileMonitor sender, File file, File? other_file, FileMonitorEvent event_type) {
		if(!global.media_import_in_progress) {
			print("%s\n", event_type.to_string());
			if(event_type == FileMonitorEvent.CREATED)  // TODO: monitor removal of folders, too
				if(file != null) 
					handle_created_file(file);
			if(event_type == FileMonitorEvent.DELETED) 
				handle_deleted_file(file);
		}
	}

	/* sets up file monitors for all subdirectories of a directory, references them and
	 stores them in monitor_list */
	private void monitor_all_subdirs(File f) {
		try {
			var enumerator = f.enumerate_children(FILE_ATTRIBUTE_STANDARD_TYPE + "," +
			                                      FILE_ATTRIBUTE_STANDARD_NAME,
			                                      0,
			                                      null);
			FileInfo info;
			while((info = enumerator.next_file(null)) != null) {
				if(info.get_file_type() == FileType.DIRECTORY) {
					var temp_f = File.new_for_path(GLib.Path.build_filename(f.get_path(), info.get_name(), null));
	
					var temp_mon = temp_f.monitor_directory(FileMonitorFlags.NONE);
					temp_mon.changed.connect(file_changed_cb);
					temp_mon.set_rate_limit(monitoring_frequency);
					var d = new DataPair(temp_f.get_path(), temp_mon);
					temp_mon.ref();
					monitor_list.append(d);
				
					monitor_all_subdirs(temp_f);
				}
			}
		}
		catch(IOError e) {
			print("Setting up file monitoring: Error: %s\n", e.message);
		}
		catch(Error e) {
			print("Setting up file monitoring: Error: %s\n", e.message);
		}
	}
}


/* 
	An info bar which shows us when import of new media items is in progress and which, 
	after notify_timeout_value of milliseconds without new importing activity,
	tells us how many items have been added / tells us artist and title of the file if was a
	single file only.
 */
private class Xnoise.ImportInfoBar : GLib.Object {
	private Gtk.InfoBar bar = null;
	private Label bar_label = null;
	private Button bar_close_button = null;
	private ProgressBar bar_progress = null;
	
	private bool shown;
	private int import_count;
	
	private string last_uri  = null;
	
	private uint import_notify_timeout;
	private const int notify_timeout_value = 2500;
	
	public ImportInfoBar() {
		import_count = 0;
		bar = new Gtk.InfoBar();

		bar_label = new Label("");
		bar_label.height_request = 20;
		var content_area = bar.get_content_area();
		((Container)content_area).add(bar_label);
		bar_label.show();
		
		var close_image = new Gtk.Image.from_stock(Gtk.STOCK_CLOSE, Gtk.IconSize.MENU);
		bar_close_button = new Gtk.Button();
		bar_close_button.set_image(close_image);
		bar_close_button.set_relief(Gtk.ReliefStyle.NONE);
		close_image.show();
		bar_close_button.set_size_request(0, 0);
		bar.add_action_widget(bar_close_button, 0);
		
		bar_progress = new ProgressBar();
		bar_progress.pulse_step = 0.01;
		bar_progress.bar_style = ProgressBarStyle.CONTINUOUS;
		((Container)content_area).add(bar_progress);
		
		bar_close_button.clicked.connect((a) => {
			bar.hide();
			import_count = 0;
			shown = false;
		});
		
		global.sig_item_imported.connect(on_import);
		
		/*global.notify["media-import-in-progress"].connect( () => {
			if(global.media_import_in_progress == false) {
				on_countdown_done();
			}
		});*/
	}
	
	private void on_ongoing_import(string uri) {
		import_count++;
		last_uri = null;
		if(bar_progress.get_realized())
			bar_progress.pulse();
		
		GLib.Source.remove (import_notify_timeout);
		import_notify_timeout = Timeout.add(notify_timeout_value, on_countdown_done);
	}
		
	private void on_import(string uri) {
		if(!global.media_import_in_progress) {
			if(bar_label == null)
				bar_label = new Label("");
	
			bar_label.set_text("Adding new files to the media database...");
		

		
			import_count++;
			last_uri = uri;
		
			if (shown == false) {
				Main.instance.main_window.display_info_bar(bar);
				shown = true;
			}
		
			bar_close_button.hide();
			bar_progress.show();
			bar_progress.pulse();
		
			bar.show();
		
			import_notify_timeout = Timeout.add(notify_timeout_value, on_countdown_done);
		
			global.sig_item_imported.disconnect(on_import);
			global.sig_item_imported.connect(on_ongoing_import);
		
			/*var spinner = new Gtk.Spinner();
			var action_area = bar.get_action_area();
			((Gtk.Container)action_area).add(spinner);
			spinner.show();
			spinner.start();*/
			//Gtk.Spinner for vala hasn't arrived yet :-( 
		}
	}
	
	
	private bool on_countdown_done() {
		//GLib.Source.remove (import_notify_timeout);
		
		if(bar_label == null)
			bar_label = new Label("");
			
		if(import_count > 1) {
			Idle.add( () => {
				// Doing this in an Idle prevents some warnings
				if(bar_label.get_realized())
					bar_label.set_text(import_count.to_string() + 
					                   " items have been added to your media library"
					                   );
				return false;
			}); 
		}
		else {
			DbBrowser dbb = null;
			try {
				dbb = new DbBrowser();
			}
			catch(Error e) {
				print("%s\n", e.message);
				return false;
			}
			TrackData data;
			dbb.get_trackdata_for_uri(last_uri, out data);
			if(bar_label.get_realized())
				bar_label.set_markup("<b>" + data.Artist + " - "+ data.Title + "</b> has been added to your media library");
			last_uri = null;
		}
		
		bar_progress.hide();
		bar_close_button.show();
		global.sig_item_imported.disconnect(on_ongoing_import);
		global.sig_item_imported.connect(on_import);
		return false;
	}
}
