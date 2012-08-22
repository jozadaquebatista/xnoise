/* magnatune.vala
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
using Xnoise.PluginModule;


private static const string MAGNATUNE_MUSIC_STORE_NAME = "MagnatuneMusicStore";

public class MagnatunePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private unowned PluginModule.Container _owner;
    private MagMusicStore music_store;

    public PluginModule.Container owner {
        get { return _owner;  }
        set { _owner = value; }
    }
    
    public string name { get { return "magnatune_music_store"; } }
    
    public bool init() {
        this.music_store = new MagMusicStore();//this);
        owner.sign_deactivated.connect(clean_up);
        return true;
    }
    
    public void uninit() {
        clean_up();
    }

    private void clean_up() {
        owner.sign_deactivated.disconnect(clean_up);
        music_store = null;
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }
}



private class MagnatuneTreeStore : Gtk.TreeStore {
    private Gdk.Pixbuf artist_icon;
    private Gdk.Pixbuf album_icon;
    private Gdk.Pixbuf title_icon;
    private Gdk.Pixbuf loading_icon;
    private static const string LOADING = _("Loading ...");
    private unowned DockableMedia dock;
    private unowned MagnatuneTreeView view;
    private uint search_idlesource = 0;
    public MagnatuneDatabaseReader dbreader;

    private GLib.Type[] col_types = new GLib.Type[] {
        typeof(Gdk.Pixbuf),  //ICON
        typeof(string),      //VIS_TEXT
        typeof(Xnoise.Item?),//ITEM
        typeof(int)          //LEVEL
    };

    public enum Column {
        ICON = 0,
        VIS_TEXT,
        ITEM,
        LEVEL,
        N_COLUMNS
    }
    
    private int data_source_id = -1;
    
    public MagnatuneTreeStore(DockableMedia dock, MagnatuneTreeView view) {
        this.dock = dock;
        this.view = view;
        set_column_types(col_types);
        create_icons();
        
        if(dbreader == null)
            dbreader = new MagnatuneDatabaseReader();
        if(dbreader == null)
            assert_not_reached();
        
        data_source_id = register_data_source(dbreader);
        
        global.sign_searchtext_changed.connect( (s,t) => {
            if(this.dock.name() != global.active_dockable_media_name) {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add_seconds(1, () => { //late search, if widget is not visible
                    //print("timeout search started\n");
                    filter();
                    search_idlesource = 0;
                    return false;
                });
            }
            else {
                if(search_idlesource != 0)
                    Source.remove(search_idlesource);
                search_idlesource = Timeout.add(180, () => {
                    this.filter();
                    search_idlesource = 0;
                    return false;
                });
            }
        });
    }
    
    ~MagnatuneTreeStore() {
        print("remove mag data source\n");
        remove_data_source_by_id(data_source_id);
    }
    
    private void create_icons() {
        try {
            unowned IconTheme theme = IconTheme.get_default();
            Gtk.Invisible w = new Gtk.Invisible();
            Gdk.Pixbuf icon  = w.render_icon_pixbuf(Gtk.Stock.FILE, IconSize.BUTTON);
            int iconheight = icon.height;
            if(theme.has_icon("system-users")) 
                artist_icon = theme.load_icon("system-users", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("stock_person")) 
                artist_icon = theme.load_icon("stock_person", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                artist_icon = w.render_icon_pixbuf(Gtk.Stock.ORIENTATION_PORTRAIT, IconSize.BUTTON);
            
            album_icon = w.render_icon_pixbuf(Gtk.Stock.CDROM, IconSize.BUTTON);
            
            if(theme.has_icon("media-audio")) 
                title_icon = theme.load_icon("media-audio", iconheight, IconLookupFlags.FORCE_SIZE);
            else if(theme.has_icon("audio-x-generic")) 
                title_icon = theme.load_icon("audio-x-generic", iconheight, IconLookupFlags.FORCE_SIZE);
            else 
                title_icon = w.render_icon_pixbuf(Gtk.Stock.OPEN, IconSize.BUTTON);
                
            loading_icon = w.render_icon_pixbuf(Gtk.Stock.REFRESH , IconSize.BUTTON);
        }
        catch(GLib.Error e) {
            print("Error: %s\n",e.message);
        }
    }
    
    public void filter() {
        //print("filter\n");
        view.set_model(null);
        this.clear();
        this.populate_model();
    }
    
    public void unload_children(ref TreeIter iter) {
        TreeIter iter_loader;
        TreePath pa = this.get_path(iter);
        if(pa.get_depth() != 1)
            return;
        Item? loader_item = Item(ItemType.LOADER);
        this.append(out iter_loader, iter);
        this.set(iter_loader,
                      Column.ICON, loading_icon,
                      Column.VIS_TEXT, LOADING,
                      Column.ITEM, loader_item,
                      Column.LEVEL, 0
        );
        TreeIter child;
        for(int i = (this.iter_n_children(iter) -2); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.remove(child);
        }
    }
    
    private void remove_loader_child(ref TreeIter iter) {
        TreeIter child;
        Item? item;
        for(int i = (this.iter_n_children(iter) - 1); i >= 0 ; i--) {
            this.iter_nth_child(out child, iter, i);
            this.get(child, Column.ITEM, out item);
            if(item.type == ItemType.LOADER) {
                this.remove(child);
                return;
            }
        }
    }
    
    private bool row_is_resolved(ref TreeIter iter) {
        if(this.iter_n_children(iter) != 1)
            return true;
        TreeIter child;
        Item? item = Item(ItemType.UNKNOWN);
        this.iter_nth_child(out child, iter, 0);
        this.get(child, Column.ITEM, out item);
        return (item.type != ItemType.LOADER);
    }

    public void load_children(ref TreeIter iter) {
        if(!row_is_resolved(ref iter))
            load_content(ref iter);
    }
    
    private void load_content(ref TreeIter iter) {
        //print("load_content\n");
        Worker.Job job;
        Item? item = Item(ItemType.UNKNOWN);
        this.get(iter, Column.ITEM, out item);
        TreePath path = this.get_path(iter);
        if(path == null)
            return;
        TreeRowReference treerowref = new TreeRowReference(this, path);
        if(path.get_depth() == 1) {
            job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.load_album_and_tracks_job);
            job.set_arg("treerowref", treerowref);
            job.set_arg("artist_id", item.db_id);
            db_worker.push_job(job);
        }
    }

    private bool load_album_and_tracks_job(Worker.Job job) {
        job.items = dbreader.get_albums_with_search(global.searchtext, (int32)job.get_arg("artist_id")); 
        //print("job.items cnt = %d\n", job.items.length);
        Idle.add( () => {
            TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
            if(row_ref == null || !row_ref.valid())
                return false;
            TreePath p = row_ref.get_path();
            TreeIter iter_artist, iter_album;
            this.get_iter(out iter_artist, p);
            Item? artist;
            string artist_name;
            this.get(iter_artist, Column.ITEM, out artist, Column.VIS_TEXT, out artist_name);
            foreach(Item? album in job.items) {     //ALBUMS
                this.append(out iter_album, iter_artist);
                this.set(iter_album,
                              Column.ICON, album_icon,
                              Column.VIS_TEXT, album.text,
                              Column.ITEM, album,
                              Column.LEVEL, 1
                );
                Gtk.TreePath p1 = this.get_path(iter_album);
                TreeRowReference treerowref = new TreeRowReference(this, p1);
                var job_title = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_title_job);
                job_title.set_arg("treerowref", treerowref);
//                job_title.set_arg("artist", (int32)job.get_arg("artist_id"));
                job_title.set_arg("albumid",  album.db_id);
                db_worker.push_job(job_title);
            }
            remove_loader_child(ref iter_artist);
            return false;
        });
        return false;
    }

    private bool populate_title_job(Worker.Job job) {
        job.track_dat = dbreader.get_trackdata_by_albumid(global.searchtext, (int32)job.get_arg("albumid"));
        Idle.add( () => {
            TreeRowReference row_ref = (TreeRowReference)job.get_arg("treerowref");
            if((row_ref == null) || (!row_ref.valid()))
                return false;
            TreePath p = row_ref.get_path();
            TreeIter iter_title, iter_album;
            this.get_iter(out iter_album, p);
            foreach(TrackData td in job.track_dat) {
                this.prepend(out iter_title, iter_album);
                this.set(iter_title,
                              Column.ICON, title_icon,
                              Column.VIS_TEXT, td.title,
                              Column.ITEM, (Item?)td.item,
                              Column.LEVEL, 2
                         );
            }
            return false;
        });
        return false;
    }
    
    private bool populate_model() {
        view.model = null;
        this.clear();
        var a_job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.populate_artists_job);
        db_worker.push_job(a_job);
        return false;
    }
    
    private bool populate_artists_job(Worker.Job job) {
        job.items = dbreader.get_artists_with_search(global.searchtext);
        //print("job.items.length : %d\n", job.items.length);
        Idle.add(() => {
            if(this == null)
                return false;
            TreeIter iter, iter_loader;
            foreach(Item? i in job.items) {
                this.prepend(out iter, null);
                this.set(iter,
                              Column.ICON, artist_icon,
                              Column.VIS_TEXT, i.text,
                              Column.ITEM, i,
                              Column.LEVEL, 0
                );
                Item? loader_item = Item(ItemType.LOADER);
                this.append(out iter_loader, iter);
                this.set(iter_loader,
                              Column.ICON, loading_icon,
                              Column.VIS_TEXT, LOADING,
                              Column.ITEM, loader_item,
                              Column.LEVEL, 1
                );
            }
            view.set_model(this);
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
            int id = -1;
            id = dbreader.get_source_id();
            DndData dnd_data = { item.db_id, item.type, id };
            dnd_data_array += dnd_data;
        }
        return dnd_data_array;
    }
}

private class MagnatuneTreeView : Gtk.TreeView {
    public MagnatuneTreeStore mag_model = null;
    private unowned DockableMedia dock;
    private unowned MagnatuneWidget widg;
    //parent container of this widget (most likely scrolled window)
    private unowned Widget ow;
    private bool dragging;

    private const TargetEntry[] src_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
    };
    
    public MagnatuneTreeView(DockableMedia dock, MagnatuneWidget widg, Widget ow) {
        this.dock = dock;
        this.widg = widg;
        this.ow = ow;
        mag_model = create_model();
        setup_view();
        Idle.add(this.populate_model);
        this.get_selection().set_mode(SelectionMode.MULTIPLE);

        Gtk.drag_source_set(this,
                            Gdk.ModifierType.BUTTON1_MASK,
                            this.src_target_entries,
                            Gdk.DragAction.COPY
                            );
        
        this.dragging = false;
        
        //Signals
        this.row_activated.connect(this.on_row_activated);
        this.drag_begin.connect(this.on_drag_begin);
        this.drag_data_get.connect(this.on_drag_data_get);
        this.drag_end.connect(this.on_drag_end);
        this.button_release_event.connect(this.on_button_release);
        this.button_press_event.connect(this.on_button_press);

    //        this.key_press_event.connect(this.on_key_pressed);
    //        this.key_release_event.connect(this.on_key_released);
    }
    
    private bool on_button_press(Gdk.EventButton e) {
        Gtk.TreePath treepath = null;
        Gtk.TreeViewColumn column;
        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        
        if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y))
            return true;
        
        switch(e.button) {
            case 1: {
                if(selection.count_selected_rows()<= 1) {
                    return false;
                }
                else {
                    if(selection.path_is_selected(treepath)) {
                        if(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
                           ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK)) {
                            selection.unselect_path(treepath);
                        }
                        return true;
                    }
                    else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK))) {
                        return true;
                    }
                    return false;
                }
            }
            case 3: {
                TreeIter iter;
                this.mag_model.get_iter(out iter, treepath);
                if(!selection.path_is_selected(treepath)) {
                    selection.unselect_all();
                    selection.select_path(treepath);
                }
//                rightclick_menu_popup(e.time);
                return true;
            }
            default: {
                break;
            }
        }
        if(!(selection.count_selected_rows()>0 ))
            selection.select_path(treepath);
        return false;
    }
    
    private bool on_button_release(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath treepath;
        Gtk.TreeViewColumn column;
        int cell_x, cell_y;

        if((e.button != 1)|(this.dragging)) {
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
        if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y)) return false;
        selection.unselect_all();
        selection.select_path(treepath);

        return false;
    }

    private void on_drag_begin(Gtk.Widget sender, DragContext context) {
        this.dragging = true;
        List<unowned TreePath> treepaths;
        Gdk.drag_abort(context, Gtk.get_current_event_time());
        Gtk.TreeSelection selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        if(treepaths != null) {
            TreeIter iter;
            Pixbuf p;
            this.mag_model.get_iter(out iter, treepaths.nth_data(0));
            this.mag_model.get(iter, MusicBrowserModel.Column.ICON, out p);
            Gtk.drag_source_set_icon_pixbuf(this, p);
        }
        else {
            if(selection.count_selected_rows() > 1) {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
            }
            else {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
            }
        }
    }

    private void on_drag_data_get(Gtk.Widget sender, 
                                  Gdk.DragContext context, 
                                  Gtk.SelectionData selection_data, 
                                  uint info, 
                                  uint etime) {
        List<unowned TreePath> treepaths;
        unowned Gtk.TreeSelection selection;
        selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        DndData[] dat = {};
        if(treepaths.length() < 1)
            return;
        foreach(TreePath treepath in treepaths) { 
            DndData[] ddat = mag_model.get_dnd_data_for_path(ref treepath); 
            foreach(DndData u in ddat) {
                dat += u;
            }
        }
        Gdk.Atom dnd_atom = Gdk.Atom.intern(src_target_entries[0].target, true);
        unowned uchar[] data = (uchar[])dat;
        data.length = (int)(dat.length * sizeof(DndData));
        selection_data.set(dnd_atom, 8, data);
    }

    private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
        this.dragging = false;
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            this.mag_model.get_iter(out iter, treepath);
            this.mag_model.get(iter, MagnatuneTreeStore.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Xnoise.Action? action = tmp.get_action(item.type, ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED, ItemSelectionType.SINGLE);
            
            if(action != null)
                action.action(item, null);
            else
                print("action was null\n");
        }
        else {
            this.expand_row(treepath, false);
        }
    }

    private MagnatuneTreeStore create_model() {
        return new MagnatuneTreeStore(this.dock, this);
    }

    private bool in_update_view = false;
    /* updates the view, leaves the original model untouched.
       expanded rows are kept as well as the scrollbar position */
    public bool update_view() {
        double scroll_position = this.widg.sw.vadjustment.value;
        in_update_view = true;
        this.set_model(null);
        this.set_model(mag_model);
        Idle.add( () => {
            in_update_view = false;
            return false;
        });
        this.widg.sw.vadjustment.set_value(scroll_position);
        this.widg.sw.vadjustment.value_changed();
        return false;
    }

    private class FlowingTextRenderer : CellRendererText {
        private int maxiconwidth;
        private unowned Widget ow;
        private unowned Pango.FontDescription font_description;
        private unowned TreeViewColumn col;
        private int expander;
        private int hsepar;
        private int calculated_widh[3];
        
        public int level    { get; set; }
        public unowned Gdk.Pixbuf pix { get; set; }
        
        public FlowingTextRenderer(Widget ow, Pango.FontDescription font_description, TreeViewColumn col, int expander, int hsepar) {
            GLib.Object();
            this.ow = ow;
            this.col = col;
            this.expander = expander;
            this.hsepar = hsepar;
            this.font_description = font_description;
            maxiconwidth = 0;
            calculated_widh[0] = 0;
            calculated_widh[1] = 0;
            calculated_widh[2] = 0;
        }
        
        public override void get_preferred_height_for_width(Gtk.Widget widget,
                                                            int width,
                                                            out int minimum_height,
                                                            out int natural_height) {
            Gdk.Window? w = ow.get_window();
            if(w == null) {
                //print("no window (magnatune)\n");
                natural_height = minimum_height = 30;
                return;
            }
            int column_width = col.get_width();
            int sum = 0;
            int iconwidth = (pix == null) ? 16 : pix.get_width();
            if(maxiconwidth < iconwidth)
                maxiconwidth = iconwidth;
            calculated_widh[level] = maxiconwidth;
            sum = (level + 1) * (expander + 2 * hsepar) + (2 * (int)xpad) + maxiconwidth + 2; 
            //print("column_width - sum :%d  level: %d\n", column_width - sum, level);
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( (int)((column_width - sum) * Pango.SCALE));
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            int wi, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            natural_height = minimum_height = he;
        }
    
        public override void get_size(Widget widget, Gdk.Rectangle? cell_area,
                                      out int x_offset, out int y_offset,
                                      out int width, out int height) {
            // function not used for gtk+-3.0 !
            x_offset = 0;
            y_offset = 0;
            width = 0;
            height = 0;
        }
    
        public override void render(Cairo.Context cr, Widget widget,
                                    Gdk.Rectangle background_area,
                                    Gdk.Rectangle cell_area,
                                    CellRendererState flags) {
            StyleContext context;
            //print("cell_area.width: %d level: %d\n", cell_area.width, level);
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( (int)((calculated_widh[level] > cell_area.width ? calculated_widh[level] : cell_area.width) * Pango.SCALE));
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            context = widget.get_style_context();
            int wi = 0, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            if(cell_area.height > he)
                context.render_layout(cr, cell_area.x, cell_area.y + (cell_area.height -he)/2, pango_layout);
            else
                context.render_layout(cr, cell_area.x, cell_area.y, pango_layout);
        }
    }

    private CellRendererText renderer = null;
    private Pango.FontDescription font_description;
    private int last_width;
    
    private int _fontsize = 0;
    internal int fontsize {
        get {
            return _fontsize;
        }
        set {
            if (_fontsize == 0) { //intialization
                if((value < 7)||(value > 14)) _fontsize = 7;
                else _fontsize = value;
                Idle.add( () => {
                    font_description.set_size((int)(_fontsize * Pango.SCALE));
                    renderer.size_points = fontsize;
                    return false;
                });
            }
            else {
                if((value < 7)||(value > 14)) _fontsize = 7;
                else _fontsize = value;
                Idle.add( () => {
                    font_description.set_size((int)(_fontsize * Pango.SCALE));
                    renderer.size_points = fontsize;
                    return false;
                });
                Idle.add(update_view);
            }
        }
    }

    private void setup_view() {
        
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
        this.set_size_request(300, 500);
        
        fontsize = Params.get_int_value("fontsizeMB");
        Gtk.StyleContext context = this.get_style_context();
        font_description = context.get_font(StateFlags.NORMAL).copy();
        font_description.set_size((int)(global.fontsize_dockable * Pango.SCALE));
        
        var column = new TreeViewColumn();
        
        int expander = 0;
        this.style_get("expander-size", out expander);
        int hsepar = 0;
        this.style_get("horizontal-separator", out hsepar);
        renderer = new FlowingTextRenderer(this.ow, font_description, column, expander, hsepar);
        
        main_window.msw.selection_changed.connect( (s,n) => {
            if(n == name_buffer)
                return;
            if(n == this.dock.name())
                last_width++;
            name_buffer = n;
        });
        
        this.ow.size_allocate.connect_after( (s, a) => {
            unowned TreeViewColumn tvc = this.get_column(0);
            int current_width = this.ow.get_allocated_width();
            if(last_width == current_width)
                return;
            
            last_width = current_width;
            
            tvc.max_width = tvc.min_width = current_width - 20;
            TreeModel? xm = this.get_model();
            if(xm != null && !in_update_view)
                xm.foreach( (mo, pt, it) => {
                    if(mo == null)
                        return true;
                    mo.row_changed(pt, it);
                    return false;
                });
        });
        
        var pixbufRenderer = new CellRendererPixbuf();
        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
        
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", MagnatuneTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", MagnatuneTreeStore.Column.VIS_TEXT); // no markup!!
        column.add_attribute(renderer, "level", MagnatuneTreeStore.Column.LEVEL);
        column.add_attribute(renderer, "pix", MagnatuneTreeStore.Column.ICON);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
        
        global.notify["fontsize-dockable"].connect( () => {
            this.fontsize = global.fontsize_dockable;
        });
    }

    private string name_buffer;
    
    private void on_row_expanded(TreeIter iter, TreePath path) {
        mag_model.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        mag_model.unload_children(ref iter);
    }
    
    private bool populate_model() {
        mag_model.filter();
        return false;
    }
}



