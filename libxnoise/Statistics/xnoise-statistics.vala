/* xnoise-statistics.vala
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
 *     Jörn Magens
 */

using Xnoise;
using Xnoise.Database;

private class Xnoise.Statistics : GLib.Object {
    private uint update_play_src = 0;
    public Statistics() {
        global.uri_changed.connect(on_track_played);
        global.uri_repeated.connect(on_track_played);
    }
    
    private void on_track_played(string? uri) {
        if(uri == null)
            return;
        if(update_play_src != 0)
            Source.remove(update_play_src);
        
        update_play_src = Timeout.add_seconds(3, () => {
            update_play(uri);
            update_play_src = 0;
            return false;
        });
    }
    
    // add statistical data for lastplay; update playcount
    private void update_play(string uri) {
        Worker.Job job;
        var dt = new DateTime.now_utc();
        job = new Worker.Job(Worker.ExecutionType.ONCE, update_play_job);
        int64 playtime = dt.to_unix();
        job.set_arg("playtime", playtime);
        job.set_arg("uri", uri);
        db_worker.push_job(job);
    }
    
    private bool update_play_job(Worker.Job job) {
        int64 playtime = (int64)job.get_arg("playtime");
        string uri = (string)job.get_arg("uri");
        db_writer.update_lastplay_time(uri, playtime);
        db_writer.inc_playcount(uri);
        return false;
    }
}


