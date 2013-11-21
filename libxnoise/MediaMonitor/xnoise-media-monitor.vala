/* xnoise-media-monitor.vala
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



using Xnoise;
//using Xnoise.PluginModule;


//public class Xnoise.MediaMonitorPlugin : GLib.Object, IPlugin {
//    
//    private unowned PluginModule.Container _owner;
//    
//    public MediaMonitor monitor;
//    
//    public PluginModule.Container owner {
//        get { return _owner; }
//        set { _owner = value; }
//    }

//    public Main xn { get; set; }
//    
//    public string name {
//        get { return "MediaMonitor"; }
//    }

//    public bool init() {
//        monitor = new MediaMonitor(MainContext.default());
//        return true;
//    }

//    public void uninit() {
//        monitor = null;
//    }

//    public Gtk.Widget? get_settings_widget() {
//        return null;
//    }

//    public bool has_settings_widget() {
//        return false;
//    }
//}


public class Xnoise.MediaMonitor : GLib.Object {
    private class Event {
        public enum ChangeType {
            CHANGED_FILE,
            DELETED_FILE,
            DELETED_DIR,
            CREATED_FILE,
            CREATED_DIR
        }
        
        public string? path;
        public ChangeType type;
        
        public Event(ChangeType type, string path) {
            this.type  = type;
            this.path  = path;
        }
    }
    
    private FileMonitor? monitor;
    private HashTable<string, FileMonitor> monitors;

    private MainContext local_context;
    private MainLoop local_loop;

    private unowned Thread<int> thread;
    
    public MediaMonitor() {
        if (!Thread.supported ()) {
            error("Cannot work without multithreading support.");
        }
        
        try {
            thread = Thread.create<int>(thread_func, false);
        }
        catch(ThreadError e) {
            print("Error creating thread: %s\n", e.message);
        }
        Source source = new TimeoutSource(2000); 
        source.set_callback(() => {
            setup_monitors();
            return false;
        });
        source.attach(local_context);
    }
    
    ~MediaMonitor() {
        if(monitor != null)
            monitor.cancel();
    }
    
    private int thread_func() {
        local_context = new MainContext();
        local_context.push_thread_default();
        local_loop = new MainLoop(local_context);
        local_loop.run();
        return 0;
    }

    private HashTable<string, Event> event_table = new HashTable<string, Event> (str_hash, str_equal);
    
    private void on_changed(FileMonitor sender,
                            File file,
                            File? other_file,
                            FileMonitorEvent event_type) {
        //print("local thread used is %s \n", ((void*)Thread.self<int>() == (void*)thread).to_string());
        //print("file: %s :: %s\n", file.get_basename(), event_type.to_string());
        if(sender.cancelled)
            return;
        switch(event_type) {
            case FileMonitorEvent.CHANGED:
                if(global.media_import_in_progress)
                    return;
                if(!monitors.contains(file.get_path())) {
                    if(!event_table.contains(file.get_path()))
                        event_table.insert(file.get_path(), 
                                           new Event(Event.ChangeType.CHANGED_FILE, 
                                                                 file.get_path()));
                    event_table_changed();
                }
                break;
            case FileMonitorEvent.CREATED:
                if(file.query_file_type(FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) {
                    add_monitor_for_directory(file);
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.CREATED_DIR, file.get_path()));
                }
                else {
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.CREATED_FILE, file.get_path()));
                }
                event_table_changed();
                break;
            case FileMonitorEvent.DELETED:
                if(monitors.contains(file.get_path())) {
                    monitors.remove(file.get_path());
                    if(event_table.contains(file.get_path()))
                        event_table.remove(file.get_path());
                    
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.DELETED_DIR, file.get_path()));
                    break;
                }
                event_table_changed();
                break;
            case FileMonitorEvent.MOVED:
                if(monitors.contains(file.get_path())) {
                    monitors.remove(file.get_path());
                    add_monitor_for_directory(other_file);
                    
                    if(event_table.contains(file.get_path()))
                        event_table.remove(file.get_path());
                    
                    event_table.insert(file.get_path(), 
                                       new Event(Event.ChangeType.DELETED_DIR, 
                                                             file.get_path()));
                    
                    event_table.insert(other_file.get_path(), 
                                       new Event(Event.ChangeType.CREATED_DIR, 
                                                             other_file.get_path()));
                }
                else {
                    bool temp_file = false;
                    if(event_table.contains(file.get_path())) {
                        if(event_table.lookup(file.get_path()).type == Event.ChangeType.CREATED_FILE) {
                            temp_file = true;
                        }
                        event_table.remove(file.get_path());
                    }
                    if(temp_file) {
                        event_table.insert(other_file.get_path(), 
                                           new Event(Event.ChangeType.CHANGED_FILE, 
                                                                 other_file.get_path()));
                    }
                    else {
                        event_table.insert(file.get_path(), 
                                           new Event(Event.ChangeType.DELETED_FILE, 
                                                                 file.get_path()));
                        event_table.insert(other_file.get_path(), 
                                           new Event(Event.ChangeType.CREATED_FILE, 
                                                                 other_file.get_path()));
                    }
                }
                event_table_changed();
                break;
            default: break;
        }
    }
    
    private uint handler_id = 0;
    
    private void event_table_changed() {
        if(handler_id != 0) {
            Source s = local_context.find_source_by_id(handler_id);
            s.destroy();
        }
        Source source = new TimeoutSource(1000); 
        source.set_callback(() => {
            if(MainContext.current_source().is_destroyed()) {
                print("current source removed\n");
                return false;
            }
            HashTable<string, Event> local_event_table = event_table;
            event_table = new HashTable<string, Event>(str_hash, str_equal);
            List<Event> list = local_event_table.get_values();
            foreach(Event e in list)
                print("EVHT: %s  ::  %s\n", e.path, e.type.to_string());
            print("---------------------------------\n\n");
            handler_id = 0;
            return false;
        });
        handler_id = source.attach(local_context);
    }

    private void add_monitor_for_directory(File dir){
        try {
            FileMonitor monitor = dir.monitor_directory(FileMonitorFlags.SEND_MOVED);
            monitor.changed.connect(on_changed);
            if(monitors.contains(dir.get_path()))
                warning("file monitor exists for path " + dir.get_path());
            monitors.insert(dir.get_path(), monitor);
        }
        catch(IOError e) {
            print("Media Monitor error: %s\n", e.message);
        }
    }
    
//                if(file.query_file_type(FileQueryInfoFlags.NONE, null) == FileType.REGULAR) {
//                    media_importer.import_media_file(file.get_path());
//                    break;
//                }
//                if(file.query_file_type(FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) {
//                    media_importer.import_media_folder(file.get_path());
//                    break;
//                }
    
    private void setup_monitors() {
        File dir = File.new_for_path(Environment.get_user_special_dir(UserDirectory.MUSIC));
        monitors = new HashTable<string, FileMonitor>(str_hash, str_equal); //List<FileMonitor>();
        setup_monitor_recoursive(dir);
    }

    private string attr = FileAttribute.STANDARD_NAME + "," +
                          FileAttribute.STANDARD_TYPE;
    
    private void setup_monitor_recoursive(File dir) {
        if(dir.get_path() == null)
            return;
        if(dir.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
            return;
        add_monitor_for_directory(dir);
        
        FileEnumerator enumerator;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error reading directory %s: %s\n", dir.get_path(), e.message);
            return;
        }
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY)
                    setup_monitor_recoursive(file);
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
    }






//    
//    private class DataPair : GLib.Object{
//        public DataPair(string path, FileMonitor monitor) {
//            this.path = path;
//            this.monitor = monitor;
//        }
//        
//        public FileMonitor monitor;
//        public string path;
//    }

//    /* creates file monitors for all directories in the media path */ 
//    private void setup_monitors_job(Worker.Job job) {
//        monitor_list = new List<DataPair>();
//        
//        var mfolders = db_reader.get_media_folders();
//        
//        foreach(string mfolder in mfolders)
//            setup_monitor_for_path(mfolder);
//    }
//    
//    private void media_path_changed_cb() {
//        //in future, when we are informed of path changes item by item
//        //we will be able to remove and add specific monitors 
//        if(monitor_list != null) {
//            unowned List<DataPair> iter = monitor_list;
//            while((iter = iter.next) != null) {
//                iter.data.monitor.cancel(); //This seems to necessary
//                iter.data.monitor.unref();
//            }
//            monitor_list.data.monitor.cancel(); //This seems to necessary
//            monitor_list.data.monitor.unref();
//            monitor_list = null;
//        }
//        var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.setup_monitors_job);
//        db_worker.push_job(job);
//    }
//    
//    /* setup file monitors for a directory and all its subdirectories, reference them and
//     store them in monitor_list */
//    private void setup_monitor_for_path(string path) {
//        //print("setup_monitor_for_path : %s\n", path);
//        try {
//            var dir = File.new_for_path(path);
//            var monitor = dir.monitor_directory(FileMonitorFlags.NONE);
//            monitor.changed.connect(file_changed_cb);
//            monitor.set_rate_limit(monitoring_frequency);
//            var d = new DataPair(path, monitor);
//            monitor.ref();
//            monitor_list.append(d);

