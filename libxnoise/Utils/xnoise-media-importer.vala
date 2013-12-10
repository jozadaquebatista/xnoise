/* xnoise-media-importer.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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

using Xnoise;
using Xnoise.Resources;
using Xnoise.Database;
using Xnoise.Utilities;
using Xnoise.TagAccess;



//public struct Xnoise.MediaFolder {
//    public Item folder;
//    public bool in_import;
//}


public class Xnoise.MediaImporter {
    
    private static const int FILE_COUNT = 500;
    
    // Imports/exports in progress
    private GLib.HashTable <string, Item?> import_targets  = new GLib.HashTable <string, Item?>(str_hash, str_equal);
    private GLib.HashTable <string, Item?> removal_targets = new GLib.HashTable <string, Item?>(str_hash, str_equal);
    
    // Media folders
    private GLib.List<Item?> media_folders = new GLib.List<Item?>();
    
//    // Media folders
//    private GLib.List<Item?> media_streams = new GLib.List<Item?>();
    
    //Signals
//    public signal void completed_import_target(Item? item);
//    public signal void processing_import_target(Item? item);
    public signal void media_folder_state_change();
    
    public signal void changed_library();
    
    public signal void folder_list_changed();
//    public signal void stream_list_changed();
    
    
    public MediaImporter() {
        update_media_folder_list();
//        update_media_stream_list();
    }
    
    
    private bool append_folder_to_mediafolders_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        assert(job.item.type == ItemType.LOCAL_FOLDER);
        db_writer.add_single_folder_to_collection(job.item);
        return false;
    }

    // Used after tagging from xnoise
    internal void reimport_media_files(string[] file_uris) {
        if(global.media_import_in_progress == true)
            return;
        string[] file_uris_loc = new string[file_uris.length];
        
        //remove from db
        var job = new Worker.Job(Worker.ExecutionType.ONCE, remove_uris_job);
        assert(file_uris != null);
        job.uris = file_uris;
        
        lock(removal_targets) {
            int i = 0;
            foreach(string? s in file_uris) {
                if(s != null) {
                    file_uris_loc[i] = s; i++;
                    if(!removal_targets.contains(s)) {
                        Item? it = Item(ItemType.UNKNOWN, s); // just for the balance
                        removal_targets.insert(s, it);
                    }
                }
                else {
                    file_uris_loc[i] = ""; i++;
                }
            }
        }
        lock(import_targets) { // enter here also to avoid double refresh
            foreach(string? s in file_uris) {
                if(s == null)
                    continue;
                if(!import_targets.contains(s)) {
                    Item? it = Item(ItemType.UNKNOWN, s); // just for the balance
                    import_targets.insert(s, it);
                }
            }
        }
        db_worker.push_job(job);
        
        //import files
        job = new Worker.Job(Worker.ExecutionType.ONCE, reimport_media_files_job);
        job.uris = file_uris_loc;
        db_worker.push_job(job);//via db thread so that it is handled inthe right order
    }
    
    private bool reimport_media_files_job(Worker.Job xjob) {
        //via db thread so that it is handled inthe right order
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        lock(import_targets) {
            foreach(string? s in xjob.uris) {
                if(s == null)
                    continue;
                if(!import_targets.contains(s)) {
                    Item? it = Item(ItemType.UNKNOWN, s); // just for the balance
                    import_targets.insert(s, it);
                }
            }
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, import_uris_job);
        job.uris = xjob.uris;
        xjob.uris = null;
        io_worker.push_job(job);
        return false;
    }
    
    public void remove_uris(string[] file_uris) {
        //remove from db
        var job = new Worker.Job(Worker.ExecutionType.ONCE, remove_uris_job);
        job.uris = file_uris;
        
        lock(removal_targets) {
            foreach(string? s in file_uris) {
                if(s == null)
                    continue;
                if(!removal_targets.contains(s)) {
                    Item? i = Item(ItemType.UNKNOWN, s); // just for the balance
                    removal_targets.insert(s, i);
                }
            }
        }
        db_worker.push_job(job);
    }
    
    // remove from database
    private bool remove_uris_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        db_writer.begin_transaction();
        foreach(string u in job.uris) {
            db_writer.remove_uri(u);
            lock(removal_targets) {
                removal_targets.remove(u);
            }
        }
        db_writer.commit_transaction();
        
        db_writer.begin_transaction();
        db_writer.cleanup_database();
        db_writer.commit_transaction();
        
        check_target_processing_queues();
        return false;
    }
    
    public void import_uris(string[] uris) {
        lock(import_targets) {
            foreach(string s in uris) {
                if(!import_targets.contains(s)) {
                    Item? i = Item(ItemType.UNKNOWN, s); // just for the balance
                    import_targets.insert(s, i);
                }
            }
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, import_uris_job);
        job.uris = uris;
        io_worker.push_job(job);
    }

    private bool import_uris_job(Worker.Job job) {
        return_val_if_fail(io_worker.is_same_thread(), false);
        
        if(job.uris == null || job.uris.length == 0)
            return false;
        
        TrackData[]? tda = {};
        string[] uris = {};
        bool got_data = false;
        
        foreach(string? s in job.uris) {
            if(s == null)
                continue;
            File f = File.new_for_uri(s);
            
            if(f == null)
                continue;
            
            if(f.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.REGULAR)
                return false;
            
            TrackData? td = TagReader.read_tag(f.get_path(), false);
            if(td != null) {
                got_data = true;
                FileInfo info = f.query_info(attr,
                                             FileQueryInfoFlags.NONE ,
                                             null);
                td.mimetype = GLib.ContentType.get_mime_type(info.get_content_type());
                td.change_time = (int32)info.get_attribute_uint64(FileAttribute.TIME_CHANGED);
                td.media_folder = null; // we are not in db thread!
                tda += td;
                uris += f.get_uri();
            }
        }
        if(got_data) {
            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
            db_job.set_arg("remove_import_targets", true);
            db_job.track_dat = tda;
            db_job.uris = (owned)job.uris;
            dbus_image_extractor.queue_uris(uris);
            db_worker.push_job(db_job);
        }
        else {
            lock(import_targets) {
                foreach(string s in job.uris)
                    import_targets.remove(s);
            }
        }
        return false;
    }
    
    private void update_media_folder_list() {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, update_media_folder_list_job, Worker.Priority.HIGH);
        db_worker.push_job(job);
    }

//    private void update_media_stream_list() {
//        var job = new Worker.Job(Worker.ExecutionType.ONCE, update_media_stream_list_job, Worker.Priority.HIGH);
//        db_worker.push_job(job);
//    }
    
    private bool update_media_folder_list_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        lock(media_folders) {
            media_folders = new GLib.List<Item?>();
            foreach(Item? i in db_reader.get_media_folders()) {
                media_folders.prepend(i);
            }
        }
        Idle.add(() => {
            folder_list_changed();
            return false;
        });
        return false;
    }
    
//    private bool update_media_stream_list_job(Worker.Job job) {
//        return_val_if_fail(db_worker.is_same_thread(), false);
//        lock(media_streams) {
//            media_streams = new GLib.List<Item?>();
//            foreach(Item? i in db_reader.get_stream_items("")) {
//                media_streams.prepend(i);
//            }
//        }
//        Idle.add(() => {
//            stream_list_changed();
//            return false;
//        });
//        return false;
//    }
//    
//    public GLib.List<Item?> get_media_streams_list() {
//        GLib.List<Item?> list = new GLib.List<Item?>();
//        lock(media_streams) {
//            foreach(Item i in media_streams) {
//                Item? it = i;
//                list.prepend(it);
//            }
//        }
//        return (owned)list;
//    }
    
    public GLib.List<Item?> get_media_folder_list() {
        GLib.List<Item?> list = new GLib.List<Item?>();
        lock(media_folders) {
            foreach(Item i in media_folders) {
                Item? item = i;
                list.prepend(item);
            }
        }
        return (owned)list;
    }
    
    public void add_import_target_folder(Item? target, bool add_folder_to_media_folders = false) {
        if(target == null || target.type != ItemType.LOCAL_FOLDER || target.uri == null)
            return;
        
        foreach(Item? i in get_media_folder_list()) {
            if(target.uri == i.uri) {
                print("folder %s is already in the list of media folders! \n", target.uri);
                return;
            }
        }
        lock(import_targets) {
            if(!import_targets.contains(target.uri))
                import_targets.insert(target.uri, target);
            global.media_import_in_progress = true;
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, imp_folder_target_job, Worker.Priority.HIGH);
        job.item = target;
        job.set_arg("add_folder_to_media_folders", add_folder_to_media_folders);
        db_worker.push_job(job);
    }
    
//    internal void rescan_media_folders(Worker w) {
//        foreach(Item it in get_media_folder_list()) {
//            File f = File.new_for_uri(it.uri);
//            lock(import_targets) {
//                if(!import_targets.contains(target.uri))
//                    import_targets.insert(target.uri, target);
////                global.media_import_in_progress = true;
//            }
//            var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
//            job.set_arg("media_folder", f.get_path());
//            job.item = it;
//            w.push_job(reader_job);
////            var job = new Worker.Job(Worker.ExecutionType.ONCE, imp_folder_target_job);
////            job.item = target;
////            job.set_arg("add_folder_to_media_folders", false);
////            db_worker.push_job(job);
//        }
//    }
    
    private void finished_import_target(Item? item) {
        if(item == null || item.uri == null)
            return;
        lock(import_targets) {
            if(item != null && import_targets.contains(item.uri)) {
                import_targets.remove(item.uri);
                //print("removed target: %s\n", item.uri);
                Item? i = item;
                Idle.add(() => {
                    media_folder_state_change();
//                    completed_import_target(i);
                    return false;
                });
            }
        }
        check_target_processing_queues();
    }
    
    internal void remove_media_folder(Item item) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, remove_media_folder_job);
        job.item = item;
        db_worker.push_job(job);
    }
    
    private bool remove_media_folder_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        assert(job.item.type == ItemType.LOCAL_FOLDER);
        db_writer.begin_transaction();
        db_writer.remove_single_media_folder(job.item);
        db_writer.commit_transaction();
        
        db_writer.begin_transaction();
        db_writer.cleanup_database();
        db_writer.commit_transaction();
        update_media_folder_list();
        
        check_target_processing_queues();
        
        return false;
    }
    
    private void sync_media_folder_to_db(string dir_uri) {
        print("sync_media_folder_to_db\n");
        return_val_if_fail(db_worker.is_same_thread(), false);
        var fjob = new Worker.Job(Worker.ExecutionType.ONCE, append_folder_to_mediafolders_job, Worker.Priority.HIGH);
        File mf = File.new_for_uri(dir_uri);
        fjob.item = Item(ItemType.LOCAL_FOLDER, mf.get_uri());
        db_worker.push_job(fjob);
        update_media_folder_list();
    }
    
    internal void remove_folder_item(Item? folder) {
        return_val_if_fail(folder != null, false);
        return_val_if_fail(folder.uri != null, false);
        return_val_if_fail(folder.type == ItemType.LOCAL_FOLDER, false);
        bool already_in_process = false;
        lock(removal_targets) {
            global.media_import_in_progress = true;
            if(removal_targets.contains(folder.uri)) {
                already_in_process = true;
            }
            else {
                removal_targets.insert(folder.uri, folder);
            }
        }
        if(already_in_process) {
            Idle.add(() => {
                print("folder removal is already being processed : %s\n", folder.uri);
                return false;
            });
            return;
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, remove_folder_item_job);
        job.item = folder;
        db_worker.push_job(job);
    }
    
    private void check_target_processing_queues() {
        bool no_remove_left = false;
        lock(removal_targets) {
            if(removal_targets.get_keys().length() == 0) {
                no_remove_left = true;
            }
            //else {
            //    print("removal_targets.get_keys().length(): %u\n", removal_targets.get_keys().length());
            //}
        }
        if(no_remove_left == false)
            return;
        lock(import_targets) {
            if(import_targets.get_keys().length() == 0 && no_remove_left) {
                Idle.add(() => {
                    changed_library();
                    return false;
                });
                global.media_import_in_progress = false;
            }
            //else {
            //    print("import_targets.get_keys().length(): %u\n", import_targets.get_keys().length());
            //}
        }
    }
    
    private bool remove_folder_item_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        return_val_if_fail(job.item.uri != null, false);
        
        File f = File.new_for_uri(job.item.uri);
        //check if removed forder is media folder
        if(f.get_path() in db_writer.get_media_folders()) {
            db_writer.begin_transaction();
            db_writer.remove_single_media_folder(job.item);
            db_writer.commit_transaction();
            
            db_writer.begin_transaction();
            db_writer.cleanup_database();
            db_writer.commit_transaction();
        }
        else {
            db_writer.begin_transaction();
            db_writer.remove_folder(job.item.uri);
            
            db_writer.cleanup_database();
            db_writer.commit_transaction();
        }
        
        lock(removal_targets) {
            removal_targets.remove(job.item.uri);
        }
        check_target_processing_queues();
        return false;
    }
    

    private bool imp_folder_target_job(Worker.Job job){
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        bool add_folder_to_media_folders = (bool)job.get_arg("add_folder_to_media_folders");
        assert(job.item != null);
        assert(job.item.uri != null);
        File? dir = File.new_for_uri(job.item.uri);
        assert(dir != null);
        
        var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
        
        string pth = dir.get_path();
        
        if(add_folder_to_media_folders) {
            sync_media_folder_to_db(job.item.uri);
        }
        else {
            //parent path must be available
            pth = db_reader.get_fitting_parent_path(pth);
        }
        
        reader_job.set_arg("media_folder", pth);
        reader_job.item = job.item;
        io_worker.push_job(reader_job);
        return false;
    }
    
//    public void add_stream(Item? item) {
//        return_if_fail(item.type == ItemType.STREAM || item.type == ItemType.PLAYLIST);
//        foreach(Item? i in get_media_streams_list()) {
//            if(item.uri == i.uri) {
//                print("Stream %s is already in the list of media folders! \n", item.uri);
//                return;
//            }
//        }
//        var job = new Worker.Job(Worker.ExecutionType.ONCE, store_stream_job);
//        job.item = item;
//        db_worker.push_job(job);
//    }
//    internal void import_media_groups(Item[] media_items,
//                                      uint msg_id,
//                                      bool full_rescan = true,
//                                      bool interrupted_populate_model = false) {
//        return_if_fail(Main.instance.is_same_thread());
//        t = new Timer(); // timer for measuring import time
//        t.start();
//        // global.media_import_in_progress has to be reset in the last job !
//        io_import_job_running = true;
//        
//        Worker.Job job;
//        if(full_rescan) {
//            //Reset subscribed Dockable Media
//            foreach(ResetNotificationData? cxd in reset_callbacks) {
//                if(cxd.cb != null) {
//                    cxd.cb();
//                }
//            }
//            renew_stamp(db_reader.get_datasource_name());
//            print("+++new stamp for db\n");
//            db_reader.refreshed_stamp(get_current_stamp(db_reader.get_source_id()));
//            
//            job = new Worker.Job(Worker.ExecutionType.ONCE, reset_local_data_library_job);
//            db_worker.push_job(job);
//        }
//        
//        int stream_cnt = 0;
//        foreach(Item? i in media_items) {
//            if(i.type == ItemType.STREAM || i.type == ItemType.PLAYLIST)
//                stream_cnt++;
//        }
//        if(stream_cnt > 0) {
//            job = new Worker.Job(Worker.ExecutionType.ONCE, store_streams_job);
//            job.items = {};
//            Item[] tmp = {};
//            
//            foreach(Item? i in media_items)
//                if(i.type == ItemType.STREAM || i.type == ItemType.PLAYLIST)
//                    tmp += i;
//            job.items = tmp;
//            
//            job.set_arg("full_rescan", full_rescan);
//            db_worker.push_job(job);
//        }
//        
//        //Assuming that number of streams will be relatively small,
//        //the progress of import will only be done for folder imports
//        job = new Worker.Job(Worker.ExecutionType.ONCE, store_folders_job);
//        job.items = {};
//        Item[] tmpx = {};
//        foreach(Item? i in media_items)
//            if(i.type == ItemType.LOCAL_FOLDER)
//                tmpx += i;
//        job.items = tmpx;
//        
//        job.set_arg("msg_id", msg_id);
////        current_import_msg_id = msg_id;
//        job.set_arg("interrupted_populate_model", interrupted_populate_model);
//        job.set_arg("full_rescan", full_rescan);
//        db_worker.push_job(job);
//    }
    
//    private bool io_import_job_running = false;

    internal bool write_lastused_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        try {
            db_writer.begin_transaction();
            db_writer.write_lastused(ref job.track_dat);
            db_writer.commit_transaction();
        }
        catch(DbError e) {
            print("%s\n", e.message);
        }
        return false;
    }

    private TrackData[] tda = {}; 
    private string[] uris_for_image_extraction  = {};

    // running in io thread
//    private void end_import(Worker.Job job) {
        //print("end import 1 %d %d\n", job.counter[1], job.counter[2]);
//        if(job.counter[1] != job.counter[2])
//            return;
//        
//        Idle.add( () => {
//            // update user info in idle in main thread
//            uint xcnt = 0;
////            lock(current_import_track_count) {
////                xcnt = current_import_track_count;
////            }
//            userinfo.update_text_by_id((uint)job.get_arg("msg_id"),
//                                       _("Found %u tracks. Updating library ...".printf(xcnt)),
//                                       false);
//            if(userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")) != null)
//                userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")).hide();
//            return false;
//        });
//        var finisher_job = new Worker.Job(Worker.ExecutionType.ONCE, finish_import_job);
//        finisher_job.set_arg("msg_id", job.get_arg("msg_id"));
//        db_worker.push_job(finisher_job);
//    }
    
    // running in db thread
//    private bool finish_import_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
//        return_val_if_fail(db_worker.is_same_thread(), false);
//        Idle.add(() => {
//            if(t != null) {
//                t.stop();
//                ulong usec;
//                double sec = t.elapsed(out usec);
//                int b = (int)(Math.floor(sec));
//                uint xcnt = 0;
////                lock(current_import_track_count) {
////                    xcnt = current_import_track_count;
////                }
//                print("finish import after %d s for %u tracks\n", b, xcnt);
//            }
//            return false;
//        });
//        Timeout.add_seconds(1, () => {
//            global.media_import_in_progress = false;
//            if((uint)job.get_arg("msg_id") != 0) {
//                userinfo.popdown((uint)job.get_arg("msg_id"));//current_import_msg_id);
//            }
////            lock(current_import_track_count) {
////                current_import_track_count = 0;
////            }
//            return false;
//        });
//        return false;
//    }

    // running in db thread
//    private bool reset_local_data_library_job(Worker.Job job) {
//        //this function uses the database so use it in the database thread
//        return_val_if_fail(db_worker.is_same_thread(), false);
//        db_writer.begin_transaction();
//        if(!db_writer.reset_database())
//            return false;
//        db_writer.commit_transaction();
//        
//        // remove streams
//        db_writer.del_all_streams();
//        return false;
//    }

    // add folders to the media path and store them in the db
    // only for Worker.Job usage
//    private bool store_folders_job(Worker.Job job){
//        //this function uses the database so use it in the database thread
//        return_val_if_fail(db_worker.is_same_thread(), false);
//        
//        //print("store_folders_job \n");
//        var mfolders_ht = new HashTable<string,Item?>(str_hash, str_equal);
//        if(((bool)job.get_arg("full_rescan"))) {
//            db_writer.del_all_folders();
//            
//            foreach(Item? folder in job.items)
//                mfolders_ht.insert(folder.uri, folder); // this removes double entries
//            
//            foreach(Item? folder in mfolders_ht.get_values())
//                db_writer.add_single_folder_to_collection(folder);
//            
//            if(mfolders_ht.get_keys().length() == 0) {
//                db_writer.commit_transaction();
//                end_import(job);
//                return false;
//            }
//            // COUNT HERE
//            //foreach(string folder in mfolders_ht.get_keys()) {
//            //    File file = File.new_for_commandline_arg(folder);
//            //    count_media_files(file, job);
//            //}
//            //print("count: %d\n", (int)(job.big_counter[0]));            
//            int cnt = 1;
//            foreach(Item? folder in mfolders_ht.get_values()) {
//                File dir = File.new_for_uri(folder.uri);
//                assert(dir != null);
//                // import all the files
//                var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
//                reader_job.set_arg("dir", dir);
//                reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
//                reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
//                reader_job.counter[1] = cnt;
//                reader_job.counter[2] = (int)mfolders_ht.get_keys().length();
//                io_worker.push_job(reader_job);
//                cnt ++;
//            }
//        }
//        else { // import new folders only
//            // after import at least the media folder have to be updated
//            
//            string[] dbfolders = db_writer.get_media_folders();
//            
//            foreach(Item? folder in job.items)
//                mfolders_ht.insert(folder.uri, folder); // this removes double entries
//            
//            db_writer.del_all_folders();
//            
//            foreach(Item? folder in mfolders_ht.get_values())
//                db_writer.add_single_folder_to_collection(folder);
//            
//            var new_mfolders_ht = new HashTable<string,Item?>(str_hash, str_equal);
//            foreach(Item? folder in mfolders_ht.get_values()) {
//                File f = File.new_for_uri(folder.uri);
//                if(f == null)
//                    continue;
//                print("f.get_path() : %s\n", f.get_path());
//                if(!(f.get_path() in dbfolders))
//                    new_mfolders_ht.insert(folder.uri, folder);
//            }
//            // COUNT HERE
//            //foreach(string folder in new_mfolders_ht.get_keys()) {
//            //    File file = File.new_for_commandline_arg(folder);
//            //    count_media_files(file, job);
//            //}
//            
//            if(new_mfolders_ht.get_keys().length() == 0) {
//                db_writer.commit_transaction();
//                end_import(job);
//                return false;
//            }
//            int cnt = 1;
//            foreach(Item? folder in new_mfolders_ht.get_values()) {
//                File? dir = File.new_for_uri(folder.uri);
//                print("++%s\n", folder.uri);
//                assert(dir != null);
//                var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
//                reader_job.set_arg("dir", dir);
//                reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
//                reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
//                reader_job.counter[1] = cnt;
//                reader_job.counter[2] = (int)new_mfolders_ht.get_keys().length();
//                io_worker.push_job(reader_job);
//                cnt++;
//            }
//        }
//        return false;
//    }
    
    
    // job.counter[0] : count folder depth
    // job.big_counter[1] : item count to track number of scanned files before db write
    
    // running in io thread
    private bool read_media_folder_job(Worker.Job job) {
        //this function shall run in the io thread
        return_val_if_fail(io_worker.is_same_thread(), false);
        //count_media_files((File)job.get_arg("dir"), job);
        assert(job.item != null);
        assert(job.item.uri != null);
        File d = File.new_for_uri(job.item.uri); //(File)job.get_arg("dir");
        Item? i = job.item;
        uint xx = 0;
        xx = Timeout.add(500, () => {
//            processing_import_target(i);
            media_folder_state_change();
            xx = 0;
            return false;
        });
        read_recoursive(d, job);
        if(xx != 0)
            Source.remove(xx);
        finished_import_target(job.item);
        return false;
    }
    
    private const string attr = FileAttribute.STANDARD_NAME + "," +
                                FileAttribute.STANDARD_TYPE + "," +
                                FileAttribute.TIME_CHANGED + "," +
                                FileAttribute.STANDARD_CONTENT_TYPE;
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_if_fail(io_worker.is_same_thread());
        
        job.counter[0]++;
        FileEnumerator enumerator;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            job.counter[0]--;
//            if(job.counter[0] == 0)
//                end_import(job);
            return;
        }
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                TrackData td = null;
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filename.has_prefix("."))
                    continue;
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    string uri_lc = filename.down();
                    string suffix = get_suffix_from_filename(uri_lc);
                    if(!Playlist.is_playlist_extension(suffix)) {
                        suffix = suffix.down();
                        if(suffix == "jpg"  || 
                           suffix == "jpeg" || 
                           suffix == "png"  || 
                           suffix == "nfo"  || 
                           suffix == "txt")
                            continue;
                        //print("filepath: %s\n", filepath);
                        td = TagReader.read_tag(filepath, false);
                        //print("2filepath: %s\n", filepath);
                        if(td != null) {
                            td.media_folder = (string?)job.get_arg("media_folder");
                            td.mimetype = GLib.ContentType.get_mime_type(info.get_content_type());
                            td.change_time = (int32)info.get_attribute_uint64(FileAttribute.TIME_CHANGED);
                            uris_for_image_extraction += file.get_uri();
                            tda += td;
                        }
                        if(tda.length > FILE_COUNT) {
                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
                            db_job.set_arg("remove_import_targets", false);
                            db_job.track_dat = (owned)tda;
                            tda = {};
                            dbus_image_extractor.queue_uris(uris_for_image_extraction);
                            uris_for_image_extraction = {};
                            db_worker.push_job(db_job);
                        }
                    }
                }
            }
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        job.counter[0]--;
        if(job.counter[0] == 0) {
            if(tda.length > 0) {
                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
                db_job.set_arg("remove_import_targets", false);
                db_job.track_dat = (owned)tda;
                tda = {};
                dbus_image_extractor.queue_uris(uris_for_image_extraction);
                uris_for_image_extraction = {};
                db_worker.push_job(db_job);
            }
        }
        return;
    }
    
    private bool insert_trackdata_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        bool remove_import_targets = false;
        remove_import_targets = (bool)job.get_arg("remove_import_targets");
        //if(remove_import_targets)
        //    print("insjob %d\n", job.uris.length);
        db_writer.begin_transaction();
        foreach(TrackData td in job.track_dat) {
            db_writer.insert_title(ref td);
        }
        db_writer.commit_transaction();
        if(remove_import_targets) {
            lock(import_targets) {
                foreach(string? s in job.uris) {
                    if(s == null)
                        continue;
                    //print("REMOVE URI from i_t %s\n", s);
                    import_targets.remove(s);
                }
            }
            check_target_processing_queues();
        }
        print("current jobs in db_worker: %d\n", db_worker.get_queue_length());
        return false;
    }

//    private bool store_stream_job(Worker.Job job) {
//        return_val_if_fail(db_worker.is_same_thread(), false);
//        
//        TrackData[]? track_dat = item_converter.to_trackdata(job.item, EMPTYSTRING);
//        
//        if(track_dat != null) {
//            foreach(TrackData td in track_dat) {
//                if(td.item.uri == null) {
//                    print("red alert!!!\n");
//                    continue;
//                }
//                td.item.text = (td.item.text != null ? td.item.text : EMPTYSTRING);
//                db_writer.add_single_stream_to_collection(td.item);
//            }
//        }
//        update_media_stream_list();
//        return false;
//    }
}

