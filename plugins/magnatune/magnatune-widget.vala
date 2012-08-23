using Gtk;

using Xnoise;



private class MagnatuneWidget : Gtk.Box {
    
    private bool database_available = false;
    private ProgressBar pb = null;
    private Label label = null;
    private unowned DockableMedia dock;
    public ScrolledWindow sw;
    public MagnatuneTreeView tv = null;

    public MagnatuneWidget(DockableMedia dock) {
        Object(orientation:Orientation.VERTICAL,spacing:0);
        this.dock = dock;
        create_widgets();
        this.show_all();
        
        load_db();
    }
    
    private static const string CONVERTED_DB = "/tmp/xnoise_magnatune.sqlite"; //TODO
    
    
    private class MagnatuneChangeDetector : GLib.Object {
        private File file;
        private const string HASH_FILE = "http://magnatune.com/info/changed.txt";
        private string old_hash;
        public string new_hash { get; private set; }
        
        public MagnatuneChangeDetector(string old_hash) {
            file = File.new_for_uri(HASH_FILE);
            this.old_hash = old_hash;
        }
        
        public bool is_uptodate() {
            try {
                var dis = new DataInputStream(file.read());
                new_hash = dis.read_line(null);
            } 
            catch(Error e) {
                print("%s\n", e.message);
                return false;
            }
            
            return (new_hash == old_hash);
        }
    }
    
    
    private void load_db() {
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

    private bool check_online_hash_job(Worker.Job job) {
        // check hash
        string old_hash = (string)job.get_arg("old_hash");
        var cd = new MagnatuneChangeDetector(old_hash);
        if(cd.is_uptodate()) {
            print("magnatune database is up to date\n");
            database_available = true;
            Timeout.add_seconds(1, () => {
                Params.set_string_value("magnatune_collection_hash", cd.new_hash);
                add_tree();
                return false;
            });
            return false;
        }
        else {
            print("magnatune database is not up to date\n");
            File fx = File.new_for_path(CONVERTED_DB);
            try {
                if(fx.query_exists(null))
                    fx.delete();
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
            Idle.add(() => {
                Params.set_string_value("magnatune_collection_hash", cd.new_hash);
                return false;
            });
            var xjob = new Worker.Job(Worker.ExecutionType.ONCE, copy_db_job);
            io_worker.push_job(xjob);
            return false;
        }
    }

    private bool copy_db_job(Worker.Job job) {
        
        bool res = false;
        try {
            File mag_db = File.new_for_uri("http://he3.magnatune.com/info/sqlite_magnatune.db.gz");
            File dest   = File.new_for_path("/tmp/xnoise_magnatune_db_zipped");
            if(dest.query_exists(null))
                dest.delete();
            res = mag_db.copy(dest, FileCopyFlags.OVERWRITE, null, progress_cb);
        }
        catch(Error e) {
            print("%s\n", e.message);
            label.label = "Magnatune Error 3";
            return false;
        }
        if(res) {
            Idle.add(() => {
                label.label = "download finished...";
                Idle.add( () => {
                    label.label = "decompressing...";
                    var decomp_job = new Worker.Job(Worker.ExecutionType.ONCE, decompress_db_job);
                    io_worker.push_job(decomp_job);
                    return false;
                });
                return false;
            });
        }
        else {
            label.label = "Magnatune Error 4";
        }
        return false;
    }

    private bool decompress_db_job(Worker.Job job) {
        File source = File.new_for_path("/tmp/xnoise_magnatune_db_zipped");
        File dest   = File.new_for_path("/tmp/xnoise_magnatune_db");
        if(!source.query_exists())
            return false;
        FileInputStream src_stream  = null;
        FileOutputStream dst_stream = null;
        ConverterOutputStream conv_stream = null;
        try {
            if(dest.query_exists())
                dest.delete();
            src_stream = source.read();
            dst_stream = dest.replace(null, false, 0);
            if(dst_stream == null) {
                print("Could not create output stream!\n");
                return false;
            }
        }
        catch(Error e) {
            print("Error decompressing! %s\n", e.message);
            label.label = "Magnatune Error 1";
            return false;
        }
        var zlc = new ZlibDecompressor(ZlibCompressorFormat.GZIP);
        conv_stream = new ConverterOutputStream(dst_stream, zlc);
        try {
            conv_stream.splice(src_stream, 0);
        }
        catch(IOError e) {
            print("Converter Error! %s\n", e.message);
            label.label = "Magnatune Error 2";
            return false;
        }
        Idle.add(() => {
            label.label = "decompressing finished...";
            var conv_job = new Worker.Job(Worker.ExecutionType.ONCE, convert_db_job);
            io_worker.push_job(conv_job);
            return false;
        });
        return false;
    }

    private bool convert_db_job(Worker.Job job) {
        Idle.add(() => {
            label.label = "Please wait while\nconverting database.";
            return false;
        });
        var conv = new MagnatuneDatabaseConverter();
        conv.progress.connect(on_db_conversion_progress);
        conv.move_data();
        conv.progress.disconnect(on_db_conversion_progress);
        conv = null;
        File fx = File.new_for_path(CONVERTED_DB);
        if(fx.query_exists(null)) {
            Idle.add( () => {
                database_available = true;
                add_tree();
                return false;
            });
        }
        else {
            printerr("ERROR CONVERTING DATABASE!!\n");
        }
        return false;
    }
    
    private void on_db_conversion_progress(MagnatuneDatabaseConverter sender, int c) {
        Idle.add(() => {
            pb.hide();
            label.label = "Please wait while\nconverting database.\nDone for %d tracks.".printf(c);
            return false;
        });
    }
    
    private void add_tree() {
        if(!database_available)
            return;
        this.remove(pb);
        this.remove(label);
        pb = null;
        label = null;
        sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        tv = new MagnatuneTreeView(this.dock, this, sw);
        sw.add(tv);
        this.pack_start(sw, true, true , 0);
        this.show_all();
    }
    
    private void progress_cb(int64 current_num_bytes, int64 total_num_bytes) {
        if(total_num_bytes <= 0)
            return;
        double fraction = (double)current_num_bytes / (double)total_num_bytes;
        if(fraction > 1.0)
            fraction = 1.0;
        if(fraction < 0.0)
            fraction = 0.0;
        
        Idle.add(() => {
            pb.set_fraction(fraction);
            return false;
        });
    }
    
    private void create_widgets() {
        label = new Label("loading...");
        this.pack_start(label, true, true, 0);
        pb = new ProgressBar();
        this.pack_start(pb, false, false, 0);
    }
}


