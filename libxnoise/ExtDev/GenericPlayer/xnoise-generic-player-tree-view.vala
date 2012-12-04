/* xnoise-generic-player-tree-view.vala
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



private class Xnoise.ExtDev.GenericPlayerTreeView : Gtk.TreeView {
    private GenericPlayerTreeStore treemodel;
    private unowned GenericPlayerDevice player_device;
    private unowned Cancellable cancellable;
    
    
    public GenericPlayerTreeView(GenericPlayerDevice player_device,
                                 Cancellable cancellable) {
        this.player_device = player_device;
        this.cancellable = cancellable;
        File[] dirs = {};
        foreach(string fd in player_device.player_folders) {
            var f = File.new_for_uri(fd);
            dirs += f;
        }
        treemodel = new GenericPlayerTreeStore(this, dirs, cancellable);
        setup_view();
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
        column.add_attribute(pixbufRenderer, "pixbuf", GenericPlayerTreeStore.Column.ICON);
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", GenericPlayerTreeStore.Column.VIS_TEXT);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
    }


}
