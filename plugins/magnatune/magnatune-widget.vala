/* magnatune-widget.vala
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */

using Gtk;

using Xnoise;



private class MagnatuneWidget : Gtk.Box {
    
    private bool database_available = false;
//    private ProgressBar pb = null;
    private Label label = null;
    private unowned DockableMedia dock;
    public ScrolledWindow sw;
    public MagnatuneTreeView tv = null;
    private unowned MagnatunePlugin plugin;

    public MagnatuneWidget(DockableMedia dock, MagnatunePlugin plugin) {
        Object(orientation:Orientation.VERTICAL,spacing:0);
        this.plugin = plugin;
        this.dock = dock;
        create_widgets();
        this.show_all();
        
        load_db();
    }
    
    private class MagnatuneChangeDetector : GLib.Object {
        private File file;
        private const string HASH_FILE = "http://magnatune.com/info/changed.txt";
        private string old_hash;
        public string new_hash { get; private set; }
        
        public MagnatuneChangeDetector(string old_hash) {
            file = File.new_for_uri(HASH_FILE);
            this.old_hash = old_hash;
        }
        
        public bool is_uptodate(Cancellable cancel) {
            if(cancel == null || cancel.is_cancelled())
                return false;
            string? wget_install_path = Environment.find_program_in_path("wget");
            if(wget_install_path != null) {
                File d = File.new_for_path("/tmp/magnatune" + Random.next_int().to_string() + ".txt");
                try {
                    string[] argv = {
                       wget_install_path,
                       "-O",
                       "%s".printf(d.get_path()),
                       file.get_uri(),
                       null
                    };
                    GLib.Process.spawn_sync(null, 
                                            argv,
                                            null,
                                            SpawnFlags.STDOUT_TO_DEV_NULL|SpawnFlags.STDERR_TO_DEV_NULL,
                                            null,
                                            null,
                                            null,
                                            null);
                }
                catch(SpawnError e) {
                    print("%s\n", e.message);
                    return false;
                }
                if(cancel == null || cancel.is_cancelled())
                    return false;
                
                try {
                    var dis = new DataInputStream(d.read(cancel));
                    new_hash = dis.read_line(null);
                } 
                catch(Error e) {
                    print("%s\n", e.message);
                    return false;
                }
                
                if(cancel.is_cancelled())
                    return false;
                try {
                    d.delete(cancel);
                } 
                catch(Error e) {
                    print("##4%s\n", e.message);
                }
            }
            else {
                return false;
            }
            return (new_hash == old_hash);
        }
    }
    
