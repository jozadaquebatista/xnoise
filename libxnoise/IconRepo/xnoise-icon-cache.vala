/* xnoise-icon-cache.vala
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

using Gtk;
using Cairo;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


private class Xnoise.IconCache : GLib.Object {
    private static HashTable<string,Gdk.Pixbuf> cache;
    
    private File dir;
    private int icon_size;
    private int import_job_count = 0;
    private bool all_jobs_in_queue = false;
    
    public Cancellable cancellable;
    
    public signal void sign_new_album_art_loaded(string path);
    
    public bool loading_in_progress { get; private set; }
    
    public Gdk.Pixbuf? album_art { get; private set; }
    
    
    public IconCache(File dir, int icon_size = ICON_LARGE_PIXELSIZE, Gdk.Pixbuf dummy_pixbuf) {
        assert(io_worker != null);
        assert(cache_worker != null);
        assert(dir.get_path() != null);
        lock(cache) {
            if(cache == null) {
                cache = new HashTable<string,Gdk.Pixbuf>(str_hash, str_equal);
            }
        }
        this.cancellable = GlobalAccess.main_cancellable;
        this.dir = dir;
        this.icon_size = ICON_LARGE_PIXELSIZE;
        this.album_art = prepare(dummy_pixbuf);
        
        dbus_image_extractor.sign_found_album_image.connect(on_new_album_art_found);
        global.sign_album_image_removed.connect(on_image_removed);
    }
    
    
    private void on_image_removed(string artist, string album, string path) {
        print("Image Cache: remove image for %s - %s\n", artist, album);
        insert_image(path, null);  // remove
    }
    
    private void on_new_album_art_found(string? image) {
        if(image == null)
            return;
        print("icon cache got new image %s\n", image);
        File? file = File.new_for_path(image);
        if(file == null)
            return;
        Gdk.Pixbuf? px = null;
        try {
            px = new Gdk.Pixbuf.from_file(file.get_path());
        }
        catch(Error e) {
            print("%s\n", e.message);
            return;
        }
        if(px == null) {
            return;
        }
        else {
            if(image.has_suffix("_medium"))
                prepare_medium(px);
            else
                px = prepare(px);
            insert_image(file.get_path(), px);
            Idle.add(() => {
                sign_new_album_art_loaded(file.get_path());
                return false;
            });
        }
    }
    
    public void handle_image(string image_path) {
        if(image_path == EMPTYSTRING) 
            return;
        
        File f = File.new_for_path(image_path);
        if(f == null || f.get_path() == null)
            return;
        string p1 = f.get_path();
        p1 = p1.replace("_medium", "_extralarge"); // medium images are reported, extralarge not
        var fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
        fjob.set_arg("file", p1);
        fjob.set_arg("initial_import", false);
        fjob.cancellable = this.cancellable;
        cache_worker.push_job(fjob);
    }
    
    private bool read_file_job(Worker.Job job) {
        return_val_if_fail(cache_worker.is_same_thread(), false);
        File file = File.new_for_path((string)job.get_arg("file"));
        if(file == null)
            return false;
        
        if(!file.query_exists(null))
            return false;
        
        Gdk.Pixbuf? px = null;
        string pth = file.get_path();
        try {
            px = new Gdk.Pixbuf.from_file(pth);
        }
        catch(Error e) {
            print("%s\n", e.message);
            return false;
        }
        if(px == null) {
            return false;
        }
        else {
            if(file.get_path().has_suffix("_medium"))
                px = prepare_medium(px);
            else
                px = prepare(px);
            insert_image(file.get_path().replace("_embedded", "_extralarge"), px);
            if(signal_source != 0)
                Source.remove(signal_source);
            signal_source = Timeout.add(200, () => {
                sign_new_album_art_loaded(pth);
                signal_source = 0;
                return false;
            });
        }
        return false;
    }
    
    private uint signal_source = 0;
    
    public Gdk.Pixbuf? get_image(string path) {
        Gdk.Pixbuf? p = null;
        lock(cache) {
            p = cache.lookup(path);
        }
        if(p == null) {
            var fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
            //print("path: %s\n", path);
            fjob.set_arg("file", path);
            fjob.cancellable = this.cancellable;
            cache_worker.push_job(fjob);
        }
        return p;
    }
    
    private void insert_image(string name, Gdk.Pixbuf? pix) {
        if(pix == null) {
            lock(cache) {
                print("remove image %s\n", name);
                cache.remove(name);
            }
            return;
        }
        lock(cache) {
            cache.insert(name, pix);
        }
    }

    private const int frame_width = 1;
    
    private Gdk.Pixbuf? prepare(Gdk.Pixbuf pixbuf) {
        return pixbuf.scale_simple(ICON_LARGE_PIXELSIZE - 3, ICON_LARGE_PIXELSIZE - 1, Gdk.InterpType.BILINEAR);
    }

    private Gdk.Pixbuf? prepare_medium(Gdk.Pixbuf pixbuf) {
        return pixbuf.scale_simple(ICON_SMALL_PIXELSIZE, ICON_SMALL_PIXELSIZE, Gdk.InterpType.BILINEAR);
    }
}
