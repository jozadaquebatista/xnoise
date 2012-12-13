/* xnoise-android-player-tree-view.vala
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */

using Gtk;
using Gdk;

using Xnoise;
using Xnoise.ExtDev;
using Xnoise.Utilities;



private class Xnoise.ExtDev.AndroidPlayerTreeView : Gtk.TreeView {
    private unowned AndroidPlayerDevice audio_player_device;
    private unowned Cancellable cancellable;
    private const int autoscroll_distance = 50;
    private uint autoscroll_source = 0;
    
    // targets used with this as a destination
    private const TargetEntry[] dest_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
        {"text/uri-list", 0, 1}
    };

    
    internal AndroidPlayerTreeStore treemodel;
    
    
    public AndroidPlayerTreeView(AndroidPlayerDevice audio_player_device,
                          Cancellable cancellable) {
        this.audio_player_device = audio_player_device;
        this.cancellable = cancellable;
        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.DEFAULT
                          );
        
//        this.drag_data_received.connect(this.on_drag_data_received);
        
        File b = File.new_for_uri(audio_player_device.get_uri());
        assert(b != null);
        b = b.get_child("Music");
        assert(b != null);
        assert(b.get_path() != null);
        if(b.query_exists(null))
            treemodel = new AndroidPlayerTreeStore(this, audio_player_device, b, cancellable);
        else {
            b = File.new_for_uri(audio_player_device.get_uri());
            b = b.get_child("media"); // old android devices
            treemodel = new AndroidPlayerTreeStore(this, audio_player_device, b, cancellable);
        }
        setup_view();
        
        this.row_activated.connect(this.on_row_activated);
        this.button_press_event.connect(this.on_button_press);
    }
    
    private bool in_data_move = false;
    private Gtk.TreeViewDropPosition drop_pos;
    public override void drag_data_received(DragContext context, int x, int y,
                                       SelectionData selection, uint target_type, uint time) {
        if(this.audio_player_device.in_loading)
            return;
        if(in_data_move)
            return;
        in_data_move = true;
        Gtk.TreePath path;
        TreeRowReference drop_rowref;
        FileType filetype;
        File file;
        string[] uris;
        this.get_dest_row_at_pos(x, y, out path, out drop_pos);
        switch(target_type) {
            // DRAGGING NOT WITHIN TRACKLIST
            case 0: // custom dnd data from media browser
                in_data_move = true;
                unowned DndData[] ids = (DndData[])selection.get_data();
                ids.length = (int)(selection.get_length() / sizeof(DndData));
                
                TreeRowReference row_ref = null;
                if(path != null)
                    row_ref = new TreeRowReference(this.model, path);
                
                var job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, 
                                         this.insert_dnd_data_job
                );
                job.dnd_data = ids;
//              print("dnd data get %d  %s\n", ids[0].db_id, ids[0].items[0].type.to_string());
                db_worker.push_job(job);
                break;
            case 1: // uri list from outside
                uris = selection.get_uris();
                print("receive get_uris\n");
//                drop_rowref = null;
                bool is_first = true;
                string attr = FileAttribute.STANDARD_TYPE + "," +
                              FileAttribute.STANDARD_CONTENT_TYPE;
                Array<Item?> items = new Array<Item?>();
                uint msg_id = 0;
                msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                        UserInfo.ContentClass.WAIT,
                                        _("Please wait while moving media to the device."),
                                        false,
                                        10,
                                        null);
                foreach(string uri in uris) {
                    print("uri:%s\n", uri);
                    file = File.new_for_uri(uri);
                    if(file.get_uri_scheme() in get_remote_schemes()) 
                        continue;
                    try {
                        FileInfo info = file.query_info(attr,
                                                        FileQueryInfoFlags.NONE,
                                                        null);
                        filetype = info.get_file_type();
                    }
                    catch(GLib.Error e){
                        print("%s\n", e.message);
                        return;
                    }
                    if(filetype != GLib.FileType.DIRECTORY) {
                        handle_dropped_file(ref uri, ref items);    //FILES
                    }
                    else {
                        handle_dropped_files_for_folders(file, ref items); //DIRECTORIES
                    }
                }
                var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_items_job);
                Item[] item_array = {};
                for(int j = 0; j < items.length; j++) {
                    item_array += items.index(j);
                }
                job.items = item_array;
                job.set_arg("msg_id", msg_id);
                device_worker.push_job(job);
                break;
            default:
                assert_not_reached();
                break;
        }
    }

    private void handle_dropped_file(ref string fileuri, ref Array<Item?> items) {//, ref TreePath? path, ref bool is_first) {
        //print ("1. xnoise-tracklist.vala => Ingresando a handle_dropped_file\n");
        //Function to import music FILES in drag'n'drop
        File file;
        FileType filetype;
        string mime;
        
        string attr = FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        try {
            file = File.new_for_uri(fileuri);
            FileInfo info = file.query_info(attr,
                                            FileQueryInfoFlags.NONE,
                                            null
            );
            filetype = info.get_file_type();
            string content = info.get_content_type();
            mime = GLib.ContentType.get_mime_type(content);
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
            return;
        }
        print("mime: %s\n", mime);
        if(Playlist.is_playlist_extension(get_suffix_from_filename(file.get_uri())))
            return;
        if(filetype == GLib.FileType.REGULAR &&
           (pattern_audio.match_string(mime)||
            pattern_video.match_string(mime)||
            supported_types.lookup(mime) == 1)) {
            Item? i = ItemHandlerManager.create_item(fileuri);
            if(i != null && i.type != ItemType.UNKNOWN)
                items.append_val(i);
        }
        else if(filetype==GLib.FileType.DIRECTORY) {
            assert_not_reached();
        }
        else {
            print("Not a regular file or at least no media file: %s\n", fileuri);
        }
    }
    
    private void handle_dropped_files_for_folders(File dir, ref Array<Item?> items) {
        //Recursive function to import music DIRECTORIES in drag'n'drop
        //as soon as a file is found it is passed to handle_dropped_file function
        //the TreePath path is just passed through if it is a directory
        FileEnumerator enumerator;
        try {
            string attr = FileAttribute.STANDARD_NAME + "," +
                          FileAttribute.STANDARD_TYPE;
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
        }
        catch(Error e) {
            print("Error importing directory %s. %s\n", dir.get_path(), e.message);
            return;
        }
        FileInfo info;
        try {
            while((info = enumerator.next_file(null)) != null) {
                string filename = info.get_name();
                string filepath = Path.build_filename(dir.get_path(), filename);
                File file = File.new_for_path(filepath);
                FileType filetype = info.get_file_type();
                
                if(filetype == FileType.DIRECTORY) {
                    this.handle_dropped_files_for_folders(file, ref items);
                }
                else {
                    string buffer = file.get_uri();
                    handle_dropped_file(ref buffer, ref items);
                }
            }
        }
        catch(Error e) {
            print("Error: %s\n", e.message);
            return;
        }
    }

    private bool copy_items_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(this.audio_player_device is IAudioPlayerDevice))
            return false;
        
        string[] destinations = {};
        
        File dest_base = File.new_for_uri(this.audio_player_device.get_uri());
        assert(dest_base != null);
        File dest1 = dest_base.get_child("Music");
        assert(dest1 != null);
        if(!dest1.query_exists(cancellable)) {
            dest1 = dest_base.get_child("media");
        }
        dest_base = dest1;
        foreach(Item? i in job.items) {
            
            File s = File.new_for_uri(i.uri);
            FileInfo info = null;
            try {
                info = s.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE, cancellable);
            }
            catch(Error e) {
                print("%s\n", e.message);
                continue;
            }
            uint64 size = info.get_attribute_uint64(FileAttribute.STANDARD_SIZE);
            if(this.audio_player_device.get_free_space_size() < size) {
                print("not enough space on device!\n");
                uint msg_id = 0;
                msg_id = userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                        UserInfo.ContentClass.CRITICAL,
                                        _("Not enough space on device! Aborting..."),
                                        false,
                                        10,
                                        null);
                break;
            }
            else {
                File dest = dest_base.get_child(s.get_basename());
                assert(dest != null);
                //print("dest : %s\n", dest.get_path());
                try {
                    s.copy(dest, FileCopyFlags.NONE, cancellable, null);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    continue;
                }
                destinations += dest.get_uri();
                //print("done copying file to android device.\n");
            }
        }
        
        Timeout.add(200, () => {
            if(cancellable.is_cancelled())
                return false;
            audio_player_device.sign_add_track(destinations);
            in_data_move = false;
            return false;
        });
        Timeout.add_seconds(1, () => {
            uint msg_id = (uint)job.get_arg("msg_id");
            if(msg_id != 0) {
                userinfo.popdown(msg_id);
            }
            in_data_move = false;
            return false;
        });
        Idle.add(() => {
            audio_player_device.sign_update_filesystem();
            return false;
        });
        return false;
    }


    private bool insert_dnd_data_job(Worker.Job job) {
        assert(db_worker.is_same_thread());
        DndData[] ids = job.dnd_data;
        bool is_first = true;
        TrackData[] localarray = {};
        foreach(DndData ix in ids) {
            if(ix.mediatype == ItemType.STREAM)
                continue;
            Item i = Item(ix.mediatype, null, ix.db_id);
            i.source_id = ix.source_id;
            i.stamp = ix.stamp;
            //print("insert type %s\n", i.type.to_string());
            Item? oo = null;
            HashTable<ItemType,Item?>? extra_items = null;
            if(ix.extra_db_id[0] > -1) {
                oo = Item(ix.extra_mediatype[0], null, ix.extra_db_id[0]);
                oo.stamp = ix.extra_stamps[0];
                extra_items = new HashTable<ItemType,Item?>(direct_hash, direct_equal);
                extra_items.insert(oo.type, oo);
            }
            TrackData[]? tmp = item_converter.to_trackdata(i, global.searchtext, extra_items);
            if(tmp != null) {
                foreach(TrackData tmpdata in tmp) {
                    if(tmpdata == null) {
                        print("tmpdata is null\n");
                        continue;
                    }
                    localarray += tmpdata;
                }
            }
        }
        job.track_dat = localarray;
        
        if(job.track_dat != null) { // && job.track_dat.length > 0) {
            uint msg_id = 0;
            Idle.add( () => {
                msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                        UserInfo.ContentClass.WAIT,
                                        _("Please wait while moving media to the device."),
                                        false,
                                        10,
                                        null);
                
                var _job = new Worker.Job(Worker.ExecutionType.ONCE, copy_files_job);
                _job.track_dat = (owned)job.track_dat;
                job.track_dat = {};
                _job.set_arg("msg_id", msg_id);
                device_worker.push_job(_job);
                return false;
            });
        }
        return false;
    }
    
    private bool copy_files_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(this.audio_player_device is IAudioPlayerDevice))
            return false;
        
        string[] destinations = {};
        
        File dest_base = File.new_for_uri(this.audio_player_device.get_uri());
        assert(dest_base != null);
        File dest1 = dest_base.get_child("Music");
        assert(dest1 != null);
        if(!dest1.query_exists(cancellable)) {
            dest1 = dest_base.get_child("media");
        }
        dest_base = dest1;
        foreach(TrackData td in job.track_dat) {
            
            File s = File.new_for_uri(td.item.uri);
            FileInfo info = null;
            try {
                info = s.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE, cancellable);
            }
            catch(Error e) {
                print("%s\n", e.message);
                continue;
            }
            uint64 size = info.get_attribute_uint64(FileAttribute.STANDARD_SIZE);
            if(this.audio_player_device.get_free_space_size() < size) {
                print("not enough space on device!\n");
                uint msg_id = 0;
                msg_id = userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
                                        UserInfo.ContentClass.CRITICAL,
                                        _("Not enough space on device! Aborting..."),
                                        false,
                                        10,
                                        null);
                break;
            }
            else {
                File dest = dest_base.get_child(s.get_basename());
                assert(dest != null);
                //print("dest : %s\n", dest.get_path());
                try {
                    s.copy(dest, FileCopyFlags.NONE, cancellable, null);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    continue;
                }
                destinations += dest.get_uri();
                //print("done copying file to android device.\n");
            }
        }
        
        Timeout.add(200, () => {
            if(cancellable.is_cancelled())
                return false;
            audio_player_device.sign_add_track(destinations);
            in_data_move = false;
            return false;
        });
        Timeout.add_seconds(1, () => {
            uint msg_id = (uint)job.get_arg("msg_id");
            if(msg_id != 0) {
                userinfo.popdown(msg_id);
            }
            in_data_move = false;
            return false;
        });
        Idle.add(() => {
            audio_player_device.sign_update_filesystem();
            return false;
        });
        return false;
    }

