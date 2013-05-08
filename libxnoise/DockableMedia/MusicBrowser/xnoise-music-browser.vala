/* xnoise-music-browser.vala
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



private class Xnoise.MusicBrowser : TreeView, IParams, TreeQueryable {
    private bool dragging;
    private bool _use_treelines = false;
    private MusicBrowserCellRenderer renderer = null;
    private Gtk.Menu menu;
    
    public MusicBrowserModel mediabrowsermodel;
    
    public bool use_treelines {
        get {
            return _use_treelines;
        }
        set {
            _use_treelines = value;
            this.enable_tree_lines = value;
        }
    }
    
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
        
//    public signal void sign_activated();
    // targets used with this as a source
    private const TargetEntry[] src_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
    };

    // targets used with this as a destination
    private const TargetEntry[] dest_target_entries = {
        {"text/uri-list", TargetFlags.OTHER_APP, 0}
    };// This is not a very long list but uris are so universal
    
    //parent container of this widget (most likely scrolled window)
    private unowned Widget ow;
    private unowned DockableMedia dock;
    
    public MusicBrowser(DockableMedia dock, Widget ow) {
        this.ow = ow;
        this.dock = dock;
        Params.iparams_register(this);
        mediabrowsermodel = new MusicBrowserModel(dock);
        this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
//        icon_repo._title_pix = IconRepo.get_themed_pixbuf_icon("emblem-music-symbolic", 
//                                                              22, this.get_style_context());
//        this.get_style_context().add_class(STYLE_CLASS_PANE_SEPARATOR);
        
        setup_view();
        Idle.add(this.populate_model);
        this.get_selection().set_mode(SelectionMode.MULTIPLE);

        Gtk.drag_source_set(this,
                            Gdk.ModifierType.BUTTON1_MASK,
                            src_target_entries,
                            Gdk.DragAction.COPY
                            );

        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
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
        this.key_release_event.connect(this.on_key_released);
        this.drag_data_received.connect(this.on_drag_data_received);
        var context = this.get_style_context();
        context.save();
        Gdk.RGBA color, scolor;//, icolor;
        scolor = context.get_background_color(StateFlags.SELECTED);
//        icolor = context.get_color(StateFlags.SELECTED);
        context.add_class(STYLE_CLASS_PANE_SEPARATOR);
        color = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
        this.override_background_color(StateFlags.NORMAL, color);
        this.override_background_color(StateFlags.SELECTED, scolor);
//        this.override_color(StateFlags.SELECTED, icolor);
//        color = context.get_color(StateFlags.NORMAL);
//        this.override_color(StateFlags.NORMAL, color);
        context.restore();

//        var context = ow.get_style_context();
//        Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
//        this.override_background_color(StateFlags.NORMAL, col);
    }
    
    private void on_drag_data_received(Gtk.Widget sender, DragContext context, int x, int y,
                                       SelectionData selection, uint target_type, uint time) {
        //TODO: Open media import dialog for dropped files and folders
        print("drag receive\n");
    }

//    public override bool draw(Cairo.Context cr) {
//        Gdk.cairo_rectangle(cr, cell_area);
//        cr.save();
//        var context = ow.get_style_context();
//        Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
//        col.alpha = 1.0;
//        Gdk.cairo_set_source_rgba(cr, col);
//        cr.fill();
//        cr.restore();
//        base.draw(cr);
//        return false;
//    }
    
    // This function is intended for the usage
    // with GLib.Idle
    private bool populate_model() {
        mediabrowsermodel.filter();
        return false;
    }

    // IParams functions
    public void read_params_data() {
        if(Params.get_int_value("use_treelines") == 1)
            use_treelines = true;
        else
            use_treelines = false;
    }

    public void write_params_data() {
        if(this.use_treelines)
            Params.set_int_value("use_treelines", 1);
        else
            Params.set_int_value("use_treelines", 0);
            
//        Params.set_int_value("fontsize", fontsize);
    }
    // end IParams functions

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//        print("%d\n",(int)e.keyval);
        Gtk.TreeModel m;
        switch(e.keyval) {
            case Gdk.Key.Right: {
                Gtk.TreeSelection selection = this.get_selection();
                if(selection.count_selected_rows()<1) break;
                GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
                TreePath? treepath = selected_rows.nth_data(0);
                if(treepath.get_depth()>2) break;
                if(treepath!=null) this.expand_row(treepath, false);
                return true;
            }
            case Gdk.Key.Left: {
                Gtk.TreeSelection selection = this.get_selection();
                if(selection.count_selected_rows()<1) break;
                GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
                TreePath? treepath = selected_rows.nth_data(0);
                if(treepath.get_depth()>2) break;
                if(treepath!=null) this.collapse_row(treepath);
                return true;
            }
            case Gdk.Key.Menu: {
                rightclick_menu_popup(e.time);
                return true;
            }
            default:
                break;
        }
        return false;
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
                this.mediabrowsermodel.get_iter(out iter, treepath);
                if(!selection.path_is_selected(treepath)) {
                    selection.unselect_all();
                    selection.select_path(treepath);
                }
                rightclick_menu_popup(e.time);
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

    private void rightclick_menu_popup(uint activateTime) {
        menu = create_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, activateTime);
    }

    public int get_model_item_column() {
        return (int)MusicBrowserModel.Column.ITEM;
    }
    
    public TreeModel? get_queryable_model() {
        TreeModel? tm = this.get_model();
        return tm;
    }
    
    public GLib.List<TreePath>? query_selection() {
        return this.get_selection().get_selected_rows(null);
    }

    private Gtk.Menu create_rightclick_menu() {
        TreeIter iter;
        var rightmenu = new Gtk.Menu();
        GLib.List<TreePath> list;
        list = this.get_selection().get_selected_rows(null);
        ItemSelectionType itemselection = ItemSelectionType.SINGLE;
        if(list.length() > 1)
            itemselection = ItemSelectionType.MULTIPLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        mediabrowsermodel.get_iter(out iter, path);
        mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.QUERYABLE_TREE_MENU_QUERY, itemselection);
        Item? parent_item = Item(ItemType.UNKNOWN);
        bool is_va_album = false;
        if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM ||
           global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
            TreePath treepath = path.copy();
            while(treepath.get_depth() > 1) {
                if(treepath.get_depth() > 1) {
                    treepath.up();
                }
                else {
                    break;
                }
            }
            mediabrowsermodel.get_iter(out iter, treepath);
            mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out parent_item);
            //print("parent_item type : %s\n", parent_item.type.to_string());
        }
        else if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE && 
                item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
            TreePath treepath = path.copy();
            treepath.up();
            Item? ar_item = null;
            mediabrowsermodel.get_iter(out iter, treepath);
            mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out ar_item);
            if(ar_item.text == VARIOUS_ARTISTS)
                is_va_album = true;
        }
        else if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE && 
                item.type == ItemType.COLLECTION_CONTAINER_ALBUMARTIST) {
            TreePath treepath = path.copy();
            while(treepath.get_depth() > 1) {
                if(treepath.get_depth() > 1) {
                    treepath.up();
                }
                else {
                    break;
                }
            }
            mediabrowsermodel.get_iter(out iter, treepath);
            mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out parent_item);
        }
        for(int i =0; i < array.length; i++) {
            unowned Action x = array.index(i);
            //print("%s\n", x.name);
            var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? x.stock_item : Gtk.Stock.INFO), null);
            menu_item.set_label(x.info);
            menu_item.activate.connect( () => {
                x.action(item, this, parent_item);
            });
            rightmenu.append(menu_item);
        }
        if(array.length > 0) {
            var sptr_item = new SeparatorMenuItem();
            rightmenu.append(sptr_item);
        }
//        if(is_va_album) {
//            var not_compilation_item = new ImageMenuItem.from_stock(Gtk.Stock.REMOVE, null);
//            not_compilation_item.set_label(_("Do not treat this album as various artists album"));
//            not_compilation_item.activate.connect( () => {
//                // TODO
//            });
//            rightmenu.append(not_compilation_item);
//        }
        var collapse_item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        collapse_item.set_label(_("Collapse all"));
        collapse_item.activate.connect( () => {
            this.collapse_all();
        });
        rightmenu.append(collapse_item);
        var sort_item = new Gtk.MenuItem.with_label(_("Sort Mode"));
        sort_item.set_submenu(get_sort_submenu());
        rightmenu.append(sort_item);
        rightmenu.show_all();
        return rightmenu;
    }

    private Gtk.Menu get_sort_submenu() {
        Gtk.Menu m = new Gtk.Menu();
        var item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        item.set_label(_("ARTIST-ALBUM-TITLE"));
        item.activate.connect( () => {
            global.collection_sort_mode = CollectionSortMode.ARTIST_ALBUM_TITLE;
            Params.set_int_value("collection_sort_mode", (int)global.collection_sort_mode);
        });
        m.append(item);
        item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        item.set_label(_("GENRE-ARTIST-ALBUM"));
        item.activate.connect( () => {
            global.collection_sort_mode = CollectionSortMode.GENRE_ARTIST_ALBUM;
            Params.set_int_value("collection_sort_mode", (int)global.collection_sort_mode);
        });
        m.append(item);
        item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        item.set_label(_("ALBUM-ARTIST-TITLE"));
        item.activate.connect( () => {
            global.collection_sort_mode = CollectionSortMode.ALBUM_ARTIST_TITLE;
            Params.set_int_value("collection_sort_mode", (int)global.collection_sort_mode);
        });
        m.append(item);
        return m;
    }
    
    private void on_drag_begin(Gtk.Widget sender, DragContext context) {
        this.dragging = true;
        List<unowned TreePath> treepaths;
        Gdk.drag_abort(context, Gtk.get_current_event_time());
        Gtk.TreeSelection selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        if(treepaths != null) {
            TreeIter iter;
            Pixbuf? p;
            this.mediabrowsermodel.get_iter(out iter, treepaths.nth_data(0));
            this.mediabrowsermodel.get(iter, MusicBrowserModel.Column.ICON, out p);
            if(p != null)
                Gtk.drag_source_set_icon_pixbuf(this, p);
            else
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
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

    private void on_drag_data_get(Gtk.Widget sender, Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint etime) {
        List<unowned TreePath> treepaths;
        unowned Gtk.TreeSelection selection;
        selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        DndData[] ids = {};
        if(treepaths.length() < 1)
            return;
        foreach(TreePath treepath in treepaths) { 
            //TreePath tp = filtermodel.convert_path_to_child_path(treepath);
            DndData[] l = mediabrowsermodel.get_dnd_data_for_path(ref treepath); 
            foreach(DndData u in l) {
                //print("dnd data get %d  %s\n", u.db_id, u.items[0].type.to_string());
                ids += u; // this is necessary, if more than one path can be selected
            }
        }
        Gdk.Atom dnd_atom = Gdk.Atom.intern(src_target_entries[0].target, true);
        unowned uchar[] data = (uchar[])ids;
        data.length = (int)(ids.length * sizeof(DndData));
        selection_data.set(dnd_atom, 8, data);
    }

    private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
        this.dragging = false;
        
        this.unset_rows_drag_dest();
        Gtk.drag_dest_set(this,
                          Gtk.DestDefaults.ALL,
                          dest_target_entries,
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.MOVE
                          );
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            this.mediabrowsermodel.get_iter(out iter, treepath);
            this.mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(item.type,
                                                    ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED,
                                                    ItemSelectionType.SINGLE
            );
            TreePath path = treepath.copy();
            while(path.get_depth() > 1) {
                if(path.get_depth() > 1) {
                    path.up();
                }
                else {
                    break;
                }
            }
            Item? parent_item = null;
            mediabrowsermodel.get_iter(out iter, path);
            mediabrowsermodel.get(iter, MusicBrowserModel.Column.ITEM, out parent_item);
            Value? val = parent_item;
            if(action != null)
                action.action(item, val, null);
            else
                print("action was null\n");
        }
        else {
            this.expand_row(treepath, false);
        }
    }

    public bool change_model_data() {
        mediabrowsermodel.filter();
        return false;
    }
    
    private bool in_update_view = false;
    /* updates the view, leaves the original model untouched.
       expanded rows are kept as well as the scrollbar position */
    internal bool update_view() {
        double scroll_position = main_window.musicBrScrollWin.vadjustment.value;
        in_update_view = true;
        this.set_model(null);
        this.set_model(mediabrowsermodel);
        Idle.add( () => {
            in_update_view = false;
            return false;
        });
        main_window.musicBrScrollWin.vadjustment.set_value(scroll_position);
        main_window.musicBrScrollWin.vadjustment.value_changed();
        return false;
    }
        
    
    private void on_row_expanded(TreeIter iter, TreePath path) {
//        print("FIXME: xnoise-music-browser.vala - on_row_expanded\n");
        mediabrowsermodel.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        mediabrowsermodel.unload_children(ref iter);
    }

    private class MusicBrowserCellRenderer : CellRenderer {
        private const int PIXPAD   = 2; // space between pixbuf and text
        private const int WRAP_BUF = 2;
        
        private int maxiconwidth;
        private unowned Widget ow;
        private unowned Pango.FontDescription font_description;
        private unowned TreeViewColumn col;
        private int expander;
        private int hsepar;
        private int calculated_widh[3];
        private static Pixbuf artist_unsel;
        private static Pixbuf album_unsel;
        private static Pixbuf title_unsel;
        private static Pixbuf genre_unsel;
        
        public int level              { get; set; }
        public Gdk.Pixbuf pix         { get; set; }
        public string text            { get; set; }
        public int size_points        { get; set; }
        
        
        public MusicBrowserCellRenderer(Widget ow, 
                                        Pango.FontDescription font_description,
                                        TreeViewColumn col,
                                        int expander,
                                        int hsepar) {
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
                print("no window\n");
                natural_height = minimum_height = 30;
                return;
            }
            int column_width = ow.get_allocated_width() - 2;
            int cw = col.get_width();
            int sum = 0;
            int iconwidth = 30;
            if(maxiconwidth < iconwidth)
                maxiconwidth = iconwidth;
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE)
                calculated_widh[level] = (level == 1 ? maxiconwidth : 17);
            else if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE)
                calculated_widh[level] = (level == 0 ? maxiconwidth : 17);
            else
                calculated_widh[level] = (level == 2 ? maxiconwidth : 17);
            sum = (level + 1) * (expander + 2 * hsepar) + (2 * (int)xpad) + calculated_widh[level] + 2 + PIXPAD; 
            //print("column_width: %d  sum: %d\n", column_width, sum);
            //print("column_width - sum :%d  level: %d\n", column_width - sum, level);
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( (int)((column_width - sum + WRAP_BUF) * Pango.SCALE));
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            int wi, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            natural_height = minimum_height = (pix != null ? 
                                                  int.max(he + 2, pix.get_height() + 2) : 
                                                  he + 2
                                              );
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
        
        private Gdk.Pixbuf? get_level_1_icon(ref StyleContext context, ref CellRendererState flags) {
            Gdk.Pixbuf? p = null;
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                if(text == VARIOUS_ARTISTS) {
                    p = IconRepo.get_themed_pixbuf_icon(VA_ICON_SYMBOLIC, 
                                          16, context);
                    return p;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(artist_unsel == null)
                        artist_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                        16, context);
                    p = artist_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                    16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
                if(pix != null) {
                    return pix;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(album_unsel == null)
                        album_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                    p = album_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(genre_unsel == null)
                        genre_unsel = 
                            IconRepo.get_themed_pixbuf_icon(GENRE_ICON_SYMBOLIC, 
                                                        16, context);
                    p = genre_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(GENRE_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            return p;
        }
        
        private Gdk.Pixbuf? get_level_2_icon(ref StyleContext context, ref CellRendererState flags) {
            Gdk.Pixbuf? p = null;
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                if(pix != null) {
                    return pix;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(album_unsel == null)
                        album_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                    p = album_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
                if(text == VARIOUS_ARTISTS) {
                    p = IconRepo.get_themed_pixbuf_icon(VA_ICON_SYMBOLIC, 
                                          16, context);
                    return p;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(artist_unsel == null)
                        artist_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                        16, context);
                    p = artist_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(artist_unsel == null)
                        artist_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                        16, context);
                    p = artist_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ARTIST_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            return p;
        }
        
        private Gdk.Pixbuf? get_level_3_icon(ref StyleContext context, ref CellRendererState flags) {
            Gdk.Pixbuf? p = null;
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                if(pix != null) {
                    return pix;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(title_unsel == null)
                        title_unsel = 
                            IconRepo.get_themed_pixbuf_icon(TITLE_ICON_SYMBOLIC, 
                                                        16, context);
                    p = title_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(TITLE_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(title_unsel == null)
                        title_unsel = 
                            IconRepo.get_themed_pixbuf_icon(TITLE_ICON_SYMBOLIC, 
                                                        16, context);
                    p = title_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(TITLE_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            else if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
                if(pix != null) {
                    return pix;
                }
                if((flags & CellRendererState.SELECTED) == 0) {
                    if(album_unsel == null)
                        album_unsel = 
                            IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                    p = album_unsel;
                }
                else {
                    p = IconRepo.get_themed_pixbuf_icon(ALBUM_ICON_SYMBOLIC, 
                                                        16, context);
                }
            }
            return p;
        }
        
        public override void render(Cairo.Context cr, Widget widget,
                                    Gdk.Rectangle background_area,
                                    Gdk.Rectangle cell_area,
                                    CellRendererState flags) {
            
            StyleContext context = widget.get_style_context();
            
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( 
                (int) ((cell_area.width - calculated_widh[level] - PIXPAD) * Pango.SCALE)
            );
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            StateFlags state = widget.get_state_flags();
            int wi = 0, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            
            
            Gdk.Pixbuf p = null;
            switch(level) {
                case 0:
                    p = get_level_1_icon(ref context, ref flags);
                    break;
                case 1:
                    p = get_level_2_icon(ref context, ref flags);
                    break;
                case 2:
                    p = get_level_3_icon(ref context, ref flags);
                    break;
                default:
                    p = null;
                    break;
            }
            if(p != null) {
                int pixheight = p.get_height();
                int x_offset = p.get_width();
                if(calculated_widh[level] > x_offset)
                    x_offset = (int)((calculated_widh[level] - x_offset) / 2.0);
                else
                    x_offset = 0;
                if(cell_area.height > pixheight)
                    Gdk.cairo_set_source_pixbuf(cr, 
                                                p, 
                                                cell_area.x + x_offset, 
                                                cell_area.y + (cell_area.height -pixheight)/2
                    );
                else
                    Gdk.cairo_set_source_pixbuf(cr,
                                                p, 
                                                cell_area.x + x_offset, 
                                                cell_area.y
                    );
                
                cr.paint();
            }
            //print("calculated_widh[level]: %d  level: %d\n", calculated_widh[level], level);
            if(cell_area.height > he)
                context.render_layout(cr, 
                                      calculated_widh[level] + 
                                          PIXPAD + cell_area.x,
                                      cell_area.y +  (cell_area.height -he)/2,
                                      pango_layout);
            else
                context.render_layout(cr, 
                                      calculated_widh[level] + 
                                          PIXPAD + cell_area.x, 
                                      cell_area.y, 
                                      pango_layout);
        }
    }
    
    
    private Pango.FontDescription font_description;
    private int last_width;
    
    private void setup_view() {
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
        fontsize = Params.get_int_value("fontsizeMB");
        Gtk.StyleContext context = this.get_style_context();
        font_description = context.get_font(StateFlags.NORMAL).copy();
        font_description.set_size((int)(global.fontsize_dockable * Pango.SCALE));
        
        var column = new TreeViewColumn();
        
        int expander = 0;
        this.style_get("expander-size", out expander);
        int hsepar = 0;
        this.style_get("horizontal-separator", out hsepar);
        renderer = new MusicBrowserCellRenderer(this.ow, font_description, column, expander, hsepar);
        
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
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text",  MusicBrowserModel.Column.VIS_TEXT); // no markup!!
        column.add_attribute(renderer, "level", MusicBrowserModel.Column.LEVEL);
        column.add_attribute(renderer, "pix",   MusicBrowserModel.Column.ICON);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
        global.notify["fontsize-dockable"].connect( () => {
            this.fontsize = global.fontsize_dockable;
        });
    }
}

