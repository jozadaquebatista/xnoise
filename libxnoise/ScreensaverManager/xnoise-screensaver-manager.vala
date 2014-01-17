/* xnoise-screensaver-manager.vala
 *
 * Copyright (C) 2010  Andreas Obergrusberger
 * Copyright (C) 2011, 2013, 2014  Jörn Magens
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



namespace Xnoise {
    
    private class ScreenSaverManager {
        
        private SSMBackend[] backends = {};
        
        
        public ScreenSaverManager() {
            var xdgssm = new XdgSSM();
            if(xdgssm != null && xdgssm.is_available()) {
                if(xdgssm.init())
                    backends += xdgssm;
            }
            
            var dbus_ssm = new DBusSSM();
            if(dbus_ssm != null && dbus_ssm.is_available()) {
                if(dbus_ssm.init())
                    backends += dbus_ssm;
            }
            //print("%d screensaver manager backends running\n", backends.length);
        }
        
        
        public bool inhibit() {
            message("calling Inhibit");
            if (backends.length == 0) {
                print("cannot suspend screensaver, install xdg-utils or gnome screensaver ");
                return false;
            }
            foreach(SSMBackend be in backends)
                be.inhibit();
            return true;
        }
    
        public bool uninhibit() {
            message("calling UnInhibit");
            if (backends.length == 0)
                return false;
            foreach(SSMBackend be in backends)
                be.uninhibit();
            return true;
        }
    }


    [DBus(name = "org.gnome.ScreenSaver")]
    private interface IDBusScreensaver : GLib.Object {
        public abstract void simulate_user_activity() throws IOError;
    }


    private class DBusSSM : GLib.Object, SSMBackend {
        private uint watch = 0;
        
        private IDBusScreensaver screensaver_proxy = null;
        private bool setup_success = false;
        
        public DBusSSM() {
        }
        
        
        public bool is_available() {
            return true;
        }
        
        public bool init() {
            get_dbus_proxy.begin();
            return true;
        }
        
        private uint activity_src = 0;
        
        public bool inhibit() {
            if(activity_src != 0)
                Source.remove(activity_src);
            activity_src = Timeout.add_seconds(10, () => {
                if(!setup_success) {
                    activity_src = 0;
                    return false;
                }
                send_activity();
                return true;
            });
            return true;
        }
        
        public bool uninhibit() {
            if(activity_src != 0) {
                Source.remove(activity_src);
                activity_src = 0;
            }
            return true;
        }
        
        public void send_activity() {
            if(screensaver_proxy == null || !setup_success)
                return;
            //print("send dbus activity\n");
            try {
                screensaver_proxy.simulate_user_activity();
            }
            catch(IOError e) {
                print("%s\n", e.message);
            }
        }
        
        private void on_name_appeared(DBusConnection conn, string name) {
            if(screensaver_proxy == null) {
                print("Dbus: screensaver's name appeared but proxy is not available\n");
                return;
            }
            //print("Dbus screensaver setup success\n");
            setup_success = true;
        }

        private void on_name_vanished(DBusConnection conn, string name) {
            print("DBus: screensaver dbus name disappeared\n");
        }
        
        private async void get_dbus_proxy() {
            try {
                screensaver_proxy = yield Bus.get_proxy(BusType.SESSION,
                                                        "org.gnome.ScreenSaver",
                                                        "/",
                                                        0,
                                                        null
                                                        );
            } 
            catch(IOError er) {
                print("%s\n", er.message);
            }
            
            watch = Bus.watch_name(BusType.SESSION,
                                  "org.gnome.ScreenSaver",
                                  BusNameWatcherFlags.NONE,
                                  on_name_appeared,
                                  on_name_vanished);
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
                Process.spawn_sync(null, {path, inhibit_param, get_window_id().to_string()}, null, 
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
            if(exit_status == 0)
                return true;
            return true;
        }

        public bool uninhibit() {
            try {
                Process.spawn_sync(null, {path, uninhibit_param, get_window_id().to_string()}, null, 
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
            if(exit_status == 0)
                return true;
            return false;
        }
    }
}

