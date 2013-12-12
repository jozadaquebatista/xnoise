/* xnoise-media-change-detector.vala
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
using Xnoise.Database;
using Xnoise.Utilities;
using Xnoise.TagAccess;


private class Xnoise.MediaChangeDetector : GLib.Object {
    private static const int FILE_COUNT = 500;
    private Worker worker;
    private uint start_source = 0;
    private bool permission;
    private bool finished_database_read  = false;
    private bool finished_old_file_check = false;
    private bool finished_new_file_check = false;
    private int32 limit_buffer = 100;
    private int32 offset_buffer = 0;
    
    private string[] changed_uris = {};
    private string[] removed_uris = {};
    
    private string[] found_uris = {}; 
//    private string[] uris_for_image_extraction  = {};
    
    // FINISH SIGNAL
    public signal void finished();
    
    
    public MediaChangeDetector() {
        assert(media_importer != null);
        worker = new Worker(MainContext.default());
        permission = false;
        Timeout.add_seconds(1, () => {
            global.notify["media-import-in-progress"].connect( () => {
                if(!finished_database_read) {
                    Idle.add(() => {
                        check_start_conditions();
                        return false;
                    });
                }
            });
            check_start_conditions();
            return false;
        });
    }
    
    ~MediaChangeDetector() {
        print("dtor MediaChangeDetector\n");
    }
    
    
    private void check_start_conditions() {
        if(!global.media_import_in_progress) {
            if(start_source != 0) {
                Source.remove(start_source);
                start_source = 0;
            }
            start_source = Timeout.add_seconds(1, () => {
                permission = true;
                start_source = 0;
                do_check();
                return false;
            });
        }
        else {
            if(start_source != 0) {
                Source.remove(start_source);
                start_source = 0;
            }
            permission = false;
        }
    }
    
    private void do_check() {
        if(GlobalAccess.main_cancellable == null || GlobalAccess.main_cancellable.is_cancelled())
            return;
        if(!finished_database_read && permission) {
            process_existing_library_content();
        }
        if(!finished_new_file_check && finished_old_file_check && permission) {
            Timeout.add_seconds(1, () => {
                process_media_folder_content();
                return false;
            });
        }
    }
    
    private void process_media_folder_content() {
        if(GlobalAccess.main_cancellable.is_cancelled())
            return;
        
        foreach(Item? item in media_importer.get_media_folder_list()) {
            if(item == null || item.uri == null) {
                continue;
            }
            print("start folder scan for %s\n", item.uri);
            File f = File.new_for_uri(item.uri);
            if(GlobalAccess.main_cancellable.is_cancelled()) {
                return;
            }
            var job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job, Worker.Priority.HIGH);
            job.set_arg("media_folder", f.get_path());
            job.item = item;
            this.worker.push_job(job);
        }
        var f_job = new Worker.Job(Worker.ExecutionType.ONCE, finish_mfc);
        this.worker.push_job(f_job);
    }
    
    private bool finish_mfc(Worker.Job job) {
        if(global.media_import_in_progress) {
            Timeout.add_seconds(1, () => {
                if(!global.media_import_in_progress) {
                    print("Requeuing finish job.\n");
                    this.worker.push_job(job);
                    return false;
                }
                else {
                    return true;
                }
            });
        }
        else {
            var iojob = new Worker.Job(Worker.ExecutionType.ONCE, (j) => {
                var dbjob = new Worker.Job(Worker.ExecutionType.ONCE, (jj) => {
//                    Idle.add( () => {
//                        userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
//                                          UserInfo.ContentClass.INFO,
//                                          _("Finished media folder scan and queued files for import into xnoise library."),
//                                          false,
//                                          5,
//                                          null);
//                        return false;
//                    });
                    print("done offline check!\n");
                    Timeout.add_seconds(1, () => {
                        finished();
                        return false;
                    });
                    return false;
                });
                db_worker.push_job(dbjob);
                return false;
            });
            io_worker.push_job(iojob); // media importer is using io_worker
        }
        return false;
    }
    
    private bool read_media_folder_job(Worker.Job job) {
        //this function shall run in the io thread
        if(GlobalAccess.main_cancellable.is_cancelled())
            return false;
        return_val_if_fail(worker.is_same_thread(), false);
        return_val_if_fail(job.item != null, false);
        return_val_if_fail(job.item.uri != null, false);
        File d = File.new_for_uri(job.item.uri);
        Item? i = job.item;
        read_recoursive(d, job);
        if(global.media_import_in_progress) {
            Timeout.add_seconds(1, () => {
                if(!uri_in_media_folders((string)job.get_arg("media_folder")))
                    return false; // do nothing if the according media folder was removed in the meantime
                if(!global.media_import_in_progress) {
                    print("Requeuing offline file check job.\n");
                    this.worker.push_job(job);
                }
                else {
                    return true;
                }
                return false;
            });
        }
        else {
            finished_new_file_check = true;
        }
        return false;
    }
    
    private static bool uri_in_media_folders(string u) {
        foreach(Item? i in media_importer.get_media_folder_list()) {
            File f = File.new_for_path(u);
            if(f.get_uri() == i.uri) return true;
        }
        return false;
    }
    
    private const string attr = FileAttribute.STANDARD_NAME + "," +
                                FileAttribute.STANDARD_TYPE;
    
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        if(GlobalAccess.main_cancellable.is_cancelled())
            return;
        return_if_fail(this.worker.is_same_thread());
        
        if(global.media_import_in_progress)
            return;
        
        if(!uri_in_media_folders((string)job.get_arg("media_folder")))
            return; // do nothing if the according media folder was removed in the meantime
        job.counter[0]++;
        FileEnumerator enumerator;
        try {
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
        } 
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            job.counter[0]--;
            return;
        }
        GLib.FileInfo info;
        try {
            while((info = enumerator.next_file()) != null) {
                if(GlobalAccess.main_cancellable.is_cancelled())
                    return;
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
                        found_uris += file.get_uri();
                        if(found_uris.length > FILE_COUNT) {
                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, handle_uris_job);
                            db_job.uris = (owned)found_uris;
                            found_uris = {};
                            db_job.set_arg("media_folder", (string)job.get_arg("media_folder"));
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
            if(found_uris.length > 0) {
                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, handle_uris_job);
                db_job.uris = (owned)found_uris;
                found_uris = {};
                db_job.set_arg("media_folder", (string)job.get_arg("media_folder"));
                db_worker.push_job(db_job);
            }
        }
        return;
    }
    
    //private static uint cntx = 0;
    
    private static bool handle_uris_job(Worker.Job job) {
        return_if_fail(db_worker.is_same_thread());
        string[] uris_for_image_extraction  = {};
        //this function uses the database so use it in the database thread
        if(GlobalAccess.main_cancellable.is_cancelled())
            return false;
        return_val_if_fail(db_worker.is_same_thread(), false);
        if(!uri_in_media_folders((string)job.get_arg("media_folder")))
            return false; // do nothing if the according media folder was removed in the meantime
        string[] add_uris = {};
        foreach(string u in job.uris) {
            if(GlobalAccess.main_cancellable.is_cancelled())
                return false;
            if(!db_reader.get_file_in_db(u)) {
                add_uris += u;
                uris_for_image_extraction += u;
            }
        }
        if(add_uris.length != 0) {
            //cntx += add_uris.length;
            media_importer.import_uris(add_uris);
        }
        if(uris_for_image_extraction.length != 0) {
            dbus_image_extractor.queue_uris(uris_for_image_extraction);
            uris_for_image_extraction = {};
        }
        return false;
    }
    
    private void process_existing_library_content() {
        if(GlobalAccess.main_cancellable.is_cancelled())
            return;
        print("start offline file change check\n");
        var job = new Worker.Job(Worker.ExecutionType.ONCE, get_library_uris_job);
        lock(offset_buffer) {
            job.big_counter[0] = offset_buffer;
        }
        lock(limit_buffer) {
            job.big_counter[1] = limit_buffer;
        }
        db_worker.push_job(job);
    }
    
    private bool get_library_uris_job(Worker.Job job) {
        return_val_if_fail(db_worker.is_same_thread(), false);
        
        if(!permission) { //save offset for next run
            lock(offset_buffer) {
                offset_buffer = job.big_counter[0];
            }
            lock(limit_buffer) {
                limit_buffer  = job.big_counter[1];
            }
            return false;
        }
        
        bool end = false;
        
        var io_job = new Worker.Job(Worker.ExecutionType.ONCE, check_change_times_job);
        io_job.file_data =
            db_reader.get_uris(/*offset*/ job.big_counter[0], 
                               /*limit*/  job.big_counter[1]);
        job.big_counter[0] += io_job.file_data.length;
        
        if(io_job.file_data.length < job.big_counter[1])
            end = true;
        this.worker.push_job(io_job);
        
        if(end) {
            finished_database_read = true;
            var finish_job = new Worker.Job(Worker.ExecutionType.ONCE, (xxjob) => {
                if(changed_uris.length != 0) {
                    string[] changed_uris_loc = changed_uris;
                    changed_uris = {};
                    media_importer.reimport_media_files(changed_uris_loc);
                    dbus_image_extractor.queue_uris(changed_uris_loc);
                }
                if(removed_uris.length != 0) {
                    string[] removed_uris_loc = removed_uris;
                    removed_uris = {};
                    media_importer.remove_uris(removed_uris_loc);
                }
                Idle.add(() => {
                    finished_old_file_check = true;
                    do_check();
                    return false;
                });
                return false;
            });
            this.worker.push_job(finish_job);
            return false;
        }
        Idle.add( () => {
            db_worker.push_job(job);
            return false;
        });
        return false;
    }
    
    private bool check_change_times_job(Worker.Job job) {
        return_val_if_fail(this.worker.is_same_thread(), false);
        if(!permission) {
            lock(offset_buffer) {
                offset_buffer -= job.file_data.length;
            }
        }
        foreach(FileData fd in job.file_data) {
            if(fd.uri == null)
                continue;
            File? f = File.new_for_uri(fd.uri);
            if(f == null)
                continue;
            int32 change_time = 0;
            try {
                FileInfo info = f.query_info(FileAttribute.TIME_CHANGED,
                                             FileQueryInfoFlags.NONE,
                                             null);
                change_time = (int32)info.get_attribute_uint64(FileAttribute.TIME_CHANGED);
            }
            catch(Error e) {
                if(e is IOError.NOT_FOUND) {
                    print("DETECTED OFFLINE FILE REMOVAL OF %s\n", fd.uri);
                    removed_uris += fd.uri;
                    continue;
                }
                print("%s\n", e.message);
                continue;
            }
            if(change_time != fd.change_time) {
                print("DETECTED OFFLINE CHANGE OF %s\n", fd.uri);
                changed_uris += fd.uri;
            }
            //else {
            //    print("no change for %s\n", fd.uri);
            //}
        }
        if(changed_uris.length != 0) {
            string[] changed_uris_loc = changed_uris;
            changed_uris = {};
            media_importer.reimport_media_files(changed_uris_loc);
            dbus_image_extractor.queue_uris(changed_uris_loc);
        }
        if(removed_uris.length != 0) {
            string[] removed_uris_loc = removed_uris;
            removed_uris = {};
            media_importer.remove_uris(removed_uris_loc);
        }
        return false;
    }
}

