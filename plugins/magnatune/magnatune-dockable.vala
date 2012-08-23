/* magnatune-dockable.vala
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


private class DockableMagnatuneMS : DockableMedia {
    
    private unowned Xnoise.MainWindow win;
    
    public override string name() {
        return MAGNATUNE_MUSIC_STORE_NAME;
    }
    
    public DockableMagnatuneMS() {
        widget = null;
    }

    ~DockableMagnatuneMS() {
        //print("dtor DockableMagnatuneMS\n");
    }
    
    public override string headline() {
        return _("Magnatune");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.STORES;
    }

    public uint ui_merge_id;
    public override Gtk.Widget? create_widget(MainWindow win) {
        this.win = win;
        
        assert(this.win != null);
        var wu = new MagnatuneWidget(this);

        widget = wu;
        wu.show_all();
        return (owned)wu;
    }
    
    public override void remove_main_view() {
    }
    
    public Gtk.ActionGroup action_group;
    
    private uint add_main_window_menu_entry() {
        action_group = new Gtk.ActionGroup("MagnatuneActions");
        action_group.set_translation_domain(Config.GETTEXT_PACKAGE);
        action_group.add_actions(action_entries, this);
        uint reply = 0;
        win.ui_manager.insert_action_group(action_group, 1);
        try {
            reply = win.ui_manager.add_ui_from_string(MENU_UI_STRING, MENU_UI_STRING.length);
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
        }
        return reply;
    }
    
    private static const string MENU_UI_STRING = """
        <ui>
            <menubar name="MainMenu">
                <menu name="ViewMenu" action="ViewMenuAction">
                    <separator />
                    <menuitem action="ShowMagnatuneStore"/>
                </menu>
            </menubar>
        </ui>
    """;
    
    private const Gtk.ActionEntry[] action_entries = {
        { "ViewMenuAction", null, N_("_View") },
            { "ShowMagnatuneStore", null, N_("Show Magnatune Store"), null, N_("Show Magnatune Store"), on_show_store_menu_clicked}
    };
    
    private void on_show_store_menu_clicked() {
        assert(win != null);
        win.msw.select_dockable_by_name(MAGNATUNE_MUSIC_STORE_NAME, true);
    }
    
    public override Gdk.Pixbuf get_icon() {
        Gdk.Pixbuf? icon = null;
        try {
            unowned Gtk.IconTheme thm = Gtk.IconTheme.get_default();
            icon = thm.load_icon("xn-magnatune", 24, IconLookupFlags.FORCE_SIZE);
        }
        catch(Error e) {
            icon = null;
            print("Magnatune icon error: %s\n", e.message);
        }
        return (owned)icon;
    }
}


