/* xnoise-tree-media-selector.vala
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


/* This is the traditional MediaSelector, which uses a TreeView */
private class Xnoise.TreeMediaSelector : TreeView, MediaSelector {
    
    private unowned MediaSoureWidget msw;
    private ListStore store;
    private bool mouse_over = false;
    private int row_height = 24;
    
    public enum Column {
        ICON = 0,
        VIS_TEXT,
        WEIGHT,
        CATEGORY,
        SELECTION_STATE,
        SELECTION_ICON,
        NAME,
        N_COLUMNS
    }
    
    public string selected_dockable_media { get; set; }
    
    public TreeMediaSelector(MediaSoureWidget msw) {
        this.events = this.events |
                      Gdk.EventMask.ENTER_NOTIFY_MASK |
                      Gdk.EventMask.LEAVE_NOTIFY_MASK;
        this.msw = msw;
        selected_dockable_media = "";
        this.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        this.headers_visible = false;
        this.set_enable_search(false);
        this.get_selection().set_mode(SelectionMode.SINGLE);
        this.store = new ListStore(Column.N_COLUMNS, 
                                   typeof(string),           //icon
                                   typeof(string),               //vis_text
                                   typeof(int),                  //weight
                                   typeof(DockableMedia.Category),
                                   typeof(bool),                 //selection state
                                   typeof(Gdk.Pixbuf),           //selection icon
                                   typeof(string)                //name
        );
        var column = new TreeViewColumn();
        TreeViewColumn first_col = column;
        var renderer = new CustomCellRendererList();
//        var rendererPb = new CellRendererPixbuf();
//        column.pack_start(rendererPb, false);
        column.pack_start(renderer, true);
        column.add_attribute(renderer, "icon", Column.ICON);
        column.add_attribute(renderer, "text", Column.VIS_TEXT);
        column.add_attribute(renderer, "weight", Column.WEIGHT);
        this.insert_column(column, -1);
        
        this.model = this.store;
        this.key_release_event.connect(this.on_key_released);
        
        this.button_press_event.connect(this.on_button_pressed);
        
        this.notify["selected-dockable-media"].connect( () => {
            global.active_dockable_media_name = selected_dockable_media;
            select_without_signal_emmission(selected_dockable_media);
        });
        
        this.show_all();
        build_model();
        dockable_media_sources.media_inserted.connect(on_media_inserted);
        dockable_media_sources.media_removed.connect(on_media_removed);
//        dockable_media_sources.category_removed.connect(on_category_removed);
//        dockable_media_sources.category_inserted.connect(on_category_inserted);
        
        Timeout.add_seconds(1, () => {
            if(this.get_window() == null)
                return true;
            var path = new Gtk.TreePath.first();
            Gdk.Rectangle rect = Gdk.Rectangle();
            this.get_cell_area(path, first_col, out rect);
            row_height = int.max(rect.height + 1, 22);
            queue_resize();
            return false;
        });
        
        this.enter_notify_event.connect(on_enter);
        this.leave_notify_event.connect(on_leave);
        
        //msw.search_entry.enter_notify_event.connect(on_enter);
        //msw.search_entry.leave_notify_event.connect(on_leave);
    }
    
    ~TreeMediaSelector() {
        this.enter_notify_event.disconnect(on_enter);
        this.leave_notify_event.disconnect(on_leave);
        
        //this.msw.search_entry.enter_notify_event.disconnect(on_enter);
        //this.msw.search_entry.leave_notify_event.disconnect(on_leave);
    }
    
    private bool on_enter() {
        mouse_over = true;
        Timeout.add(300, () => {
            queue_resize();
            return false;
        }); 
        return false;
    }
    
    private bool on_leave() { 
        mouse_over = false;
        Idle.add( () => {
            queue_resize();
            return false;
        }); 
        return false;
    }
    
