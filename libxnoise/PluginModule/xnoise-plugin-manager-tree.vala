/* xnoise-plugin-manager-tree.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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


private class Xnoise.PluginManagerTree: Gtk.TreeView {
    private const string group = "XnoisePlugin";
    private ListStore listmodel;
    private enum Column {
        TOGGLE,
        ICON,
        NAME,
        DESCRIPTION,
        MODULE,
        N_COLUMNS
    }
    private CellRendererText text;
    private TreeViewColumn column;

    private unowned Main xn;

    //TODO: File vala bug: if this is called sign_plugin_active_state_changed compilation fails
    public signal void sign_plugin_activestate_changed(string name);

    public PluginManagerTree() {
        this.xn = Main.instance;
        this.create_model();
        this.create_view();
    }

    private static void text_cell_cb(CellLayout cell_layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        string val;
        string markup_string;
        
        tree_model.get(iter, Column.DESCRIPTION, out val);
        markup_string = Markup.printf_escaped("%s", val);
        
        tree_model.get(iter, Column.NAME, out val);
        markup_string += Markup.printf_escaped("\n<b><small>%s</small></b>", val);
        
        ((CellRendererText)cell).markup = markup_string;
    }

    private void create_view() {
        this.set_size_request(-1, 250);
        this.get_selection().set_mode(SelectionMode.SINGLE);
        var toggle = new CellRendererToggle();
        column = new TreeViewColumn();
        column.pack_start(toggle, false);
        column.add_attribute(toggle, "active", Column.TOGGLE);
        
        toggle.toggled.connect( (c,ps) => {
            print("toggled\n");
            Gtk.TreePath path = new Gtk.TreePath.from_string(ps);
            
            TreeIter iter;
            listmodel.get_iter(out iter, path);
            string module;
            listmodel.get(iter, Column.MODULE, out module);
            
            if(plugin_loader.plugin_htable.lookup(module).activated) 
                plugin_loader.deactivate_single_plugin(module);
            else 
                plugin_loader.activate_single_plugin(module);
                
            unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(module);
            listmodel.set(iter,
                          Column.TOGGLE, p.activated
                          );
            sign_plugin_activestate_changed(module);
        });
        
        this.append_column(column);
        
        var pixbufRenderer = new CellRendererPixbuf();
        column.pack_start(pixbufRenderer, false);
        column.add_attribute(pixbufRenderer, "pixbuf", Column.ICON);
        
        text = new CellRendererText();
        
        column.pack_start(text, true);
        column.add_attribute(text, "text", Column.NAME);
        column.set_cell_data_func(text, text_cell_cb);
        
        this.set_headers_visible(false);
        setup_entries();
        this.set_model(listmodel);
        
        this.get_selection().set_mode(SelectionMode.NONE);
        this.row_activated.connect( (vi,pat,co) => {
            TreeIter iter;
            listmodel.get_iter(out iter, pat);
            string module;
            bool state;
            if(pat != null) {
                this.get_selection().unselect_all();
                this.get_selection().select_path(pat);
            }
            listmodel.get(iter, Column.MODULE, out module, Column.TOGGLE, out state);
            listmodel.set(iter, Column.TOGGLE, !state);
            if(plugin_loader.plugin_htable.lookup(module).activated) 
                plugin_loader.deactivate_single_plugin(module);
            else 
                plugin_loader.activate_single_plugin(module);
                
            unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(module);
            listmodel.set(iter,
                          Column.TOGGLE, p.activated
                          );
            sign_plugin_activestate_changed(module);
        });
    }

    private void setup_entries() {
        foreach(string s in plugin_loader.get_info_files()) {
            string name, description, icon, author, website, license, copyright, module;
            try {
                var kf = new KeyFile();
                kf.load_from_file(s, KeyFileFlags.NONE);
                if(!kf.has_group(group))
                    continue;
                name        = kf.get_string(group, "name"); //TODO: Write this data into cell; maybe info button?
                description = kf.get_locale_string(group, "description");
                module      = kf.get_string(group, "module");
                icon        = kf.get_string(group, "icon");
                author      = kf.get_string(group, "author");
                website     = kf.get_string(group, "website");
                license     = kf.get_string(group, "license");
                copyright   = kf.get_string(group, "copyright");
                
                var invisible = new Gtk.Invisible();
                Gdk.Pixbuf pixbuf = invisible.render_icon(Gtk.Stock.EXECUTE , IconSize.BUTTON, null); //TODO: use plugins' icons
                unowned PluginModule.Container p = null;
                p = plugin_loader.plugin_htable.lookup(module);
                if(p == null)
                    continue;
                p.sign_activated.connect( () => {
                    refresh_tree();
                });
                p.sign_deactivated.connect( () => {
                    refresh_tree();
                });
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.TOGGLE, p.activated,
                              Column.ICON, pixbuf,
                              Column.NAME, name,
                              Column.DESCRIPTION, description,
                              Column.MODULE, module);
            }
            catch(Error e) {
                print("Error plugin information: %s\n", e.message);
            }
        }
    }

    private void refresh_tree() {
        listmodel.foreach(update_acivation_state);
    }
    
    private bool update_acivation_state(TreeModel sender, TreePath path, TreeIter iter) {
        //update activation state
        string? module = null;
        sender.get(iter, Column.MODULE, out module);
        unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(module);
        if(p == null) {
            print("p is null! %s\n", module);
            return true;
        }
        listmodel.set(iter,
                     Column.TOGGLE, p.activated
                     );
        return false;
    }
    
    private void create_model() {
        listmodel = new ListStore(Column.N_COLUMNS,
                                  typeof(bool),
                                  typeof(Gdk.Pixbuf),
                                  typeof(string),
                                  typeof(string),
                                  typeof(string));
    }
}
