/* xnoise-tracklist.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Playlist;
using Xnoise.Utilities;
using Xnoise.TagAccess;


private class Xnoise.TrackListViewWidget : Gtk.Box, Xnoise.IMainView {
    private const string UI_FILE = Config.XN_UIDIR + "tracklist.ui";
    
    private unowned MainWindow win;
    internal ScrolledWindow scrolled_window;
    
    public TrackListViewWidget(MainWindow win) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.win = win;
        setup_widgets();
    }
    
    public string get_view_name() {
        return TRACKLIST_VIEW_NAME;
    }
    
    
    private void setup_widgets() {
        scrolled_window = new ScrolledWindow(null, null);
        scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS);
        scrolled_window.set_shadow_type(Gtk.ShadowType.NONE);
        scrolled_window.add(tl);
        
        var context = this.get_style_context();
        context.save();
        context.add_class(STYLE_CLASS_CELL);
        Gdk.RGBA color = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
        this.override_background_color(StateFlags.NORMAL, color);
        context.restore();
        
        this.pack_start(scrolled_window, true, true, 0);
    }
}


public class Xnoise.TrackList : TreeView, IParams {
    private Main xn;
    private unowned IconTheme theme = null;

    private const TargetEntry[] src_target_entries = {
        {"text/uri-list", Gtk.TargetFlags.SAME_WIDGET, 0}
    };

    // targets used with this as a destination
    private const TargetEntry[] dest_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
        {"text/uri-list", 0, 1}
    };

    private const string USE_LEN_COL     = "use_length_column";
    private const string USE_TR_NO_COL   = "use_tracknumber_column";
    private const string USE_DISK_NO_COL = "use_disknumber_column";
    private const string USE_ARTIST_COL  = "use_artist_column";
    private const string USE_ALBUM_COL   = "use_album_column";
    private const string USE_GENRE_COL   = "use_genre_column";
    private const string USE_YEAR_COL    = "use_year_column";

    private TreeViewColumn columnPixb;
    private TextColumn columnAlbum;
    private TextColumn columnTitle;
    private TextColumn columnArtist;
    private TextColumn columnLength;
    private TextColumn columnTracknumber;
    private TextColumn columnDisknumber;
    private TextColumn columnGenre;
    private TextColumn columnYear;
    private int variable_col_count = 0;
    private TreeRowReference[] rowref_list;
    private bool dragging;
    private Gtk.Menu menu;
    private const int autoscroll_distance = 50;
    private uint autoscroll_source = 0;
    private bool reorder_dragging = false;
    private uint hide_timer = 0;
    
    private bool column_length_visible {
        get { return this.columnLength.visible; }
        set { this.columnLength.visible = value; }
    }
    
    private bool column_tracknumber_visible {
        get { return this.columnTracknumber.visible; }
        set { this.columnTracknumber.visible = value; }
    }
    
    private bool column_disknumber_visible {
        get { return this.columnDisknumber.visible; }
        set { this.columnDisknumber.visible = value; }
    }
    
    private bool column_artist_visible { 
        get { return this.columnArtist.visible; }
        set { this.columnArtist.visible = value; }
    }

    private bool column_album_visible { 
        get { return this.columnAlbum.visible; }
        set { this.columnAlbum.visible = value; }
    }

    private bool column_genre_visible { 
        get { return this.columnGenre.visible; }
        set { this.columnGenre.visible = value; }
    }

    private bool column_year_visible { 
        get { return this.columnYear.visible; }
        set { this.columnYear.visible = value; }
    }

    internal TrackListModel tracklistmodel { get; private set; }

    public TrackList() {
        this.xn = Main.instance;
        theme = IconTheme.get_default();
//        this.get_style_context().add_class(STYLE_CLASS_VIEW);
//        var context = this.get_style_context();
//        context.save();
//        context.add_class(STYLE_CLASS_CELL);
//        Gdk.RGBA color = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
//        this.override_background_color(StateFlags.NORMAL, color);
//        context.restore();
        if(tlm == null)
            print("tracklist model instance not available\n");
        
        this.set_fixed_height_mode(true);
        
        Params.iparams_register(this);
        
        this.setup_view();
        
        tracklistmodel = tlm;
        this.set_model(tracklistmodel);
        
        this.get_selection().set_mode(SelectionMode.MULTIPLE);
        
        Gtk.drag_source_set(this,
                            Gdk.ModifierType.BUTTON1_MASK,
                            src_target_entries,
                            Gdk.DragAction.COPY|
                            Gdk.DragAction.MOVE
                            );
        
        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.DEFAULT
                          );
        
        // Signals
        this.row_activated.connect(this.on_row_activated);
        this.key_release_event.connect(this.on_key_released);
        this.drag_begin.connect(this.on_drag_begin);
        this.drag_data_get.connect(this.on_drag_data_get);
        this.drag_end.connect(this.on_drag_end);
        this.drag_motion.connect(this.on_drag_motion);
        this.drag_data_received.connect(this.on_drag_data_received);
        this.drag_leave.connect(this.on_drag_leave);
        this.button_release_event.connect(this.on_button_release);
        this.button_press_event.connect(this.on_button_press);
        
        this.set_headers_clickable(true);
        Idle.add( () => {
            foreach(TreeViewColumn col in this.get_columns()) {
                col.set_widget(new Label(col.title));
                col.get_widget().show();
                ((Button)col.get_widget().get_ancestor(typeof(Button))).button_press_event.connect(on_press_header);
            }
            return false;
        });
        this.set_size_request(100, 100);
    }
    
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
                print("button 2\n");
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
        tracklistmodel.get_iter(out iter, path);
        string? artist_name = null;
        tracklistmodel.get(iter, 
                           TrackListModel.Column.ITEM, out item,
                           TrackListModel.Column.ARTIST, out artist_name);
        item.text = artist_name;
        array = itemhandler_manager.get_actions(item.type, ActionContext.TRACKLIST_MENU_QUERY, itsel);
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

    private bool on_button_release(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        int cell_x, cell_y;

        if((e.button != 1) | (this.dragging)) {
            this.dragging = false;
            return true;
        }
        if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
            return true;
        }
        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y))) return false;
        selection.unselect_all();
        selection.select_path(path);
        return false; //for testing
    }

    private bool on_drag_motion(Gtk.Widget sender, Gdk.DragContext context, int x, int y, uint timestamp) {
        Gtk.TreePath path;
        Gtk.TreeViewDropPosition pos;
        if(!(this.get_dest_row_at_pos(x, y, out path, out pos))) return false;
        this.set_drag_dest_row(path, pos);
        
        // Autoscroll
        start_autoscroll();
        return true;
    }
    
    private bool do_scroll(int delta) { 
        int buffer;
        Gtk.Adjustment adjustment = this.get_vadjustment();
        
        if(adjustment == null)
            return false;
        
        buffer = (int)adjustment.get_value();
        adjustment.set_value(adjustment.get_value() + delta);
        return (adjustment.get_value() != buffer);
    }
    
    private bool autoscroll_timeout() {
        double delta = 0.0;
        Gdk.Rectangle expose_area = Gdk.Rectangle();
        
        get_autoscroll_delta(ref delta);
        if(delta == 0) 
            return true;
        
        if(!do_scroll((int)delta))
            return true;
        
        Allocation alloc;
        this.get_allocation(out alloc);
        expose_area.x      = alloc.x;
        expose_area.y      = alloc.y;
        expose_area.width  = alloc.width;
        expose_area.height = alloc.height;
        
        if(delta > 0) {
            expose_area.y = expose_area.height - (int)delta;
        } 
        else {
            if(delta < 0)
                expose_area.height = (int)(-1.0 * delta);
        }

        expose_area.x -= alloc.x;
        expose_area.y -= alloc.y;

        this.queue_draw_area(expose_area.x,
                             expose_area.y,
                             expose_area.width,
                             expose_area.height);
        return true;
    }
    
    private void start_autoscroll() { 
        double delta = 0.0;
        get_autoscroll_delta(ref delta);
        if(delta != 0) {
            if(autoscroll_source == 0) 
                autoscroll_source = Timeout.add(100, autoscroll_timeout);
        } 
        else {
            stop_autoscroll();
        }
    }

    private void stop_autoscroll() {
        if(autoscroll_source != 0) {
            Source.remove(autoscroll_source);
            autoscroll_source = 0;
        }
    }

    private void get_autoscroll_delta(ref double delta) {
        int y_pos;
        this.get_pointer(null, out y_pos);
        delta = 0.0;
        if(y_pos < autoscroll_distance) 
            delta = (double)(y_pos - autoscroll_distance);
        Allocation alloc;
        this.get_allocation(out alloc);
        if(y_pos > (alloc.height - autoscroll_distance)) {
            if(delta != 0) { //window too narrow, don't autoscroll.
                return;
            }
            delta = (double)(y_pos - (alloc.height - autoscroll_distance));
        }
        if(delta == 0) {
            return;
        }
        if(delta != 0) {
            delta /= autoscroll_distance;
            delta *= 60;
        }
    }

    private void on_drag_begin(Gtk.Widget sender, DragContext context) {
        this.dragging = true;
        this.reorder_dragging = true;

        Gtk.TreeSelection selection = this.get_selection();
        Gdk.drag_abort(context, Gtk.get_current_event_time());
        if(selection.count_selected_rows() == 0) {
            return;
        }
        try {
            Gtk.Invisible w = new Gtk.Invisible();
            Pixbuf title_pixb;
            if(theme.has_icon("media-audio")) 
                title_pixb = theme.load_icon("media-audio", 22, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("audio-x-generic")) 
                title_pixb = theme.load_icon("audio-x-generic", 22, IconLookupFlags.FORCE_SIZE);
            else 
                title_pixb = w.render_icon(Gtk.Stock.OPEN, IconSize.BUTTON, null);
            Gtk.drag_source_set_icon_pixbuf(this, title_pixb);
        }
        catch(Error e) {
            print("%s\n", e.message);
            if(selection.count_selected_rows() > 1) {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
            }
            else {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
            }
        }

        return;
    }

    private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
        this.dragging = false;
        this.reorder_dragging = false;
        this.unset_rows_drag_dest();
        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.MOVE
                          );
        stop_autoscroll();
    }

    private void on_drag_leave(Gtk.Widget sender, Gdk.DragContext context, uint etime) {
        stop_autoscroll();
        
        Gdk.Window win = this.get_window();
        if(win == null)
            return;
        
        int px = 0, py = 0;
        this.get_pointer(out px, out py); //using widget pointer instead of widget.window pointer
        
        if(px < 0 || py < 0) {
//            if(main_window.temporary_tab != TrackListNoteBookTab.TRACKLIST) {
//                main_window.tracklistnotebook.set_current_page(main_window.temporary_tab);
//                main_window.temporary_tab = TrackListNoteBookTab.TRACKLIST;
//            }
            main_window.restore_tab();
        }
    }

    private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context,
                                  Gtk.SelectionData selection, 
                                  uint target_type, uint etime) {
        rowref_list = {};
        TreeIter iter;
        List<unowned TreePath> paths;
        unowned Gtk.TreeSelection sel;
        string[] uris;

        sel = this.get_selection();
        paths = sel.get_selected_rows(null);
         int i = 0;
        uris = new string[(int)paths.length() + 1];
        foreach(unowned TreePath path in paths) {
            this.tracklistmodel.get_iter(out iter, path);
            Item? item;
            this.tracklistmodel.get(iter, TrackListModel.Column.ITEM, out item);
            uris[i] = item.uri;
            i++;
            TreeRowReference treerowref = new TreeRowReference(this.tracklistmodel, path);
            if(treerowref.valid()) {
                rowref_list += (owned)treerowref;
            }
        }
        selection.set_uris(uris);
    }

    private Gtk.TreeViewDropPosition drop_pos;
    private void on_drag_data_received(Gtk.Widget sender, DragContext context, int x, int y,
                                       SelectionData selection, uint target_type, uint time) {
        //set uri list for dragging out of xnoise. in parallel work around with rowreferences
        //if reorder = false then data is coming from outside (music browser or nautilus)
        // -> use uri_list
        Gtk.TreePath path;
        TreeRowReference drop_rowref;
        FileType filetype;
        File file;
        string[] uris;
        this.get_dest_row_at_pos(x, y, out path, out drop_pos);
        
        if(!this.reorder_dragging ) {
            switch(target_type) {
                // DRAGGING NOT WITHIN TRACKLIST
                case 0: // custom dnd data from media browser
                    unowned DndData[] ids = (DndData[])selection.get_data();
                    ids.length = (int)(selection.get_length() / sizeof(DndData));
                    
                    TreeRowReference row_ref = null;
                    if(path != null)
                        row_ref = new TreeRowReference(this.model, path);
                    
                    var job = new Worker.Job(Worker.ExecutionType.ONCE, 
                                             this.insert_dnd_data_job, Worker.Priority.HIGH
                    );
                    job.set_arg("row_ref", row_ref);
                    job.set_arg("drop_pos", drop_pos);
                    job.dnd_data = ids;
//                    print("dnd data get %d  %s\n", ids[0].db_id, ids[0].items[0].type.to_string());
                    db_worker.push_job(job);
                    break;
                case 1: // uri list from outside
                    uris = selection.get_uris();
                    print("receive get_uris\n");
                    drop_rowref = null;
                    bool is_first = true;
                    string attr = FileAttribute.STANDARD_TYPE + "," +
                                  FileAttribute.STANDARD_CONTENT_TYPE;
                    foreach(string uri in uris) {
                        print("uri:%s\n", uri);
                        bool is_stream = false;
                        file = File.new_for_uri(uri);
                        if(file.get_uri_scheme() in get_remote_schemes()) 
                            is_stream = true;
                        if(!is_stream) {
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
                                //print("1. on_drag_data_received - Aqui se llama a handle_dropped_file");
                                handle_dropped_file(ref uri, ref path, ref is_first);    //FILES
                            }
                            else {
                                handle_dropped_files_for_folders(file, ref path, ref is_first); //DIRECTORIES
                            }
                        }
                        else {
                            handle_dropped_stream_uri(ref uri, ref path, ref is_first);
                        }
                    }
                    break;
                default:
                    assert_not_reached();
            
            }
        }
        else { // DRAGGING WITHIN TRACKLIST
            uris = selection.get_uris();
            drop_rowref = null;
            if(path != null) {
                //TODO:check if drop position is selected
                drop_rowref = new TreeRowReference(this.tracklistmodel, path);
                if(drop_rowref == null || !drop_rowref.valid()) 
                    return;
            }
            else {
                get_last_unselected_path(ref path);
                if(path == null)
                    return;
                drop_rowref = new TreeRowReference(this.tracklistmodel, path);
                if(drop_rowref == null || !drop_rowref.valid()) {
                    return;
                }
            }
            if((!(drop_pos == Gtk.TreeViewDropPosition.BEFORE))&&
               (!(drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE))) {
                for(int i=rowref_list.length-1;i>=0;i--) {
                    if(rowref_list[i] == null || !rowref_list[i].valid()) {
                        return;
                    }
                    unowned TreeIter current_iter;
                    unowned TreeIter drop_iter;
                    var current_path = rowref_list[i].get_path();
                    this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
                    TreePath drop_path = drop_rowref.get_path();
                    this.tracklistmodel.get_iter(out drop_iter, drop_path);//get iter for drop position
                    this.tracklistmodel.move_after(ref current_iter, drop_iter); //move
                }
            }
            else {
                for(int i=0;i<rowref_list.length;i++) {
                    if(rowref_list[i] == null || !rowref_list[i].valid()) {
                        return;
                    }
                    unowned TreeIter current_iter;
                    unowned TreeIter drop_iter;
                    var current_path = rowref_list[i].get_path();
                    this.tracklistmodel.get_iter(out current_iter, current_path); //get iter for current
                    TreePath drop_path = drop_rowref.get_path();
                    this.tracklistmodel.get_iter(out drop_iter, drop_path); //get iter for drop position
                    this.tracklistmodel.move_before(ref current_iter, drop_iter); //move
                }
            }
        }
        drop_pos = Gtk.TreeViewDropPosition.AFTER; //Default position for next run
        rowref_list = null;
        
        //After dropping an item hide the tracklist with a delay of 1s 
        //if it was only shown temporarily
        if(hide_timer != 0) 
            GLib.Source.remove(hide_timer);
        
        hide_timer = Timeout.add(200, () => {
            main_window.restore_tab();
            hide_timer = 0;
            return false;
        });
    }

    private bool insert_dnd_data_job(Worker.Job job) {
        assert(db_worker.is_same_thread());
//        DndData[] ids = job.dnd_data;
        bool is_first = true;
        TrackData[] localarray = {};
        foreach(DndData ix in job.dnd_data) { //ids
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
            Idle.add( () => {
                TreeViewDropPosition drop_pos_1 = (TreeViewDropPosition)job.get_arg("drop_pos");
                TreeRowReference row_ref = (TreeRowReference)job.get_arg("row_ref");
                TreePath path = null;
                if(row_ref != null && row_ref.valid())
                    path = row_ref.get_path();
                foreach(TrackData tdx in job.track_dat) {
                    TreeIter iter, new_iter;
                    TreeIter first_iter = TreeIter();
                    if((path == null)||(!this.tracklistmodel.get_iter_first(out first_iter))) { 
                        //dropped below all entries, first uri OR
                        //dropped on empty list, first uri
                        tracklistmodel.append(out new_iter);
                        drop_pos_1 = Gtk.TreeViewDropPosition.AFTER;
                    }
                    else { //all other uris
                        this.tracklistmodel.get_iter(out iter, path);
                        if(is_first) {
                            if((drop_pos_1 == Gtk.TreeViewDropPosition.BEFORE)||
                               (drop_pos_1 == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
                               //Determine drop position for first, insert all others after first
                                this.tracklistmodel.insert_before(out new_iter, iter);
                            }
                            else {
                                this.tracklistmodel.insert_after(out new_iter, iter);
                            }
                            is_first = false;
                        }
                        else {
                            this.tracklistmodel.insert_after(out new_iter, iter);
                        }
                    }
                    string tracknumberString = EMPTYSTRING;
                    if(tdx.tracknumber != 0) {
                        tracknumberString = "%u".printf(tdx.tracknumber);
                    }
                    string? yearString = null;
                    if(tdx.year > 0) {
                        yearString = "%u".printf(tdx.year);
                    }
                    string? disk_number_string = null;
                    if(tdx.disk_number > 0)
                        disk_number_string = "%d".printf(tdx.disk_number);
                    
                    tracklistmodel.set(new_iter,
                                       TrackListModel.Column.TRACKNUMBER, tracknumberString,
                                       TrackListModel.Column.TITLE, tdx.title,
                                       TrackListModel.Column.ALBUM, tdx.album,
                                       TrackListModel.Column.ARTIST, (tdx.artist.down() == "various artists" &&
                                                                      tdx.albumartist != "" ? 
                                                                          tdx.albumartist : tdx.artist),
                                       TrackListModel.Column.LENGTH, make_time_display_from_seconds(tdx.length),
                                       TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
                                       TrackListModel.Column.ITEM, tdx.item,
                                       TrackListModel.Column.YEAR, yearString,
                                       TrackListModel.Column.GENRE, tdx.genre,
                                       TrackListModel.Column.DISK_NUMBER, disk_number_string);
                    path = tracklistmodel.get_path(new_iter);
                }
                return false;
            });
        }
        return false;
    }

    private void handle_dropped_files_for_folders(File dir, ref TreePath? path, ref bool is_first) {
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
                    this.handle_dropped_files_for_folders(file, ref path, ref is_first);
                }
                else {
                    string buffer = file.get_uri();
                    //print("2. on_drag_data_received - Aqui se llama a handle_dropped_file");
                    handle_dropped_file(ref buffer, ref path, ref is_first);
                }
            }
        }
        catch(Error e) {
            print("Error: %s\n", e.message);
            return;
        }
    }

    private void add_dropped_uri(ref string fileuri, ref TreePath? path, ref bool is_first, bool from_playlist = false) {
    //Add dropped uri to tracklist
        TreeIter iter, new_iter;
        string artist=EMPTYSTRING, album = EMPTYSTRING, title = EMPTYSTRING, lengthString = EMPTYSTRING, genre = UNKNOWN_GENRE;
        string? yearString = null;
        uint tracknumb = 0;
        
        File file = File.new_for_uri(fileuri);
        Item? item = ItemHandlerManager.create_item(file.get_uri());
        if(item.type == ItemType.UNKNOWN) // only handle file, if we know it
            if(from_playlist == false)
                return;
            else
                item.type = Xnoise.ItemType.STREAM; //When it is call from playlist then acept STREAM
        
        TrackData td = new TrackData();
        TrackData[]? tmp = item_converter.to_trackdata(item, EMPTYSTRING);
        print("BBB td.artist: %s\n", td.artist);
        if(tmp != null && tmp[0] != null) {
            td = tmp[0];
            artist         = (td.artist.down() == "various artists" && td.albumartist != "" ? 
                                                   td.albumartist : td.artist);
            album          = td.album;
            title          = td.title;
            tracknumb      = td.tracknumber;
            genre          = td.genre;
            if(td.year > 0)
                yearString = "%u".printf(td.year);
            lengthString = make_time_display_from_seconds(td.length);
        }
        else {
            var tr = new TagReader();
            var tags = tr.read_tag(file.get_path());
            if(tags == null) {
                title          = prepare_name_from_filename(file.get_basename());
            }
            else {
                artist         = tags.artist;
                album          = tags.album;
                title          = tags.title;
                tracknumb      = tags.tracknumber;
                genre          = tags.genre;
                lengthString = make_time_display_from_seconds(tags.length);
                if(tags.year > 0) 
                    yearString = "%u".printf(tags.year);
            }
        }
        TreeIter first_iter;
        if(path == null || !this.tracklistmodel.get_iter_first(out first_iter)) {
            tracklistmodel.append(out new_iter);
            drop_pos = Gtk.TreeViewDropPosition.AFTER;
        }
        else {
            this.tracklistmodel.get_iter(out iter, path);
            
            if(is_first) {
                if((drop_pos == Gtk.TreeViewDropPosition.BEFORE)||
                   (drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
                       //Determine drop position for first, insert all others after first
                    this.tracklistmodel.insert_before(out new_iter, iter);
                }
                else {
                    this.tracklistmodel.insert_after(out new_iter, iter);
                }
                is_first = false;
            }
            else {
                this.tracklistmodel.insert_after(out new_iter, iter);
            }
        }
        
        string tracknumberString = null;
        if(tracknumb!=0) {
            tracknumberString = "%u".printf(tracknumb);
        }
        tracklistmodel.set(new_iter,
                       TrackListModel.Column.TRACKNUMBER, tracknumberString,
                       TrackListModel.Column.TITLE, title,
                       TrackListModel.Column.ALBUM, album,
                       TrackListModel.Column.ARTIST, artist,
                       TrackListModel.Column.LENGTH, lengthString,
                       TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
                       TrackListModel.Column.ITEM, item,
                       TrackListModel.Column.YEAR, yearString,
                       TrackListModel.Column.GENRE, genre
                       );
        path = this.tracklistmodel.get_path(new_iter);
    }

    private void handle_dropped_stream_uri(ref string fileuri, ref TreePath? path, ref bool is_first) {
        File file;
        file = File.new_for_uri(fileuri);
        TreeIter iter, new_iter;
        string title = EMPTYSTRING;
        Item? item = Item(ItemType.STREAM, file.get_uri());
        title          = prepare_name_from_filename(file.get_basename());
        TreeIter first_iter;
        if(path == null || !this.tracklistmodel.get_iter_first(out first_iter)) {
            tracklistmodel.append(out new_iter);
            drop_pos = Gtk.TreeViewDropPosition.AFTER;
        }
        else {
            this.tracklistmodel.get_iter(out iter, path);
            
            if(is_first) {
                if((drop_pos == Gtk.TreeViewDropPosition.BEFORE)||
                   (drop_pos == Gtk.TreeViewDropPosition.INTO_OR_BEFORE)) {
                       //Determine drop position for first, insert all others after first
                    this.tracklistmodel.insert_before(out new_iter, iter);
                }
                else {
                    this.tracklistmodel.insert_after(out new_iter, iter);
                }
                is_first = false;
            }
            else {
                this.tracklistmodel.insert_after(out new_iter, iter);
            }
        }
        
        tracklistmodel.set(new_iter,
                       TrackListModel.Column.TITLE, title,
                       TrackListModel.Column.WEIGHT, Pango.Weight.NORMAL,
                       TrackListModel.Column.ITEM, item
                       );
        path = this.tracklistmodel.get_path(new_iter);
    }
    
    private void handle_dropped_file(ref string fileuri, ref TreePath? path, ref bool is_first) {
        //print ("1. xnoise-tracklist.vala => Ingresando a handle_dropped_file\n");
        //Function to import music FILES in drag'n'drop
        File file;
        FileType filetype;
        string mime;
        
        string attr = FileAttribute.STANDARD_TYPE + "," +
                      FileAttribute.STANDARD_CONTENT_TYPE;
        try {
            file = File.new_for_uri(fileuri);
            FileInfo info = file.query_info(
                                attr,
                                FileQueryInfoFlags.NONE,
                                null);
            filetype = info.get_file_type();
            string content = info.get_content_type();
            mime = GLib.ContentType.get_mime_type(content);
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
            return;
        }
        print("mime: %s\n", mime);
        bool is_playlist = Playlist.is_playlist_extension(get_suffix_from_filename(file.get_uri()));
        if(filetype == GLib.FileType.REGULAR &&
           (pattern_audio.match_string(mime)||
            pattern_video.match_string(mime)||
            supported_types.lookup(mime) == 1 ||
            is_playlist)) {
            if(is_playlist) {
                Reader reader = new Reader();
                Result result = Result.UNHANDLED;
                try {
                    result = reader.read(fileuri);
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    result = Result.UNHANDLED;
                }
                if(result != Result.UNHANDLED) {
                    EntryCollection results = reader.data_collection;
                    if(results != null) {
                        int size = results.get_size();
                        for(int i = 0; i < size; i++) {
                            Playlist.Entry entry = results[i];
                            string current_uri = entry.get_uri();
                            //print("add_dropped_uri con o sin tags %s\n",current_uri);
                            this.add_dropped_uri(ref current_uri, ref path, ref is_first,true);
                        }
                    }
                }
            }
            else {
                this.add_dropped_uri(ref fileuri, ref path, ref is_first);
            }
        }
        else if(filetype==GLib.FileType.DIRECTORY) {
            assert_not_reached();
        }
        else {
            print("Not a regular file or at least no media file: %s\n", fileuri);
        }
    }

    private void get_last_unselected_path(ref TreePath? path) {
        int rowcount = -1;
        rowcount = (int)this.tracklistmodel.iter_n_children(null);
        if(rowcount>0) {
            //get path of last unselected
            bool found = false;
            List<unowned TreePath> selected_paths;
            unowned Gtk.TreeSelection sel = this.get_selection();
            selected_paths = sel.get_selected_rows(null);
            int i=0;
            do {
                path = new TreePath.from_string("%d".printf(rowcount - 1 - i));
                foreach(unowned TreePath treepath in selected_paths) {
                    if(treepath.compare(path)!=0) {
                        found = true;
                        break;
                    }
                }
                if(found) break;
                i++;
            }
            while(i<(rowcount-1));
        }
        else {
            print("no path\n");
            path = null;
            return;
        }
    }

    private void on_row_activated(Gtk.Widget sender, TreePath path, TreeViewColumn column) {
        Item? item = Item(ItemType.UNKNOWN);
        TreeIter iter;
        if(tracklistmodel.get_iter(out iter, path)) {
            tracklistmodel.get(iter, TrackListModel.Column.ITEM, out item);
            this.on_activated(item, path);
            //print("tracklist itemtype %s\n", item.type.to_string());
        }
    }

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey ek) {
        switch(ek.keyval) {
            case Gdk.Key.Delete: {
                this.remove_selected_rows();
                return true;
            }
            case Gdk.Key.Menu: {
                rightclick_menu_popup(ek.time);
                return true;
            }
            default:
                break;
        }
        return false;
    }

    internal void scroll_to_iter(ref TreeIter iter) {
        TreePath start_path, end_path;
        TreePath current_path = tracklistmodel.get_path(iter);
        
        if(!this.get_visible_range(out start_path, out end_path))
            return;
        
        unowned int[] start   = start_path.get_indices();
        unowned int[] end     = end_path.get_indices();
        unowned int[] current = current_path.get_indices();
        
        if(!((start[0] < current[0])&&
            (current[0] < end[0]))) {
            this.scroll_to_cell(current_path, null, true, (float)0.3, (float)0.0);
        }
    }

    internal void set_focus_on_iter(ref TreeIter iter) {
        TreePath start_path, end_path;
        TreePath current_path = tracklistmodel.get_path(iter);
        
        if(!this.get_visible_range(out start_path, out end_path))
            return;
        
        unowned int[] start   = start_path.get_indices();
        unowned int[] end     = end_path.get_indices();
        unowned int[] current = current_path.get_indices();
        
        if(!((start[0] < current[0])&&
            (current[0] < end[0]))) {
            this.scroll_to_cell(current_path, null, true, (float)0.3, (float)0.0);
        }
        this.get_selection().unselect_all();
        this.get_selection().select_path(current_path);
    }

    public void remove_uri_rows(string uri) {
        bool removed_playing_title = false;
        TreePath path_2 = new TreePath();
        List<TreePath> pths = new List<TreePath>();
        tracklistmodel.foreach( (m,pa,i) => {
            Item? item = null;
            this.tracklistmodel.get(i, TrackListModel.Column.ITEM, out item);
            if(item.uri == uri)
                pths.prepend(pa);
            return false;
        });
        foreach(TreePath p in pths) {
            TreeIter it;
            tracklistmodel.get_iter(out it, p);
            path_2 = p;
            if((global.position_reference != null) &&
               (!removed_playing_title) &&
               (p.compare(global.position_reference.get_path()) == 0)) {
                removed_playing_title = true;
                global.position_reference = null;
            }
            this.tracklistmodel.remove(it);
        }
        TreeIter iter;
        if(path_2.prev() && removed_playing_title) {
            tracklistmodel.get_iter(out iter, path_2);
            global.position_reference_next = new TreeRowReference(tracklistmodel, path_2);
            return;
        }
        if(removed_playing_title)
            tracklistmodel.set_reference_to_last();
    }
    
    public void remove_selected_rows() {
        bool removed_playing_title = false;
        TreeIter iter;
        TreePath path_2 = new TreePath();
        GLib.List<TreePath> list;
        list = this.get_selection().get_selected_rows(null);
        if(list.length() == 0) return;
        list.reverse();
        foreach(unowned Gtk.TreePath path in list) {
            tracklistmodel.get_iter(out iter, path);
            path_2 = path;
            if((global.position_reference!=null)&&
               (!removed_playing_title)&&
               (path.compare(global.position_reference.get_path()) == 0)) {
                removed_playing_title = true;
                global.position_reference = null;
                //global.reset_position_reference(); // set to null without *_changed signal
            }
            tracklistmodel.remove(iter);
        }
        if(path_2.prev() && removed_playing_title) {
            tracklistmodel.get_iter(out iter, path_2);
            global.position_reference_next = new TreeRowReference(tracklistmodel, path_2);
            return;
        }
        if(removed_playing_title)
            tracklistmodel.set_reference_to_last();
    }

    private void on_activated(Item item, TreePath path) {//(string uri, TreePath path) {
        if(path != null) {
            global.position_reference = new TreeRowReference(this.tracklistmodel, path);
        }
        else {
            print("cannot setup treerowref\n");
            return;
        }
        global.in_preview = false;
        if(item.type != ItemType.UNKNOWN) {
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.PLAY_NOW);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(item.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);

            if(action != null)
                action.action(item, null, null);
        }
        
        TreeIter iter;
        this.tracklistmodel.get_iter(out iter, path);
        this.set_focus_on_iter(ref iter);
    }

    private void setup_view() {
        CellRendererText renderer;
        HashTable<int, TreeViewColumn?> cols_postions = new HashTable<int, TreeViewColumn?>(direct_hash, direct_equal);
        int position = -1;
        
        // STATUS ICON
        var pixbufRenderer = new PlayerStatePixbuf();
        columnPixb         = new TrackListColumn();
        pixbufRenderer.set_fixed_size(-1,22);
        columnPixb.pack_start(pixbufRenderer, false);
        columnPixb.add_attribute(pixbufRenderer, "state", TrackListModel.Column.ICON);
        columnPixb.set_fixed_width(30);
        columnPixb.min_width = 30;
        columnPixb.reorderable = false;
        ((TrackListColumn)columnPixb).name = "status-icon";
        
        position = Params.get_int_value("position_" + ((TrackListColumn)columnPixb).name + "_column");
        cols_postions.insert(position, columnPixb);

        // TRACKNUMBER
        renderer = new CellRendererText();
        columnTracknumber = new TextColumn("#", renderer, TrackListModel.Column.TRACKNUMBER);
        columnTracknumber.add_attribute(renderer,
                                        "text", TrackListModel.Column.TRACKNUMBER);
        columnTracknumber.add_attribute(renderer,
                                        "weight", TrackListModel.Column.WEIGHT);
        columnTracknumber.min_width = 32;
        columnTracknumber.resizable = false;
        columnTracknumber.reorderable = true;
        columnTracknumber.name = "tracknumber";
        columnTracknumber.visible = (Params.get_int_value(USE_TR_NO_COL) == 1);
        
        position = Params.get_int_value("position_" + ((TrackListColumn)columnTracknumber).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnTracknumber);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnTracknumber);
        }

        // DISK_NUMBER
        renderer = new CellRendererText();
        columnDisknumber = new TextColumn(_("Disk"), renderer, TrackListModel.Column.DISK_NUMBER);
        columnDisknumber.add_attribute(renderer,
                                        "text", TrackListModel.Column.DISK_NUMBER);
        columnDisknumber.add_attribute(renderer,
                                        "weight", TrackListModel.Column.WEIGHT);
        columnDisknumber.min_width = 38;
        columnDisknumber.resizable = true;
        columnDisknumber.reorderable = true;
        columnDisknumber.name = "disknumber";
        columnDisknumber.visible = (Params.get_int_value(USE_DISK_NO_COL) == 1);
        
        position = Params.get_int_value("position_" + ((TrackListColumn)columnDisknumber).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnDisknumber);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnDisknumber);
        }



        // TITLE
        renderer = new CellRendererText();
        renderer.ellipsize = Pango.EllipsizeMode.END;
        renderer.ellipsize_set = true;
        columnTitle = new TextColumn(_("Title"), renderer, TrackListModel.Column.TITLE);
        columnTitle.add_attribute(renderer,
                                  "text", TrackListModel.Column.TITLE);
        columnTitle.add_attribute(renderer,
                                  "weight", TrackListModel.Column.WEIGHT);
        columnTitle.min_width = 80;
        columnTitle.resizable = true;
        columnTitle.reorderable = true;
        columnTitle.expand = true;
        columnTitle.name = "title";
        variable_col_count++;
        position = Params.get_int_value("position_" + ((TrackListColumn)columnTitle).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnTitle);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnTitle);
        }


        // ALBUM
        renderer = new CellRendererText();
        renderer.ellipsize = Pango.EllipsizeMode.END;
        renderer.ellipsize_set = true;
        columnAlbum = new TextColumn(_("Album"), renderer, TrackListModel.Column.ALBUM);
        columnAlbum.add_attribute(renderer,
                                  "text", TrackListModel.Column.ALBUM);
        columnAlbum.add_attribute(renderer,
                                  "weight", TrackListModel.Column.WEIGHT);
        columnAlbum.min_width = 80;
        columnAlbum.resizable = true;
        columnAlbum.reorderable = true;
        columnAlbum.expand = true;
        columnAlbum.name = "album";
        variable_col_count++;
        columnAlbum.visible = (Params.get_int_value(USE_ALBUM_COL) == 1);
        position = Params.get_int_value("position_" + ((TrackListColumn)columnAlbum).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnAlbum);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnAlbum);
        }
        
        // ARTIST
        renderer = new CellRendererText();
        renderer.ellipsize = Pango.EllipsizeMode.END;
        renderer.ellipsize_set = true;
        columnArtist = new TextColumn(_("Artist"), renderer, TrackListModel.Column.ARTIST);
        columnArtist.add_attribute(renderer,
                                   "text", TrackListModel.Column.ARTIST);
        columnArtist.add_attribute(renderer,
                                   "weight", TrackListModel.Column.WEIGHT);
        columnArtist.min_width = 80;
        columnArtist.resizable = true; // This is the case for the current column order
        columnArtist.reorderable = true;
        columnArtist.expand = true;
        columnArtist.name = "artist";
        variable_col_count++;
        columnArtist.visible = (Params.get_int_value(USE_ARTIST_COL) == 1);
        position = Params.get_int_value("position_" + ((TrackListColumn)columnArtist).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnArtist);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnArtist);
        }

        // LENGTH
        renderer = new CellRendererText();
        columnLength = new TextColumn(_("Length"), renderer, TrackListModel.Column.LENGTH);
        columnLength.add_attribute(renderer,
                                   "text", TrackListModel.Column.LENGTH);
        columnLength.add_attribute(renderer,
                                   "weight", TrackListModel.Column.WEIGHT);

        columnLength.min_width = 75;
        columnLength.max_width = 75;
        columnLength.resizable = false;
        columnLength.reorderable = true;
        columnLength.name = "length";
        columnLength.visible = (Params.get_int_value(USE_LEN_COL) == 1);
        position = Params.get_int_value("position_" + ((TrackListColumn)columnLength).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnLength);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnLength);
        }

        // Genre
        renderer = new CellRendererText();
        renderer.ellipsize = Pango.EllipsizeMode.END;
        renderer.ellipsize_set = true;
        columnGenre = new TextColumn(_("Genre"), renderer, TrackListModel.Column.GENRE);
        columnGenre.add_attribute(renderer,
                                  "text", TrackListModel.Column.GENRE);
        columnGenre.add_attribute(renderer,
                                  "weight", TrackListModel.Column.WEIGHT);
        columnGenre.min_width = 80;
        columnGenre.resizable = true;
        columnGenre.reorderable = true;
        columnGenre.expand = true;
        columnGenre.name = "genre";
        variable_col_count++;
        columnGenre.visible = (Params.get_int_value(USE_GENRE_COL) == 1);
        position = Params.get_int_value("position_" + ((TrackListColumn)columnGenre).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnGenre);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnGenre);
        }

        // year
        renderer = new CellRendererText();
        renderer.ellipsize = Pango.EllipsizeMode.END;
        renderer.ellipsize_set = true;
        columnYear = new TextColumn(_("Year"), renderer, TrackListModel.Column.YEAR);
        columnYear.add_attribute(renderer,
                                  "text", TrackListModel.Column.YEAR);
        columnYear.add_attribute(renderer,
                                  "weight", TrackListModel.Column.WEIGHT);
        columnYear.min_width = 80;
        columnYear.max_width = 80;
        columnYear.resizable = false;
        columnYear.reorderable = true;
        columnYear.name = "year";
        variable_col_count++;
        columnYear.visible = (Params.get_int_value(USE_YEAR_COL) == 1);
        position = Params.get_int_value("position_" + ((TrackListColumn)columnYear).name + "_column");
        if(cols_postions.lookup(position) == null)
            cols_postions.insert(position, columnYear);
        else {
            int r = (int)Random.next_int();
            cols_postions.insert(r, columnYear);
        }
        List<int> col_pos_list = cols_postions.get_keys().copy();
        col_pos_list.sort(int_cmp_func);
        foreach(int cp in col_pos_list) {
            TreeViewColumn c = cols_postions.lookup(cp);
            this.insert_column(c, -1);
        }
        this.set_enable_search(false);
        this.rules_hint = false;
    }
    
    private static int int_cmp_func(int a, int b) {
        if(a < b)
            return -1;
        if(a > b)
            return 1;
        return 0;
    }
    
    private bool on_press_header(Gtk.Widget sender, Gdk.EventButton e) {
        if(e.button != 3)
            return false;
        menu = create_header_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, e.time);
        return true;
    }

    private Gtk.Menu create_header_rightclick_menu() {
        var rightmenu = new Gtk.Menu();
        CheckMenuItem menu_item;
        
        // TRACKNUMBER
        menu_item = new CheckMenuItem.with_label(_("Track number"));
        menu_item.set_active((Params.get_int_value(USE_TR_NO_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_TR_NO_COL, (s.get_active() == true ? 1 : 0));
            this.column_tracknumber_visible = s.get_active();
        });
        rightmenu.append(menu_item);
        
        // DISK_NUMBER
        menu_item = new CheckMenuItem.with_label(_("Disk number"));
        menu_item.set_active((Params.get_int_value(USE_DISK_NO_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_DISK_NO_COL, (s.get_active() == true ? 1 : 0));
            this.column_disknumber_visible = s.get_active();
        });
        rightmenu.append(menu_item);
        
        // ARTIST
        menu_item = new CheckMenuItem.with_label(_("Artist"));
        menu_item.set_active((Params.get_int_value(USE_ARTIST_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_ARTIST_COL, (s.get_active() == true ? 1 : 0));
            this.column_artist_visible = s.get_active();
        });
        rightmenu.append(menu_item);

        // ALBUM
        menu_item = new CheckMenuItem.with_label(_("Album"));
        menu_item.set_active((Params.get_int_value(USE_ALBUM_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_ALBUM_COL, (s.get_active() == true ? 1 : 0));
            this.column_album_visible = s.get_active();
        });
        rightmenu.append(menu_item);
        
        // GENRE
        menu_item = new CheckMenuItem.with_label(_("Genre"));
        menu_item.set_active((Params.get_int_value(USE_GENRE_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_GENRE_COL, (s.get_active() == true ? 1 : 0));
            this.column_genre_visible = s.get_active();
        });
        rightmenu.append(menu_item);
        
        // YEAR
        menu_item = new CheckMenuItem.with_label(_("Year"));
        menu_item.set_active((Params.get_int_value(USE_YEAR_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_YEAR_COL, (s.get_active() == true ? 1 : 0));
            this.column_year_visible = s.get_active();
        });
        rightmenu.append(menu_item);
        
        // LENGTH 
        menu_item = new CheckMenuItem.with_label(_("Length"));
        menu_item.set_active((Params.get_int_value(USE_LEN_COL) == 1 ? true : false));
        menu_item.toggled.connect( (s) => {
            Params.set_int_value(USE_LEN_COL, (s.get_active() == true ? 1 : 0));
            this.column_length_visible = s.get_active();
        });
        rightmenu.append(menu_item);

        rightmenu.show_all();
        return rightmenu;
    }
    
    public void write_params_data() {
        var columns = this.get_columns();
        int counter = 0;
        foreach(TreeViewColumn c in columns) {
            if(c == null) continue;
            
            // write column position, counting from 1 onwards
            string col_name = ((TrackListColumn)c).name;
            //print("col_name:%s : %d\n", col_name, counter);
            Params.set_int_value("position_" + col_name + "_column", counter);
            counter++;
        }
    }
    
    public void read_params_data() {
    }
}


private class PlayerStatePixbuf : Gtk.CellRendererPixbuf {
    private const int ICONSIZE = 16;
    private const int X_OFFSET = 2;
    
    public PlayerState state { get; set; default = PlayerState.STOPPED; }
    
    public override void render(Cairo.Context cr, Widget widget,
                                Gdk.Rectangle background_area,
                                Gdk.Rectangle cell_area,
                                CellRendererState flags) {
        Gdk.Pixbuf p = null;
        switch(state) {
            case PlayerState.PAUSED:
                p = IconRepo.get_themed_pixbuf_icon("media-playback-pause-symbolic", 
                                                    ICONSIZE, widget.get_style_context());
                break;
            case PlayerState.PLAYING:
                p = IconRepo.get_themed_pixbuf_icon("media-playback-start-symbolic", 
                                                    ICONSIZE, widget.get_style_context());
                break;
            case PlayerState.STOPPED:
            default:
                p = null;
                break;
        }
        if(p != null) {
            int pixheight = p.get_height();
            if(cell_area.height > pixheight)
                Gdk.cairo_set_source_pixbuf(cr, 
                                            p, 
                                            cell_area.x + X_OFFSET, 
                                            cell_area.y + (cell_area.height -pixheight)/2
                );
            else
                Gdk.cairo_set_source_pixbuf(cr,
                                            p, 
                                            cell_area.x + X_OFFSET, 
                                            cell_area.y
                );
            cr.paint();
        }
    }
}