//    private bool on_drag_motion(Gtk.Widget sender, Gdk.DragContext context, int x, int y, uint timestamp) {
//        Gtk.TreePath path;
//        Gtk.TreeViewDropPosition pos;
//        if(!(this.get_dest_row_at_pos(x, y, out path, out pos))) return false;
//        this.set_drag_dest_row(path, pos);
//        
//        // Autoscroll
//        start_autoscroll();
//        return true;
//    }
//    
//    private bool do_scroll(int delta) { 
//        int buffer;
//        Gtk.Adjustment adjustment = this.get_vadjustment();
//        
//        if(adjustment == null)
//            return false;
//        
//        buffer = (int)adjustment.get_value();
//        adjustment.set_value(adjustment.get_value() + delta);
//        return (adjustment.get_value() != buffer);
//    }
//    
//    private bool autoscroll_timeout() {
//        double delta = 0.0;
//        Gdk.Rectangle expose_area = Gdk.Rectangle();
//        
//        get_autoscroll_delta(ref delta);
//        if(delta == 0) 
//            return true;
//        
//        if(!do_scroll((int)delta))
//            return true;
//        
//        Allocation alloc;
//        this.get_allocation(out alloc);
//        expose_area.x      = alloc.x;
//        expose_area.y      = alloc.y;
//        expose_area.width  = alloc.width;
//        expose_area.height = alloc.height;
//        
//        if(delta > 0) {
//            expose_area.y = expose_area.height - (int)delta;
//        } 
//        else {
//            if(delta < 0)
//                expose_area.height = (int)(-1.0 * delta);
//        }

