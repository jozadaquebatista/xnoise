/* xnoise-sound-menu-2.vala
 *
 * Copyright (C) 2010-2012  Jörn Magens
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
using Xnoise.PluginModule;


public class Xnoise.SoundMenu2 : GLib.Object, IPlugin {
    private unowned PluginModule.Container p;
    private unowned PluginModule.Container _owner;
    
    public Main xn { get; set; }
    
    public string name { 
        get {
            return "soundmenu2";
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
        if(watch != 0) {
            Bus.unwatch_name(watch);
            watch = 0;
        }
        //stdout.printf("%s appeared\n", name);
        if(name != (new_sid_version ? NEW_SID : OLD_SID))
            return;
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
        if(!p.activated)
            plugin_loader.activate_single_plugin(p.info.name);
        
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
        tray_icon.visible = false;
    }
    
    private void on_name_vanished(DBusConnection conn, string name) {
        //stdout.printf("%s vanished\n", name);
        if(tray_icon == null && !Params.get_bool_value("quit_if_closed")) {
            tray_icon = new TrayIcon();
        }
        tray_icon.visible = !Params.get_bool_value("quit_if_closed");
    }

    private uint watch;
    private bool new_sid_version = false;
    
    private void intitialize() {
        //print("initialize sm2\n");
        new_sid_version = !using_old_gsettings_scheme();
        //print("new_sid_version: %s\n", new_sid_version.to_string());
        watch = Bus.watch_name(BusType.SESSION,
                               (new_sid_version ? NEW_SID : OLD_SID),
                               BusNameWatcherFlags.NONE,
                               on_name_appeared,
                               on_name_vanished);
        addremove_xnoise_player_to_blacklist(false);
    }
    
    public bool init() {
        Idle.add( () => {
            intitialize();
            return false;
        });
        return true;
    }
    
    public void uninit() {
        //print("try remove xnoise from soundmenu\n");
        addremove_xnoise_player_to_blacklist(true);
        if(tray_icon == null && !Params.get_bool_value("quit_if_closed")) {
            tray_icon = new TrayIcon();
        }
        tray_icon.visible = !Params.get_bool_value("quit_if_closed");;
        if(watch != 0) {
            Bus.unwatch_name(watch);
            watch = 0;
        }
    }

    private const string OLD_SID = "com.canonical.indicators.sound";
    private const string NEW_SID = "com.canonical.indicator.sound";
    
    private bool using_old_gsettings_scheme() {
        bool old = false;
        bool nw  = false;
        foreach(unowned string s in Settings.list_schemas()) {
            if(s == OLD_SID) {
                old = true;
                break;
            }
        }
        foreach(unowned string s in Settings.list_schemas()) {
            if(s == NEW_SID) {
                nw = true;
                break;
            }
        }
        if(old == false && nw == false) {
            if(this.owner != null)
                Idle.add( () => {
                    if(tray_icon == null && !Params.get_bool_value("quit_if_closed")) {
                        tray_icon = new TrayIcon();
                    }
                    tray_icon.visible = !Params.get_bool_value("quit_if_closed");;
                    owner.deactivate();
                    return false;
                }); 
        }
        return old;
    }

    private bool soundmenu_gsettings_available() {
        foreach(unowned string s in Settings.list_schemas()) {
            if(s == (new_sid_version ? NEW_SID : OLD_SID)) 
                return true;
        }
        return false;
    }

    private void addremove_xnoise_player_to_blacklist(bool add_xnoise) {
        //print("addremove %s\n", add_xnoise.to_string());
        if(soundmenu_gsettings_available()) {
            string[] sa;
            string[] res = {};
            var settings = new Settings((new_sid_version ? NEW_SID : OLD_SID));
            sa = settings.get_strv("blacklisted-media-players");
            foreach(string s in sa) {
                if(s != "xnoise")
                    res += s;
            }
            
            if(add_xnoise)
                res += "xnoise";
            
            //foreach(string s in res) {
            //      print("zz: %s\n", s);
            //}
            
            settings.set_strv("blacklisted-media-players", res);
        }
        else {
            print("soundmenu gsetting unavailable\n");
        }
    }

    ~SoundMenu2() {
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
