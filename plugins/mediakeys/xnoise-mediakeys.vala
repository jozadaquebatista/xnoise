/* xnoise-mediakeys.vala
 *
 * Copyright (C) 2010  Jörn Magens
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
using Xnoise;
using X;

public class Xnoise.MediaKeys : GLib.Object, IPlugin {
	private unowned Xnoise.Plugin _owner;

	public unowned Main xn { get; set; }
	
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
			return "mediakeys";
		} 
	}

	private GlobalKey stopkey;
	private GlobalKey prevkey;
	private GlobalKey playkey;
	private GlobalKey nextkey;
	
	public bool init() {
		stopkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioStop"), 0);
		stopkey.register();
		stopkey.pressed.connect(
			() => {
				this.xn.main_window.stop();
			}
		);
		
		prevkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioPrev"), 0);
		prevkey.register();
		prevkey.pressed.connect(
			() => {
				this.xn.main_window.change_track(Xnoise.ControlButton.Direction.PREVIOUS);
			}
		);
		
		playkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioPlay"), 0);
		playkey.register();
		playkey.pressed.connect(
			() => {
				if(global.current_uri == null) {
					string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
					if((uri != "")&&(uri != null)) 
						global.current_uri = uri;
				}
				if(global.player_state == PlayerState.PLAYING) {
					global.player_state = PlayerState.PAUSED;
				}
				else {
					global.player_state = PlayerState.PLAYING;
				}
			}
		);
		
		nextkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioNext"), 0);
		nextkey.register();
		nextkey.pressed.connect(
			() => {
				this.xn.main_window.change_track(Xnoise.ControlButton.Direction.NEXT);
			}
		);
		return true;
	}
	
	~MediaKeys() {
		stopkey.unregister();
		prevkey.unregister();
		playkey.unregister();
		nextkey.unregister();
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public Gtk.Widget? get_singleline_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public bool has_singleline_settings_widget() {
		return false;
	}
}


private class GlobalKey : GLib.Object {
	private bool _registered = false;
	private const int GRAB_ASYNC  = 1;
	private const int KEY_PRESSED = 2;
	private int keysym;
	private int keycode;
	private Gdk.ModifierType modifiers;
	
	private unowned Gdk.Window root_window;
	private unowned X.Display xdisplay;
	
	public signal void pressed();

	public bool registered { 
		get {
			return _registered;
		}
	}

	public GlobalKey(int _keysym = 0, Gdk.ModifierType _modifiers = 0) {
		
		this.keysym = _keysym;
		this.modifiers = _modifiers;
		
		this.root_window = Gdk.get_default_root_window();
		this.xdisplay    = get_x_display_for_window(root_window);
		
		this.keycode = xdisplay.keysym_to_keycode(this.keysym);
	}

	~GlobalKey() {
		if(_registered == true)
			this.unregister();
	}
	
	[CCode (instance_pos=-1)]
	private Gdk.FilterReturn filterfunc(Gdk.XEvent e1, Gdk.Event e2) {
		void* p = &e1; // use this intermediate pointer, so that vala does not dereference the pointer-to-struct, while casting
		X.Event* e0 = p;
		if(e0 == null) {
			print("event error mediakeys\n");
			return Gdk.FilterReturn.CONTINUE;
		}
		if(e0.xkey.type == KEY_PRESSED && this.keycode == e0.xkey.keycode) {
			this.pressed();
			return Gdk.FilterReturn.REMOVE;
		}
		return Gdk.FilterReturn.CONTINUE;
	}
	
	
	public void register() {
		
		if(this.xdisplay == null || this.keycode == 0)
			return;
		
		this.root_window.add_filter(filterfunc);

		xdisplay.grab_key(this.keycode,
		                  (uint)this.modifiers,
		                  get_x_id_for_window(root_window),
		                  false,
		                  GRAB_ASYNC,
		                  GRAB_ASYNC
		                  );
		//print("grabbed key %d\n", this.keycode);
		_registered = true;
	}

	public void unregister() {
		
		if(this.xdisplay == null || this.keycode == 0)
			return;
		
		this.root_window.remove_filter(filterfunc);
		
		if(xdisplay == null)
			return;
		xdisplay.ungrab_key(this.keycode,
		                    (uint)this.modifiers,
		                    get_x_id_for_window(root_window)
		                    );
		//print("ungrabbed key %d\n", this.keycode);
		_registered = false;
	}

	private static X.ID get_x_id_for_window(Gdk.Window window) {
		return Gdk.x11_drawable_get_xid(window);
	}

	private static unowned X.Display get_x_display_for_window(Gdk.Window window) {
		return Gdk.x11_drawable_get_xdisplay(Gdk.x11_window_get_drawable_impl(window));
	}
}
