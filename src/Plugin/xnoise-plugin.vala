/* xnoise-plugin.vala
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
 

public class Xnoise.Plugin : TypeModule {
	//THIS CLASS IS A WRAPPER FOR THE PLUGIN OBJECT FROM MODULE
	private unowned Main xn;
	private bool _loaded = false;
	private Module module;
	private Type _type;
	private PluginInformation _info;
	private bool _activated;

	public Object loaded_plugin;
	
	public PluginInformation info {
		get {
			return _info;
		}
	}
	public bool loaded {
		get {
			return _loaded;
		}
	}

	public bool activated { 
		get {
			return _activated;
		}
	}
	public bool configurable { get; private set; }
	public bool is_lyrics_plugin { get; private set; default = false;}
	public bool is_album_image_plugin { get; private set; default = false;}

	public signal void sign_activated();
	public signal void sign_deactivated();

	private delegate Type InitModuleFunction(TypeModule module);

	public Plugin(PluginInformation info) {
		Object();
		base.set_name(info.name);
		this._info = info;
		this.xn = Main.instance;
		this.notify["activated"].connect( (s, p) => {
			if(((Plugin)s).activated)
				activate();
			else
				deactivate();
		});
	}

	public override bool load() {
		//print("load_plugin_module %s\n", _info.name);
		if(this.loaded) 
			return true;
		
		string path = Module.build_path(Config.PLUGINSDIR, info.module);
		module = Module.open(path, ModuleFlags.BIND_LAZY);
		if(module == null) {
			print("cannot find module\n");
			return false;
		}
		void* func;
		module.symbol("init_module", out func);
		InitModuleFunction init_module = (InitModuleFunction)func;
		if(init_module == null) 
			return false;
			
		_type = init_module(this);
		_loaded = true;
		this.configurable = false;

		if(!_type.is_a(typeof(IPlugin)))
			return false;

		if(_type.is_a(typeof(ILyricsProvider)))
			this.is_lyrics_plugin = true;

		if(_type.is_a(typeof(IAlbumCoverImageProvider)))
			this.is_album_image_plugin = true;

		return true;
	}

	public override void unload() {
		//print("unload %s\n", _info.name);
		_loaded = false;
		_activated = false;
		sign_deactivated();
	}

	public void activate() {
		if(activated)
			return;
		
		if(module == null)
			return;
		
		unowned Plugin ow = this;
		loaded_plugin = Object.new(_type,
		                           "xn", this.xn,
		                           "owner", ow,      //set properties via this, because
		                           null);            //parameters are not allowed
		                                             //for this kind of Object construction
		if(loaded_plugin == null) {
			message("Failed to load plugin %s. Cannot get type.\n", _info.name);
			_activated = false;
		}
		//if(loaded_plugin is IPlugin) print("sucess\n");
		if(!((IPlugin)loaded_plugin).init()) {
			message("Failed to load plugin %s. Cannot initialize.\n", _info.name);
			_activated = false;
			return;
		}
		this.configurable = ((IPlugin)this.loaded_plugin).has_settings_widget();
		_activated = true;
		sign_activated();
	}

	public void deactivate() {
		//print("deactivate\n");
		((IPlugin)loaded_plugin).uninit();
		_activated = false;
		loaded_plugin = null;
		sign_deactivated();
	}

	public Gtk.Widget? settingwidget() {
		if(this.loaded) { // && this.activated
			return ((IPlugin)this.loaded_plugin).get_settings_widget();
		}
		else {
			return null;
		}
	}
}
