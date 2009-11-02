/* xnoise-plugin-loader.vala
 *
 * Copyright (C) 2009  softshaker
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
 * 	softshaker <softshaker   gmail.com>
 */
 
public class Xnoise.PluginLoader : Object {
	public HashTable<string,Plugin> plugin_htable;
	private Main xn;
	private PluginInformation info;
	private GLib.List<string> info_files;
	
	public signal void sign_plugin_activated(Plugin p);
	public signal void sign_plugin_deactivated(Plugin p);
	
	public PluginLoader(ref weak Main xn) {
		assert (Module.supported());
		this.xn = xn;
		plugin_htable = new HashTable<string,Plugin>(str_hash, str_equal);
	}

	public unowned GLib.List<string> get_info_files() {
		return info_files;
	}
			
	public bool load_all() {
		Plugin plugin;
		File dir = File.new_for_path(Config.PLUGINSDIR);
		
		this.get_plugin_information_files(dir);
		foreach(string pluginInfoFile in info_files) {
			info = new PluginInformation(pluginInfoFile);
			if(info.load_info()) {
				plugin = new Plugin(info);
				plugin.load(ref xn);
				plugin_htable.insert(info.name, plugin); //Hold reference to plugin in hash table
			}
			else {
				print("Failed to load %s.\n", pluginInfoFile);
				return false;
			}
		}
		if(info_files.length()==0) print("No plugin inforamtion found\n");
		return true;
	}
	
	private void get_plugin_information_files(File dir) {
		//Recoursive scanning of plugin directory.
		//Module will have to be in the same path as its info file
		//Modules organized in subdirectories are allowed
		FileEnumerator enumerator;
		info_files = new GLib.List<string>();
		try {
			string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
			              FILE_ATTRIBUTE_STANDARD_TYPE;
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
		} catch (Error error) {
			critical("Error importing plugin information directory %s. %s\n", dir.get_path(), error.message);
			return;
		}
		FileInfo info;
		while((info = enumerator.next_file(null))!=null) {
			string filename = info.get_name();
			string filepath = Path.build_filename(dir.get_path(), filename);
			File file = File.new_for_path(filepath);
			FileType filetype = info.get_file_type();
			if(filetype == FileType.DIRECTORY) {
				this.get_plugin_information_files(file);
			} 
			else if(filename.has_suffix(".xnplugin")) {
//				print("found plugin information file: %s\n", filepath);
				info_files.append(filepath);
			}
		}
	}

	public bool activate_single_plugin(string name) {
		Plugin p = this.plugin_htable.lookup(name);
		if(p == null) return false;
		p.activated=true;//ref xn);
		sign_plugin_activated(p);
		return true;
	}	

	public void deactivate_single_plugin(string name) {
		Plugin p = this.plugin_htable.lookup(name);
		if(p == null) return;
		p.activated=false;
		sign_plugin_deactivated(p);
	}
}
