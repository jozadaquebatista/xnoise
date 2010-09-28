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

public class Xnoise.SoundMenu : GLib.Object, IPlugin {
	private Indicate.Server server;
	public Main xn { get; set; }
	
	public string name { 
		get {
			return "soundmenu";
		}
	}
	
	public bool init() {
		//TODO check for mpris plugin being active
		unowned Xnoise.Plugin p = xn.plugin_loader.plugin_htable.lookup("mpris");
		if(p == null)
			return false;
		
		p.activate();
		
		if(!p.activated) {
			print("cannot start mpris plugin\n");
			return false;
		}
		
		Timeout.add(2, () => {
			server = Indicate.Server.ref_default();
			server.set("type", "music.xnoise");
			server.set_desktop_file("xnoise.desktop");
			server.show();
			return false;
		});
		
		return true;
	}
	
	~SoundMenu() {
		server.hide();
	}
	
	public Gtk.Widget? get_settings_widget() {
		return null;
	}
	
	public Gtk.Widget? get_singleline_settings_widget() {
		//TODO: provide single line opption widget for the settings dialog
		return null;
	}
	
	public bool has_settings_widget() {
		return false;
	}
	
	public bool has_singleline_settings_widget() {
		return false;
	}
}

