/* xnoise-plugin.vala
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

public class Xnoise.Plugin : GLib.Object {
	//THIS CLASS IS A WRAPPER FOR THE PLUGIN OBJECT RETURNED FROM MODULE INITIALIZATION 
	private Module module;
	private IPlugin loaded_plugin;
	private Type type;
	private PluginInformation info;
	
	public bool loaded { private set; get; }	
	public bool activated { private set; get; }
	
	private delegate Type InitModuleFunction();
	
	public Plugin(PluginInformation info) {
		this.info = info;
    }
    
    public bool load() {
		if (this.loaded) return true;
		string path = Module.build_path(Config.PLUGINSDIR, info.module);
		module = Module.open(path, ModuleFlags.BIND_LAZY);
		if (module == null) {
			print("cannot find module\n");
			return false;
		}		
		void* func;
		module.symbol("init_module", out func);
		InitModuleFunction init_module = (InitModuleFunction)func;
		if(init_module == null) return false;
		type = init_module();
		loaded = true;
		return true;
	}

	public bool activate (ref weak Main xn) {
		if(!loaded) return false;
		if(activated) return true;
		loaded_plugin = (IPlugin)Object.new(type, 
		                               "xn", xn,    //set properties via this, because
		                               null);       //parameters are not allowed 
		                                            //for this type of Object construction
		if(loaded_plugin == null) return false;
		if(!loaded_plugin.init()) return false;
		activated = true;
		return true;
	}

	public void deactivate() {
		loaded_plugin = null;
		activated = false;
	}
}

