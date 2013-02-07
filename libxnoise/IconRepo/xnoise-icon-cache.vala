/* xnoise-icon-cache.vala
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

using Gtk;
using Cairo;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


private class Xnoise.IconCache : GLib.Object {
    private static HashTable<string,Gdk.Pixbuf> cache;
    
    private File dir;
    private int icon_size;
    private int import_job_count;
    private bool all_jobs_in_queue;
    
    public Cancellable cancellable;
    
    public signal void sign_new_album_art_loaded(string path);
    public signal void loading_done();
    
    public bool loading_in_progress { get; private set; }
    
    public Gdk.Pixbuf? album_art { get; private set; }
    
    
    public IconCache(File dir, int icon_size = IconsModel.ICONSIZE, Gdk.Pixbuf dummy_pixbuf) {
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
        this.icon_size = IconsModel.ICONSIZE;
        this.album_art = prepare(dummy_pixbuf);
        loading_in_progress = true;
        
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.populate_cache_job);
        job.cancellable = this.cancellable;
        io_worker.push_job(job);
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
    
    private void on_loading_finished() {
        return_if_fail(Main.instance.is_same_thread());
        loading_done();
    }
    
    private bool populate_cache_job(Worker.Job job) {
        if(job.cancellable.is_cancelled())
            return false;
        return_val_if_fail(io_worker.is_same_thread(), false);
        read_recoursive(this.dir, job);
        return false;
    }
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_val_if_fail(io_worker.is_same_thread(), false);
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            return;
        }
        job.big_counter[0]++;
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                string filename = info.get_name();
                string filepath = GLib.Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    var fjob = new Worker.Job(Worker.ExecutionType.ONCE, this.read_file_job);
                    fjob.set_arg("file", file.get_path());
                    fjob.set_arg("initial_import", true);
                    fjob.cancellable = this.cancellable;
                    lock(import_job_count) {
                        import_job_count++;
                    }
                    cache_worker.push_job(fjob);
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        job.big_counter[0]--;
        if(job.big_counter[0] == 0) {
            lock(all_jobs_in_queue) {
                all_jobs_in_queue = true;
            }
        }
    }
    
    private void import_job_count_dec_and_test(Worker.Job job) {
        assert(cache_worker.is_same_thread());
        if(!((bool)job.get_arg("initial_import"))) {
            string p = (string)job.get_arg("file");
            Idle.add(() => {
                sign_new_album_art_loaded(p);
                return false;
            });
            return;
        }
        bool res_flag = false;
        lock(import_job_count) {
            import_job_count--;
            if(import_job_count <=0) {
                res_flag = true;
            }
        }
        lock(all_jobs_in_queue) {
            if(all_jobs_in_queue && res_flag) {
                res_flag = true;
            }
            else {
                res_flag = false;
            }
        }
        if(res_flag) {
            Timeout.add(100, () => {
                print("Icon Cache: inital import done.\n");
                loading_in_progress = false;
                on_loading_finished();
                return false;
            });
        }
    }
    
    private bool read_file_job(Worker.Job job) {
        return_val_if_fail(cache_worker.is_same_thread(), false);
        File file = File.new_for_path((string)job.get_arg("file"));
        job.set_arg("file", file.get_path());
        if(file == null ||
            (!file.get_path().has_suffix("_extralarge") &&
             !file.get_path().has_suffix("_embedded"))) {
            import_job_count_dec_and_test(job);
            return false;
        }
        if(!file.query_exists(null)) {
            import_job_count_dec_and_test(job);
            return false;
        }
        Gdk.Pixbuf? px = null;
        try {
            px = new Gdk.Pixbuf.from_file(file.get_path());
        }
        catch(Error e) {
            print("%s\n", e.message);
            import_job_count_dec_and_test(job);
            return false;
        }
        if(px == null) {
            import_job_count_dec_and_test(job);
            return false;
        }
        else {
            px = prepare(px);
            insert_image(file.get_path().replace("_embedded", "_extralarge"), px);
        }
        import_job_count_dec_and_test(job);
        return false;
    }
    
    public Gdk.Pixbuf? get_image(string path) {
        Gdk.Pixbuf? p = null;
        lock(cache) {
            p = cache.lookup(path);
        }
        return p;
    }
    
    private void insert_image(string name, Gdk.Pixbuf? pix) {
        //print("insert image : %s\n", name);
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
        return pixbuf.scale_simple(IconsModel.ICONSIZE - 2, IconsModel.ICONSIZE - 1, Gdk.InterpType.BILINEAR);
    }
}
