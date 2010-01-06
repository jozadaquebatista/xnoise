/* xnoise-plugin.vala
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

public class Xnoise.Plugin : GLib.Object {
	//THIS CLASS IS A WRAPPER FOR THE PLUGIN OBJECT FROM MODULE
	private Module module;
	public Object loaded_plugin;
	private Type type;
	private PluginInformation _info;
	public PluginInformation info {
		get {
			return _info;
		}
	}
	private bool _loaded = false;
	public bool loaded {
		get {
			return _loaded;
		}
	}
	public bool activated { get; set; }
	public bool configurable { get; private set; }
	public bool is_lyrics_plugin { get; private set; default = false;}
	public bool is_album_image_plugin { get; private set; default = false;}
	private weak Main xn;

	public signal void sign_activated();
	public signal void sign_deactivated();

	private delegate Type InitModuleFunction();

	public Plugin(PluginInformation info) {
		this._info = info;
		this.notify.connect( (s, p) => {
			switch(p.name) {
				case "activated": {
					if(((Plugin)s).activated)
						activate();
					else
						deactivate();
					break;
				}
				default: break;
			}
		});
	}

	public bool load() {
		this.xn = Main.instance;
		if(this.loaded) return true;
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
		_loaded = true;
		this.configurable = false;

		if(!type.is_a(typeof(IPlugin)))
			return false;

		if(type.is_a(typeof(ILyricsProvider)))
			this.is_lyrics_plugin = true;

		if(type.is_a(typeof(IAlbumCoverImageProvider)))
			this.is_album_image_plugin = true;

		return true;
	}

	private void activate() {
		if(!loaded) return;
		loaded_plugin = Object.new(type,
		                           "xn", this.xn,    //set properties via this, because
		                           null);            //parameters are not allowed
		                                             //for this kind of Object construction
		if(loaded_plugin == null) {
			message("Failed to load plugin %s. Cannot get type.\n", ((IPlugin)loaded_plugin).name);
			activated = false;
		}
		//if(loaded_plugin is IPlugin) print("sucess\n");
		if(!((IPlugin)loaded_plugin).init()) {
			message("Failed to load plugin %s. Cannot get initialize.\n", ((IPlugin)loaded_plugin).name);
			activated = false;
		}
		this.configurable = ((IPlugin)this.loaded_plugin).has_settings_widget();

		sign_activated();
	}

	private void deactivate() {
		loaded_plugin = null;
		sign_deactivated();
	}

	public Gtk.Widget? settingwidget() {
		if(this.loaded && this.activated) {
			return ((IPlugin)this.loaded_plugin).get_settings_widget();
		}
		else {
			return null;
		}
	}
}
