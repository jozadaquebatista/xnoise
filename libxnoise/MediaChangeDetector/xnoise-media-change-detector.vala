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


private class Xnoise.MediaChangeDetector : GLib.Object {
    private Worker worker;
    private uint start_source = 0;
    private bool permission;
    private bool finished_database_read = false;
    private int32 limit_buffer = 100;
    private int32 offset_buffer = 0;
    
    private string[] changed_uris = {};
    
    // FINISH SIGNAL
    public signal void finished();
    
    
    public MediaChangeDetector() {
        assert(media_importer != null);
        worker = new Worker(MainContext.default());
        global.notify["media-import-in-progress"].connect( () => {
            if(!finished_database_read)
                check_start_conditions();
        });
        permission = false;
        Timeout.add_seconds(10, () => {
            check_start_conditions();
            return false;
        });
    }
    
    
    private void check_start_conditions() {
        if(!global.media_import_in_progress) {
            if(start_source != 0) {
                Source.remove(start_source);
                start_source = 0;
            }
            start_source = Timeout.add_seconds(20, () => {
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
        //print("job.big_counter[0]: %d\n", (int)job.big_counter[0]);
        var io_job = new Worker.Job(Worker.ExecutionType.ONCE, check_change_times_job);
        io_job.file_data =
            db_reader.get_uris(/*offset*/ job.big_counter[0], 
                               /*limit*/  job.big_counter[1]);
        job.big_counter[0] += io_job.file_data.length;
        bool end = false;
        
        if(io_job.file_data.length < job.big_counter[1])
            end = true;
        
        this.worker.push_job(io_job);
        
        if(end) {
            finished_database_read = true;
            var finish_job = new Worker.Job(Worker.ExecutionType.ONCE, (job) => {
                if(changed_uris.length != 0)
                    media_importer.reimport_media_files(changed_uris);
                Idle.add(() => {
                    print("done offline check!\n");
                    finished();
                    return false;
                });
                return false;
            });
            this.worker.push_job(finish_job);
            return false;
        }
        Timeout.add(500, () => {
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
                print("%s\n", e.message);
                continue;
            }
            if(change_time != fd.change_time) {
                print("DETECTED OFFLINE CHANGE OF %s\n", fd.uri);
                changed_uris += fd.uri;
            }
        }
        return false;
    }
}