    private uint scroll_source = 0;
    private int height_last = 0;
    private int l_minimum_height = 0;
    private int l_natural_height = 0;
    private int STEPSIZE = 16;
    private int ANIMATION_SPEED = 25;
    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        //print("get_preferred_height\n");
        base.get_preferred_height(out l_minimum_height, out l_natural_height);
        l_natural_height = int.max(l_natural_height, 24);
        if(mouse_over) { // SHOWING
            if(height_last < l_natural_height) {
                if(height_last < row_height)
                    height_last = row_height;
                height_last = height_last + STEPSIZE;
                if(height_last > l_natural_height)
                    height_last = l_natural_height;
                natural_height = minimum_height = height_last;
                Timeout.add(ANIMATION_SPEED, () => {
                    queue_resize();
                    return false;
                });
                return;
            }
            else {
                natural_height = minimum_height = l_natural_height;
            }
        }
        else { //HIDING
            if(height_last > row_height) {
                height_last = height_last - STEPSIZE;
                if(height_last < row_height)
                    height_last = row_height;
                natural_height = minimum_height = height_last;
                Timeout.add(ANIMATION_SPEED, () => {
                    queue_resize();
                    return false;
                });
                return;
            }
            else {
                natural_height = minimum_height = row_height;
            }
            if(scroll_source != 0)
                Source.remove(scroll_source);
            scroll_source = Idle.add(() => {
                GLib.List<TreePath> list;
                list = this.get_selection().get_selected_rows(null);
                if(list.length() != 0) {
                    this.scroll_to_cell(list.data, null, false, 0.0f, 0.0f);
                }
                scroll_source = 0;
                return false;
            });
        }
    }
    
    public void select_without_signal_emmission(string dockable_name) {
        Gtk.TreePath? path = null;
        Gtk.TreeSelection sel = this.get_selection();
        string? name = null;
        this.model.foreach( (m,p,i) => {
            m.get(i, Column.NAME, out name);
            if(name == dockable_name) {
                //print("%s == %s\n", dockable_name, name);
                path = m.get_path(i);
                return true;
            }
            return false;
        });
        if(path != null) {
            this.model.foreach( (mo,px,iy) => {
                ListStore mx = (ListStore)mo;
                mx.set(iy, 
                       Column.SELECTION_STATE, false,
                       Column.SELECTION_ICON, null
                );
                return false;
            });
            TreeIter it;
            this.model.get_iter(out it, path);
            ((ListStore)this.model).set(it,
                           Column.SELECTION_STATE, true,
                           Column.SELECTION_ICON, icon_repo.selected_collection_icon
            );
            Idle.add( () => {
                sel.unselect_all();
                sel.select_path(path);
                return false;
            });
            //print("sel treepth %s\n", dockable_name);
        }
        else {
            print("couldn't find treepath\n");
        }
    }
    
    private bool on_button_pressed(Gdk.EventButton e) {
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        TreePath treepath;
        TreeViewColumn co;
        if(!this.get_path_at_pos(x, y, out treepath, out co, out cell_x, out cell_y))
            return true;
        
        TreeIter it;
        ListStore m = (ListStore)this.get_model();
            m.foreach( (mo,p,iy) => {
                ListStore mx = (ListStore)mo;
                mx.set(iy, 
                       Column.SELECTION_STATE, false,
                       Column.SELECTION_ICON, null
                );
                return false;
            });
            m.get_iter(out it, treepath);
            string? name;
            m.get(it, 
                  Column.NAME, out name
            );
            m.set(it,
                  Column.SELECTION_STATE, true,
                  Column.SELECTION_ICON, icon_repo.selected_collection_icon
            );
            if(name == null)
                name = "";
            selected_dockable_media = name;
        return false;
    }
    
    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
        //print("%d\n",(int)e.keyval);
        Gtk.TreeModel m;
        switch(e.keyval) {
            case Gdk.Key.Up:
            case Gdk.Key.Down:
                Gtk.TreeSelection selection = this.get_selection();
                if(selection.count_selected_rows() < 1) break;
                GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
                TreePath? treepath = selected_rows.nth_data(0);
                if(treepath != null) {
                    TreeIter iter;
                    this.model.get_iter(out iter, treepath);
                    m.foreach( (mo,p,iy) => {
                        ListStore mx = (ListStore)mo;
                        mx.set(iy, 
                               Column.SELECTION_STATE, false,
                               Column.SELECTION_ICON, null
                        );
                        return false;
                    });
                    this.set_cursor(treepath, null,false);
                    ListStore mx = (ListStore)this.model;
                    string? name;
                    mx.get(iter, Column.NAME, out name);
                    mx.set(iter, 
                          Column.SELECTION_STATE, true,
                          Column.SELECTION_ICON, icon_repo.selected_collection_icon
                    );
                    if(name == null)
                        name = "";
                    selected_dockable_media = name;
                }
                break;
            default:
                break;
        }
        return false;
    }
    
    private void set_row_data(TreeIter iter, DockableMedia media) {
        assert(media != null);
        string? icon;
        icon = media.get_icon_name();
        
//        if(pix != null && pix.get_height() != 22)
//            pix = pix.scale_simple(22, 22, Gdk.InterpType.BILINEAR);
        
        this.store.set(iter,
              TreeMediaSelector.Column.ICON, icon,
              TreeMediaSelector.Column.VIS_TEXT, media.headline(),
              TreeMediaSelector.Column.WEIGHT, Pango.Weight.NORMAL,
              TreeMediaSelector.Column.CATEGORY, media.category,
              TreeMediaSelector.Column.SELECTION_STATE, false,
              TreeMediaSelector.Column.SELECTION_ICON, null,
              TreeMediaSelector.Column.NAME, media.name()
        );
    }
    
    private void set_row_category(TreeIter iter, DockableMedia.Category category) {
        this.store.set(iter,
              TreeMediaSelector.Column.ICON, null,
              TreeMediaSelector.Column.VIS_TEXT, category.to_string(),
              TreeMediaSelector.Column.WEIGHT, Pango.Weight.NORMAL,
              TreeMediaSelector.Column.CATEGORY, category,
              TreeMediaSelector.Column.SELECTION_STATE, false,
              TreeMediaSelector.Column.SELECTION_ICON, null,
              TreeMediaSelector.Column.NAME, ""
          );
      }    
    
    private void build_model() {
        this.store.clear();
        TreeIter iter;
        foreach(DockableMedia.Category c in dockable_media_sources.get_existing_categories()) {
            int child_count = 0; 
//            this.store.append(out iter);//, null);
//            set_row_category(iter, c);
            
            List<unowned DockableMedia> list = new List<unowned DockableMedia>();
            foreach(DockableMedia d in dockable_media_sources.get_media_for_category(c)) {
                if(d.name() == "MusicBrowserDockable")
                    list.prepend(d);
                else
                    list.append(d);
            }
            foreach(DockableMedia d in list) {
                TreeIter iter_child; 
                this.store.append(out iter_child);//, iter);
                set_row_data(iter_child, d);
                child_count++;
            }
            // if there were children being added, move up to toplevel again
//            if(child_count > 0)
//                this.store.iter_parent(out iter, iter);
        }
    }
    
    private void on_media_inserted(string name) {
        DockableMedia d = dockable_media_sources.lookup(name);
        assert(d != null);
        
        TreeIter iter_category;
        this.store.get_iter_first(out iter_category);
//        bool found_category = false;
//        
//        this.store.foreach((model, path, iter) => {
//            Value v;
//            this.store.get_value(iter, Column.CATEGORY, out v);
//            if(v.get_enum() == d.category()) {
//                iter_category = iter;
//                found_category = true;
//                return true;
//            }
//            return false;
//        });
        
//        if(found_category) {
            TreeIter iter;
            this.store.append(out iter);//, iter_category);
            set_row_data(iter, d);
//        }
    }
    
    private void on_media_removed(string name) {
         this.store.foreach((model, path, iter) => {
            Value v;
            this.store.get_value(iter, Column.NAME, out v);
            if(v.get_string() == name) {
                this.store.remove(iter);
                return true;
            }
            return false;
        });
    }
    
    private void on_category_inserted(DockableMedia.Category category) {
//        TreeIter iter;
//        this.store.append(out iter, null);
//        this.set_row_category(iter, category);    
    }
    
    private void on_category_removed(DockableMedia.Category category) {
//        this.store.foreach((model, path, iter) => {
//            Value v;
//            this.store.get_value(iter, Column.CATEGORY, out v);
//            if(v.get_enum() == category) {
//                this.store.remove(ref iter);
//                return true;
//            }
//            return false;
//        });
    }
    
} // end class TreeMediaSelector



