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
	* test performance, maybe switch to inotify
	* find a well performing facility to automatically add files that were created in the media 
		path while xnoise was not monitoring/running (i have no solution here)
	* act upon changes of the media path directories/items more precisely 
		(don't regenerate everything) -> also needs work on MediaImporter and AddMediaDialog
	* handle file deletions
*/

using Xnoise;

public class MediawatcherPlugin : GLib.Object, IPlugin {
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


public class Mediawatcher : GLib.Object {
	private List<FileMonitor> monitor_list;
	
	// the frequency limit to check monitored directories for changes
	private const int monitoring_frequency = 2000;
	
	public Mediawatcher() {
		global.sig_media_path_changed.connect(media_path_changed_cb);
		setup_monitors();
	}

	/* creates file monitors for all directories in the media path */ 
	protected void setup_monitors() {
		monitor_list = new List<FileMonitor>();
		var dbb = new DbBrowser();
		var mfolders = dbb.get_media_folders();
		
		foreach(string mfolder in mfolders)
			setup_monitor_for_path(mfolder);
	}
	
	protected void media_path_changed_cb() {
		unowned List<FileMonitor> iter = monitor_list;
		while((iter = iter.next) != null) 
			iter.data.unref();
			
		monitor_list.data.unref();
		
		setup_monitors();
	}
	
	/* setup file monitors for a directory and all its subdirectories, reference them and
	 store them in monitor_list */
	protected void setup_monitor_for_path(string path) {
		print("setup_monitor_for_path : %s\n", path);
		try {
			var dir = File.new_for_path(path);
			var monitor = dir.monitor_directory(FileMonitorFlags.NONE);
			monitor.changed.connect(file_changed_cb);
			monitor.ref();
			monitor.set_rate_limit(monitoring_frequency);
			monitor_list.append(monitor);	

			monitor_all_subdirs(dir);
		}
		catch(IOError e) {
			print("Could not setup file monitoring for \'%s\': Error %s\n", path, e.message);
		}
	}


	protected void file_changed_cb(FileMonitor sender, File file, File? other_file, FileMonitorEvent event_type) {
		print("%s\n", event_type.to_string());
		if(event_type == FileMonitorEvent.CREATED) { // TODO: monitor removal of folders, too
			if(file != null) {
				print("\'%s\' has been created recently, updating db...", file.get_path());
				
				var dbw = new DbWriter();
				var mi = new MediaImporter();
				
				try {
					var info = file.query_info(FILE_ATTRIBUTE_STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
					
					if(info.get_file_type() == FileType.REGULAR) mi.add_single_file(file.get_uri(), ref dbw);	
					else if (info.get_file_type() == FileType.DIRECTORY) {
						mi.add_local_tags(file, ref dbw);
						setup_monitor_for_path(file.get_path());
					}
					
					Main.instance.main_window.mediaBr.change_model_data();
				} 
				catch(Error e) {
					print("Adding of \'%s\' failed: Error: %s\n", file.get_path(), e.message);
				}
			}
		}
	}


	/* sets up file monitors for all subdirectories of a directory, references them and
	 stores them in monitor_list */
	protected void monitor_all_subdirs(File f) {
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
					temp_mon.ref();
					temp_mon.set_rate_limit(monitoring_frequency);
					monitor_list.append(temp_mon);
				
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
