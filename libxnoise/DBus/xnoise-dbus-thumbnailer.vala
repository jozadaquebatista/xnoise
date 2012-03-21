/* xnoise-dbus-thumbnailer.vala
 *
 * Copyright (C) 2012  Jörn Magens
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


/* using the freedesktop standard for demanding thumnail via dbus */

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
private interface Thumbnailer : Object {
    
    //public abstract void dequeue(uint32 handle) throws IOError;
    //public abstract string[] get_flavors(string msg) throws IOError;
    //public abstract string[] get_schedulers() throws IOError;
    
    public abstract uint32 queue(string[] uris, string[] mime_types, string flavor, string scheduler, uint32 handle_to_unqueue) throws IOError;
    
    //public abstract void get_supported(out string[] uri_schemes, out string[] mime_types) throws IOError;
    //public signal void error(uint32 handle, string[] aa, int32 bb, string stri);
    
    public signal void finished(uint32 handle);
    public signal void ready(uint32 handle, string[] uris);
    public signal void started(uint32 handle);
}

public class Xnoise.DbusThumbnailer : Object {
    private uint32  current_handle  = 0;
    private uint    watch           = 0;
    private uint    handle_queue_timeout = 0;
    
    private Thumbnailer thumbnailer_proxy = null;
    private Queue<string> queue = new Queue<string>();
    
    public signal void sign_got_thumbnail(string uri, string thumb_uri);
    
    public void queue_uris(string[] uris) {
        foreach(string uri in uris) {
            if(!already_available(uri, null))
                queue.push_head(uri);
        }
        if(handle_queue_timeout != 0)
            return;
        
        // wait some time before starting. Maybe some more uris will appear
        handle_queue_timeout = Timeout.add(200, () => { 
            handle_queue_timeout = 0;
            handle_queue();
            return false;
        });
    }    
    
    private void on_name_appeared(DBusConnection conn, string name) {
        if(thumbnailer_proxy == null) {
            print("name appeared but proxy is not available\n");
            return;
        }
        if(handle_queue_timeout != 0) 
            return;
        handle_queue_timeout = Idle.add( () => {
            handle_queue_timeout = 0;
            handle_queue();
            return false;
        });
    }

    private void on_name_vanished(DBusConnection conn, string name) {
    }
    
    private ulong ready_sign_handler_id = 0;
    private async void get_dbus() {
        try {
            thumbnailer_proxy = yield Bus.get_proxy(BusType.SESSION,
                                                    "org.freedesktop.thumbnails.Thumbnailer1",
                                                    "/org/freedesktop/thumbnails/Thumbnailer1"
            );
            ready_sign_handler_id = thumbnailer_proxy.ready.connect(on_thumbnail_ready);
        } 
        catch(IOError er) {
            print("%s\n", er.message);
        }
        
        watch = Bus.watch_name(BusType.SESSION,
                              "org.freedesktop.thumbnails.Thumbnailer1",
                              BusNameWatcherFlags.NONE,
                              on_name_appeared,
                              on_name_vanished);
    }

    private void on_thumbnail_ready(uint32 handle, string[] uris) {
        //stdout.printf("Got thumbnail ready for %u\n", handle);
        foreach(string s in uris) {
            //print("ready uri: %s\n", s);
            string md5string = Checksum.compute_for_string(ChecksumType.MD5, s);
            File thumb = File.new_for_path(GLib.Path.build_filename(Environment.get_home_dir(), ".thumbnails", "normal", md5string + ".png"));
            assert(thumb.query_exists(null));
            sign_got_thumbnail(s, thumb.get_uri());
        }
    }
    
    private bool already_available(string uri, out File? _thumb) {
        string md5string = Checksum.compute_for_string(ChecksumType.MD5, uri);
        File thumb = File.new_for_path(GLib.Path.build_filename(Environment.get_home_dir(), ".thumbnails", "normal", md5string + ".png"));
        if(thumb.query_exists(null)) {
            //print("already_available . thumb is already there!\n");
            sign_got_thumbnail(uri, thumb.get_uri());
            _thumb = thumb;
            return true;
        }
        _thumb = null;
        return false;
    }

    private void handle_queue() {
        if(queue.is_empty())
            return;
        if(thumbnailer_proxy == null) {
            get_dbus.begin();
            return;
        }
        Idle.add( () => {
            start();
            return false;
        });
    }
    
    private void start() {
        string attr =   FileAttribute.STANDARD_NAME + "," +
                        FileAttribute.STANDARD_TYPE + "," +
                        FileAttribute.STANDARD_CONTENT_TYPE;
        string _uri;
        string[] query_uris = {};
        string[] query_mimetypes = {};
        while((_uri = queue.pop_head()) != null) {
            File thumb;
            if(already_available(_uri, out thumb))
                continue;
            
            File f = File.new_for_uri(_uri);
            GLib.FileInfo info = null;
            try {
                info = f.query_info(attr, GLib.FileQueryInfoFlags.NONE, null);
            }
            catch(Error e) {
                print("%s", e.message);
                continue;
            }
            string content  = info.get_content_type();
            string mimetype = GLib.ContentType.get_mime_type(content);
            if(mimetype != null && _uri != null)
            query_mimetypes += mimetype;
            query_uris += _uri;
        }
        
        return_if_fail(query_mimetypes.length == query_uris.length);
        
        try {
            if(query_uris.length > 0) {
                print("send thumbnail request\n");
                current_handle = thumbnailer_proxy.queue(query_uris, query_mimetypes, "normal", "foreground", 0);
            }
        }
        catch(IOError e) {
            print("%s", e.message);
        }
    }
}

