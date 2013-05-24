/* xnoise-treeview-videos.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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
using Xnoise.Database;


private class Xnoise.TreeViewVideos : Gtk.TreeView, TreeQueryable {
    private unowned MainWindow win;
    private unowned DockableMedia dock;
    private bool dragging = false;
    private Gtk.Menu menu;

    private const TargetEntry[] src_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
    };
    
    private int last_width;
    //parent container of this widget (most likely scrolled window)
    private unowned Widget ow;
    private TreeViewVideosModel tvm;
    private ListFlowingTextRenderer renderer;
    
    public TreeViewVideos(DockableMedia dock, MainWindow window, Widget ow) {
        this.win = window;
        this.dock = dock;
        this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
        this.headers_visible = false;
        this.get_selection().set_mode(SelectionMode.MULTIPLE);
        this.ow = ow;
        this.set_enable_search(false);
        
        var column = new TreeViewColumn();
        
        Gtk.StyleContext context = this.get_style_context();
        
        int hsepar = 0;
        this.style_get("horizontal-separator", out hsepar);
        renderer = new ListFlowingTextRenderer(column, hsepar);
        
        column.pack_start(renderer, true);
        column.add_attribute(renderer, "itype", TreeViewVideosModel.Column.ITEMTYPE);
        column.add_attribute(renderer, "text", TreeViewVideosModel.Column.VIS_TEXT);
        column.add_attribute(renderer, "pix", TreeViewVideosModel.Column.ICON);
        
        this.insert_column(column, -1);
        tvm = new TreeViewVideosModel(dock, this);
        this.model = tvm;
        
        this.row_activated.connect( (s,tp,c) => {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            this.model.get_iter(out iter, tp);
            this.model.get(iter, TreeViewVideosModel.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(item.type, ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED, ItemSelectionType.SINGLE);
            
            if(action != null)
                action.action(item, null, null);
            else
                print("action was null\n");
        });
        Gtk.drag_source_set(this,
                            Gdk.ModifierType.BUTTON1_MASK,
                            src_target_entries,
                            Gdk.DragAction.COPY
        );
        this.drag_begin.connect(this.on_drag_begin);
        this.drag_data_get.connect(this.on_drag_data_get);
        this.drag_end.connect(this.on_drag_end);
        this.button_release_event.connect(this.on_button_release);
        this.button_press_event.connect(this.on_button_press);
        this.key_release_event.connect(this.on_key_released);
        
        this.ow.size_allocate.connect_after( (s, a) => {
            unowned TreeViewColumn tvc = this.get_column(0);
            int current_width = this.ow.get_allocated_width();
            if(last_width == current_width)
                return;
            
            last_width = current_width;
            
            tvc.max_width = tvc.min_width = current_width - 20;
            TreeModel? xm = this.get_model();
            if(xm != null)
                xm.foreach( (mo, pt, it) => {
                    if(mo == null)
                        return true;
                    mo.row_changed(pt, it);
                    return false;
                });
        });
        this.realize.connect_after( () => {
            Idle.add( () => {
                //print("realized\n");
                unowned TreeViewColumn tvc = this.get_column(0);
                int current_width = this.ow.get_allocated_width();
                
                tvc.max_width = tvc.min_width = current_width - 20;
                TreeModel? xm = this.get_model();
                if(xm != null)
                    xm.foreach( (mo, pt, it) => {
                        if(mo == null)
                            return true;
                        mo.row_changed(pt, it);
                        return false;
                    });
                return false;
            });
        });
        context.save();
        Gdk.RGBA color, scolor;
        scolor = context.get_background_color(StateFlags.SELECTED);
        context.add_class(STYLE_CLASS_PANE_SEPARATOR);
        color = context.get_background_color(StateFlags.NORMAL);
        Timeout.add_seconds(1, () => {
            StyleContext ctx = main_window.media_browser_box.get_style_context();
            ctx.add_class(STYLE_CLASS_SIDEBAR);
            Gdk.RGBA col = ctx.get_background_color(StateFlags.NORMAL);
            this.override_background_color(StateFlags.NORMAL, col);
            return false;
        });
        this.override_background_color(StateFlags.SELECTED, scolor);
        context.restore();
    }

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
        //print("%d\n",(int)e.keyval);
        switch(e.keyval) {
            case Gdk.Key.Menu: {
                rightclick_menu_popup(e.time);
                return true;
            }
            default:
                break;
        }
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
            this.model.get_iter(out iter, treepaths.nth_data(0));
            this.model.get(iter, TreeViewVideosModel.Column.ICON, out p);
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
            DndData[] l = ((TreeViewVideosModel)this.model).get_dnd_data_for_path(ref treepath); 
            foreach(DndData u in l) {
                //print("dnd data get %d  %s\n", u.db_id, u.mediatype.to_string());
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
                this.tvm.get_iter(out iter, treepath);
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
        if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y))
            return false;
        selection.unselect_all();
        selection.select_path(treepath);
        
        return false;
    }

    public int get_model_item_column() {
        return (int)TreeViewVideosModel.Column.ITEM;
    }
    
    public TreeModel? get_queryable_model() {
        TreeModel? tm = this.get_model();
        return tm;
    }

    public GLib.List<TreePath>? query_selection() {
        return this.get_selection().get_selected_rows(null);
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
        ItemSelectionType itemselection = ItemSelectionType.SINGLE;
        if(list.length() > 1)
            itemselection = ItemSelectionType.MULTIPLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        tvm.get_iter(out iter, path);
        tvm.get(iter, TreeViewVideosModel.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, 
                                                ActionContext.QUERYABLE_TREE_MENU_QUERY,
                                                itemselection
        );
        for(int i =0; i < array.length; i++) {
            unowned Action x = array.index(i);
            //print("%s\n", x.name);
            var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? 
                                                            x.stock_item : 
                                                            Gtk.Stock.INFO), null);
            menu_item.set_label(x.info);
            menu_item.activate.connect( () => {
                x.action(item, this, null);
            });
            rightmenu.append(menu_item);
        }
        rightmenu.show_all();
        return rightmenu;
    }
}

private class Xnoise.CustomCellRendererPixbuf : Gtk.CellRendererPixbuf {
    
    public override void render(Cairo.Context cr, Widget widget,
                                Gdk.Rectangle background_area,
                                Gdk.Rectangle cell_area,
                                CellRendererState flags) {
        StyleContext context;
        context = main_window.media_browser_box.get_style_context();
        context.add_class(STYLE_CLASS_SIDEBAR);
        if((flags & CellRendererState.SELECTED) == 0) {
            Gdk.cairo_rectangle(cr, cell_area);
            Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL);
            Gdk.cairo_set_source_rgba(cr, col);
            cr.fill();
        }
        if(pixbuf != null) {
            int pixheight = pixbuf.get_height();
            if(cell_area.height > pixheight)
                Gdk.cairo_set_source_pixbuf(cr, 
                                            pixbuf, 
                                            cell_area.x, 
                                            cell_area.y + (cell_area.height -pixheight)/2
                );
            else
                Gdk.cairo_set_source_pixbuf(cr,
                                            pixbuf, 
                                            cell_area.x, 
                                            cell_area.y
                );
            cr.paint();
        }
    }
}

