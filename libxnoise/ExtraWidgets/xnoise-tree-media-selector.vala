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
    private TreeStore store;
    private bool mouse_over = false;
    private int row_height = 23;
    
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
        TreeViewColumn first_col = column;
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
        
        Timeout.add_seconds(1, () => {
            if(this.get_window() == null)
                return true;
            var path = new Gtk.TreePath.first();
            Gdk.Rectangle rect = Gdk.Rectangle();
            this.get_cell_area(path, first_col, out rect);
            row_height = rect.height;
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
        Timeout.add(200, () => {
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
    private int STEPSIZE = 10;
    public override void get_preferred_height(out int minimum_height, out int natural_height) {
        base.get_preferred_height(out l_minimum_height, out l_natural_height);
        if(mouse_over) { // SHOWING
            if(height_last < l_natural_height) {
                if(height_last < row_height)
                    height_last = row_height;
                natural_height = minimum_height = (height_last = height_last + STEPSIZE);
                Timeout.add(40, () => {
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
                natural_height = minimum_height = (height_last = height_last - STEPSIZE);
                Timeout.add(40, () => {
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

