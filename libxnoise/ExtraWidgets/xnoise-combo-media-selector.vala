/* xnoise-combo-media-selector.vala
 *
 * Copyright (C) 2012  Andi Obergrußberger
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
 *     Andi Obergrußberger <softshaker@googlemail.com>
 */


using Gtk;


/* This is a compact media selector, which uses a ComboBox */

private class Xnoise.ComboMediaSelector : ComboBox, MediaSelector {
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
                              typeof(string),           //icon
                              typeof(string),               //vis_text
                              typeof(int),                  //weight
                              typeof(DockableMedia.Category),
                              typeof(bool),                 //is_separator
                              typeof(string)                //name
                              );
        var renderer = new CellRendererText();
        var rendererPb = new IconCellRenderer();
        
        this.pack_start(rendererPb, false);
        this.pack_start(renderer, true);
        
        this.add_attribute(rendererPb, "icon", Column.ICON);
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
              ComboMediaSelector.Column.ICON, media.get_icon_name(),
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



private class Xnoise.IconCellRenderer : Gtk.CellRendererPixbuf {
    private const int ICONSIZE = 16;
    private const int X_OFFSET = 2;
    
    public string? icon { get; set; default = null; }
    
    public override void render(Cairo.Context cr, Widget widget,
                                Gdk.Rectangle background_area,
                                Gdk.Rectangle cell_area,
                                CellRendererState flags) {
        if(icon == null || icon.strip() == "")
            return;
        Gdk.Pixbuf p = null;
        p = IconRepo.get_themed_pixbuf_icon(icon, ICONSIZE, widget.get_style_context());
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
