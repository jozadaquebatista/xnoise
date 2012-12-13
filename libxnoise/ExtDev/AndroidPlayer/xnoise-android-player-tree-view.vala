/* xnoise-android-player-tree-view.vala
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

using Xnoise;
using Xnoise.ExtDev;



private class Xnoise.ExtDev.AndroidPlayerTreeView : Gtk.TreeView {
    private unowned AndroidPlayerDevice audio_player_device;
    private unowned Cancellable cancellable;
    
    internal AndroidPlayerTreeStore treemodel;
    
    
    public AndroidPlayerTreeView(AndroidPlayerDevice audio_player_device,
                          Cancellable cancellable) {
        this.audio_player_device = audio_player_device;
        this.cancellable = cancellable;
        File b = File.new_for_uri(audio_player_device.get_uri());
        assert(b != null);
        b = b.get_child("Music");
        assert(b != null);
        assert(b.get_path() != null);
        if(b.query_exists(null))
            treemodel = new AndroidPlayerTreeStore(this, audio_player_device, b, cancellable);
        else {
            b = File.new_for_uri(audio_player_device.get_uri());
            b = b.get_child("media"); // old android devices
            treemodel = new AndroidPlayerTreeStore(this, audio_player_device, b, cancellable);
        }
        setup_view();
        
        this.row_activated.connect(this.on_row_activated);
        this.button_press_event.connect(this.on_button_press);
    }
    
    
    private bool on_button_press(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        
        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        if(!(this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y)))
            return true;
        
        switch(e.button) {
            case 1:
                if(selection.count_selected_rows()<=1) {
                    return false;
                }
                else {
                    if(selection.path_is_selected(path)) {
                        if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
                                selection.unselect_path(path);
                        }
                        return true;
                    }
                    else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
                        return true;
                    }
                    return false;
                }
            case 2:
                //print("button 2\n");
                break;
            case 3:
                if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
                    ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
                        return false;
                }
                else {
                    int selectioncount = selection.count_selected_rows();
                    if(selectioncount <= 1) {
                        selection.unselect_all();
                        selection.select_path(path);
                    }
                }
                rightclick_menu_popup(e.time);
                return true;
            }
        if(!(selection.count_selected_rows()>0)) selection.select_path(path);
        return false;
    }

    private Gtk.Menu menu;
    
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
        if(list == null)
            return rightmenu;
        ItemSelectionType itsel;
        if(list.length() > 1)
            itsel = ItemSelectionType.MULTIPLE;
        else
            itsel = ItemSelectionType.SINGLE;
        Item? item = null;
        Array<unowned Action?> array = null;
        TreePath path = (TreePath)list.data;
        treemodel.get_iter(out iter, path);
        treemodel.get(iter, AndroidPlayerTreeStore.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.EXTERNAL_DEVICE_LIST, itsel);
        //print("array.length:::%u\n", array.length);
        for(int i =0; i < array.length; i++) {
            print("%s\n", array.index(i).name);
            var menu_item = new ImageMenuItem.from_stock(array.index(i).stock_item, null);
            menu_item.set_label(array.index(i).info);
            //Value? v = list;
            unowned Action x = array.index(i);
            menu_item.activate.connect( () => {
                x.action(item, null, null);
            });
            rightmenu.append(menu_item);
        }
        rightmenu.show_all();
        return rightmenu;
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            treemodel.get_iter(out iter, treepath);
            treemodel.get(iter, GenericPlayerTreeStore.Column.ITEM, out item);
            if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
               item.type != ItemType.LOCAL_VIDEO_TRACK &&
               item.type != ItemType.STREAM) {
                this.expand_row(treepath, false);
                return;
            }
            global.preview_uri(item.uri);
        }
        else {
            this.expand_row(treepath, false);
        }
    }

    private void on_row_expanded(TreeIter iter, TreePath path) {
        treemodel.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        treemodel.unload_children(ref iter);
    }
    
    private void setup_view() {
        
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
        var column = new TreeViewColumn();
        
        var pixbufRenderer = new CellRendererPixbuf();
        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
        var renderer = new CellRendererText();
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", AndroidPlayerTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", AndroidPlayerTreeStore.Column.VIS_TEXT);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
    }


}
