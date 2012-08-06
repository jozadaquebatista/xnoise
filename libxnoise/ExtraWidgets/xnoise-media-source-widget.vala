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

public class Xnoise.MediaSoureWidget : Gtk.Box {
    
    private Gtk.Notebook notebook;
    private unowned Xnoise.MainWindow mwindow;
    private unowned HashTable<string,DockableMedia> media_sources;
    
    public Gtk.Entry search_entry              { get; private set; }
    public MediaSelector media_source_selector { get; private set; }
    
    public MediaSoureWidget(Xnoise.MainWindow mwindow, HashTable<string,DockableMedia>? media_sources) {
        Object(orientation:Orientation.VERTICAL, spacing:0);
        assert(media_sources != null);
        this.media_sources = media_sources;
        this.mwindow = mwindow;
        
        setup_widgets();
    }

    private string? get_category_name(DockableMedia.Category category) {
        switch(category) {
            case DockableMedia.Category.MEDIA_COLLECTION:
                return _("Media Collections");
            case DockableMedia.Category.PLAYLIST:
                return _("Playlists");
            case DockableMedia.Category.STORES:
                return _("Stores");
            case DockableMedia.Category.DEVICES:
                return _("Devices");
            case DockableMedia.Category.UNKNOWN:
            default:
                return null;
        }
    }
    
    public void select_dockable_by_name(string name) {
        DockableMedia? d = media_sources.lookup(name);
        if(d == null) {
            print("dockable %s does not exist\n", name);
            return;
        }
        notebook.set_current_page(notebook.page_num(d.get_widget(mwindow)));
    }
    
    public void insert_dockable(DockableMedia d) {
        TreeIter? ix = null;
        if(media_sources.lookup(d.name()) != null)
            return; // already inside
        media_sources.insert(d.name(), d);
        _insert_dockable(d, false, ref ix, false);
        media_source_selector.expand_all();
    }
    
    public void remove_dockable(string name) {
        TreeStore m = (TreeStore)media_source_selector.get_model();
        string? iname = null;
        m.foreach( (m,p,i) => {
            if(p.get_depth() == 2) {
                m.get(i, MediaSelector.Column.NAME, out iname);
                if(name == iname) {
                    TreePath pc = m.get_path(i);
                    pc.up();
                    TreeIter parent_iter;
                    m.get_iter(out parent_iter, pc);
                    if(m.iter_n_children(parent_iter) == 1)
                        ((TreeStore)m).remove(parent_iter);
                    else
                        ((TreeStore)m).remove(i);
                    DockableMedia? d = media_sources.lookup(name);
                    d.remove_main_view();
                    notebook.remove_page(notebook.page_num(d.get_widget(mwindow)));
                    media_sources.remove(name);
                    return true;
                }
            }
            return false;
        });
    }

    private void _insert_dockable(DockableMedia d, bool bold = false, ref TreeIter? xiter, bool initial_selection = false) {
        Gtk.Widget? widg = d.get_widget(mwindow);
        if(widg == null) {
            xiter = null;
            return;
        }
        widg.show_all();
        notebook.append_page(widg, null);
        var category = d.category();
        TreeStore m = (TreeStore)media_source_selector.get_model();
        TreeIter iter = TreeIter(), child;
        
        // Add Category, if necessary
        bool found_category = false;
        m.foreach( (m,p,i) => {
            if(p.get_depth() == 1) {
                DockableMedia.Category cat;
                m.get(i, MediaSelector.Column.CATEGORY , out cat);
                if(cat == category) {
                    found_category = true;
                    iter = i;
                    return true;
                }
            }
            return false;
        });
        if(!found_category) {
            print("add new category %s\n", get_category_name(category));
            m.append(out iter, null);
            m.set(iter,
                  MediaSelector.Column.ICON, null,
                  MediaSelector.Column.VIS_TEXT, get_category_name(category),
                  MediaSelector.Column.WEIGHT, Pango.Weight.BOLD,
                  MediaSelector.Column.CATEGORY, category,
                  MediaSelector.Column.SELECTION_STATE, false,
                  MediaSelector.Column.SELECTION_ICON, null,
                  MediaSelector.Column.NAME, ""
            );
        }
        
        //insert dockable info
        m.append(out child, iter);
        m.set(child,
              MediaSelector.Column.ICON, d.get_icon(),
              MediaSelector.Column.VIS_TEXT, d.headline(),
              MediaSelector.Column.WEIGHT, Pango.Weight.NORMAL,
              MediaSelector.Column.CATEGORY, category,
              MediaSelector.Column.SELECTION_STATE, initial_selection,
              MediaSelector.Column.SELECTION_ICON, (initial_selection ? icon_repo.selected_collection_icon : null),
              MediaSelector.Column.NAME, d.name()
        );
        xiter = child;
    }

