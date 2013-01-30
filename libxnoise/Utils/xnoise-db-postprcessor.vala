/* xnoise-db-postprcessor.vala
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */


using Xnoise;
using Xnoise.Database;
using Xnoise.Resources;

private class Xnoise.DbPostprocessor : GLib.Object {
    
    private AsyncQueue<string> candidates = new AsyncQueue<string>();
    
    public DbPostprocessor() {
        assert(db_reader != null);
        assert(db_writer != null);
    }
    
    public void find_compilations() {
//        if(global.media_import_in_progress == true)
//            return;
        print("looking for compilations in the database\n");
        var job = new Worker.Job(Worker.ExecutionType.ONCE, find_compilations_job);
        db_worker.push_job(job);
    }
    
    private bool find_compilations_job(Worker.Job job) {
        string[] albums = db_reader.get_all_album_names();
        foreach(string album in albums) {
            string lowercase_album = album.down();
            if(album == UNKNOWN_ALBUM || lowercase_album == "self titled" ||
               lowercase_album == "unknown" || lowercase_album == "greatest hits" ||
               lowercase_album == "no title" || lowercase_album == "%s".printf(_("unknown").down()) ||
               lowercase_album.has_prefix("http") || lowercase_album == "live") {
                continue;
            }
            var item_job = new Worker.Job(Worker.ExecutionType.ONCE, check_single_album_job);
            item_job.set_arg("album", album);
            db_worker.push_job(item_job);
        }
        var candidates_job = new Worker.Job(Worker.ExecutionType.ONCE, handle_candidates_job);
        db_worker.push_job(candidates_job);
        return false;
    }
    
    private bool handle_candidates_job(Worker.Job job) {
        string? album;
        while((album = candidates.try_pop()) != null) {
            var ujob = new Worker.Job(Worker.ExecutionType.ONCE, album_name_is_va_job);
            ujob.set_arg("album", album);
            db_worker.push_job(ujob);
        }
        return false;
    }

    private bool album_name_is_va_job(Worker.Job job) {
        print("handle candidate  : %s\n", (string)job.get_arg("album"));
        db_writer.set_albumname_is_va_album((string)job.get_arg("album"));
        return false;
    }

    private bool check_single_album_job(Worker.Job job) {
        string album = ((string)job.get_arg("album"));
        
        int32 artist_cnt = db_reader.get_artist_count_with_album_name(ref album);
        if(artist_cnt > 1) {
            candidates.push(album);
        }
        return false;
    }
}

