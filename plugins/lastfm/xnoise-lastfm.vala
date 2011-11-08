/* xnoise-mpris.vala
 *
 * Copyright (C) 2011 Jörn Magens
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

using Gtk;
using Lastfm;

using Xnoise;
using Xnoise.PluginModule;


public class Xnoise.Lfm : GLib.Object, IPlugin {
	public Main xn { get; set; }
	private unowned PluginModule.Container _owner;
	private unowned DBusConnection conn;
	private Session session;
	
	public PluginModule.Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}
	
	public string name { 
		get {
			return "mpris";
		} 
	}
	
	public bool init() {
		//owner.sign_deactivated.connect(clean_up);
		session = new Lastfm.Session(
		   Lastfm.Session.AuthenticationType.MOBILE,   // session authentication type
		   "a39db9ab0d1fb9a18fabab96e20b0a34",         // api_key
		   "55993a9f95470890c6806271085159a3",         // secret
		   null//"de"                                  // language
		);
		return true;
	}
	
	public void uninit() {
		//clean_up();
		session = null;
	}

	private void clean_up() {
	}
	
	~Mpris() {
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
}

