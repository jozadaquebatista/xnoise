/* ubuntuone.vala
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
using U1;

using Xnoise;
using Xnoise.Resources;
using Xnoise.PluginModule;


private static const string UBUNTUONE_MUSIC_STORE_NAME = "UbuntuOneMusicStore";

public class UbuntuOnePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private unowned PluginModule.Container _owner;
    private UbuMusicStore music_store;

    construct {
    }

    public PluginModule.Container owner {
        get { return _owner;  }
        set { _owner = value; }
    }
    
    public string name { get { return "ubuntuone_music_store"; } }
    
    public bool init() {
        this.music_store = new UbuMusicStore();
        owner.sign_deactivated.connect(clean_up);
        return true;
    }
    
    public void uninit() {
        clean_up();
    }

    private void clean_up() {
        owner.sign_deactivated.disconnect(clean_up);
        music_store = null;
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }
}



private class UStore : U1.MusicStore, Xnoise.IMainView {
    
    public UStore() {
        GLib.Object();
    }
    
    public string get_view_name() {
        return UBUNTUONE_MUSIC_STORE_NAME;
    }
    
    ~UStore() {
        print("DTOR USTORE\n");
    }
}



private class DockableUbuntuOneMS : DockableMedia {
    
    public override string name() {
        return UBUNTUONE_MUSIC_STORE_NAME;
    }
    
    private UStore ms;
    private unowned Xnoise.MainWindow win;
    
    public DockableUbuntuOneMS() {
        //print("construt ubu dokable\n");
    }

    private void disconnect_signals() {
        if(ms == null)
            return;
        ms.preview_mp3.disconnect(on_preview_mp3);
        ms.play_library.disconnect(on_play_library);
        ms.download_finished.disconnect(on_download_finished); 
        ms.url_loaded.disconnect(on_url_loaded);
    }
    
    ~DockableUbuntuOneMS() {
        //print("dtor UBUNTUONE_MUSIC_STORE dockable\n");
        widget = null;
    }
    
    public override string headline() {
        return _("UbuntuOne Music");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.STORES;
    }

    public uint ui_merge_id;
    public override Gtk.Widget? create_widget(MainWindow win) {
        this.win = win;
        
        assert(this.win != null);
        var wu = new Label("UbuntuOne Music");
        
        win.msw.selection_changed.connect(on_selection_changed);
        widget = wu;
        wu.show_all();
        return wu;
    }
    
    private void on_selection_changed(string dname) {
        if(dname == UBUNTUONE_MUSIC_STORE_NAME) {
            if(ms == null) {
                ms = new UStore();
                //Signals
                ms.preview_mp3.connect(on_preview_mp3);// working
                ms.play_library.connect(on_play_library);
                ms.download_finished.connect(on_download_finished); 
                ms.url_loaded.connect(on_url_loaded); // working
                assert(win != null);
                assert(win.mainview_box != null);
                if(ms.parent == null)
                    win.mainview_box.add_main_view(ms);
                ms.show();
                ui_merge_id = add_main_window_menu_entry();
                
                Xnoise.media_importer.import_media_folder(ms.get_library_location());
                //print("ui_merge_id:%u\n", ui_merge_id);
            }
            Idle.add( () => {
                assert(win != null);
                assert(win.mainview_box != null);
                win.mainview_box.select_main_view(ms.get_view_name());
                return false;
            });
        }
        else {
            if(ms == null)
                return;
            assert(win != null);
            assert(win.mainview_box != null);
            if(win.mainview_box.get_current_main_view_name() == UBUNTUONE_MUSIC_STORE_NAME)
                win.mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
        }
    }
    
    public override void remove_main_view() {
        disconnect_signals();
        assert(win != null);
        if(ms == null)
            return;
        win.msw.selection_changed.disconnect(this.on_selection_changed);
        win.mainview_box.remove_main_view(ms);
        ms = null;
    }
    
    public Gtk.ActionGroup action_group;
    
    private uint add_main_window_menu_entry() {
        action_group = new Gtk.ActionGroup("UbuntuOneActions");
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
                    <menuitem action="ShowUbuntuOneStore"/>
                </menu>
            </menubar>
        </ui>
    """;
    
    private const Gtk.ActionEntry[] action_entries = {
        { "ViewMenuAction", null, N_("_View") },
            { "ShowUbuntuOneStore", "ubuntuone", N_("Show _UbuntuOne Store"), null, N_("Show UbuntuOne Store"), on_show_store_menu_clicked}
    };
    
    private void on_show_store_menu_clicked() {
        assert(win != null);
        win.msw.select_dockable_by_name(UBUNTUONE_MUSIC_STORE_NAME, true);
    }

    private void on_preview_mp3(string uri, string title) {
        global.preview_uri(uri);
        string ti = title;
        global.current_album  = null;
        global.current_artist = null;
        global.current_title  = null;
        Timeout.add_seconds(1, () => {
            global.current_title  = ti;
            return false;
        });
    }

    private void on_play_library(string path) {
        print("on_play_library::%s\n", path);
    }
    
    private void on_url_loaded(string url) {
        print("on_url_loaded::%s\n", url);
    }
    
    private void on_download_finished(string path) {
        print("on_download_finished::%s\n", path);
        Xnoise.media_importer.import_media_folder(ms.get_library_location());
    }
    
    public override Gdk.Pixbuf get_icon() {
        Gdk.Pixbuf? icon = null;
        try {
            icon = Gtk.IconTheme.get_default().load_icon("ubuntuone", 24, IconLookupFlags.FORCE_SIZE);
        }
        catch(Error e) {
            print("Ubuntu one icon error: %s\n", e.message);
        }
        return icon;
    }
}



//The Ubuntu One Music Store.
private class UbuMusicStore : GLib.Object {
    
    public UbuMusicStore()  {
        main_window.msw.insert_dockable(new DockableUbuntuOneMS());
    }
    
    ~UbuMusicStore() {
        main_window.msw.select_dockable_by_name("MusicBrowserDockable");
        unowned DockableUbuntuOneMS msd = 
            (DockableUbuntuOneMS)dockable_media_sources.lookup(UBUNTUONE_MUSIC_STORE_NAME);
        if(msd == null)
            return;
        if(msd.action_group != null) {
            main_window.ui_manager.remove_action_group(msd.action_group);
            msd.action_group = null;
        }
        if(msd.ui_merge_id != 0)
            main_window.ui_manager.remove_ui(msd.ui_merge_id);
        main_window.msw.remove_dockable_in_idle(UBUNTUONE_MUSIC_STORE_NAME);
    }
}

