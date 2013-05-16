/* xnoise-albumart-view.vala
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

using Xnoise;
using Xnoise.Resources;


private class Xnoise.AlbumArtView : Gtk.IconView, TreeQueryable {
    
    internal static unowned IconCache icon_cache;
    internal IconsModel icons_model;
    private uint col_count_source = 0;
    private uint update_icons_source = 0;
    
    public int get_model_item_column() {
        return (int)IconsModel.Column.ITEM;
    }

    public TreeModel? get_queryable_model() {
        TreeModel? tm = this.get_model();
        return tm;
    }

    public GLib.List<TreePath>? query_selection() {
        return this.get_selected_items();
    }
    
//    public bool in_loading { get; private set; }
    public bool in_import  { get; private set; }
    
    private Gdk.RGBA black_color;
    private bool black = true;
    
    public AlbumArtView(CellArea area) {
        GLib.Object(cell_area:area);
        
        black_color = Gdk.RGBA();
        black_color.red   = 0.0;
        black_color.green = 0.0;
        black_color.blue  = 0.0;
        black_color.alpha  = 1.0;
        
        Gdk.RGBA selc = base.get_style_context().get_background_color(Gtk.StateFlags.PRELIGHT);
        this.override_background_color(StateFlags.NORMAL, black_color);
        this.override_background_color(StateFlags.SELECTED, selc);
        
        this.area = area;
        var font_description = new Pango.FontDescription();
        font_description.set_family("Sans");
        this.set_column_spacing(0);
        this.set_margin(2);
        this.set_item_padding(0);
        this.set_row_spacing(0);
        this.set_spacing(0);
        if(icon_cache == null) {
            icon_cache = global.icon_cache;
        }
        icons_model = new IconsModel(this);
        this.set_item_width(ICON_LARGE_PIXELSIZE);
        this.set_model(icons_model);
        icon_cache.sign_new_album_art_loaded.connect( (p) => {
            print("queue_draw\n");
            queue_draw();
        });
        this.item_activated.connect(this.on_row_activated);
        this.button_press_event.connect(this.on_button_press);
        this.key_release_event.connect(this.on_key_released);
        
        MediaImporter.ResetNotificationData cbr = MediaImporter.ResetNotificationData();
        cbr.cb = reset_change_cb;
        media_importer.register_reset_callback(cbr);
        
        this.notify.connect( (s,p) => {
            if(p.name != "in-import")
                return;
            if(this.in_import) {
                black = false;
                queue_draw();
            }
            else {
                black = true;
                queue_draw();
            }
        });
        
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress) {
                Idle.add(() => {
                    this.in_import = false;
                    this.icons_model.filter();
                    return false;
                });
            }
        });
        
        Idle.add(() => {
            icons_model.populate_model();
            return false;
        });
        Timeout.add_seconds(5, () => {
            in_import = false;
            this.icons_model.filter();
            return false;
        });
    }
    
    private CellArea area = null;

    private void reset_change_cb() {
        Idle.add(() => {
            this.in_import = true;
            this.icons_model.remove_all();
            return false;
        });
    }
    
    private void on_row_activated(Gtk.IconView sender, TreePath path) {
        Item? item = Item(ItemType.UNKNOWN);
        TreeIter iter;
        if(icons_model.get_iter(out iter, path)) {
            icons_model.get(iter, IconsModel.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Action? action = tmp.get_action(item.type, 
                                                    ActionContext.QUERYABLE_TREE_ITEM_ACTIVATED, 
                                                    ItemSelectionType.SINGLE
            );
            
            if(action != null)
                action.action(item, null, null);
            else
                print("action was null\n");
            
            Idle.add(() => {
                main_window.set_bottom_view(0);
                main_window.reset_mainview_to_tracklist();
                return false;
            });
            Idle.add(() => {
                if(global.position_reference == null || !global.position_reference.valid())
                    return false;
                TreePath p = global.position_reference.get_path();
                var store = (ListStore)tlm;
                TreeIter it;
                store.get_iter(out it, p);
                tl.set_focus_on_iter(ref it);
                return false;
            });
        }
    }

    public override bool draw(Cairo.Context cr) {
        
        if(col_count_source != 0)
            Source.remove(col_count_source);
        col_count_source = Timeout.add(100, set_column_count_idle);
        
        if(update_icons_source != 0)
            Source.remove(update_icons_source);
        update_icons_source = Timeout.add(100, () => {
            update_visible_icons();
            update_icons_source = 0;
            return false;
        });
        
        if(black) {
            cr.set_source_rgb(0.0f, 0.0f, 0.0f);
            cr.rectangle(0, 0, get_allocated_width(), get_allocated_height());
            cr.fill();
        }
        base.draw(cr);
        return true;
    }
    
    public void update_visible_icons() {
        TreePath? start_path = null, end_path = null;
        TreeIter iter;
        IconsModel.IconState state;
        string artist, album, pth;
        if(this.get_visible_range(out start_path, out end_path)) {
            do {
                this.icons_model.get_iter(out iter, start_path);
                start_path.next();
                
                this.icons_model.get(iter,
                                     IconsModel.Column.STATE, out state,
                                     IconsModel.Column.ARTIST, out artist,
                                     IconsModel.Column.ALBUM, out album,
                                     IconsModel.Column.IMAGE_PATH, out pth
                );
                if(state == IconsModel.IconState.RESOLVED)
                    continue;
                
                Gdk.Pixbuf? art = null;
                File? f = null;
                if(pth != null && pth != "")
                    f = File.new_for_path(pth);
                
                if(f == null) {
                    continue;
                }
                
                art = icon_cache.get_image(f.get_path());
                if(art == null) {
                    continue;
                }
                else {
                    this.icons_model.set(iter, 
                                         IconsModel.Column.ICON, art,
                                         IconsModel.Column.STATE, IconsModel.IconState.RESOLVED
                    );
                }
            } while(start_path != null && start_path.get_indices()[0] <= end_path.get_indices()[0]);
        }
    }
    
    private Gtk.Menu menu;
    
    private int w = 0;
    private int w_last = 0;
    private bool set_column_count_idle() {
        w = this.get_allocated_width();
        if(w == w_last) {
            col_count_source = 0;
            return false;
        }
        this.set_columns(3);
        this.set_columns(-1);
        w_last = w;
        col_count_source = 0;
        return false;
    }

    private bool on_button_press(Gdk.EventButton e) {
        if(e.button==1 && e.type == Gdk.EventType.@2BUTTON_PRESS) {
            TreePath tp = this.get_path_at_pos((int)e.x, (int)e.y).copy();
            on_row_activated(this, tp);
            return true;
        }
        Gtk.TreePath treepath = null;
        GLib.List<TreePath> selection = this.get_selected_items();
        int x = (int)e.x;
        int y = (int)e.y;
        
        if((treepath = this.get_path_at_pos(x, y)) == null)
            return true;
        
        switch(e.button) {
            case 1:
                break;
            case 3: {
                TreeIter iter;
                this.get_model().get_iter(out iter, treepath);
                bool in_sel = false;
                foreach(var px in selection) {
                    if(treepath == px) {
                        in_sel = true;
                        break;
                    }
                }
                if(!(in_sel)) {
                    this.unselect_all();
                    this.select_path(treepath);
                }
                rightclick_menu_popup(e.time);
                return true;
            }
            default: {
                break;
            }
        }
        if(selection.length() <= 0 )
            this.select_path(treepath);
        return false;
    }

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//        print("%d\n",(int)e.keyval);
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

    private void rightclick_menu_popup(uint activateTime) {
        menu = create_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, activateTime);
    }

    private Gtk.Menu create_rightclick_menu() {
        TreeIter iter;
        var rightmenu = new Gtk.Menu();
        GLib.List<TreePath> list;
        list = this.get_selected_items();
        ItemSelectionType itemselection = ItemSelectionType.SINGLE;
        if(list.length() > 1)
            itemselection = ItemSelectionType.MULTIPLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        this.get_model().get_iter(out iter, path);
        this.get_model().get(iter, IconsModel.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.QUERYABLE_TREE_MENU_QUERY, itemselection);
        for(int i =0; i < array.length; i++) {
            unowned Action x = array.index(i);
            //print("%s\n", x.name);
            var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? x.stock_item : Gtk.Stock.INFO), null);
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