private class MagnatuneWidget : Gtk.Box {
    
    private bool database_available = false;
    private ProgressBar pb = null;
    private Label label = null;
    private unowned DockableMedia dock;
    public ScrolledWindow sw;
    public MagnatuneTreeView tv = null;

    public MagnatuneWidget(DockableMedia dock) {
        Object(orientation:Orientation.VERTICAL,spacing:0);
        this.dock = dock;
        create_widgets();
        this.show_all();
        
        load_db();
    }
    private static const string CONVERTED_DB = "/tmp/xnoise_magnatune.sqlite";
    private void load_db() {
        File dbf   = File.new_for_path(CONVERTED_DB);
        if(dbf.query_exists()) {
            database_available = true;
            Timeout.add_seconds(1, () => {
                add_tree();
                return false;
            });
            return;
        }
        var job = new Worker.Job(Worker.ExecutionType.ONCE, copy_db_job);
        io_worker.push_job(job);
    }

    private bool copy_db_job(Worker.Job job) {
        
        bool res = false;
        try {
            File mag_db = File.new_for_uri("http://he3.magnatune.com/info/sqlite_magnatune.db.gz");
            File dest   = File.new_for_path("/tmp/xnoise_magnatune_db_zipped");
            res = mag_db.copy(dest, FileCopyFlags.OVERWRITE, null, progress_cb);
        }
        catch(Error e) {
            print("%s\n", e.message);
            label.label = "Magnatune Error 3";
            return false;
        }
        if(res) {
            Idle.add(() => {
                label.label = "download finished...";
                Idle.add( () => {
                    label.label = "decompressing...";
                    var decomp_job = new Worker.Job(Worker.ExecutionType.ONCE, decompress_db_job);
                    io_worker.push_job(decomp_job);
                    return false;
                });
                return false;
            });
        }
        else {
            label.label = "Magnatune Error 4";
        }
        return false;
    }