    private void load_db() {
        if(this.plugin.cancel.is_cancelled())
            return;
        File dbf = File.new_for_path(CONVERTED_DB);
        if(!dbf.query_exists()) {
            print("magnatune database is not yet available\n");
            var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_db_job);
            io_worker.push_job(job);
        }
        else {
            string old_hash = (string)Params.get_string_value("magnatune_collection_hash");
            var job = new Worker.Job(Worker.ExecutionType.ONCE, check_online_hash_job);
            job.set_arg("old_hash", old_hash);
            io_worker.push_job(job);
        }
    }

    private string new_hash;
    
    private bool check_online_hash_job(Worker.Job job) {
        // check hash
        if(this.plugin.cancel.is_cancelled())
            return false;
        string old_hash = (string)job.get_arg("old_hash");
        var cd = new MagnatuneChangeDetector(old_hash);
        if(cd.is_uptodate(this.plugin.cancel)) {
            print("magnatune database is up to date\n");
            database_available = true;
            new_hash = cd.new_hash;
           Timeout.add_seconds(1, () => {
                if(this.plugin.cancel.is_cancelled())
                    return false;
                add_tree();
                return false;
            });
            return true;
        }
        else {
            if(this.plugin.cancel.is_cancelled())
                return false;
            print("magnatune database is NOT up to date.\n");
            File fx = File.new_for_path(CONVERTED_DB);
            try {
                if(fx.query_exists(this.plugin.cancel))
                    fx.delete(this.plugin.cancel);
            }
            catch(Error e) {
                print("##5%s\n", e.message);
            }
            if(this.plugin.cancel.is_cancelled())
                return false;
            new_hash = cd.new_hash;
            if(this.plugin.cancel.is_cancelled())
                return false;
            var xjob = new Worker.Job(Worker.ExecutionType.ONCE, copy_db_job);
            io_worker.push_job(xjob);
            return false;
        }
    }

    private bool copy_db_job(Worker.Job job) {
        if(this.plugin.cancel.is_cancelled())
            return false;
        bool res = false;
        string? wget_install_path = Environment.find_program_in_path("wget");
        if(wget_install_path != null) {
            File mag_db = File.new_for_uri("http://he3.magnatune.com/info/sqlite_magnatune.db.gz");
            File d   = File.new_for_path("/tmp/xnoise_magnatune_db_zipped");
            if(d.query_exists(this.plugin.cancel))
                d.delete(this.plugin.cancel);
            try {
                string[] argv = {
                   wget_install_path,
                   "-O",
                   "%s".printf(d.get_path()),
                   mag_db.get_uri(),
                   null
                };
                GLib.Process.spawn_sync(null, 
                                        argv,
                                        null,
                                        SpawnFlags.STDOUT_TO_DEV_NULL|SpawnFlags.STDERR_TO_DEV_NULL,
                                        null,
                                        null,
                                        null,
                                        null);
            }
            catch(SpawnError e) {
                print("%s\n", e.message);
                return false;
            }
            if(this.plugin.cancel.is_cancelled())
                return false;
            if(d.query_exists(this.plugin.cancel)) {
                Idle.add(() => {
                    if(this.plugin.cancel.is_cancelled())
                        return false;
                    label.label = _("download finished...");
                    Idle.add( () => {
                        if(this.plugin.cancel.is_cancelled())
                            return false;
                        label.label = _("decompressing...");
                        var decomp_job = new Worker.Job(Worker.ExecutionType.ONCE, decompress_db_job);
                        if(this.plugin.cancel.is_cancelled())
                            return false;
                        io_worker.push_job(decomp_job);
                        return false;
                    });
                    return false;
                });
            }
        }
        return false;
    }

    private bool decompress_db_job(Worker.Job job) {
        if(this.plugin.cancel.is_cancelled())
            return false;
        File source = File.new_for_path(ZIPPED_DB);
        File dest   = File.new_for_path(UNZIPPED_DB);
        if(!source.query_exists())
            return false;
        FileInputStream src_stream  = null;
        FileOutputStream dst_stream = null;
        ConverterOutputStream conv_stream = null;
        try {
            if(dest.query_exists(this.plugin.cancel))
                dest.delete(this.plugin.cancel);
            src_stream = source.read(this.plugin.cancel);
            dst_stream = dest.replace(null, false, 0);
            if(dst_stream == null) {
                print("Could not create output stream!\n");
                return false;
            }
        }
        catch(Error e) {
            print("Error decompressing! %s\n", e.message);
//            Idle.add(() => {
//                if(this.plugin.cancel.is_cancelled())
//                    return false;
////                label.label = "Magnatune Error 1";
//                return false;
//            });
            return false;
        }
        if(this.plugin.cancel.is_cancelled())
            return false;
        var zlc = new ZlibDecompressor(ZlibCompressorFormat.GZIP);
        conv_stream = new ConverterOutputStream(dst_stream, zlc);
        try {
            conv_stream.splice(src_stream, 0);
        }
        catch(IOError e) {
            print("Converter Error! %s\n", e.message);
//            Idle.add(() => {
//                label.label = "Magnatune Error 2";
//                return false;
//            });
            return false;
        }
        Idle.add(() => {
            if(this.plugin.cancel.is_cancelled())
                return false;
            label.label = _("decompressing finished...");
            var conv_job = new Worker.Job(Worker.ExecutionType.ONCE, convert_db_job);
            io_worker.push_job(conv_job);
            return false;
        });
        try {
            source.delete();
        }
        catch(Error e) {
        }
        return false;
    }

    private bool convert_db_job(Worker.Job job) {
        if(this.plugin.cancel.is_cancelled())
            return false;
        Idle.add(() => {
            if(this.plugin.cancel.is_cancelled())
                return false;
            label.label = _("Please wait while\nconverting database.");
            return false;
        });
        var conv = new MagnatuneDatabaseConverter(this.plugin.cancel);
        conv.progress.connect(on_db_conversion_progress);
        conv.move_data();
        conv.progress.disconnect(on_db_conversion_progress);
        conv = null;
        File fx = File.new_for_path(CONVERTED_DB);
        if(fx.query_exists(null)) {
            Idle.add( () => {
                if(this.plugin.cancel.is_cancelled())
                    return false;
                database_available = true;
                add_tree();
                return false;
            });
        }
        else {
            printerr("ERROR CONVERTING DATABASE!!\n");
        }
        try {
            var source = File.new_for_path(UNZIPPED_DB);
            source.delete(this.plugin.cancel);
        }
        catch(Error e) {
        }
        Idle.add(() => {
            if(this.plugin.cancel.is_cancelled())
                return false;
            if(new_hash != null)
                Params.set_string_value("magnatune_collection_hash", new_hash);
            else
                print("new_hash is null!\n");
            return false;
        });
        return false;
    }
    
    private void on_db_conversion_progress(MagnatuneDatabaseConverter sender, int c) {
        Idle.add(() => {
            if(this.plugin.cancel.is_cancelled())
                return false;
//            pb.hide();
            label.label = _("Please wait while\nconverting database.\nDone for %d tracks.").printf(c);
            return false;
        });
    }
    
    private void add_tree() {
        if(!database_available)
            return;
//        this.remove(pb);
        this.remove(label);
//        pb = null;
        label = null;
        sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        tv = new MagnatuneTreeView(this.dock, this, sw, this.plugin);
        if(tv != null)
            sw.add(tv);
        this.pack_start(sw, true, true , 0);
        this.show_all();
    }
    
//    private void progress_cb(int64 current_num_bytes, int64 total_num_bytes) {
//        if(total_num_bytes <= 0)
//            return;
//        double fraction = (double)current_num_bytes / (double)total_num_bytes;
//        if(fraction > 1.0)
//            fraction = 1.0;
//        if(fraction < 0.0)
//            fraction = 0.0;
//        
//        Idle.add(() => {
//            if(this.plugin.cancel.is_cancelled())
//                return false;
//            pb.set_fraction(fraction);
//            return false;
//        });
//    }
    
    private void create_widgets() {
        label = new Label(_("loading..."));
        this.pack_start(label, true, true, 0);
//        pb = new ProgressBar();
//        this.pack_start(pb, false, false, 0);
    }
}