//            monitor_all_subdirs(dir);
//        }
//        catch(IOError e) {
//            print("Could not setup file monitoring for \'%s\': Error %s\n", path, e.message);
//        }
//    }

//    private void remove_dir_monitors(string path) {
//        monitor_list.foreach((data) => {
//            unowned List<DataPair> iter = monitor_list;
//            while(iter != null) {    
//                if(iter.data.path.has_prefix(path)) {
//                    print("removed monitor %s", iter.data.path);
//                    iter.data.monitor.cancel(); //This seems to necessary
//                    iter.data.monitor.unref();
//                    unowned List<DataPair> temp = iter.next;
//                    iter.delete_link(iter);
//                    iter = temp;
//                    print("REMOVE\n");
//                }
//                else iter = iter.next;
//            }
//        });
//    }
//    
//    private bool monitor_in_list(string path) {
//        bool success = false;
//        monitor_list.foreach((data) => {
//            unowned List<DataPair> iter = monitor_list;
//            while(iter != null) {
//                //print("!!%s\n", iter.data.path);
//                if(iter.data.path == path) success = true;
//                iter = iter.next;
//            }
//        });
//        return success;
//    }
//            
//    private void handle_deleted_file_job(Worker.Job job) {
//        //if the file was a directory it is in monitor_list
//        //search for filepath in monitor list and remove it
//        //remove all its subdirs from monitor list
//        //in the course of that try to remove the uri of every file 
//        //that was in those directories from the db 
//        //(we might need to store the directory of files in the db)
//        File file = (File)job.get_arg("file");
//        print("File deleted: \'%s\'\n", file.get_path());