//        expose_area.x -= alloc.x;
//        expose_area.y -= alloc.y;

//        this.queue_draw_area(expose_area.x,
//                             expose_area.y,
//                             expose_area.width,
//                             expose_area.height);
//        return true;
//    }
//    
//    private void start_autoscroll() { 
//        double delta = 0.0;
//        get_autoscroll_delta(ref delta);
//        if(delta != 0) {
//            if(autoscroll_source == 0) 
//                autoscroll_source = Timeout.add(100, autoscroll_timeout);
//        } 
//        else {
//            stop_autoscroll();
//        }
//    }

//    private void stop_autoscroll() {
//        if(autoscroll_source != 0) {
//            Source.remove(autoscroll_source);
//            autoscroll_source = 0;
//        }
//    }

//    private void get_autoscroll_delta(ref double delta) {
//        int y_pos;
//        this.get_pointer(null, out y_pos);
//        delta = 0.0;
//        if(y_pos < autoscroll_distance) 
//            delta = (double)(y_pos - autoscroll_distance);
//        Allocation alloc;
//        this.get_allocation(out alloc);
//        if(y_pos > (alloc.height - autoscroll_distance)) {
//            if(delta != 0) { //window too narrow, don't autoscroll.
//                return;
//            }
//            delta = (double)(y_pos - (alloc.height - autoscroll_distance));
//        }
//        if(delta == 0) {
//            return;
//        }
//        if(delta != 0) {
//            delta /= autoscroll_distance;
//            delta *= 60;
//        }
//    }

    private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        
        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y)))
            return true;
        
        switch(e.button) {
            case 1:
                if(selection.count_selected_rows()<=1) {
                    return false;
                }
                else {
                    if(selection.path_is_selected(path)) {
                        if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
                                selection.unselect_path(path);
                        }
                        return true;
                    }
                    else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
                        return true;
                    }
                    return false;
                }
            case 2:
                //print("button 2\n");
                break;
            case 3:
                if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                    ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
                        return false;
                }
                else {
                    int selectioncount = selection.count_selected_rows();
                    if(selectioncount <= 1) {
                        selection.unselect_all();
                        selection.select_path(path);
                    }
                }
                rightclick_menu_popup(e.time);
                return true;
            }
        if(!(selection.count_selected_rows()>0)) selection.select_path(path);
        return false;
    }

    private Gtk.Menu menu;
    
    private void rightclick_menu_popup(uint activateTime) {
        menu = create_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, activateTime);
    }

    private Gtk.Menu create_rightclick_menu() {
        TreeIter iter;
        var rightmenu = new Gtk.Menu();
        GLib.List<TreePath> list;
        list = this.get_selection().get_selected_rows(null);
        if(list == null)
            return rightmenu;
        ItemSelectionType itsel;
        if(list.length() > 1)
            itsel = ItemSelectionType.MULTIPLE;
        else
            itsel = ItemSelectionType.SINGLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        treemodel.get_iter(out iter, path);
        treemodel.get(iter, AndroidPlayerTreeStore.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.EXTERNAL_DEVICE_LIST, itsel);
        //print("array.length:::%u\n", array.length);
        for(int i =0; i < array.length; i++) {
            print("%s\n", array.index(i).name);
            var menu_item = new ImageMenuItem.from_stock(array.index(i).stock_item, null);
            menu_item.set_label(array.index(i).info);
            //Value? v = list;
            unowned Action x = array.index(i);
            menu_item.activate.connect( () => {
                x.action(item, null, null);
            });
            rightmenu.append(menu_item);
        }
        rightmenu.show_all();
        return rightmenu;
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            treemodel.get_iter(out iter, treepath);
            treemodel.get(iter, GenericPlayerTreeStore.Column.ITEM, out item);
            if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
               item.type != ItemType.LOCAL_VIDEO_TRACK &&
               item.type != ItemType.STREAM) {
                this.expand_row(treepath, false);
                return;
            }
            global.preview_uri(item.uri);
        }
        else {
            this.expand_row(treepath, false);
        }
    }

    private void on_row_expanded(TreeIter iter, TreePath path) {
        treemodel.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        treemodel.unload_children(ref iter);
    }
    
    private void setup_view() {
        
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
        var column = new TreeViewColumn();
        
        var pixbufRenderer = new CellRendererPixbuf();
        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
        var renderer = new CellRendererText();
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", AndroidPlayerTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", AndroidPlayerTreeStore.Column.VIS_TEXT);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
    }


}
