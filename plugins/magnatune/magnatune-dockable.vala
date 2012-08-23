
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