private class Xnoise.CustomCellRendererList : Gtk.CellRenderer {
//    private int maxiconwidth;
//    private unowned Widget ow;
    private unowned Pango.FontDescription font_description;
//    private unowned TreeViewColumn col;
//    private int expander;
//    private int hsepar;
    private int PIXPAD = 10; // space between pixbuf and text
    private int INDENT = 15;
    private const int ICONSIZE = 16;
//    private int calculated_widh[3];
    
//    public int level    { get; set; }
    public string icon            { get; set; }
    public string text            { get; set; }
    public int weight             { get; set; }
    
    public CustomCellRendererList() {
        GLib.Object();
//        this.ow = ow;
//        this.col = col;
//        this.expander = expander;
//        this.hsepar = hsepar;
//        this.font_description = font_description;
//        maxiconwidth = 0;
//        calculated_widh[0] = 0;
//        calculated_widh[1] = 0;
//        calculated_widh[2] = 0;
    }
    
    public override void get_preferred_height_for_width(Gtk.Widget widget,
                                                        int width,
                                                        out int minimum_height,
                                                        out int natural_height) {
        natural_height = minimum_height = 20;//(pix != null ? int.max(24, pix.get_height() + 2) : 24);
    }

    public override void get_size(Widget widget, Gdk.Rectangle? cell_area,
                                  out int x_offset, out int y_offset,
                                  out int width, out int height) {
        // function not used for gtk+-3.0 !
        x_offset = 0;
        y_offset = 0;
        width = 0;
        height = 24;
    }
    