    private bool decompress_db_job(Worker.Job job) {
        File source = File.new_for_path("/tmp/xnoise_magnatune_db_zipped");
        File dest   = File.new_for_path("/tmp/xnoise_magnatune_db");
        if(!source.query_exists())
            return false;
        FileInputStream src_stream  = null;
        FileOutputStream dst_stream = null;
        ConverterOutputStream conv_stream = null;
        try {
            if(dest.query_exists())
                dest.delete();
            src_stream = source.read();
            dst_stream = dest.replace(null, false, 0);
            if(dst_stream == null) {
                print("Could not create output stream!\n");
                return false;
            }
        }
        catch(Error e) {
            print("Error decompressing! %s\n", e.message);
            label.label = "Magnatune Error 1";
            return false;
        }
        var zlc = new ZlibDecompressor(ZlibCompressorFormat.GZIP);
        conv_stream = new ConverterOutputStream(dst_stream, zlc);
        try {
            conv_stream.splice(src_stream, 0);
        }
        catch(IOError e) {
            print("Converter Error! %s\n", e.message);
            label.label = "Magnatune Error 2";
            return false;
        }
        Idle.add(() => {
            label.label = "decompressing finished...";
            var conv_job = new Worker.Job(Worker.ExecutionType.ONCE, convert_db_job);
            io_worker.push_job(conv_job);
            return false;
        });
        return false;
    }

