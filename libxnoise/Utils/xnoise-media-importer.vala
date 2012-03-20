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
using Xnoise.Services;
using Xnoise.TagAccess;

public class Xnoise.MediaImporter : GLib.Object {

    private static int FILE_COUNT = 150;
    
    internal void reimport_media_groups() {
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, reimport_media_groups_job);
        db_worker.push_job(job);
    }
    
    private Timer t;
    
    private bool reimport_media_groups_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
        
        main_window.mediaBr.mediabrowsermodel.cancel_fill_model();
        
        //add folders
        string[] mfolders = db_reader.get_media_folders();
        job.set_arg("mfolders", mfolders);
        
        //add files
        string[] mfiles = db_reader.get_media_files();
        job.set_arg("mfiles", mfiles);
        
        //add streams to list
        StreamData[] streams = db_reader.get_streams();
        
        string[] strms = {};
        
        foreach(unowned StreamData sd in streams)
            strms += sd.uri;
        
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
            main_window.mediaBr.mediabrowsermodel.remove_all();
            
            import_media_groups(strms, mfiles, mfolders, msg_id, true, false);
            
            return false;
        });
        return false;
    }

    internal void update_item_tag(ref Item? item, ref TrackData td) {
        
        //this function uses the database so use it in the database thread
        return_if_fail((int)Linux.gettid() == db_worker.thread_id);
        
        if(global.media_import_in_progress == true)
            return;
        db_writer.update_title(ref item, ref td);
    }
    
    public string? get_uri_for_item_id(int32 id) {
        //this function uses the database so use it in the database thread
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, null);
        
        return db_writer.get_uri_for_item_id(id);
    }

    private uint current_import_msg_id = 0;
    private uint current_import_track_count = 0;
    
    internal void import_media_groups(string[] list_of_streams,
                                      string[] list_of_files,
                                      string[] list_of_folders,
                                      uint msg_id,
                                      bool full_rescan = true,
                                      bool interrupted_populate_model = false) {
        return_if_fail((int)Linux.gettid() == Main.instance.thread_id);
        t = new Timer(); // timer for measuring import time
        t.start();
        // global.media_import_in_progress has to be reset in the last job !
        io_import_job_running = true;
        
        Worker.Job job;
        if(full_rescan) {
            job = new Worker.Job(Worker.ExecutionType.ONCE, reset_local_data_library_job);
            db_worker.push_job(job);
        }
        
        if(list_of_streams.length > 0) {
            job = new Worker.Job(Worker.ExecutionType.ONCE, store_streams_job);
            job.set_arg("list_of_streams", list_of_streams);
            job.set_arg("full_rescan", full_rescan);
            db_worker.push_job(job);
        }
        
        //Assuming that number of streams will be relatively small,
        //the progress of import will only be done for folder imports
        job = new Worker.Job(Worker.ExecutionType.ONCE, store_folders_job);
        job.set_arg("mfolders", list_of_folders);
        job.set_arg("msg_id", msg_id);
        current_import_msg_id = msg_id;
        job.set_arg("interrupted_populate_model", interrupted_populate_model);
        job.set_arg("full_rescan", full_rescan);
        db_worker.push_job(job);
    }
    
    private bool io_import_job_running = false;

    internal bool write_final_tracks_to_db_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
        try {
            db_writer.write_final_tracks_to_db(job);
        }
        catch(Error err) {
            print("%s\n", err.message);
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
        db_worker.push_job(finisher_job);
    }
    
    // running in db thread
    private bool finish_import_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
        
        Idle.add( () => {
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
            global.media_import_in_progress = false;
            if(current_import_msg_id != 0) {
                userinfo.popdown(current_import_msg_id);
                current_import_msg_id = 0;
                lock(current_import_track_count) {
                    current_import_track_count = 0;
                }
            }
            return false;
        });
        return false;
    }

    // running in db thread
    private bool reset_local_data_library_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
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
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
        
        //print("store_folders_job \n");
        var mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
        if(((bool)job.get_arg("full_rescan"))) {
            db_writer.del_all_folders();
            
            foreach(unowned string folder in (string[])job.get_arg("mfolders"))
                mfolders_ht.insert(folder, 1); // this removes double entries
            
            foreach(unowned string folder in mfolders_ht.get_keys())
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
            foreach(unowned string folder in mfolders_ht.get_keys()) {
                File dir = File.new_for_path(folder);
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
            mfolders_ht.remove_all();
        }
        else { // import new folders only
            // after import at least the media folder have to be updated
            
            string[] dbfolders = db_writer.get_media_folders();
            
            foreach(unowned string folder in (string[])job.get_arg("mfolders"))
                mfolders_ht.insert(folder, 1); // this removes double entries
            
            db_writer.del_all_folders();
            foreach(unowned string folder in mfolders_ht.get_keys()) {
                db_writer.add_single_folder_to_collection(folder);
            }
            var new_mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
            foreach(unowned string folder in mfolders_ht.get_keys()) {
                if(!(folder in dbfolders))
                    new_mfolders_ht.insert(folder, 1);
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
            foreach(unowned string folder in new_mfolders_ht.get_keys()) {
                File dir = File.new_for_path(folder);
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
            mfolders_ht.remove_all();
        }
        return false;
    }
    
    // running in io thread
    private bool read_media_folder_job(Worker.Job job) {
        //this function shall run in the io thread
        return_if_fail((int)Linux.gettid() == io_worker.thread_id);
        //count_media_files((File)job.get_arg("dir"), job);
        read_recoursive((File)job.get_arg("dir"), job);
        return false;
    }
    
    // running in io thread
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_if_fail((int)Linux.gettid() == io_worker.thread_id);
        
        job.counter[0]++;
        FileEnumerator enumerator;
        string attr = FileAttribute.STANDARD_NAME + "," +
                      FileAttribute.STANDARD_TYPE;
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
                                unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
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
                    else {
                        print("found playlist file\n");
                        Item item = ItemHandlerManager.create_item(file.get_uri());
                        TrackData[]? playlist_content = null;
                        var pr = new Playlist.Reader();
                        Playlist.Result rslt;
                        try {
                            rslt = pr.read(item.uri , null);
                        }
                        catch(Playlist.ReaderError e) {
                            print("%s\n", e.message);
                            continue;
                        }
                        if(rslt != Playlist.Result.SUCCESS)
                            continue;
                        Playlist.EntryCollection ec = pr.data_collection;
                        if(ec != null) {
                            playlist_content = {};
                            foreach(Playlist.Entry e in ec) {
                                var tmp = new TrackData();
                                tmp.title  = (e.get_title()  != null ? e.get_title()  : UNKNOWN_TITLE);
                                tmp.album  = (e.get_album()  != null ? e.get_album()  : UNKNOWN_ALBUM);
                                tmp.artist = (e.get_author() != null ? e.get_author() : UNKNOWN_ARTIST);
                                tmp.genre  = (e.get_genre()  != null ? e.get_genre()  : UNKNOWN_GENRE);
                                tmp.item   = ItemHandlerManager.create_item(e.get_uri());
                                playlist_content += (owned)tmp;
                            }
                        }
                        else {
                            continue;
                        }
                        if(playlist_content != null) {
                            foreach(TrackData tdat in playlist_content) {
                                //print("fnd playlist_content : %s - %s\n", tdat.item.uri, tdat.title);
                                tda += (owned)tdat;
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
                                    unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
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
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
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
        return_val_if_fail((int)Linux.gettid() == db_worker.thread_id, false);
        var streams_ht = new HashTable<string,int>(str_hash, str_equal);
        db_writer.begin_transaction();
        
        db_writer.del_all_streams();
        
        foreach(unowned string strm in (string[])job.get_arg("list_of_streams")) {
            streams_ht.insert(strm, 1); // remove duplicates
        }
        foreach(unowned string strm in streams_ht.get_keys()) {
            string streamuri = "%s".printf(strm.strip());
            Item? item = ItemHandlerManager.create_item(streamuri);
            if(item.type == ItemType.UNKNOWN) {
                continue;
            }
            TrackData[]? track_dat = item_converter.to_trackdata(item, EMPTYSTRING);
            
            if(track_dat != null) {
                foreach(TrackData td in track_dat) {
                    if(td.item.uri == null) {
                        print("red alert!!!\n");
                        continue;
                    }
                    string name = (td.title != null && td.title != UNKNOWN_TITLE ? td.title : (td.item.text != null ? td.item.text : EMPTYSTRING));
                    db_writer.add_single_stream_to_collection(td.item.uri, name); 
                    lock(current_import_track_count) {
                        current_import_track_count++;
                    }
                }
            }
        }
        db_writer.commit_transaction();
        
        streams_ht.remove_all();
        return false;
    }
}