//        if(monitor_in_list(file.get_path())) {
//            print("%s was a directory\n", file.get_path());
//            
//            

//            var search_string = file.get_uri();
//            search_string = search_string.replace("%", "\\%");
//            search_string = search_string.replace("_", "\\_");
//            search_string += "/%";
//            var results = db_reader.get_uris(search_string);
//            foreach (string a in results) {
//                print("deleting %s from db\n", a);
//                dbw.delete_uri(a);
//            }
//        }
//        
//        dbw.delete_uri(file.get_uri());
//        remove_dir_monitors(file.get_path());
//    
////        if(main_window.musicBr != null)
////            main_window.musicBr.change_model_data();
////        Idle.add( () => {
//        dbw = null;
////            return false;
////        });
//    }

//    private void handle_created_file_job(Worker.Job job) {
//        File file = (File)job.get_arg("file");
//        print("\'%s\' has been created recently, updating db...\n", file.get_path());
//        string buffer = file.get_path();
//        queue.push_tail(buffer);
//        if(queue.length > 0)
//            starter_method_async.begin(job);
//    }
//    
////    private Writer dbw = null;
//    
//    private async void starter_method_async(Worker.Job job) {
//        if(async_running == true)
//            return;
//        while(queue.length > 0) {
//            async_running = true;
//            yield async_worker(job);
//        }
////        Idle.add( () => {
////            dbw = null;
////            return false;
////        });
////        Idle.add( () => {
////            if(main_window.musicBr != null)
////                main_window.musicBr.change_model_data(); // where is this used
////            return false;
////        });
//        async_running = false;
//    }