    private bool convert_db_job(Worker.Job job) {
        Idle.add(() => {
            label.label = "Please wait while\nconverting database.";
            return false;
        });
        var conv = new MagnatuneDatabaseConverter();
        conv.progress.connect(on_db_conversion_progress);
        conv.move_data();
        conv.progress.disconnect(on_db_conversion_progress);
        conv = null;
        File fx = File.new_for_path(CONVERTED_DB);
        if(fx.query_exists(null)) {
            Idle.add( () => {
                database_available = true;
                add_tree();
                return false;
            });
        }
        else {
            printerr("ERROR CONVERTING DATABASE!!\n");
        }
        return false;
    }
    
    private void on_db_conversion_progress(MagnatuneDatabaseConverter sender, int c) {
        Idle.add(() => {
            pb.hide();
            label.label = "Please wait while\nconverting database.\nDone for %d tracks.".printf(c);
            return false;
        });
    }
    
    private void add_tree() {
        if(!database_available)
            return;
        this.remove(pb);
        this.remove(label);
        pb = null;
        label = null;
        sw = new ScrolledWindow(null, null);
        sw.set_shadow_type(ShadowType.IN);
        tv = new MagnatuneTreeView(this.dock, this, sw);
        sw.add(tv);
        this.pack_start(sw, true, true , 0);
        this.show_all();
    }
    
