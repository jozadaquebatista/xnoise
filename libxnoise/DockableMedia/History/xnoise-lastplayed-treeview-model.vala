/* xnoise-lastplayed-treeview-model.vala
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
using Xnoise.Resources;
using Xnoise.Database;


private class Xnoise.LastplayedTreeviewModel : Gtk.ListStore {
    private bool populating_model = false;
    private uint search_idlesource = 0;
    private PlaylistTreeViewLastplayed view;
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

    public LastplayedTreeviewModel(PlaylistTreeViewLastplayed view, DockableMedia dock) {
        this.set_column_types(col_types);
        this.view = view;
        this.dock = dock;
        this.populate();
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
        Writer.NotificationData nd = Writer.NotificationData();
        nd.cb = database_change_cb;
        db_writer.register_change_callback(nd);
    }

    private uint src = 0;
    private void database_change_cb(Writer.ChangeType changetype, Item? item) {
        if(changetype == Writer.ChangeType.UPDATE_LASTPLAYED) {
            if(src != 0)
                Source.remove(src);
            src = Timeout.add_seconds(2, () => {
                filter();
                src = 0;
                return false;
            });
        }
    }
    
    public void filter() {
        //print("filter\n");
        if(populating_model)
            return;
        populating_model = true;
        view.set_model(null);
        this.clear();
        this.populate();
    }
    
    private void populate() {
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, insert_last_played_job);
        db_worker.push_job(job);
    }
    
    private bool insert_last_played_job(Worker.Job job) {
        job.items = db_reader.get_last_played(global.searchtext);
        Idle.add( () => {
            TreeIter iter;
            foreach(Item? i in job.items) {
                if(i.type == ItemType.LOCAL_VIDEO_TRACK) {
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
                    this.append(out iter);
                    this.set(iter,
                             Column.ICON, (has_thumbnail == true ? thumbnail : icon_repo.video_icon),
                             Column.VIS_TEXT, i.text,
                             Column.ITEM, i
                    );
                }
                else if(i.type == ItemType.STREAM) {
                    this.append(out iter);
                    this.set(iter,
                             Column.ICON, icon_repo.radios_icon,
                             Column.VIS_TEXT, i.text,
                             Column.ITEM, i
                    );
                }
                else {
                    this.append(out iter);
                    this.set(iter,
                             Column.ICON, icon_repo.title_icon,
                             Column.VIS_TEXT, i.text,
                             Column.ITEM, i
                    );
                }
            }
            view.model = this;
            populating_model = false;
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