    public override void render(Cairo.Context cr, Widget widget,
                                Gdk.Rectangle background_area,
                                Gdk.Rectangle cell_area,
                                CellRendererState flags) {
        
        StyleContext context;
        var pango_layout = widget.create_pango_layout(text);
//        var font_description = widget.get_style_context().get_font(widget.get_state_flags());
        pango_layout.set_alignment(Pango.Alignment.LEFT);
//        font_description.set_weight(Pango.Weight.BOLD);
//        pango_layout.set_font_description(font_description);
//        int pixwidth = (pix != null ? pix.get_width() : 16);
//        pango_layout.set_width( 
//            cell_area.width - (pixwidth + PIXPAD)
////            (int) ((cell_area.width - calculated_widh[level] - PIXPAD) * Pango.SCALE)
//        );
//        pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
        context = main_window.media_browser_box.get_style_context();
        context.add_class(STYLE_CLASS_SIDEBAR);
        StateFlags state = widget.get_state_flags();
        if((flags & CellRendererState.SELECTED) == 0) {
            Gdk.cairo_rectangle(cr, background_area);
            Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL);
            Gdk.cairo_set_source_rgba(cr, col);
            cr.fill();
        }
        int wi = 0, he = 0;
        pango_layout.get_pixel_size(out wi, out he);
        Gdk.Pixbuf p = null;
        if(icon != null && icon.strip() != "") {
            p = IconRepo.get_themed_pixbuf_icon(icon, ICONSIZE, widget.get_style_context());
            
            if(p != null) {
                int pixheight = p.get_height();
    //            int x_offset = pix.get_width();
    //            if(calculated_widh[level] > x_offset)
    //                x_offset = (int)((calculated_widh[level] - x_offset) / 2.0);
    //            else
    //                x_offset = 0;
                if(cell_area.height > pixheight)
                    Gdk.cairo_set_source_pixbuf(cr, 
                                                p, 
                                                cell_area.x + INDENT,
                                                cell_area.y + (cell_area.height - pixheight)/2
                    );
                else
                    Gdk.cairo_set_source_pixbuf(cr,
                                                p, 
                                                cell_area.x + INDENT,
                                                cell_area.y
                    );
                
                cr.paint();
            }
        }
        int pixwidth = (p != null ? p.get_width() : ICONSIZE);
        //print("calculated_widh[level]: %d  level: %d\n", calculated_widh[level], level);
        context = widget.get_style_context();
        if(cell_area.height > he)
            context.render_layout(cr, 
                                  pixwidth + 
                                      PIXPAD + cell_area.x + INDENT,
                                  cell_area.y +  (cell_area.height -he)/2,
                                  pango_layout);
        else
            context.render_layout(cr, 
                                  pixwidth + 
                                      PIXPAD + cell_area.x + INDENT, 
                                  cell_area.y, 
                                  pango_layout);
    }
}