    private void progress_cb(int64 current_num_bytes, int64 total_num_bytes) {
        if(total_num_bytes <= 0)
            return;
        double fraction = (double)current_num_bytes / (double)total_num_bytes;
        if(fraction > 1.0)
            fraction = 1.0;
        if(fraction < 0.0)
            fraction = 0.0;
        
        Idle.add(() => {
            pb.set_fraction(fraction);
            return false;
        });
    }
    
    private void create_widgets() {
        label = new Label("loading...");
        this.pack_start(label, true, true, 0);
        pb = new ProgressBar();
        this.pack_start(pb, false, false, 0);
    }
}




private class DockableMagnatuneMS : DockableMedia {
    
    private unowned Xnoise.MainWindow win;
    
    public override string name() {
        return MAGNATUNE_MUSIC_STORE_NAME;
    }
    
    public DockableMagnatuneMS() {
        widget = null;
    }

    ~DockableMagnatuneMS() {
        print("dtor DockableMagnatuneMS\n");
    }
    
    public override string headline() {
        return _("Magnatune");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.STORES;
    }

    public uint ui_merge_id;
    public override Gtk.Widget? create_widget(MainWindow win) {
        this.win = win;
        
        assert(this.win != null);
        var wu = new MagnatuneWidget(this);

        widget = wu;
        wu.show_all();
        return (owned)wu;
    }
    