//    private bool async_running = false;

//    private async void async_worker(Worker.Job job) {
//        // todo : this seems to be a blocker for the gui
//        // doing this async in a source function and taking data from a queue improved the situation slightly
//        string? path = queue.peek_head();
//        if(path == null)
//            return;
//        print("\nHANDLE QUEUE for %s\n", path);
//        File file = File.new_for_path(path);
//        queue.pop_head();
////        if(dbw == null) {
////         Writer dbw;
////        try {
////            dbw = new Writer();
////        }
////        catch(Error e1) {
////            print("%s\n", e1.message);
////            return;
////        }
////        }
////        var mi = new MediaImporter();
//        try {
//            var info = file.query_info(FileAttribute.STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
//            if(info.get_file_type() == FileType.REGULAR) media_importer.add_single_file(file.get_uri());
//            else if (info.get_file_type() == FileType.DIRECTORY) {
//                add_local_tags.begin(file);
//print("++1\n");
////                media_importer.add_local_tags(file, job);
////print("++2\n");
////                setup_monitor_for_path(file.get_path());
////print("++3\n");
//            }
//        } 
//        catch(Error e2) {
//            print("Adding of \'%s\' failed: Error: %s\n", file.get_path(), e2.message);
//        }
//    }

//    private async void add_local_tags(File dir) { //Writer dbw,
//        
//        FileEnumerator enumerator;
//        string attr = FileAttribute.STANDARD_NAME + "," +
//                      FileAttribute.STANDARD_TYPE + "," +
//                      FileAttribute.STANDARD_CONTENT_TYPE;
//        try {
//            enumerator = yield dir.enumerate_children_async(attr, FileQueryInfoFlags.NONE, GLib.Priority.DEFAULT, null);
//        } 
//        catch (Error error) {
//            critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
//            return;
//        }
//        GLib.List<GLib.FileInfo> infos;
//        try {
//            while(true) {
//                infos = yield enumerator.next_files_async(15, GLib.Priority.DEFAULT, null);
//                
//                if(infos == null) {
//                    return;
//                }
//                TrackData td;
//                foreach(FileInfo info in infos) {
//                    int idbuffer;
//                    string filename = info.get_name();
//                    string filepath = Path.build_filename(dir.get_path(), filename);
//                    File file = File.new_for_path(filepath);
//                    FileType filetype = info.get_file_type();

//                    string content = info.get_content_type();
//                    string mime = GLib.ContentType.get_mime_type(content);
//                    PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
//                    PatternSpec psVideo = new PatternSpec("video*");

