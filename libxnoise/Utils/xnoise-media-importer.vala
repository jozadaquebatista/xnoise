/* xnoise-media-importer.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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

public class Xnoise.MediaImporter : GLib.Object {
    
    private static int FILE_COUNT = 150;
    
    public delegate void DatabaseResetCallback();
    
    public struct ResetNotificationData {
        public unowned DatabaseResetCallback cb;
    }
    
    private List<ResetNotificationData?> reset_callbacks = new List<ResetNotificationData?>();
    
    public void register_reset_callback(ResetNotificationData? cbd) {
        if(cbd == null)
            return;
        reset_callbacks.prepend(cbd);
    }
    
    internal void reimport_media_groups() {
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, reimport_media_groups_job);
        db_worker.push_job(job);
    }
    
    public void import_media_folder(string folder_path,
                                   bool create_user_info = false,
                                   bool add_folder_to_media_folders = false) {
        var dir = File.new_for_path(folder_path);
        if(dir.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
            return;
        if(global.media_import_in_progress == true)
            return;
        if(add_folder_to_media_folders) {
            Worker.Job fjob = new Worker.Job(Worker.ExecutionType.ONCE, append_folder_to_mediafolders_job);
            fjob.item = Item(ItemType.LOCAL_FOLDER);
            File mf = File.new_for_path(folder_path);
            fjob.item.uri = mf.get_uri();
            db_worker.push_job(fjob);
        }
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, import_media_folder_job);
        job.set_arg("path", dir.get_path());
        job.set_arg("create_user_info", create_user_info);
        io_worker.push_job(job);
    }
    
    private bool append_folder_to_mediafolders_job(Worker.Job job) {
        assert(job.item.type == ItemType.LOCAL_FOLDER);
        db_writer.add_single_folder_to_collection(job.item);
        return false;
    }

    private bool import_media_folder_job(Worker.Job job) {
        return_val_if_fail(io_worker.is_same_thread(), false);
        uint msg_id = 0;
        Idle.add( () => {
            if((bool)job.get_arg("create_user_info") == true) {
                var prg_bar = new Gtk.ProgressBar();
                prg_bar.set_fraction(0.0);
                prg_bar.set_text("0 / 0");
                msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                        UserInfo.ContentClass.WAIT,
                                        _("Importing media data. This may take some time..."),
                                        true,
                                        5,
                                        prg_bar);
            }
            File dir = File.new_for_path((string)job.get_arg("path"));
            
            global.media_import_in_progress = true;
            
            print("++%s\n", dir.get_path());
            assert(dir != null);
            var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
            reader_job.set_arg("dir", dir);
            reader_job.set_arg("msg_id", msg_id);
            reader_job.set_arg("full_rescan", true);
            io_worker.push_job(reader_job);
            
            return false;
        });
        return false;
    }
    
    public void import_media_file(string file_path) {
        var f = File.new_for_path(file_path);
        if(f.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.REGULAR)
            return;
        if(global.media_import_in_progress == true)
            return;
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, import_media_file_job);
        job.set_arg("path", f.get_path());
        io_worker.push_job(job);
    }

    private bool import_media_file_job(Worker.Job job) {
        return_val_if_fail(io_worker.is_same_thread(), false);
        var tr = new TagReader();
        File f = File.new_for_path((string)job.get_arg("path"));
        TrackData? td = tr.read_tag(f.get_path());
        if(td != null) {
            FileInfo info = f.query_info(FileAttribute.STANDARD_TYPE + "," + 
                                         FileAttribute.STANDARD_CONTENT_TYPE,
                                         FileQueryInfoFlags.NONE ,
                                         null);
            td.mimetype = GLib.ContentType.get_mime_type(info.get_content_type());
            TrackData[]? tda = {};
            tda += td;
            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
            db_job.track_dat = (owned)tda;
            uint msg_id = 0;
            db_job.set_arg("msg_id", msg_id);
            db_worker.push_job(db_job);
        }
        return false;
    }

    private Timer t;
    
    private bool reimport_media_groups_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        main_window.musicBr.mediabrowsermodel.cancel_fill_model(); // TODO
        
        Item[] tmp = {};
        //add folders
         Item[] fldrs = db_reader.get_media_folders();
        foreach(Item? i in fldrs) //append
            tmp += i;
        
        //add streams to list
        Item[] strms = db_reader.get_stream_items("");
        foreach(Item? i in strms) //append
            tmp += i;
            
        job.items = (owned)tmp;
        
        Timeout.add(200, () => {
            var prg_bar = new Gtk.ProgressBar();
            prg_bar.set_fraction(0.0);
            prg_bar.set_text("0 / 0");
            uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                         UserInfo.ContentClass.WAIT,
                                         _("Importing media data. This may take some time..."),
                                         true,
                                         5,
                                         prg_bar);
            global.media_import_in_progress = true;
            
            import_media_groups(job.items, msg_id, true, false);
            
            return false;
        });
        return false;
    }

    internal void update_item_tag(ref Item? item, ref TrackData td) {
        
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        if(global.media_import_in_progress == true)
            return;
        db_writer.update_title(ref item, ref td);
    }
    
//    private uint current_import_msg_id = 0;
    private uint current_import_track_count = 0;
    
    internal void import_media_groups(Item[] media_items,
                                      uint msg_id,
                                      bool full_rescan = true,
                                      bool interrupted_populate_model = false) {
        return_if_fail(Main.instance.is_same_thread());
        t = new Timer(); // timer for measuring import time
        t.start();
        // global.media_import_in_progress has to be reset in the last job !
        io_import_job_running = true;
        
        Worker.Job job;
        if(full_rescan) {
            //Reset subscribed Dockable Media
            foreach(ResetNotificationData? cxd in reset_callbacks) {
                if(cxd.cb != null) {
                    cxd.cb();
                }
            }
            renew_stamp(db_reader.get_datasource_name());
            print("+++new stam for db\n");
            db_reader.refreshed_stamp(get_current_stamp(db_reader.get_source_id()));
            
            job = new Worker.Job(Worker.ExecutionType.ONCE, reset_local_data_library_job);
            db_worker.push_job(job);
        }
        
        int stream_cnt = 0;
        foreach(Item? i in media_items) {
            if(i.type == ItemType.STREAM || i.type == ItemType.PLAYLIST)
                stream_cnt++;
        }
        if(stream_cnt > 0) {
            job = new Worker.Job(Worker.ExecutionType.ONCE, store_streams_job);
            job.items = {};
            Item[] tmp = {};
            
            foreach(Item? i in media_items)
                if(i.type == ItemType.STREAM || i.type == ItemType.PLAYLIST)
                    tmp += i;
            job.items = (owned)tmp;
            
            job.set_arg("full_rescan", full_rescan);
            db_worker.push_job(job);
        }
        
        //Assuming that number of streams will be relatively small,
        //the progress of import will only be done for folder imports
        job = new Worker.Job(Worker.ExecutionType.ONCE, store_folders_job);
        job.items = {};
        Item[] tmpx = {};
        foreach(Item? i in media_items)
            if(i.type == ItemType.LOCAL_FOLDER)
                tmpx += i;
        job.items = (owned)tmpx;
        
        job.set_arg("msg_id", msg_id);
//        current_import_msg_id = msg_id;
        job.set_arg("interrupted_populate_model", interrupted_populate_model);
        job.set_arg("full_rescan", full_rescan);
        db_worker.push_job(job);
    }
    
    private bool io_import_job_running = false;

    internal bool write_lastused_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        try {
            db_writer.write_lastused(ref job.track_dat);
        }
        catch(DbError e) {
            print("%s\n", e.message);
        }
        return false;
    }

    private TrackData[] tda = {}; 

    // running in io thread
    private void end_import(Worker.Job job) {
        //print("end import 1 %d %d\n", job.counter[1], job.counter[2]);
        if(job.counter[1] != job.counter[2])
            return;
        
        Idle.add( () => {
            // update user info in idle in main thread
            uint xcnt = 0;
            lock(current_import_track_count) {
                xcnt = current_import_track_count;
            }
            userinfo.update_text_by_id((uint)job.get_arg("msg_id"),
                                       _("Found %u tracks. Updating library ...".printf(xcnt)),
                                       false);
            if(userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")) != null)
                userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")).hide();
            return false;
        });
        var finisher_job = new Worker.Job(Worker.ExecutionType.ONCE, finish_import_job);
        finisher_job.set_arg("msg_id", job.get_arg("msg_id"));
        db_worker.push_job(finisher_job);
    }
    
    // running in db thread
    private bool finish_import_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        Idle.add(() => {
            if(t != null) {
                t.stop();
                ulong usec;
                double sec = t.elapsed(out usec);
                int b = (int)(Math.floor(sec));
                uint xcnt = 0;
                lock(current_import_track_count) {
                    xcnt = current_import_track_count;
                }
                print("finish import after %d s for %u tracks\n", b, xcnt);
            }
            return false;
        });
        Timeout.add_seconds(1, () => {
            global.media_import_in_progress = false;
            if((uint)job.get_arg("msg_id") != 0) {
                userinfo.popdown((uint)job.get_arg("msg_id"));//current_import_msg_id);
            }
            lock(current_import_track_count) {
                current_import_track_count = 0;
            }
            return false;
        });
        return false;
    }

    // running in db thread
    private bool reset_local_data_library_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        db_writer.begin_transaction();
        if(!db_writer.delete_local_media_data())
            return false;
        db_writer.commit_transaction();
        
        // remove streams
        db_writer.del_all_streams();
        return false;
    }

    // add folders to the media path and store them in the db
    // only for Worker.Job usage
    private bool store_folders_job(Worker.Job job){
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        //print("store_folders_job \n");
        var mfolders_ht = new HashTable<string,Item?>(str_hash, str_equal);
        if(((bool)job.get_arg("full_rescan"))) {
            db_writer.del_all_folders();
            
            foreach(unowned Item? folder in job.items)
                mfolders_ht.insert(folder.uri, folder); // this removes double entries
            
            foreach(unowned Item? folder in mfolders_ht.get_values())
                db_writer.add_single_folder_to_collection(folder);
            
            if(mfolders_ht.get_keys().length() == 0) {
                db_writer.commit_transaction();
                end_import(job);
                return false;
            }
            // COUNT HERE
            //foreach(string folder in mfolders_ht.get_keys()) {
            //    File file = File.new_for_commandline_arg(folder);
            //    count_media_files(file, job);
            //}
            //print("count: %d\n", (int)(job.big_counter[0]));            
            int cnt = 1;
            foreach(unowned Item? folder in mfolders_ht.get_values()) {
                File dir = File.new_for_uri(folder.uri);
                assert(dir != null);
                // import all the files
                var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
                reader_job.set_arg("dir", dir);
                reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
                reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
                reader_job.counter[1] = cnt;
                reader_job.counter[2] = (int)mfolders_ht.get_keys().length();
                io_worker.push_job(reader_job);
                cnt ++;
            }
        }
        else { // import new folders only
            // after import at least the media folder have to be updated
            
            string[] dbfolders = db_writer.get_media_folders();
            
            foreach(unowned Item? folder in job.items)
                mfolders_ht.insert(folder.uri, folder); // this removes double entries
            
            db_writer.del_all_folders();
            
            foreach(unowned Item? folder in mfolders_ht.get_values())
                db_writer.add_single_folder_to_collection(folder);
            
            var new_mfolders_ht = new HashTable<string,Item?>(str_hash, str_equal);
            foreach(unowned Item? folder in mfolders_ht.get_values()) {
                File f = File.new_for_uri(folder.uri);
                if(f == null)
                    continue;
                print("f.get_path() : %s\n", f.get_path());
                if(!(f.get_path() in dbfolders))
                    new_mfolders_ht.insert(folder.uri, folder);
            }
            // COUNT HERE
            //foreach(string folder in new_mfolders_ht.get_keys()) {
            //    File file = File.new_for_commandline_arg(folder);
            //    count_media_files(file, job);
            //}
    
            if(new_mfolders_ht.get_keys().length() == 0) {
                db_writer.commit_transaction();
                end_import(job);
                return false;
            }
            int cnt = 1;
            foreach(unowned Item? folder in new_mfolders_ht.get_values()) {
                File? dir = File.new_for_uri(folder.uri);
                print("++%s\n", folder.uri);
                assert(dir != null);
                var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
                reader_job.set_arg("dir", dir);
                reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
                reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
                reader_job.counter[1] = cnt;
                reader_job.counter[2] = (int)new_mfolders_ht.get_keys().length();
                io_worker.push_job(reader_job);
                cnt++;
            }
        }
        return false;
    }
    
    // running in io thread
    private bool read_media_folder_job(Worker.Job job) {
        //this function shall run in the io thread
        return_val_if_fail(io_worker.is_same_thread(), false);
        //count_media_files((File)job.get_arg("dir"), job);
        read_recoursive((File)job.get_arg("dir"), job);
        return false;
    }
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_if_fail(io_worker.is_same_thread());
        
        job.counter[0]++;
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            job.counter[0]--;
            if(job.counter[0] == 0)
                end_import(job);
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
                if(filetype == FileType.DIRECTORY) {
                    read_recoursive(file, job);
                }
                else {
                    string uri_lc = filename.down();
                    if(!Playlist.is_playlist_extension(get_suffix_from_filename(uri_lc))) {
                        var tr = new TagReader();
                        td = tr.read_tag(filepath);
                        if(td != null) {
                            td.mimetype = GLib.ContentType.get_mime_type(info.get_content_type());
                            tda += td;
                            job.big_counter[1]++;
                            lock(current_import_track_count) {
                                current_import_track_count++;
                            }
                        }
                        if(job.big_counter[1] % 50 == 0) {
                            Idle.add( () => {  // Update progress bar
                                uint xcnt = 0;
                                lock(current_import_track_count) {
                                    xcnt = current_import_track_count;
                                }
                                unowned Gtk.ProgressBar pb = 
                                    (Gtk.ProgressBar) userinfo.get_extra_widget_by_id(
                                                                    (uint)job.get_arg("msg_id")
                                );
                                if(pb != null) {
                                    pb.pulse();
                                    pb.set_text(_("%u tracks found").printf(xcnt));
                                }
                                return false;
                            });
                        }
                        if(tda.length > FILE_COUNT) {
                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
                            db_job.track_dat = (owned)tda;
                            db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
                            tda = {};
                            db_worker.push_job(db_job);
                        }
                    }
//                    else {
//                        print("found playlist file\n");
//                        Item item = ItemHandlerManager.create_item(file.get_uri());
//                        TrackData[]? playlist_content = null;
//                        var pr = new Playlist.Reader();
//                        Playlist.Result rslt;
//                        try {
//                            rslt = pr.read(item.uri , null);
//                        }
//                        catch(Playlist.ReaderError e) {
//                            print("%s\n", e.message);
//                            continue;
//                        }
//                        if(rslt != Playlist.Result.SUCCESS)
//                            continue;
//                        Playlist.EntryCollection ec = pr.data_collection;
//                        if(ec != null) {
//                            playlist_content = {};
//                            foreach(Playlist.Entry e in ec) {
//                                var tmp = new TrackData();
//                                tmp.title  = (e.get_title()  != null ? e.get_title()  : UNKNOWN_TITLE);
//                                tmp.album  = (e.get_album()  != null ? e.get_album()  : UNKNOWN_ALBUM);
//                                tmp.artist = (e.get_author() != null ? e.get_author() : UNKNOWN_ARTIST);
//                                tmp.genre  = (e.get_genre()  != null ? e.get_genre()  : UNKNOWN_GENRE);
//                                tmp.item   = ItemHandlerManager.create_item(e.get_uri());
//                                File fe = File.new_for_uri(e.get_uri());
//                                FileInfo einfo = null;
//                                try {
//                                    einfo = fe.query_info(FileAttribute.STANDARD_TYPE + "," + 
//                                                          FileAttribute.STANDARD_CONTENT_TYPE,
//                                                          FileQueryInfoFlags.NONE , null);
//                                }
//                                catch(Error err) {
//                                    print("mimeinfo error for playlist content: %s\n", err.message);
//                                    continue;
//                                }
//                                tmp.mimetype = 
//                                    GLib.ContentType.get_mime_type(einfo.get_content_type());
//                                playlist_content += (owned)tmp;
//                            }
//                        }
//                        else {
//                            continue;
//                        }
//                        if(playlist_content != null) {
//                            foreach(TrackData tdat in playlist_content) {
//                                //print("fnd playlist_content : %s - %s\n", tdat.item.uri, tdat.title);
//                                tda += (owned)tdat;
//                                job.big_counter[1]++;
//                                lock(current_import_track_count) {
//                                    current_import_track_count++;
//                                }
//                            }
//                            if(job.big_counter[1] % 50 == 0) {
//                                Idle.add( () => {  // Update progress bar
//                                    uint xcnt = 0;
//                                    lock(current_import_track_count) {
//                                        xcnt = current_import_track_count;
//                                    }
//                                    unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
//                                    if(pb != null) {
//                                        pb.pulse();
//                                        pb.set_text(_("%u tracks found").printf(xcnt));
//                                    }
//                                    return false;
//                                });
//                            }
//                            if(tda.length > FILE_COUNT) {
//                                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
//                                db_job.track_dat = (owned)tda;
//                                db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
//                                tda = {};
//                                db_worker.push_job(db_job);
//                            }
//                        }
//                    }
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
                db_job.track_dat = (owned)tda;
                tda = {};
                db_worker.push_job(db_job);
            }
            end_import(job);
        }
        return;
    }
    
    private bool insert_trackdata_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        db_writer.begin_transaction();
        foreach(TrackData td in job.track_dat) {
            db_writer.insert_title(ref td);
        }
        db_writer.commit_transaction();
        return false;
    }

    // add streams to the media path and store them in the db
    private bool store_streams_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        var streams_ht = new HashTable<string,Item?>(str_hash, str_equal);
        db_writer.begin_transaction();
        
        db_writer.del_all_streams();
        
        foreach(Item? strm in job.items)
            streams_ht.insert(strm.uri, strm); // remove duplicates
        
        foreach(unowned Item? strm in streams_ht.get_values()) {
            string streamuri = "%s".printf(strm.uri.strip());
            Item? item = ItemHandlerManager.create_item(streamuri);
            item.text = strm.text;
            
            if(item.type == ItemType.UNKNOWN)
                continue;
            
            TrackData[]? track_dat = item_converter.to_trackdata(item, EMPTYSTRING);
            
            if(track_dat != null) {
                foreach(TrackData td in track_dat) {
                    if(td.item.uri == null) {
                        print("red alert!!!\n");
                        continue;
                    }
                    td.item.text = (item.text != null ? item.text : EMPTYSTRING);
                    db_writer.add_single_stream_to_collection(td.item);
                    lock(current_import_track_count) {
                        current_import_track_count++;
                    }
                }
            }
        }
        db_writer.commit_transaction();
        return false;
    }
}

