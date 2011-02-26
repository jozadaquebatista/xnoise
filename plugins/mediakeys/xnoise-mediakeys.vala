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

	private GlobalKey stopkey = null;
	private GlobalKey prevkey = null;
	private GlobalKey playkey = null;
	private GlobalKey nextkey = null;
	
	private const uint AnyModifier = 1<<15; // from X.h
	
	private GnomeMediaKeys gmk = null;
	
	private void on_name_appeared(DBusConnection conn, string name) {
		//stdout.printf("%s appeared\n", name);
		if(stopkey != null)
			stopkey.unregister();
		if(prevkey != null)
			prevkey.unregister();
		if(playkey != null)
			playkey.unregister();
		if(nextkey != null)
			nextkey.unregister();
		
		try {
			gmk = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
		}
		catch(GLib.IOError e) {
			print("Mediakeys error: %s", e.message);
			print("Mediakeys: Try to use x keybindings instead of gnome-settings-daemon's dbus service'\n");
			gmk = null;
			if(!setup_x_keys())
				if(this.owner != null)
					Idle.add( () => {
						owner.deactivate();
						return false;
					}); 
			return;
		}
		
		try {
			gmk.GrabMediaPlayerKeys("xnoise", (uint32)0);
			gmk.MediaPlayerKeyPressed.connect(on_media_player_key_pressed);
		}
		catch(Error e) {
			//print("Mediakeys error: %s", e.message);
			print("Mediakeys: Try to use x keybindings instead of gnome-settings-daemon's dbus service'\n");
			gmk = null;
			if(!setup_x_keys())
				if(this.owner != null)
					Idle.add( () => {
						owner.deactivate();
						return false;
					}); 
			return;
		}
	}

	private void on_name_vanished(DBusConnection conn, string name) {
		//stdout.printf("%s vanished\n", name);
		//print("gmk not found\n");
		if(!setup_x_keys())
			if(this.owner != null)
				Idle.add( () => {
					owner.deactivate();
					return false;
				});
			return;
		
	}

	private uint watch;
	
	private void get_keys_dbus() {
		watch = Bus.watch_name(BusType.SESSION,
		                      "org.gnome.SettingsDaemon",
		                      BusNameWatcherFlags.NONE,
		                      on_name_appeared,
		                      on_name_vanished);
	}

	private bool setup_x_keys() {
		if(gmk != null) {
			gmk.MediaPlayerKeyPressed.connect(on_media_player_key_pressed);
			try {
				gmk.GrabMediaPlayerKeys("xnoise", (uint32)0);
			}
			catch(Error error) {
				print("%s", error.message);
			}
		}
		else {
			stopkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioStop"), AnyModifier);
			if(stopkey.register()) {
				stopkey.pressed.connect(
					() => {
						global.stop();
					}
				);
			}
			else {
				return false;
			}
		
			prevkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioPrev"), AnyModifier);
			if(prevkey.register()) {
				prevkey.pressed.connect(
					() => {
						global.prev();
					}
				);
			}
			else {
				return false;
			}
		
			playkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioPlay"), AnyModifier);
			if(playkey.register()) {
				playkey.pressed.connect(
					() => {
						global.play(true);
					}
				);
			}
			else {
				return false;
			}
			
			nextkey = new GlobalKey((int)Gdk.keyval_from_name("XF86AudioNext"), AnyModifier);
			if(nextkey.register()) {
				nextkey.pressed.connect(
					() => {
						global.next();
					}
				);
			}
			else {
				return false;
			}
		}
		return true;
	}
	
	public bool init() {
		// Try to use gnome settings deamon via dbus interface, first
		Idle.add( () => {
			get_keys_dbus();
			return false;
		});
		return true;
	}
	
	public void uninit() {
		if(stopkey != null)
			stopkey.unregister();
		if(prevkey != null)
			prevkey.unregister();
		if(playkey != null)
			playkey.unregister();
		if(nextkey != null)
			nextkey.unregister();
		if(gmk != null) 
			gmk.ReleaseMediaPlayerKeys("xnoise");
		if(watch != 0) {
			Bus.unwatch_name(watch);
			watch = 0;
		}
	}

	~MediaKeys() {
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	private void on_media_player_key_pressed(string application,
	                                         string key) {
		//print("key pressed (%s %s)\n", application, key);
		if(application != "xnoise")
			return;
		
		switch(key) {
			case "Next": {
				global.next();
				break;
			}
			case "Previous": {
				global.prev();
				break;
			}
			case "Play": {
				global.play(true);
				break;
			}
			case "Stop": {
				global.stop();
				break;
			}
			default:
				//print("not an used mediakey\n");
				break;
		}
	}
}

private class GlobalKey : GLib.Object {
	private bool _registered = false;
	private const int GRAB_ASYNC  = 1;
	private const int KEY_PRESSED = 2;
	private int keysym;
	private int keycode;
	private uint modifiers;
	
	private unowned Gdk.Window root_window;
	private unowned X.Display xdisplay;
	
	public signal void pressed();

	public bool registered { 
		get {
			return _registered;
		}
	}

	public GlobalKey(int _keysym = 0, uint _modifiers = 0) {
		
		this.keysym = _keysym;
		this.modifiers = _modifiers;
		
		this.root_window = Gdk.get_default_root_window();
		this.xdisplay    = get_x_display_for_window(root_window);
		
		this.keycode     = xdisplay.keysym_to_keycode(this.keysym);
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
	
	
	public bool register() {
		
		if(this.xdisplay == null || this.keycode == 0)
			return false;
		
		this.root_window.add_filter(filterfunc);
		
		Gdk.error_trap_push();
		
		xdisplay.grab_key(this.keycode,
		                  this.modifiers,
		                  get_x_id_for_window(root_window),
		                  false,
		                  GRAB_ASYNC,
		                  GRAB_ASYNC
		                  );
		
		Gdk.flush();
		if(Gdk.error_trap_pop() != 0) {
			_registered = false;
			print("failed to grab key %d\n", this.keycode);
			return false;
		}
		//print("grabbed key %d\n", this.keycode);
		_registered = true;
		return true;
	}

	public void unregister() {
		
		if(this.xdisplay == null || this.keycode == 0)
			return;
			
		if(!_registered)
			return;
			
		this.root_window.remove_filter(filterfunc);
		
		if(xdisplay == null)
			return;
		
		xdisplay.ungrab_key(this.keycode,
		                    this.modifiers,
		                    get_x_id_for_window(root_window)
		                    );
		
		_registered = false;
	}

	private static X.ID get_x_id_for_window(Gdk.Window window) {
		return Gdk.x11_drawable_get_xid(window);
	}

	private static unowned X.Display get_x_display_for_window(Gdk.Window window) {
		return Gdk.x11_drawable_get_xdisplay(Gdk.x11_window_get_drawable_impl(window));
	}
}
