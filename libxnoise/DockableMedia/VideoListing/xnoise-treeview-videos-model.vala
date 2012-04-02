/* xnoise-treeview-videos-model.vala
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


using Gtk;

using Xnoise;
using Xnoise.Services;
using Xnoise.Database;


private class Xnoise.TreeViewVideosModel : Gtk.ListStore {
    private uint update_thumbnails_src  = 0;
    private uint search_idlesource      = 0;
    private unowned TreeViewVideos view;
    private bool populating_model = false;
    private unowned DockableMedia dock;
    
    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf), //ICON
        typeof(string),     //VIS_TEXT
        typeof(Xnoise.Item?)//ITEM
    };
    
    public enum Column {
        ICON = 0,
        VIS_TEXT,
        ITEM,
        N_COLUMNS
    }

    public TreeViewVideosModel(DockableMedia dock, TreeViewVideos view) {
        this.view = view;
        this.dock = dock;
        this.set_column_types(col_types);
        this.populate();
        Writer.NotificationData cbd = Writer.NotificationData();
        cbd.cb = database_change_cb;
        db_writer.register_change_callback(cbd);
        global.sign_searchtext_changed.connect( (s,t) => {
            if(this.dock.name() != global.active_dockable_media_name) {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add_seconds(1, () => {
                    this.filter();
                    this.search_idlesource = 0;
                    return false;
                });
            }
            else {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add(200, () => {
                    this.filter();
                    this.search_idlesource = 0;
                    return false;
                });
            }
        });
        thumbnailer.sign_got_thumbnail.connect( (u,t) => {
            //print("it worked : %s - %s\n", u, t);
            if(update_thumbnails_src != 0)
                Source.remove(update_thumbnails_src);
            update_thumbnails_src = Timeout.add_seconds(1, () => {
                filter();
                update_thumbnails_src = 0;
                return false;
            });
        });
        MediaImporter.ResetNotificationData? cbr = MediaImporter.ResetNotificationData();
        cbr.cb = reset_cb;
        media_importer.register_reset_callback(cbr);
    }
    
    private void reset_cb() {
        this.remove_all();
    }

    public void remove_all() {
        view.set_model(null);
        this.clear();
        view.set_model(this);
    }

    public void filter() {
        //print("filter\n");
        view.set_model(null);
        this.clear();
        this.populate();
    }
    
    private void populate() {
        if(populating_model)
            return;
        populating_model = true;
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, insert_job);
        db_worker.push_job(job);
    }
    
    private List<string> uri_list;
    private uint thumbnailer_src = 0;
    
    private bool insert_job(Worker.Job job) {
        job.items = db_reader.get_video_items(global.searchtext);
        
        Idle.add( () => {
            TreeIter iter;
            foreach(Item? i in job.items) {
                Gdk.Pixbuf thumbnail = null;
                File thumb = null;
                bool has_thumbnail = false;
                if(thumbnail_available(i.uri, out thumb)) {
                    try {
                        if(thumb != null) {
                            thumbnail = new Gdk.Pixbuf.from_file_at_scale(thumb.get_path(), VIDEOTHUMBNAILSIZE, VIDEOTHUMBNAILSIZE, true);
                            has_thumbnail = true;
                        }
                    }
                    catch(Error e) {
                        thumbnail = null;
                        has_thumbnail = false;
                    }
                }
                this.prepend(out iter);
                this.set(iter,
                         Column.ICON, (has_thumbnail == true ? thumbnail : icon_repo.video_icon),
                         Column.VIS_TEXT, i.text,
                         Column.ITEM, i
                );
                if(!has_thumbnail) {
                    if(uri_list == null)
                        uri_list = new List<string>();
                    uri_list.prepend(i.uri);
                    if(thumbnailer_src != 0)
                        Source.remove(thumbnailer_src);
                    thumbnailer_src = Timeout.add_seconds(1, () => {
                        print("queue uris for thumbnailing\n");
                        string[] uri_array = {};
                        foreach(string s in uri_list)
                            uri_array += s;
                        thumbnailer.queue_uris(uri_array);
                        uri_list = null;
                        thumbnailer_src = 0;
                        return false;
                    });
                }
            }
            view.model = this;
            populating_model = false;
            return false;
        });
        return false;
    }
    
    private void database_change_cb(Writer.ChangeType changetype, Item? item) {
        switch(changetype) {
            case Writer.ChangeType.ADD_VIDEO:
                if(item.db_id == -1){
                    print("GOT -1\n");
                    return;
                }
                Worker.Job job;
                job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.add_imported_job);
                job.item = item;
                db_worker.push_job(job);
                break;
            default:
                break;
        }
    }
    
    private bool add_imported_job(Worker.Job job) {
        //print("found video\n");
        job.item = db_reader.get_videoitem_by_id(job.item.db_id); // necessary because of search
        if(job.item.type == ItemType.UNKNOWN) // not matching searchtext
            return false;
        Idle.add( () => {
            if(populating_model)
                return false;
            string text = null;
            TreeIter iter = TreeIter();
            Gdk.Pixbuf thumbnail = null;
            File thumb = null;
            bool has_thumbnail = false;
            if(thumbnail_available(job.item.uri, out thumb)) {
                try {
                    if(thumb != null) {
                        thumbnail = new Gdk.Pixbuf.from_file_at_scale(thumb.get_path(), VIDEOTHUMBNAILSIZE, VIDEOTHUMBNAILSIZE, true);
                        has_thumbnail = true;
                    }
                }
                catch(Error e) {
                    thumbnail = null;
                    has_thumbnail = false;
                }
            }
            if(!has_thumbnail) {
                if(uri_list == null)
                    uri_list = new List<string>();
                uri_list.prepend(job.item.uri);
                if(thumbnailer_src != 0)
                    Source.remove(thumbnailer_src);
                thumbnailer_src = Timeout.add_seconds(1, () => {
                    print("queue uris for thumbnailing\n");
                    string[] uri_array = {};
                    foreach(string s in uri_list)
                        uri_array += s;
                    thumbnailer.queue_uris(uri_array);
                    uri_list = null;
                    thumbnailer_src = 0;
                    return false;
                });
            }
            if(this.iter_n_children(null) == 0) {
                this.prepend(out iter);
                this.set(iter,
                         Column.ICON,  (has_thumbnail == true ? thumbnail : icon_repo.video_icon),
                         Column.VIS_TEXT, job.item.text,
                         Column.ITEM, job.item
                         );
                return false;
            }
            string itemtext_prep = job.item.text.down().strip();
            
            for(int i = 0; i < this.iter_n_children(null); i++) {
                if(i == 0) {
                    this.iter_nth_child(out iter, null, i);
                }
                else {
                    if(!iter_next(ref iter))
                        break;
                }
                Item? current_item;
                this.get(iter, Column.VIS_TEXT, out text, Column.ITEM, out current_item);
                text = text != null ? text.down().strip() : EMPTYSTRING;
                if(strcmp(text.collate_key(), itemtext_prep.collate_key()) == 0) {
                    //found
                    return false;
                }
                if(strcmp(text.collate_key(), itemtext_prep.collate_key()) > 0) {
                    TreeIter new_iter;
                    this.insert_before(out new_iter, iter);
                    this.set(new_iter,
                             Column.ICON, (has_thumbnail == true ? thumbnail : icon_repo.video_icon),
                             Column.VIS_TEXT, job.item.text,
                             Column.ITEM, job.item
                             );
                    iter = new_iter;
                    return false;
                }
            }
            TreeIter x_iter;
            this.insert_after(out x_iter, iter);
            iter = x_iter;
            this.set(iter,
                     Column.ICON, (has_thumbnail == true ? thumbnail : icon_repo.video_icon),
                     Column.VIS_TEXT, job.item.text,
                     Column.ITEM, job.item
                     );
            return false;
        });
        return false;
    }
    
    public DndData[] get_dnd_data_for_path(ref TreePath treepath) {
        TreeIter iter;
        DndData[] dnd_data_array = {};
        Item? item = null;
        this.get_iter(out iter, treepath);
        this.get(iter, Column.ITEM, out item);
        if(item != null && item.type != ItemType.UNKNOWN) {
            DndData dnd_data = { item.db_id, item.type };
            dnd_data_array += dnd_data;
        }
        return dnd_data_array;
    }
}
