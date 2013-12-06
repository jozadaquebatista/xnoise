/* xnoise-notifications.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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
 *     Jörn Magens
 */

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


[DBus(name = "org.freedesktop.Notifications")]
private interface Xnoise.IDesktopNotifications : GLib.Object {
    public abstract void close_notification(uint32 id) throws IOError;
    //public abstract string[] get_capabilities() throws IOError;
    //public abstract void get_server_information(out string name,
    //                                            out string vendor,
    //                                            out string version
    //                                            ) throws IOError;
    public abstract uint32 notify(string app_name,
                                  uint32 id,
                                  string icon,
                                  string summary,
                                  string body,
                                  string[] actions,
                                  HashTable<string,Variant> hints,
                                  int32 timeout) throws IOError;
}


private class Xnoise.DesktopNotifications : GLib.Object {
    private uint watch = 0;
    private int32 duration = 10;
    private uint32 current_id = 0;
    
    private Xnoise.IDesktopNotifications notifications_proxy = null;
    
    
    public DesktopNotifications() {
        assert(global != null);
        assert(Params.is_inited());
        
        get_dbus_proxy.begin();
        Idle.add( () => {
            global.tag_changed.connect(on_tag_changed);
            global.image_loader.image_path_small_changed.connect(on_image_changed);
            global.image_loader.image_path_embedded_changed.connect(on_image_changed);
            return false;
        });
    }
    
    private uint data_changed_source = 0;
    
    private void on_image_changed() {
//        if(!Main.instance.use_notifications)
//            return;
        if(global.current_uri == null)
            return;
        if(data_changed_source != 0)
            Source.remove(data_changed_source);
        data_changed_source = Timeout.add(200, () => {
            setup_notification_in_idle();
            data_changed_source = 0;
            return false;
        });
    }
    
    private void on_tag_changed() {
        //print("use_notifications : %s\n", Main.instance.use_notifications.to_string());
        if(data_changed_source != 0)
            Source.remove(data_changed_source);
        data_changed_source = Timeout.add(200, () => {
            setup_notification_in_idle();
            data_changed_source = 0;
            return false;
        });
    }
    
    private void setup_notification_in_idle() {
        if(global.current_uri == null)
            return;
        if(main_window.window_in_foreground) // only show notification if window is not visible
            return;
        string album, artist, title;
        string basename = null;
        File file = File.new_for_uri(global.current_uri);

        if(!gst_player.is_stream)
            basename = file.get_basename();

        if(global.current_artist != null && global.current_artist != EMPTYSTRING)
            artist = remove_linebreaks(global.current_artist);
        else
            artist = UNKNOWN_ARTIST_LOCALIZED;

        if(global.current_title != null && global.current_title != EMPTYSTRING)
            title = remove_linebreaks(global.current_title);
        else
            title = UNKNOWN_TITLE_LOCALIZED;

        if(global.current_album != null && global.current_album != EMPTYSTRING)
            album = remove_linebreaks(global.current_album);
        else
            album = UNKNOWN_ALBUM_LOCALIZED;

        if(album == UNKNOWN_ALBUM)
            album = UNKNOWN_ALBUM_LOCALIZED;
        if(artist == UNKNOWN_ARTIST)
            artist = UNKNOWN_ARTIST_LOCALIZED;
        if(title == UNKNOWN_TITLE)
            title = UNKNOWN_TITLE_LOCALIZED;
        
        if(title  == UNKNOWN_TITLE_LOCALIZED)
            return; // Don't show notifications, if information is unsufficient
        
        string summary = title;
        string body = (artist != UNKNOWN_ARTIST_LOCALIZED ? 
                            (_("by") + " " + Markup.printf_escaped("%s", artist) + " \n") : 
                            "") +
                      (album != UNKNOWN_ALBUM_LOCALIZED ? 
                            (_("on") + " " + Markup.printf_escaped("%s", album)) : 
                            "");
        string image = 
            ((global.image_loader.image_path_embedded != null && global.image_loader.image_path_embedded != "") ? 
                global.image_loader.image_path_embedded : 
                global.image_loader.image_path_small);
        
        if(image == null || image == "")
            image = "xnoise";
        
        Idle.add( () => {
            this.send_notification(image, summary, body, duration);
            return false;
        });
    }

    //public void print_capabilities() {
    //    if(notifications_proxy == null)
    //        return;
    //    string[] sa = {};
    //    try {
    //        sa = notifications_proxy.get_capabilities();
    //    }
    //    catch(IOError e) {
    //        print("%s\n", e.message);
    //    }
    //    foreach(string s in sa)
    //        print("s=%s\n", s);
    //}

    //public void print_server_information() {
    //    if(notifications_proxy == null)
    //        return;
    //    string name = "", vendor = "", version = "";
    //    try {
    //        notifications_proxy.get_server_information(out name, out vendor, out version);
    //    }
    //    catch(IOError e) {
    //        print("%s\n", e.message);
    //    }
    //    if(name != null && name != "")
    //        print("%s, %s, %s\n", name, vendor, version);
    //}
    
    private int fail_counter = 0;
    
    public void send_notification(string icon,
                                  string summary,
                                  string body,
                                  int32 timeout) {
        if(notifications_proxy == null) {
            fail_counter++;
            if(fail_counter > 2) {
                print("Could not wake up notifications daemon. Giving up...\n");
                return;
            }
            print("Try waking up notification daemon...\n");
            get_dbus_proxy.begin();
            Timeout.add_seconds(2, () => {
                send_notification(icon,
                                  summary,
                                  body,
                                  timeout);
                return false;
            });
        }
        string[] actions = {};
        var hints = new HashTable<string,Variant>(str_hash, str_equal);
        uint32 i = 0;
        try {
            i = notifications_proxy.notify("Xnoise media player",
                                           (uint32)current_id,
                                           icon,
                                           summary,
                                           body,
                                           actions,
                                           hints,
                                           timeout
                                           );
            if(removal_timeout != 0)
                Source.remove(removal_timeout);
            removal_timeout = Timeout.add_seconds(timeout, () => {
                removal_timeout = 0;
                close_notification(i);
                return false;
            });
        }
        catch(IOError e) {
            print("%s\n", e.message);
        }
        //print("got notification id : %u\n", i);
        current_id = i;
    }
    
    private uint removal_timeout = 0;
    
    public void close_notification(uint32 id) {
        if(notifications_proxy == null)
            return;
        //print("Trying to close current notification...\n");
        try {
            notifications_proxy.close_notification(id);
        }
        catch(IOError e) {
            print("error closing notification\n");
        }
    }
    
    private void on_name_appeared(DBusConnection conn, string name) {
        if(notifications_proxy == null) {
            print("Dbus: notification's name appeared but proxy is not available\n");
            return;
        }
        fail_counter = 0;
    }

    private void on_name_vanished(DBusConnection conn, string name) {
        print("DBus: Notifications name disappeared\n");
//        notifications_proxy = null;
    }
    
    private async void get_dbus_proxy() {
        try {
            notifications_proxy = yield Bus.get_proxy(BusType.SESSION,
                                                    "org.freedesktop.Notifications",
                                                    "/org/freedesktop/Notifications",
                                                    0,
                                                    null
                                                    );
        } 
        catch(IOError er) {
            print("%s\n", er.message);
        }
        
        watch = Bus.watch_name(BusType.SESSION,
                              "org.freedesktop.Notifications",
                              BusNameWatcherFlags.NONE,
                              on_name_appeared,
                              on_name_vanished);
    }
}