//                    if(filetype == FileType.DIRECTORY) {
//                        yield this.add_local_tags(file);
//                        setup_monitor_for_path(file.get_path());
//                    }
//                    else if(psAudio.match_string(mime)) {
//                        string uri_lc = filepath.down();
//                        if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
//                            var job = new Worker.Job(33, Worker.ExecutionType.REPEATED_LOW_PRIORITY, this.low_prio_import_job, null);
//                            string nm = file.get_uri();
//                            job.set_arg("uri", nm);
//                            worker.push_job(job);
//                        }
//                    }
//                }
//            }
//        }
//        catch(Error e) {
//            print("%s\n", e.message);
//        }
//        return;
//    }
//    
//    private bool low_prio_import_job(Worker.Job job) {
//        print("low prio job!\n");
//        Writer dbw = null;
//        try {
//            dbw = new Writer();
//        }
//        catch(Error e) {
//            print("%s\n", e.message);
//        }
//        File f = File.new_for_uri((string)job.get_arg("uri"));
//        int idbuffer = dbw.uri_entry_exists(f.get_uri());
//        if(idbuffer== -1) {
//            var tr = new TagReader();
//            TrackData td = tr.read_tag(f.get_path());
//            td.db_id = dbw.insert_title(td, f.get_uri());
//            TrackData[] tdy = { td };
//            Idle.add( () => {
//                main_window.musicBr.mediabrowsermodel.insert_trackdata_sorted(tdy); 
//                return false; 
//            });
//        }
////        media_importer.add_single_file((string)job.get_arg("uri"));
//        return false;
//    }
//    
////    private void async_worker() {
////        // todo : this seems to be a blocker for the gui
////        // doing this async in a source function and taking data from a queue improved the situation slightly
////        string? path = queue.peek_head();
////        if(path == null)
////            return;
////        print("\nHANDLE QUEUE for %s\n", path);
////        File file = File.new_for_path(path);
////        queue.pop_head();
////        Writer dbw = null;
////        try {
////            dbw = new Writer();
////        }
////        catch(Error e) {
////            print("%s\n", e.message);
////            return;
////        }
////        var mi = new MediaImporter();
////        try {
////            var info = file.query_info(FileAttribute.STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
////        
////            if(info.get_file_type() == FileType.REGULAR) mi.add_single_file(file.get_uri(), ref dbw);    
////            else if (info.get_file_type() == FileType.DIRECTORY) {
////                mi.add_local_tags(file, ref dbw);
////                setup_monitor_for_path(file.get_path());
////            }
////            Idle.add( () => {
////                if(main_window.musicBr != null)
////                    main_window.musicBr.change_model_data();
////                return false;
////            });
////        } 
////        catch(Error e) {
////            print("Adding of \'%s\' failed: Error: %s\n", file.get_path(), e.message);
////        }
////    }

//    private void file_changed_cb(FileMonitor sender, File file, File? other_file, FileMonitorEvent event_type) {
//        if(!global.media_import_in_progress) {
//            print("%s\n", event_type.to_string());
//            if(event_type == FileMonitorEvent.CREATED) { // TODO: monitor removal of folders, too
//                if(file != null) {
//                    var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_created_file_job);
//                    job.set_arg("file", file);
//                    worker.push_job(job);
////                    handle_created_file(file);
//                }
//            }
//            if(event_type == FileMonitorEvent.DELETED) {
//                if(file != null) {
//                    var job = new Worker.Job(1, Worker.ExecutionType.ONCE, null, this.handle_deleted_file_job);
//                    job.set_arg("file", file);
//                    worker.push_job(job);
//                }
////                handle_deleted_file(file);
//            }
//        }
//    }

//    /* sets up file monitors for all subdirectories of a directory, references them and
//     stores them in monitor_list */
//    private void monitor_all_subdirs(File f) {
//        try {
//            var enumerator = f.enumerate_children(FileAttribute.STANDARD_TYPE + "," +
//                                                  FileAttribute.STANDARD_NAME,
//                                                  0,
//                                                  null);
//            FileInfo info;
//            while((info = enumerator.next_file(null)) != null) {
//                if(info.get_file_type() == FileType.DIRECTORY) {
//                    var temp_f = File.new_for_path(GLib.Path.build_filename(f.get_path(), info.get_name(), null));
//    
//                    var temp_mon = temp_f.monitor_directory(FileMonitorFlags.NONE);
//                    temp_mon.changed.connect(file_changed_cb);
//                    temp_mon.set_rate_limit(monitoring_frequency);
//                    var d = new DataPair(temp_f.get_path(), temp_mon);
//                    temp_mon.ref();
//                    monitor_list.append(d);
//                
//                    monitor_all_subdirs(temp_f);
//                }
//            }
//        }
//        catch(IOError e) {
//            print("Setting up file monitoring: Error: %s\n", e.message);
//        }
//        catch(Error e) {
//            print("Setting up file monitoring: Error: %s\n", e.message);
//        }
//    }
}


