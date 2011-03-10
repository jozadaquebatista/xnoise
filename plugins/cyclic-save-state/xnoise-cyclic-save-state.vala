/* xnoise-cyclic-save-state.vala
 *
 * Copyright (C) 2011  Jörn Magens
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
 
using Xnoise;

public class Xnoise.CyclicSaveState : GLib.Object, IPlugin {
	private unowned Xnoise.Plugin _owner;

	public Main xn { get; set; }
	
	public Xnoise.Plugin owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public string name { 
		get {
			return "CyclicSaveState";
		} 
	}
	
	private uint source = 0;

	public bool init() {
		source = Timeout.add_seconds(60, () => {
			if(MainContext.current_source().is_destroyed())
				return false;
			if(!global.media_import_in_progress) {
				Main.instance.save_tracklist();
				Main.instance.save_activated_plugins();
				par.write_all_parameters_to_file();
			}
			return true;
		});
		return true;
	}

	public void uninit() {
		//print("remove CyclicSaveState source\n");
		if(source != 0)
			Source.remove(source);
	}

	~CyclicSaveState() {
		//print("dtor of CyclicSaveState\n");
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return true;
	}
}

