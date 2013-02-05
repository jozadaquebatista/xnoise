/* xnoise-cdda-tree-view.vala
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
using Xnoise.ExtDev;
using Xnoise.Resources;


private class CddaTreeView : Gtk.TreeView {
    private static const string ATTR_ARTIST   = "xattr::org.gnome.audio.artist";
    private static const string ATTR_TITLE    = "xattr::org.gnome.audio.title";
    private static const string ATTR_DURATION = "xattr::org.gnome.audio.duration";
    
    private Gtk.ListStore store;
    
    private unowned Device device;
    private unowned Mount mount;
    
    public bool in_loading { get; set; }
    
    
    public CddaTreeView(Device device) {
        this.device = device;
        this.mount = device.mount;
        setup_widgets();
        populate_model();
        row_activated.connect(on_row_activated);
    }
    
    
    private void on_row_activated(Gtk.Widget sender, Gtk.TreePath treepath, Gtk.TreeViewColumn column) {
        Item? item = Item(ItemType.UNKNOWN);
        Gtk.TreeIter iter;
        string title  = null;
        string album  = null;
        string artist = null;
        
        store.get_iter(out iter, treepath);
        store.get(iter, 
                  Columns.TITLE, out title,
                  Columns.ALBUM, out album,
                  Columns.ARTIST, out artist,
                  Columns.ITEM, out item
        );
        if(item.type != ItemType.CDROM_TRACK)
            return;
        
        global.preview_uri(item.uri);
        
        global.current_title = title + " " + _("(CD)");
        global.current_album = album;
        global.current_artist = artist;
    }

    public enum Columns {
        ICON,
        TRACKNUMBER,
        TITLE,
        ALBUM,
        ARTIST,
        DURATION,
        ITEM,
        N_COLUMNS
    }
    
    private void populate_model() {
        in_loading = true;
        var job = new Worker.Job(Worker.ExecutionType.ONCE, populate_model_job);
        job.set_arg("mount", mount);
        device_worker.push_job(job);
    }
    
    private const string attr = FileAttribute.STANDARD_NAME + "," +
                                ATTR_TITLE + "," +
                                ATTR_ARTIST + "," +
                                ATTR_DURATION;
    
    private bool populate_model_job() {
        File dir = device.mount.get_default_location();
        try {
            var info = dir.query_info(attr, FileQueryInfoFlags.NONE);
            if(info == null) {
                print("Could not query CD\n");
                Idle.add(() => {
                    in_loading = false;
                    return false;
                });
                return false;
            }
            
            string? artist = info.get_attribute_string(ATTR_ARTIST);
            string? album  = info.get_attribute_string(ATTR_TITLE);
            
            if(artist == null || artist == "")
                artist = UNKNOWN_ARTIST;
            
            if(album == null || album == "")
                album = UNKNOWN_ALBUM;
            
            if(dir.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
                return false;
                
            var enumerator = dir.enumerate_children(attr + "," + ATTR_DURATION, FileQueryInfoFlags.NONE);
            
            int i = 0;
            FileInfo track_info = null;
            
            while((track_info = enumerator.next_file()) != null) {
                i++;
                
                string? track_title  = track_info.get_attribute_string(ATTR_TITLE);
                string? track_artist = track_info.get_attribute_string(ATTR_ARTIST);
                
                uint64 duration  = track_info.get_attribute_uint64(ATTR_DURATION);
                
                // TODO put this to utils
                int dur_min, dur_sec, pos_min, pos_sec;
                dur_min = (int)(duration / 60);
                dur_sec = (int)(duration % 60);
                string duration_str = "%02d:%02d".printf(dur_min, dur_sec);
                
                if(track_title == null)
                    track_title = "Track " + i.to_string(); 
                
                Item? item = ItemHandlerManager.create_item("cdda://%d".printf(i));
                
                int tracknumber = i;
                Idle.add( () => {
                    Gtk.TreeIter iter;
                    store.append(out iter);
                    store.set(iter, 
                              Columns.ICON, null, 
                              Columns.TRACKNUMBER, tracknumber,
                              Columns.TITLE, track_title,
                              Columns.ALBUM, album,
                              Columns.ARTIST, artist,
                              Columns.DURATION, duration_str,
                              Columns.ITEM, item
                    );
                    return false;
                });
            }
        } 
        catch(Error e) {
            print("%s", e.message);
        }
        Idle.add(() => {
            in_loading = false;
            return false;
        });
        return false;
    }
    
    private void setup_widgets() {
        Gtk.TreeViewColumn col;
        store = new Gtk.ListStore(Columns.N_COLUMNS,
                                  typeof(Gdk.Pixbuf),
                                  typeof(int),
                                  typeof(string),
                                  typeof(string),
                                  typeof(string),
                                  typeof(string),
                                  typeof(Item?)
        );
        this.set_model(store);
        this.insert_column_with_attributes(-1, 
                                           "",
                                           new Gtk.CellRendererPixbuf(),
                                           "pixbuf",
                                           Columns.ICON
        );
        col = this.get_column(Columns.ICON);
        col.min_width = 30;
        col.max_width = 30;
        col.resizable = false;
        col.reorderable = false;
        col.expand = false;
        
        this.insert_column_with_attributes(-1,
                                           "#",
                                           new Gtk.CellRendererText(),
                                           "text",
                                           Columns.TRACKNUMBER
        );
        col = this.get_column(Columns.TRACKNUMBER);
        col.min_width = 30;
        col.max_width = 30;
        col.resizable = false;
        col.reorderable = true;
        col.expand = false;
        
        this.insert_column_with_attributes(-1,
                                           _("Title"),
                                           new Gtk.CellRendererText(),
                                           "text",
                                           Columns.TITLE
        );
        col = this.get_column(Columns.TITLE);
        col.resizable = true;
        col.reorderable = true;
        col.expand = true;
        
        this.insert_column_with_attributes(-1,
                                           _("Album"),
                                           new Gtk.CellRendererText(),
                                           "text",
                                           Columns.ALBUM
        );
        col = this.get_column(Columns.ALBUM);
        col.resizable = true;
        col.reorderable = true;
        col.expand = true;
        
        this.insert_column_with_attributes(-1,
                                           _("Artist"),
                                           new Gtk.CellRendererText(),
                                           "text",
                                           Columns.ARTIST
        );
        col = this.get_column(Columns.ARTIST);
        col.resizable = true;
        col.reorderable = true;
        col.expand = true;
        
        this.insert_column_with_attributes(-1,
                                           _("Length"),
                                           new Gtk.CellRendererText(),
                                           "text",
                                           Columns.DURATION
        );
        col = this.get_column(Columns.DURATION);
        col.min_width = 80;
        col.max_width = 80;
        col.resizable = false;
        col.reorderable = true;
        col.expand = false;
        
   }
}