    private void setup_widgets() {
        this.search_entry = new Gtk.Entry(); // media_source_widget.search_entry;
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
        notebook.set_border_width(0);
        notebook.show_border = false;
            
        media_source_selector = new MediaSelector();
        media_source_selector.selection_changed.connect( (s,t) => {
            select_dockable_by_name(t);
            //notebook.set_current_page(t);
        });
        var mss_sw = new ScrolledWindow(null, null);
        mss_sw.set_policy(PolicyType.NEVER, PolicyType.NEVER);
        mss_sw.add(media_source_selector);
        mss_sw.set_shadow_type(ShadowType.IN);
        this.pack_start(mss_sw, false, false, 0);
        
        //Separator
        da = new Gtk.DrawingArea();
        da.height_request = 4;
        this.pack_start(da, false, false, 0);
        
        unowned DockableMedia? dm_mb = null;
        assert((dm_mb = media_sources.lookup("MusicBrowserDockable")) != null);
        this.pack_start(notebook, true, true, 0);
        //Insert Media Browser first
        TreeIter? media_browser_iter = null;
        _insert_dockable(dm_mb, true, ref media_browser_iter, true);
        string dname = dm_mb.name();
        global.active_dockable_media_name = dname;
        media_source_selector.selected_dockable_media = dname;
        
        foreach(unowned string n in media_sources.get_keys()) {
            if(n == "MusicBrowserDockable")
                continue;
            
            unowned DockableMedia? d = null;
            d = media_sources.lookup(n);
            if(d == null)
                continue;
            TreeIter? ix = null;
            _insert_dockable(d, false, ref ix, false);
        }
        media_source_selector.expand_all();
        media_source_selector.get_selection().select_iter(media_browser_iter);
    }
}


public class Xnoise.MediaSelector : TreeView {
    
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
    
    public signal void selection_changed(string dockable_name); //int selection_number
    
    public MediaSelector() {
        selected_dockable_media = "";
        //this.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        this.headers_visible = false;
        this.set_enable_search(false);
        this.get_selection().set_mode(SelectionMode.SINGLE);
        TreeStore media_source_selector_model = new TreeStore(Column.N_COLUMNS, 
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
        this.insert_column(column, -1);
        column.add_attribute(rendererPb, "pixbuf", Column.SELECTION_ICON);
        
        this.model = media_source_selector_model;
        
        this.key_release_event.connect(this.on_key_released);
        
        this.button_press_event.connect(this.on_button_pressed);
        
        this.notify["selected-dockable-media"].connect( () => {
            global.active_dockable_media_name = selected_dockable_media;
        });
    }
    
    private const int KEY_CURSOR_DOWN  = 0xFF54;
    private const int KEY_CURSOR_UP    = 0xFF52;
    
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
            selection_changed(name);
        }
        return false;
    }
    
    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
        //print("%d\n",(int)e.keyval);
        Gtk.TreeModel m;
        switch(e.keyval) {
            case KEY_CURSOR_UP:
            case KEY_CURSOR_DOWN:
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
                        selection_changed(name);
                    }
                }
                break;
            default:
                break;
        }
        return false;
    }
}
