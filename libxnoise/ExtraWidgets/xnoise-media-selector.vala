/* xnoise-media-selector.vala
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


public class Xnoise.MediaSelector : TreeView {
    
    public enum Column {
        ICON,
        VIS_TEXT,
        TAB_NO,
        WEIGHT,
        CATEGORY,
        SELECTION_STATE,
        SELECTION_ICON,
        N_COLUMNS
    }
    
    public signal void selection_changed(int selection_number);
    
    public MediaSelector() {
        this.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        this.headers_visible = false;
        this.set_enable_search(false);
        this.get_selection().set_mode(SelectionMode.SINGLE);
        TreeStore media_source_selector_model = new TreeStore(7, 
                                                              typeof(Gdk.Pixbuf),           //icon
                                                              typeof(string),               //vis_text
                                                              typeof(int),                  //tab no.
                                                              typeof(int),                  //weight
                                                              typeof(DockableMedia.Category),
                                                              typeof(bool),                 //selection state
                                                              typeof(Gdk.Pixbuf)            //selection icon
                                                              );
        var column = new TreeViewColumn();
        var renderer = new CellRendererText();
        var rendererPb = new CellRendererPixbuf();
        column.pack_start(rendererPb, false);
        column.pack_start(renderer, true);
        column.add_attribute(rendererPb, "pixbuf", 0);
        column.add_attribute(renderer, "text", 1);
        column.add_attribute(renderer, "weight", 3);
        this.insert_column(column, -1);
        
        column = new TreeViewColumn();
        rendererPb = new CellRendererPixbuf();
        column.pack_start(rendererPb, false);
        this.insert_column(column, -1);
        column.add_attribute(rendererPb, "pixbuf", 6);
        
        this.model = media_source_selector_model;
        
        this.key_release_event.connect(this.on_key_released);
        
        this.button_press_event.connect( (e)  => {
            int x = (int)e.x;
            int y = (int)e.y;
            int cell_x, cell_y;
            TreePath treepath;
            TreeViewColumn co;
            if(!this.get_path_at_pos(x, y, out treepath, out co, out cell_x, out cell_y))
                return true;
            
            TreeIter it;
            TreeStore m = (TreeStore)this.get_model();
            int tab = 0;
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
                m.get(it, Column.TAB_NO, out tab);
                m.set(it,
                      Column.SELECTION_STATE, true,
                      Column.SELECTION_ICON, icon_repo.selected_collection_icon
                );
                selection_changed(tab);
            }
            //media_sources_nb.set_current_page(tab);
            return false;
        });
    }
    
    private const int KEY_CURSOR_DOWN  = 0xFF54;
    private const int KEY_CURSOR_UP    = 0xFF52;
    
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
                        int tab = 0;
                        TreeStore mx = (TreeStore)this.model;
                        mx.get(iter, Column.TAB_NO, out tab);
                        mx.set(iter, 
                              Column.SELECTION_STATE, true,
                              Column.SELECTION_ICON, icon_repo.selected_collection_icon
                        );
                        selection_changed(tab);
                    }
                }
                break;
            default:
                break;
        }
        return false;
    }
}
