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
    
    private TrackData[] tda = {}; 
    private string[] uris_for_image_extraction  = {};
    
    // FINISH SIGNAL
    public signal void finished();
    
    
    public MediaChangeDetector() {
        assert(media_importer != null);
        worker = new Worker(MainContext.default());
        foreach(Item? it in media_importer.get_media_folder_list()) {
            Item? item = it;
            folder_queue.push(item);
        }
        global.notify["media-import-in-progress"].connect( () => {
            if(!finished_database_read)
                check_start_conditions();
        });
        permission = false;
        Timeout.add_seconds(4, () => {
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
            start_source = Timeout.add_seconds(4, () => {
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
            Idle.add(() => {
                do_check();
                return false;
            });
        }
    }
    
    private void do_check() {
        if(!finished_database_read && permission) {
            process_existing_library_content();
        }
        if(!finished_new_file_check && finished_old_file_check && permission) {
            Timeout.add_seconds(3, () => {
                process_media_folder_content();
                return false;
            });
        }
    }
    
    private AsyncQueue<Item?> folder_queue = new AsyncQueue<Item?>();
    
    private void process_media_folder_content() {
        Item? item = null;
        item = folder_queue.try_pop();
        if(item == null) {
            print("media folder in queue\n");
            return;
        }
        File f = File.new_for_uri(item.uri);
        var job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
        job.set_arg("media_folder", f.get_path());
        job.item = item;
        this.worker.push_job(job);
    }
    
    private bool read_media_folder_job(Worker.Job job) {
        //this function shall run in the io thread
        return_val_if_fail(worker.is_same_thread(), false);
        File d = File.new_for_uri(job.item.uri);
        Item? i = job.item;
        read_recoursive(d, job);
        if(global.media_import_in_progress) {
            Timeout.add_seconds(2, () => {
                if(!global.media_import_in_progress)
                    this.worker.push_job(job);
                else
                    return true;
                return false;
            });
        }
        else {
            finished_new_file_check = true;
            Idle.add(() => {
                finished();
                return false;
            });
        }
        return false;
    }
    
    private const string attr = FileAttribute.STANDARD_NAME + "," +
                                FileAttribute.STANDARD_TYPE + "," +
                                FileAttribute.TIME_CHANGED + "," +
                                FileAttribute.STANDARD_CONTENT_TYPE;
    
    private void read_recoursive(File dir, Worker.Job job) {
        //this function shall run in the io thread
        return_if_fail(this.worker.is_same_thread());
        if(global.media_import_in_progress)
            return;
        
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
                TrackData td = null;
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                if(filetype == FileType.DIRECTORY && !filename.has_prefix(".")) {
                    read_recoursive(file, job);
                }
                else {
                    string uri_lc = filename.down();
                    string suffix = get_suffix_from_filename(uri_lc);
                    if(!Playlist.is_playlist_extension(suffix)) {
                        suffix = suffix.down();
                        if(suffix == "jpg" || suffix == "png" || suffix == "txt")
                            continue;
                        //print("filepath: %s\n", filepath);
                        var tr = new TagReader();
                        td = tr.read_tag(filepath, false);
                        //print("2filepath: %s\n", filepath);
                        if(td != null) {
                            td.media_folder = (string?)job.get_arg("media_folder");
                            td.mimetype     = GLib.ContentType.get_mime_type(info.get_content_type());
                            td.change_time  = (int32)info.get_attribute_uint64(FileAttribute.TIME_CHANGED);
                            uris_for_image_extraction += file.get_uri();
                            tda += td;
                            job.big_counter[1]++;
                        }
                        if(tda.length > FILE_COUNT) {
                            var db_job = new Worker.Job(Worker.ExecutionType.ONCE, handle_trackdata_job);
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
                var db_job = new Worker.Job(Worker.ExecutionType.ONCE, handle_trackdata_job);
                db_job.track_dat = (owned)tda;
                tda = {};
                dbus_image_extractor.queue_uris(uris_for_image_extraction);
                uris_for_image_extraction = {};
                db_worker.push_job(db_job);
            }
        }
        return;
    }
    
    private bool handle_trackdata_job(Worker.Job job) {
        //this function uses the database so use it in the database thread
        return_val_if_fail(db_worker.is_same_thread(), false);
        string[] add_uris     = {};
        foreach(TrackData td in job.track_dat) {
            FileData? fd = 
                db_reader.get_file_data(td.item.uri);
            if(fd == null) {
                add_uris += td.item.uri;
                continue;
            }
        }
        if(add_uris.length != 0)
            media_importer.import_uris(add_uris);
        return false;
    }
    
    private void process_existing_library_content() {
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
            var finish_job = new Worker.Job(Worker.ExecutionType.ONCE, (job) => {
                if(changed_uris.length != 0)
                    media_importer.reimport_media_files(changed_uris);
                if(removed_uris.length != 0)
                    media_importer.remove_uris(removed_uris);
                Idle.add(() => {
                    finished_old_file_check = true;
                    print("done offline check!\n");
                    do_check();
                    return false;
                });
                return false;
            });
            this.worker.push_job(finish_job);
            return false;
        }
        Timeout.add(100, () => {
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
            File f = File.new_for_uri(fd.uri);
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
        }
        if(changed_uris.length != 0) {
            media_importer.reimport_media_files(changed_uris);
            changed_uris = {};
        }
        if(removed_uris.length != 0) {
            media_importer.remove_uris(removed_uris);
            removed_uris = {};
        }
        return false;
    }
}

