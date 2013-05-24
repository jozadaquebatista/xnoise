/* xnoise-dbus-image-extraction.vala
 *
 * Copyright (C) 2013  Jörn Magens
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


[DBus (name = "org.gtk.xnoise.ImageExtractor")]
private interface ImageExtractor : GLib.Object {
    public const string UNIQUE_NAME = "org.gtk.xnoise.ImageExtractor";
    public const string OBJECT_PATH = "/ImageExtractor";
    
    public signal void found_image(string artist, string album, string image);
    
    public abstract string ping()                throws IOError;
    public abstract void add_uris(string[] uris) throws IOError;
    
    public abstract uint waiting_jobs {get; set;}
}



private class Xnoise.DbusImageExtractor : Object {
    private uint watch = 0;
    
    public signal void sign_found_album_image(string uri);
    
    private ImageExtractor iextr;
    
    
    public DbusImageExtractor() {
        get_dbus();
    }
    
    ~DbusImageExtractor() {
        if(watch != 0)
            Bus.unwatch_name(watch);
        if(iextr != null && ready_sign_handler_id != 0)
            iextr.disconnect(ready_sign_handler_id);
        ready_sign_handler_id = 0;
        iextr = null;
    }
    
    public void queue_uris(string[] uris) {
        if(uris == null || uris.length == 0)
            return;
        try {
            if(iextr == null)
                iextr = Bus.get_proxy_sync(BusType.SESSION,
                                           ImageExtractor.UNIQUE_NAME,
                                           ImageExtractor.OBJECT_PATH);
            iextr.add_uris(uris);
        }
        catch (IOError e) {
          stderr.printf ("Service is not available.\n%s", e.message);
          return;
        }
    }
    
    private void on_name_appeared(DBusConnection conn, string name) {
        Timeout.add_seconds(1, () => {
            if(iextr != null)
                ready_sign_handler_id = iextr.found_image.connect(on_found_image);
            return false;
        });
    }

    private void on_name_vanished(DBusConnection conn, string name) {
        if(iextr != null && ready_sign_handler_id != 0)
            iextr.disconnect(ready_sign_handler_id);
        ready_sign_handler_id = 0;
        iextr = null;
    }
    
    private ulong ready_sign_handler_id = 0;
    private void get_dbus() {
        watch = Bus.watch_name(BusType.SESSION,
                               ImageExtractor.UNIQUE_NAME,
                               BusNameWatcherFlags.NONE,
                               on_name_appeared,
                               on_name_vanished);
    }

    private void on_found_image(string artist, string album, string image) {
        //print("found image for %s - %s\n", album, artist);
        sign_found_album_image(image);
    }
}

