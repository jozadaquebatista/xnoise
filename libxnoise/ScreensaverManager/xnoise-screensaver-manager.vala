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
 *     Andreas Obergrusberger
 */


using GLib;

namespace Xnoise {
    class ScreenSaverManager {
        private SSMBackend backend = null;
        private bool backlight_dim_prevent;
        
        
        public ScreenSaverManager() {
            backlight_dim_prevent = true;
            var xdgssm = new XdgSSM();
            if(xdgssm.is_available()) backend = xdgssm;
            if(backend == null) return;
            if (!backend.init()) backend = null;
        }
            
        public bool inhibit() {
            message("calling Inhibit");
            backlight_dim_prevent = true;
            if (backend == null) {
                print("cannot suspend screensaver, install xdg-utils");
                return false;
            }
            Timeout.add_seconds(10, () => {
                //print("event\n");
                Idle.add(() => {
                    Gdk.KeymapKey[] keys;
                    Gdk.Keymap keymap = Gdk.Keymap.get_default();
                    keymap.get_entries_for_keyval(Gdk.Key.Shift_L, out keys);
                    unowned Gdk.DisplayManager display_manager = Gdk.DisplayManager.@get();
                    unowned Gdk.Display display = null;
                    unowned Gdk.DeviceManager dev_manager = null;
                    if(display_manager != null) {
                        display = display_manager.get_default_display();
                        if(display != null)
                            dev_manager = display.get_device_manager();
                    }
                    
                    Gdk.Event e = new Gdk.Event(Gdk.EventType.KEY_PRESS);
                    if(dev_manager != null)
                        e.set_device(dev_manager.list_devices(Gdk.DeviceType.MASTER).nth_data(0));
                    e.key.keyval = Gdk.Key.Shift_L;
                    e.key.window = main_window.get_window();
                    e.key.send_event = 1;
                    e.key.time = Gdk.CURRENT_TIME;
                    e.key.state = Gdk.ModifierType.SHIFT_MASK;
                    e.key.keyval = Gdk.Key.Shift_L;
                    e.key.hardware_keycode = (uint16)keys[0].keycode;
                    e.key.group = (uint8)keys[0].group;
                    
                    display.put_event(e);
                    return false;
                });
                Idle.add(() => {
                    Gdk.KeymapKey[] keys;
                    Gdk.Keymap keymap = Gdk.Keymap.get_default();
                    keymap.get_entries_for_keyval(Gdk.Key.Shift_L, out keys);
                    unowned Gdk.DisplayManager display_manager = Gdk.DisplayManager.@get();
                    unowned Gdk.Display display = null;
                    unowned Gdk.DeviceManager dev_manager = null;
                    if(display_manager != null) {
                        display = display_manager.get_default_display();
                        if(display != null)
                            dev_manager = display.get_device_manager();
                    }
                    
                    Gdk.Event e = new Gdk.Event(Gdk.EventType.KEY_RELEASE);
                    if(dev_manager != null)
                        e.set_device(dev_manager.list_devices(Gdk.DeviceType.MASTER).nth_data(0));
                    e.key.keyval = Gdk.Key.Shift_L;
                    e.key.window = main_window.get_window();
                    e.key.send_event = 1;
                    e.key.time = Gdk.CURRENT_TIME;
                    e.key.state = 0;
                    e.key.keyval = Gdk.Key.Shift_L;
                    e.key.hardware_keycode = (uint16)keys[0].keycode;
                    e.key.group = (uint8)keys[0].group;
                    
                    display.put_event(e);
                    return false;
                });
                return backlight_dim_prevent;
            });
            return backend.inhibit();
        }
    
        public bool uninhibit() {
            message("calling UnInhibit");
            backlight_dim_prevent = false;
            if (backend == null) return false;
            return backend.uninhibit();
        }
    }

    private interface SSMBackend : GLib.Object {
        public abstract bool is_available();
        public abstract bool init();
        public abstract bool inhibit();
        public abstract bool uninhibit();
    }



    private class XdgSSM : GLib.Object, SSMBackend {
        private string path = null;
        
        private const string binary_name = "xdg-screensaver";
        private const string inhibit_param = "suspend";
        private const string uninhibit_param = "resume";
        
        private int exit_status;
        
        private int get_window_id() {
            var win = main_window.get_window();
            if(win == null) return -1;
            X.ID id = Gdk.X11Window.get_xid(win);
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

