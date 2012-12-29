/* xnoise-media-source-widget.vala
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


// Vala does not seem to allow nested interfaces
private interface MediaSelector : Gtk.Widget {
    public abstract string selected_dockable_media {get; set;} 
    public abstract void select_without_signal_emmission(string name);
    public abstract void expand_all();
}
    

public class Xnoise.MediaSoureWidget : Gtk.Box, Xnoise.IParams {
    
    private Gtk.Notebook notebook;
    private unowned Xnoise.MainWindow mwindow;
    
    public Gtk.Entry search_entry              { get; private set; }
    private MediaSelector media_source_selector = null;// { get; private set; }
    private ScrolledWindow media_source_selector_window = null;
    private Box media_source_selector_box = null;
    
    public MediaSoureWidget(Xnoise.MainWindow mwindow) {
        Object(orientation:Orientation.VERTICAL, spacing:0);
        Params.iparams_register(this);
        this.mwindow = mwindow;
        
        setup_widgets();
    }
    
    /* This is a compact media selector, which uses a ComboBox */
    private class ComboMediaSelector : ComboBox, MediaSelector {
        private TreeStore store;
        
        public enum Column {
            ICON = 0,
            VIS_TEXT,
            WEIGHT,
            CATEGORY,
            IS_SEPARATOR,
            NAME,
            N_COLUMNS
        }
        
        public string selected_dockable_media { get; set; }
        
        public ComboMediaSelector() {
            selected_dockable_media = "";
            store = new TreeStore(Column.N_COLUMNS, 
                                  typeof(Gdk.Pixbuf),           //icon
                                  typeof(string),               //vis_text
                                  typeof(int),                  //weight
                                  typeof(DockableMedia.Category),
                                  typeof(bool),                 //is_separator
                                  typeof(string)                //name
                                  );
            var renderer = new CellRendererText();
            var rendererPb = new CellRendererPixbuf();
            
            this.pack_start(rendererPb, false);
            this.pack_start(renderer, true);
            
            this.add_attribute(rendererPb, "pixbuf", Column.ICON);
            this.add_attribute(renderer, "text", Column.VIS_TEXT);
            this.add_attribute(renderer, "weight", Column.WEIGHT);
            this.set_row_separator_func(separator_func);
            this.model = store;
            
            this.notify["selected-dockable-media"].connect( () => {
                select_without_signal_emmission(selected_dockable_media);
                global.active_dockable_media_name = selected_dockable_media;
            });
            
            this.changed.connect((a) => {
                assert(this.get_model() != null);
                
                TreeIter iter;
                this.get_active_iter(out iter);
                
                string name;
                store.get(iter, Column.NAME, out name);
                selected_dockable_media = name;
            });
            
            this.show_all();
            build_model();
            connect_signal_handlers();
        }
        
        private void connect_signal_handlers() {
            dockable_media_sources.media_inserted.connect(on_media_inserted);
            dockable_media_sources.media_removed.connect(on_media_removed);
            dockable_media_sources.category_removed.connect(on_category_removed);
            dockable_media_sources.category_inserted.connect(on_category_inserted);
        }
        
        private void disconnect_signal_handlers() {
            dockable_media_sources.media_inserted.disconnect(on_media_inserted);
            dockable_media_sources.media_removed.disconnect(on_media_removed);
            dockable_media_sources.category_removed.disconnect(on_category_removed);
            dockable_media_sources.category_inserted.disconnect(on_category_inserted);
        }
        
        public void expand_all() {
        }
             
        public void select_without_signal_emmission(string dockable_name) {
            TreeIter iter_search;
            Value v;
            if(!this.store.get_iter_first(out iter_search))
                return;
                
            while(true) {
                this.store.get_value(iter_search, ComboMediaSelector.Column.NAME, out v);
                string row_name = v.get_string();
                if(row_name == dockable_name) {
                    disconnect_signal_handlers();
                    this.set_active_iter(iter_search);
                    connect_signal_handlers();
                    return;
                }
                if(!this.store.iter_next(ref iter_search))
                    break;
            }
        }
        
        /* set the data of a row that is not a separator between categories */
        private void set_row_data(TreeIter iter, DockableMedia media) {
            assert(media != null);
            
            this.store.set(iter,
                  ComboMediaSelector.Column.ICON, media.get_icon(),
                  ComboMediaSelector.Column.VIS_TEXT, media.headline(),
                  ComboMediaSelector.Column.WEIGHT, Pango.Weight.NORMAL,
                  ComboMediaSelector.Column.CATEGORY, media.category,
                  ComboMediaSelector.Column.IS_SEPARATOR, false,
                  ComboMediaSelector.Column.NAME, media.name()
            );
        }
        
        /* make a row a separator for a category */
        private void set_row_separator(TreeIter iter, DockableMedia.Category category) {
            this.store.set(iter,
                  ComboMediaSelector.Column.ICON, null,
                  ComboMediaSelector.Column.VIS_TEXT, "",
                  ComboMediaSelector.Column.WEIGHT, Pango.Weight.NORMAL,
                  ComboMediaSelector.Column.CATEGORY, category,
                  ComboMediaSelector.Column.IS_SEPARATOR, true,
                  ComboMediaSelector.Column.NAME, ""
              );
          }
        
        private void on_media_inserted(string name) {
            DockableMedia? d = dockable_media_sources.lookup(name);
            assert(d != null);
            insert_media_into_category(d, d.category());
        }
        
        /* we can always rely on the fact that the category media is inserted into has already been added
        to the model - DockableMediaManager takes care of this*/
        private void insert_media_into_category(DockableMedia media, DockableMedia.Category category) {
            TreeIter iter;
            Value v;
            assert(this.store.get_iter_first(out iter));
            
            while(true) {
                store.get_value(iter, ComboMediaSelector.Column.IS_SEPARATOR, out v);
                if(v.get_boolean()) {
                    Value v_category;
                    store.get_value(iter, ComboMediaSelector.Column.CATEGORY, out v_category);
                    if(v_category.get_enum() == category) { //found the appropriate section
                        TreeIter iter_section = iter;
                        while(this.store.iter_next(ref iter_section)) { //cycle to last entry in section
                            this.store.get_value(iter, ComboMediaSelector.Column.IS_SEPARATOR, out v);
                            if(v.get_boolean()) {
                                this.store.iter_previous(ref iter_section);
                                break;
                            }
                        }
                        TreeIter iter_new;
                        // if iter is still valid (end was no reached) insert new entry after it, else append
                        if(this.store.iter_is_valid(iter_section))
                            this.store.insert_after(out iter_new, null, iter_section);
                        else
                            this.store.append(out iter_new, null);
                        set_row_data(iter_new, media);
                        return;
                    }
                }
                if(!store.iter_next(ref iter))
                    break;
            }
        }
        
        private void on_category_inserted(DockableMedia.Category category) {
            TreeIter iter;
            this.store.append(out iter, null);
            set_row_separator(iter, category);
        }
        
        private void on_media_removed(string name) {
            TreeIter iter;
            Value v;
            if(!this.store.get_iter_first(out iter))
                return;
            while(true) {
                this.store.get_value(iter, ComboMediaSelector.Column.NAME, out v);
                string row_name = v.get_string();
                if(row_name == name) {
                    this.set_active(1);
                    this.store.remove(ref iter);
                    return;
                }
                if(!this.store.iter_next(ref iter))
                    break;
            }
        }
        
        /* this code will only be called when the last element in a category has been removed, because only then
        DockableMediaManager fires the signal */
        private void on_category_removed(DockableMedia.Category category) {
            TreeIter iter;
            Value v;
            if(!this.store.get_iter_first(out iter))
                return;
                
            while(true) {
                this.store.get_value(iter, ComboMediaSelector.Column.CATEGORY, out v);
                if(v.get_enum() == category) {
                    this.store.remove(ref iter);
                    return;
                }
                
                if(!this.store.iter_next(ref iter))
                    break;
            }
        }
        
        /* the model is first built here. Further updates to the model when new sources are added are handled
        by the functions that respond to DockableMediaManager's signals (instead of building everything anew.
        Adds code but saves startup time when several plugins register at the beginning. */
        private void build_model() {
            this.store.clear();
            TreeIter iter;
            if(!this.store.get_iter_first(out iter))
                this.store.append(out iter, null);
            int count = 0;
            foreach(DockableMedia.Category c in dockable_media_sources.get_existing_categories()) {
                // don't add a redundant row at the beginning
                if(count != 0)
                    this.store.append(out iter, null);
                set_row_separator(iter, c);
                List<unowned DockableMedia> list = new List<unowned DockableMedia>();
                foreach(DockableMedia d in dockable_media_sources.get_media_for_category(c)) {
                    if(d.name() == "MusicBrowserDockable")
                        list.prepend(d);
                    else
                        list.append(d);
                }
                foreach(DockableMedia d in list) {
                    this.store.append(out iter, null);
                    set_row_data(iter, d);
                }
                ++count;
            }
        }
        
        /* determines whether a row is to be drawn as a separator */
        bool separator_func (TreeModel model, TreeIter iter) {
            Value v;
            
            model.get_value(iter, ComboMediaSelector.Column.IS_SEPARATOR, out v);
            return v.get_boolean();
        }   
    }
        
        
    /* This is the traditional MediaSelector, which uses a TreeView */
    private class TreeMediaSelector : TreeView, MediaSelector {

        private TreeStore store;
        
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
        
        public TreeMediaSelector() {
            selected_dockable_media = "";
            //this.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
            this.headers_visible = false;
            this.set_enable_search(false);
            this.get_selection().set_mode(SelectionMode.SINGLE);
            this.store = new TreeStore(Column.N_COLUMNS, 
                                                                  typeof(Gdk.Pixbuf),           //icon
                                                                  typeof(string),               //vis_text
                                                                  typeof(int),                  //weight
                                                                  typeof(DockableMedia.Category),
                                                                  typeof(bool),                 //selection state
                                                                  typeof(Gdk.Pixbuf),           //selection icon
                                                                  typeof(string)                //name
                                                                  );
            var column = new TreeViewColumn();
            var renderer = new CellRendererText();
            var rendererPb = new CellRendererPixbuf();
            column.pack_start(rendererPb, false);
            column.pack_start(renderer, true);
            column.add_attribute(rendererPb, "pixbuf", Column.ICON);
            column.add_attribute(renderer, "text", Column.VIS_TEXT);
            column.add_attribute(renderer, "weight", Column.WEIGHT);
            this.insert_column(column, -1);
            
            column = new TreeViewColumn();
            rendererPb = new CellRendererPixbuf();
            column.pack_start(rendererPb, false);
            rendererPb.xalign = 1.0f;
            
            this.insert_column(column, -1);
            column.add_attribute(rendererPb, "pixbuf", Column.SELECTION_ICON);
            
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
            dockable_media_sources.category_removed.connect(on_category_removed);
            dockable_media_sources.category_inserted.connect(on_category_inserted);
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
                    TreeStore mx = (TreeStore)mo;
                    mx.set(iy, 
                           Column.SELECTION_STATE, false,
                           Column.SELECTION_ICON, null
                    );
                    return false;
                });
                TreeIter it;
                this.model.get_iter(out it, path);
                ((TreeStore)this.model).set(it,
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
            TreeStore m = (TreeStore)this.get_model();
            if(treepath.get_depth() == 1) {
                if(!this.is_row_expanded(treepath)) {
                    this.expand_row(treepath, false);
                }
                else {
                    this.collapse_row(treepath);
                }
                this.get_selection().unselect_all();
                this.get_selection().select_path(treepath);
                return true;
            }
            if(treepath.get_depth() == 2) {
                m.foreach( (mo,p,iy) => {
                    TreeStore mx = (TreeStore)mo;
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
            }
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
                    if(treepath!=null) {
                        if(treepath.get_depth() == 1) {
                            this.expand_row(treepath, false);
                        }
                        else if(treepath.get_depth() == 2) {
                            TreeIter iter;
                            this.model.get_iter(out iter, treepath);
                            m.foreach( (mo,p,iy) => {
                                TreeStore mx = (TreeStore)mo;
                                mx.set(iy, 
                                       Column.SELECTION_STATE, false,
                                       Column.SELECTION_ICON, null
                                );
                                return false;
                            });
                            this.set_cursor(treepath, null,false);
                            TreeStore mx = (TreeStore)this.model;
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
                    }
                    break;
                default:
                    break;
            }
            return false;
        }
        
        private void set_row_data(TreeIter iter, DockableMedia media) {
            assert(media != null);
            
            this.store.set(iter,
                  TreeMediaSelector.Column.ICON, media.get_icon(),
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
            foreach(DockableMedia.Category c in dockable_media_sources.get_existing_categories())
            {
                int child_count = 0; 
                this.store.append(out iter, null);
                set_row_category(iter, c);
                
                List<unowned DockableMedia> list = new List<unowned DockableMedia>();
                foreach(DockableMedia d in dockable_media_sources.get_media_for_category(c)) {
                    if(d.name() == "MusicBrowserDockable")
                        list.prepend(d);
                    else
                        list.append(d);
                }
                foreach(DockableMedia d in list) {
                    TreeIter iter_child; 
                    this.store.append(out iter_child, iter);
                    set_row_data(iter_child, d);
                    child_count++;
                }
                // if there were children being added, move up to toplevel again
                if(child_count > 0)
                    this.store.iter_parent(out iter, iter);
            }
        }
        
        private void on_media_inserted(string name) {
            DockableMedia d = dockable_media_sources.lookup(name);
            assert(d != null);
            
            TreeIter iter_category;
            this.store.get_iter_first(out iter_category);
            bool found_category = false;
            
            this.store.foreach((model, path, iter) => {
                Value v;
                this.store.get_value(iter, Column.CATEGORY, out v);
                if(v.get_enum() == d.category()) {
                    iter_category = iter;
                    found_category = true;
                    return true;
                }
                return false;
            });
            
            if(found_category) {
                TreeIter iter;
                this.store.append(out iter, iter_category);
                set_row_data(iter, d);
            }
        }
        
        private void on_media_removed(string name) {
             this.store.foreach((model, path, iter) => {
                Value v;
                this.store.get_value(iter, Column.NAME, out v);
                if(v.get_string() == name) {
                    this.store.remove(ref iter);
                    return true;
                }
                return false;
            });
        }
        
        private void on_category_inserted(DockableMedia.Category category) {
            TreeIter iter;
            this.store.append(out iter, null);
            this.set_row_category(iter, category);    
        }
        
        private void on_category_removed(DockableMedia.Category category) {
            this.store.foreach((model, path, iter) => {
                Value v;
                this.store.get_value(iter, Column.CATEGORY, out v);
                if(v.get_enum() == category) {
                    this.store.remove(ref iter);
                    return true;
                }
                return false;
            });
        }
        
    } // end class TreeMediaSelector
    
    public void set_focus_on_selector() {
        this.media_source_selector.grab_focus();
    }
    
    public void select_dockable_by_name(string name, bool emmit_signal = false) {
        //print("dockable %s selected\n", name);
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d == null) {
            print("dockable %s does not exist\n", name);
            return;
        }
        if(d.widget == null) {
            print("dockable's widget is null for %s\n", name);
            return;
        }
        assert(notebook != null && notebook is Gtk.Container);
        int i = notebook.page_num(d.widget);
        if(i > -1)
            notebook.set_current_page(i);
    }
    
    private void add_page(DockableMedia d) {
        Gtk.Widget? widg = d.create_widget(mwindow);
        if(widg == null)
            return;
        
        widg.show_all();
        notebook.show_all();
        assert(notebook != null && notebook is Gtk.Container);
        notebook.append_page(widg, new Label("x"));
        d = null;
    }
    
    private void remove_page(string name) {
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d != null) {
            d.remove_main_view();
            assert(notebook != null && notebook is Gtk.Container);
            notebook.remove_page(notebook.page_num(d.widget));
        }
        
        Idle.add( () => {
            set_focus_on_selector();
            return false;
        });
    }
    
    private void on_media_inserted(string name) {
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d == null)
            return;
        add_page(d);
    }
    
    private void setup_widgets() {
        var buff = new Gtk.EntryBuffer(null);
        this.search_entry = new Gtk.Entry.with_buffer(buff); // media_source_widget.search_entry;
        this.search_entry.secondary_icon_stock = Gtk.Stock.CLEAR;
        this.search_entry.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, false);
        this.search_entry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
        this.search_entry.set_sensitive(true);
        this.search_entry.set_placeholder_text (_("Search..."));
        
        this.pack_start(search_entry, false, false, 2);
        
        //Separator
        var da = new Gtk.DrawingArea();
        da.height_request = 1;
        this.pack_start(da, false, false, 0);
            
        // DOCKABLE MEDIA
        
        notebook = new Gtk.Notebook();
        notebook.set_show_tabs(false);
        notebook.set_border_width(1);
        notebook.show_border = true;
            
        
        this.media_source_selector_box = new Box(Orientation.VERTICAL, 0);
        this.pack_start(media_source_selector_box, false, false, 0);
        
        // initialize the proper type of media source selector
        read_params_data();
        build_media_selector();
        
        global.notify["active-dockable-media-name"].connect(() => {
            select_dockable_by_name(global.active_dockable_media_name, false);
        });
        
        //Separator
        da = new Gtk.DrawingArea();
        da.height_request = 4;
        this.pack_start(da, false, false, 0);
        this.pack_start(notebook, true, true, 0);
        
        //load pre-existing
        foreach(string n in dockable_media_sources.get_keys()) {
            DockableMedia? d = null;
            d = dockable_media_sources.lookup(n);
            if(d == null)
                continue;
            add_page(d);
        }
        media_source_selector.expand_all();
        
        dockable_media_sources.media_removed.connect(on_media_removed);
        dockable_media_sources.media_inserted.connect(on_media_inserted);
        
        DockableMedia? dm_mb = null;
        assert((dm_mb = dockable_media_sources.lookup("MusicBrowserDockable")) != null);
        string dname = dm_mb.name();
        media_source_selector.selected_dockable_media = dname;
    }
    
    private string _media_source_selector_type = "tree";
    public string media_source_selector_type {
        get {
            return _media_source_selector_type;
        }
        set {
            if(value == _media_source_selector_type)
                return;
            _media_source_selector_type = value;
            build_media_selector();
        }
    }
    
    private void build_media_selector() {
        // clear the box and remove all references
        if(media_source_selector_box != null) {
            foreach(Widget w in media_source_selector_box.get_children()) {
                media_source_selector_box.remove(w);
            }
            media_source_selector = null;
            media_source_selector_window = null;
        }
        switch(media_source_selector_type) {
            case "combobox":
                media_source_selector = new ComboMediaSelector();
                media_source_selector_box.add(media_source_selector);
                break;
            default:
                media_source_selector = new TreeMediaSelector();
                var mss_sw = new ScrolledWindow(null, null);
                mss_sw.set_policy(PolicyType.NEVER, PolicyType.NEVER);
                mss_sw.set_border_width(1);
                mss_sw.add(media_source_selector);
                mss_sw.set_shadow_type(ShadowType.IN);
                media_source_selector_box.add(mss_sw);
                media_source_selector_window = mss_sw;
                break;
        }
        media_source_selector.selected_dockable_media = global.active_dockable_media_name;
        media_source_selector.expand_all();
        this.show_all();
    }
    
    private void on_media_removed(string name) {
        remove_page(name);
    }
    
    public void read_params_data() {
        _media_source_selector_type = Params.get_string_value("media_source_selector_type");
    }

    public void write_params_data() {
        Params.set_string_value("media_source_selector_type", media_source_selector_type);
    }
}

