/* xnoise-audio-player-tree-view.vala
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


public abstract class Xnoise.ExtDev.PlayerTreeView : Gtk.TreeView {
    protected unowned PlayerDevice audio_player_device;
    protected unowned Cancellable cancellable;
    
    // targets used with this as a destination
    private const TargetEntry[] dest_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
        {"text/uri-list", 0, 1}
    };
    
    internal PlayerTreeStore treemodel;
    
    
    public PlayerTreeView(PlayerDevice audio_player_device,
                                 Cancellable cancellable) {
        this.audio_player_device = audio_player_device;
        this.cancellable = cancellable;
        
        treemodel = get_tree_store();
        
        setup_view();
        
        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.DEFAULT
                          );
        row_activated.connect(on_row_activated);
        button_press_event.connect(on_button_press);
    }
    
    protected abstract PlayerTreeStore? get_tree_store();
    
    public override void drag_data_received(DragContext context, int x, int y,
                                       SelectionData selection, uint target_type, uint time) {
        if(audio_player_device.in_loading || audio_player_device.in_data_transfer)
             return;
        audio_player_device.in_data_transfer = true;
        Gtk.TreeViewDropPosition drop_pos;
        Gtk.TreePath path;
        FileType filetype;
        File file;
        string[] uris;
        get_dest_row_at_pos(x, y, out path, out drop_pos);
        switch(target_type) {
            // DRAGGING NOT WITHIN TRACKLIST
            case 0: // custom dnd data from media browser
                unowned DndData[] ids = (DndData[])selection.get_data();
                ids.length = (int)(selection.get_length() / sizeof(DndData));
                
                TreeRowReference row_ref = null;
                if(path != null)
                    row_ref = new TreeRowReference(model, path);
                
                var job = new Worker.Job(Worker.ExecutionType.ONCE, 
                                         insert_dnd_data_job, Worker.Priority.HIGH
                );
                job.dnd_data = ids;
                //print("dnd data get %d  %s\n", ids[0].db_id, ids[0].items[0].type.to_string());
                db_worker.push_job(job);
                break;
            case 1: // uri list from outside
                uris = selection.get_uris();
                print("receive get_uris\n");
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
                audio_player_device.in_data_transfer = false;
                assert_not_reached();
        }
    }

    private void handle_dropped_file(ref string fileuri, ref Array<Item?> items) {
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
                    handle_dropped_files_for_folders(file, ref items);
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

    protected abstract File? get_dest_dir();
    
    private bool copy_items_job(Worker.Job job) {
        if(cancellable.is_cancelled())
            return false;
        if(!(audio_player_device is PlayerDevice))
            return false;
        
        string[] destinations = {};
        
        File dest_base = get_dest_dir();
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
            if(audio_player_device.get_free_space_size() < size) {
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
            audio_player_device.in_data_transfer = false;
            return false;
        });
        Timeout.add_seconds(1, () => {
            uint msg_id = (uint)job.get_arg("msg_id");
            if(msg_id != 0) {
                userinfo.popdown(msg_id);
            }
            audio_player_device.in_data_transfer = false;
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
        if(!(audio_player_device is PlayerDevice))
            return false;
        
        string[] destinations = {};
        
        File dest_base = get_dest_dir();
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
            if(audio_player_device.get_free_space_size() < size) {
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
            audio_player_device.in_data_transfer = false;
            return false;
        });
        Timeout.add_seconds(1, () => {
            uint msg_id = (uint)job.get_arg("msg_id");
            if(msg_id != 0) {
                userinfo.popdown(msg_id);
            }
            audio_player_device.in_data_transfer = false;
            return false;
        });
        Idle.add(() => {
            audio_player_device.sign_update_filesystem();
            return false;
        });
        return false;
    }

    private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        
        Gtk.TreeSelection selection = get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        if(!(get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y)))
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
        list = get_selection().get_selected_rows(null);
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
        treemodel.get(iter, PlayerTreeStore.Column.ITEM, out item);
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
        if(array.length > 0) {
            var sptr_item = new SeparatorMenuItem();
            rightmenu.append(sptr_item);
        }
        var collapse_item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        collapse_item.set_label(_("Collapse all"));
        collapse_item.activate.connect( () => {
            collapse_all();
        });
        rightmenu.append(collapse_item);
        
        rightmenu.show_all();
        return rightmenu;
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            treemodel.get_iter(out iter, treepath);
            treemodel.get(iter, PlayerTreeStore.Column.ITEM, out item);
            if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
               item.type != ItemType.LOCAL_VIDEO_TRACK &&
               item.type != ItemType.STREAM) {
                expand_row(treepath, false);
                return;
            }
            global.preview_uri(item.uri);
        }
        else {
            expand_row(treepath, false);
        }
    }

    private void on_row_expanded(TreeIter iter, TreePath path) {
        treemodel.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        treemodel.unload_children(ref iter);
    }
    
    private void setup_view() {
        
        row_collapsed.connect(on_row_collapsed);
        row_expanded.connect(on_row_expanded);
        
        var column = new TreeViewColumn();
        
        var pixbufRenderer = new CellRendererPixbuf();
        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
        var renderer = new CellRendererText();
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", PlayerTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", PlayerTreeStore.Column.VIS_TEXT);
        insert_column(column, -1);
        
        headers_visible = false;
        enable_search = false;
    }
}