    public override void remove_main_view() {
    }
    
    public Gtk.ActionGroup action_group;
    
    private uint add_main_window_menu_entry() {
        action_group = new Gtk.ActionGroup("MagnatuneActions");
        action_group.set_translation_domain(Config.GETTEXT_PACKAGE);
        action_group.add_actions(action_entries, this);
        uint reply = 0;
        win.ui_manager.insert_action_group(action_group, 1);
        try {
            reply = win.ui_manager.add_ui_from_string(MENU_UI_STRING, MENU_UI_STRING.length);
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
        }
        return reply;
    }
    
    private static const string MENU_UI_STRING = """
        <ui>
            <menubar name="MainMenu">
                <menu name="ViewMenu" action="ViewMenuAction">
                    <separator />
                    <menuitem action="ShowMagnatuneStore"/>
                </menu>
            </menubar>
        </ui>
    """;
    
    private const Gtk.ActionEntry[] action_entries = {
        { "ViewMenuAction", null, N_("_View") },
            { "ShowMagnatuneStore", null, N_("Show Magnatune Store"), null, N_("Show Magnatune Store"), on_show_store_menu_clicked}
    };
    
    private void on_show_store_menu_clicked() {
        assert(win != null);
        win.msw.select_dockable_by_name(MAGNATUNE_MUSIC_STORE_NAME, true);
    }
    
    public override Gdk.Pixbuf get_icon() {
        Gdk.Pixbuf? icon = null;
        try {
            unowned Gtk.IconTheme thm = Gtk.IconTheme.get_default();
            icon = thm.load_icon(Gtk.Stock.EXECUTE, 24, IconLookupFlags.FORCE_SIZE);
        }
        catch(Error e) {
            icon = null;
            print("Magnatune icon error: %s\n", e.message);
        }
        return (owned)icon;
    }
}



//The Magnatune Music Store.
private class MagMusicStore : GLib.Object {
    private DockableMagnatuneMS msd;
    
    public MagMusicStore() {
        msd = new DockableMagnatuneMS();
        main_window.msw.insert_dockable(msd);
    }
    
    ~MagMusicStore() {
        main_window.msw.select_dockable_by_name("MusicBrowserDockable");
        if(msd == null)
            return;
        if(msd.action_group != null) {
            main_window.ui_manager.remove_action_group(msd.action_group);
        }
        if(msd.ui_merge_id != 0)
            main_window.ui_manager.remove_ui(msd.ui_merge_id);
        main_window.msw.remove_dockable_in_idle(MAGNATUNE_MUSIC_STORE_NAME);
    }
}

