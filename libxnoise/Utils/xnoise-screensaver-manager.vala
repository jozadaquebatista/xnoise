/* xnoise-screensaver-manager.vala
 *
 * Copyright (C) 2010  Andreas Obergrusberger
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
 * 	Andreas Obergrusberger
 */


using GLib;

namespace Xnoise {
	class ScreenSaverManager {
		private SSMBackend backend = null;
		public ScreenSaverManager() {
			var xdgssm = new XdgSSM();
			if(xdgssm.is_available()) backend = xdgssm;
			if(backend == null) return;
			if (!backend.init()) backend = null;
		}
			
		public bool inhibit() {
			message("calling Inhibit");
			if (backend == null) {
				print("cannot suspend screensaver, install xdg-utils");
				return false;
			}
			return backend.inhibit();
		}
	
		public bool uninhibit() {
			message("calling UnInhibit");
			if (backend == null) return false;
			return backend.uninhibit();
		}
	}

	interface SSMBackend : GLib.Object {
		public abstract bool is_available();
		public abstract bool init();
		public abstract bool inhibit();
		public abstract bool uninhibit();
	}



	class XdgSSM : GLib.Object, SSMBackend {
		private string path = null;
	
		private const string binary_name = "xdg-screensaver";
		private const string inhibit_param = "suspend";
		private const string uninhibit_param = "resume";

		private int exit_status;

		private int get_window_id() {
			var win = main_window.get_window();
			if(win == null) return -1;
			X.ID id = gdk_x11_window_get_xid(win); // TODO
			return (int)id;
		}
		
		private bool get_path() {
			string ret = null;
			ret = Environment.find_program_in_path(binary_name);
			if (ret != null) {
				path = ret;
				return true;
			}
			return false;
		}
	
		public bool is_available() {
			return get_path();
		}

		public bool init() {
			if (path == null) return get_path();
			return true;
		}

		public bool inhibit() {
			//int id = get_window_id();
			//print ("%i", id);
			try {
				Process.spawn_sync (null, {path, inhibit_param, get_window_id().to_string()}, null, 
				                    SpawnFlags.STDOUT_TO_DEV_NULL, 
				                    null, 
				                    null, 
				                    null, 
				                    out exit_status);
			}
			catch(GLib.Error e) {
				print("Failed to inhibit screensaver using xdg-screensaver: %s\n", e.message);
				return false;
			}
		
			if(exit_status == 0) return true;
			return true;
		}

		public bool uninhibit() {
			try {
				Process.spawn_sync (null, {path, uninhibit_param, get_window_id().to_string()}, null, 
				                    SpawnFlags.STDOUT_TO_DEV_NULL, 
				                    null, 
				                    null, 
				                    null, 
				                    out exit_status);
			}
			catch(GLib.Error e) {
				print("Failed to uninhibit screensaver using xdg-screensaver: %s", e.message);
				return false;
			}
		
			if(exit_status == 0) return true;
			return false;
		}
	}
}

