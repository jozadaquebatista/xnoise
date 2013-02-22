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
    private uint32  current_handle  = 0;
    private uint    watch           = 0;
    private uint    handle_queue_timeout = 0;
    
    private ImageExtractor extractor_proxy = null;
//    private Queue<string> queue = new Queue<string>();
    private string[] uris_buffer = {};
    
    public signal void sign_found_album_image(string uri, string thumb_uri);
    
    private ImageExtractor iextr;
    
    
    public DbusImageExtractor() {
        get_dbus();
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

//print("queue_uris ##1\n");
//        if(uris == null || uris.length == 0)
//            return;
//print("queue_uris ##2\n");
//        if(extractor_proxy == null) {
//            get_dbus();
//            try {
////              ImageExtractor extractor_proxy = Bus.get_proxy_sync(BusType.SESSION,
////                                                                  ImageExtractor.UNIQUE_NAME,
////                                                                  ImageExtractor.OBJECT_PATH);
//              extractor_proxy.add_uris(uris);
//            }
//            catch (IOError e) {
//              stderr.printf ("Service is not available.\n%s", e.message);
//              return;
//            }
//        }
//        if(extractor_proxy == null) {
//            get_dbus.begin();
//print("queue_uris ##3\n");
//            foreach(string s in uris)
//                uris_buffer += s;
//print("queue_uris ##4\n");
//            return;
//        }
//print("queue_uris ##5\n");
//        Idle.add(() => {
//print("queue_uris ##6\n");
//            try {
//print("queue_uris ##7\n");
//                if(uris.length > 0)
//                    extractor_proxy.add_uris(uris);
//                if(uris_buffer.length > 0) {
//print("queue_uris ##8\n");
//                    extractor_proxy.add_uris(uris_buffer);
//                    uris_buffer = {};
//print("queue_uris ##9\n");
//                }
//            }
//            catch(IOError e) {
//                print("Extractor Error: %s\n", e.message);
//            }
//print("queue_uris ##10\n");
//            return false;
//        });
    }
    
    private void on_name_appeared(DBusConnection conn, string name) {
print("name appeared\n");
//        Timeout.add_seconds(1, () => {
//            if(iextr != null)
//                ready_sign_handler_id = iextr.found_image.connect(on_found_image);
//            return false;
//        });
//        if(extractor_proxy == null) {
//            print("name appeared but proxy is not available\n");
//            return;
//        }
//        string[] uris = {};
//        queue_uris(uris);
//        if(handle_queue_timeout != 0) 
//            return;
//        handle_queue_timeout = Idle.add( () => {
//            handle_queue_timeout = 0;
//            handle_queue();
//            return false;
//        });
    }

    private void on_name_vanished(DBusConnection conn, string name) {
print("name vanished\n");
//        if(iextr != null && ready_sign_handler_id != 0)
//            iextr.disconnect(ready_sign_handler_id);
//        ready_sign_handler_id = 0;
//        iextr = null;
    }
    
    private ulong ready_sign_handler_id = 0;
    private void get_dbus() {
print("get_dbus\n");
//        try {
//            extractor_proxy = Bus.get_proxy_sync(BusType.SESSION,
//                                                    ImageExtractor.UNIQUE_NAME,
//                                                    ImageExtractor.OBJECT_PATH
//            );
//            ready_sign_handler_id = extractor_proxy.found_image.connect(on_found_image);
//        } 
//        catch(IOError er) {
//            print("%s\n", er.message);
//        }
        
//        watch = Bus.watch_name(BusType.SESSION,
//                               ImageExtractor.UNIQUE_NAME,
//                               BusNameWatcherFlags.NONE,
//                               on_name_appeared,
//                               on_name_vanished);
    }

    private void on_found_image(string artist, string album, string image) {
        print("found image for %s - %s\n", album, artist);
    }
}

