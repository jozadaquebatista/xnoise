/* xnoise-plugin-loader.vala
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
 */

public class Xnoise.PluginModule.Loader : Object {
	public HashTable<string, Container> plugin_htable;
	public HashTable<string, unowned Container> lyrics_plugins_htable;
	public HashTable<string, unowned Container> image_provider_htable;
	private Main xn;
	private Information info;
	private GLib.List<string> info_files;
	private string[] banned_plugins;

	public signal void sign_plugin_activated(Container p);
	public signal void sign_plugin_deactivated(Container p);

	public Loader() {
		assert(Module.supported());
		this.xn = Main.instance;
		
		// setup banned 
		banned_plugins = {};
		banned_plugins += "LastfmCovers";
		
		plugin_htable = new HashTable<string, Container>(str_hash, str_equal);
		lyrics_plugins_htable   = new HashTable<string, unowned Container>(str_hash, str_equal);
		image_provider_htable   = new HashTable<string, unowned Container>(str_hash, str_equal);
	}

	public unowned GLib.List<string> get_info_files() {
		return info_files;
	}
	
	private bool is_banned(string name) {
		foreach(string s in banned_plugins) {
			if(name == s)
				return true;
		}
		return false;
	}

	public bool load_all() {
		Container plugin;
		File dir = File.new_for_path(Config.PLUGINSDIR);
		this.get_plugin_information_files(dir);
		foreach(string pluginInfoFile in info_files) {
			info = new PluginModule.Information(pluginInfoFile);
			if(info.load_info()) {
				if(is_banned(info.name))
					continue;
				plugin = new PluginModule.Container(info);
				plugin.load();
				if(plugin.loaded == true)
					plugin_htable.insert(info.module, plugin); //Hold reference to plugin in hash table
				else
					continue;
				if(plugin.is_lyrics_plugin) {
					lyrics_plugins_htable.insert(info.module, plugin);
				}
				if(plugin.is_album_image_plugin) {
					image_provider_htable.insert(info.module, plugin);
				}
			}
			else {
				print("Failed to load %s.\n", pluginInfoFile);
				continue;
			}
		}
		if(info_files.length()==0) print("No plugin inforamtion found\n");
		//foreach(string s in lyrics_plugins_htable.get_keys()) print("%s in plugin ht\n", s);
		return true;
	}

	private void get_plugin_information_files(File dir) {
		//Recoursive scanning of plugin directory.
		//Module will have to be in the same path as its info file
		//Modules organized in subdirectories are allowed
		if(dir.query_exists(null)) {
			FileEnumerator enumerator;
			info_files = new GLib.List<string>();
			try {
				string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
					          FILE_ATTRIBUTE_STANDARD_TYPE;
				enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
			} 
			catch(Error error) {
				critical("Error importing plugin information directory %s. %s\n", dir.get_path(), error.message);
				return;
			}
			FileInfo info;
			try {
				while((info = enumerator.next_file(null)) != null) {
					string filename = info.get_name();
					string filepath = Path.build_filename(dir.get_path(), filename);
					File file = File.new_for_path(filepath);
					FileType filetype = info.get_file_type();
					if(filetype == FileType.DIRECTORY) {
						this.get_plugin_information_files(file);
					}
					else if(filename.has_suffix(".xnplugin")) {
						//print("found plugin information file: %s\n", filepath);
						info_files.append(filepath);
					}
				}
			}
			catch(Error e) {
				print("Get plugin information: %s\n", e.message);
			}
		}
	}

	public bool activate_single_plugin(string module) {
		Container p = this.plugin_htable.lookup(module);
		if(p == null) return false;
		p.activate();
		if(p.activated) {//notifications
			sign_plugin_activated(p);
			return true;
		}
		return false;
	}

	public void deactivate_single_plugin(string module) {
		Container p = this.plugin_htable.lookup(module);
		if(p == null) return;
		p.deactivate();
		sign_plugin_deactivated(p);
	}
}
