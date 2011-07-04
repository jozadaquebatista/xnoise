/* xnoise-sound-menu.vala
 *
 * Copyright (C) 2010 Jörn Magens
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
 * Jörn Magens
 */

using Xnoise;
using Indicate;

using Xnoise;
using Xnoise.PluginModule;


public class Xnoise.SoundMenu : GLib.Object, IPlugin {
	private Indicate.Server server;
	private PluginModule.Container p;
	private unowned Xnoise.Plugin _owner;
	
	public Main xn { get; set; }
	
	public string name { 
		get {
			return "soundmenu";
		}
	}
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	private void on_name_appeared(DBusConnection conn, string name) {
		//stdout.printf("%s appeared\n", name);
		//TODO check for mpris plugin being active
		p = plugin_loader.plugin_htable.lookup("mpris");
		if(p == null) {
			if(this.owner != null)
				Idle.add( () => {
					owner.deactivate();
					return false;
				}); 
			return;
		}
		
		p.activate();
		
		if(!p.activated) {
			print("cannot start mpris plugin\n");
			if(this.owner != null)
				Idle.add( () => {
					owner.deactivate();
					return false;
				}); 
			return;
		}
		p.sign_deactivated.connect(mpris_deactivated);
		//print("init\n");
		Timeout.add(2, () => {
			server = Indicate.Server.ref_default();
			server.set("type", "music.xnoise");
			server.set_desktop_file(GLib.Path.build_filename(Config.DATADIR, "applications", "xnoise.desktop", null));
			server.show();
			return false;
		});
		addremove_xnoise_player_to_blacklist(false);
		tray_icon.visible = false;
	}
	
	private void on_name_vanished(DBusConnection conn, string name) {
		//stdout.printf("%s vanished\n", name);
		if(server != null)
			server.hide();
		tray_icon.visible = true;
	}

	private uint watch;

	private void intitialize() {
		watch = Bus.watch_name(BusType.SESSION,
		                      "org.ayatana.indicator.sound",
		                      BusNameWatcherFlags.NONE,
		                      on_name_appeared,
		                      on_name_vanished);
	}
	
	public bool init() {
		Idle.add( () => {
			intitialize();
			return false;
		});
		return true;
	}
	
	public void uninit() {
		print("try remove xnoise from soundmenu\n");
		addremove_xnoise_player_to_blacklist(true);
		if(server != null)
			server.hide();
		tray_icon.visible = true;
		if(watch != 0) {
			Bus.unwatch_name(watch);
			watch = 0;
		}
	}

	private bool soundmenu_gsettings_available() {
		foreach(unowned string s in Settings.list_schemas()) {
			if(s == "com.canonical.indicators.sound") 
				return true;
		}
		return false;
	}

	private void addremove_xnoise_player_to_blacklist(bool add_xnoise) {
		if(soundmenu_gsettings_available()) {
			string[] sa;
			string[] res = {};
			var settings = new Settings("com.canonical.indicators.sound");
			sa = settings.get_strv("blacklisted-media-players");
			foreach(string s in sa) {
				if(s != "xnoise")
					res += s;
			}
			
			if(add_xnoise)
				res += "xnoise";
			
			settings.set_strv("blacklisted-media-players", res);
		}
	}

	
	~SoundMenu() {
	}
	
	public Gtk.Widget? get_settings_widget() {
		return null;
	}
	
	public bool has_settings_widget() {
		return false;
	}
	
	private void mpris_deactivated() {
		//this plugin depends on mpris2 plugin
		if(this.owner != null)
			Idle.add( () => {
				owner.deactivate();
				return false;
			}); 
	}
}

