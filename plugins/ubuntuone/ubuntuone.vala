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
using Xnoise.Services;
using Xnoise.PluginModule;


private static const string UBUNTUONE_MUSIC_STORE_NAME = "UbuntuOneMusicStore";

public class UbuntuOnePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private unowned PluginModule.Container _owner;
    private MusicStore music_store;

    construct {
        this.music_store = new MusicStore(this);
    }

    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }
    
    public string name { get { return "ubuntuone_music_store"; } }

    public bool init() {
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


private class DockableUbuntuOneMS : DockableMedia {
    
    public override string name() {
        return UBUNTUONE_MUSIC_STORE_NAME;
    }
    
    private U1.MusicStore ms;
    private unowned Xnoise.MainWindow win;
    
    ~DockableUbuntuOneMS() {
        int ms_num = win.tracklistnotebook.page_num(ms);
        if(ms_num > -1)
            win.tracklistnotebook.remove_page(ms_num);
        ms = null;
        if(ui_merge_id != 0)
            win.ui_manager.remove_ui(ui_merge_id);
        Idle.add( () => {
            win.tracklistnotebook.set_current_page(0);
            return false;
        });
    }
    
    public override string headline() {
        return _("UbuntuOne Music Store");
    }
    
    public override DockableMedia.Category category() {
        return DockableMedia.Category.STORES;
    }

    private Widget? w = null;
    private uint ui_merge_id;
    public override unowned Gtk.Widget? get_widget(MainWindow win) {
        this.win = win;
        unowned Widget wu = w;
        if(w != null)
            return wu;
        
        w = new Label("Ubuntu One Music Store");
        
        win.msw.media_source_selector.selection_changed.connect( (s,t) => {
            if(t == UBUNTUONE_MUSIC_STORE_NAME) {
                if(ms == null) {
                    ms = new U1.MusicStore();
                    //Signals
                    //ms.preview_mp3.connect(on_preview_mp3); // doesn't work for a strange reason
                    Signal.connect((void*)ms, "preview-mp3", (GLib.Callback)on_preview_mp3, (void*)this);
                    ms.play_library.connect(on_play_library);
                    ms.download_finished.connect(on_download_finished); 
                    ms.url_loaded.connect(on_url_loaded); // working
                    
                    if(ms.parent == null)
                        win.tracklistnotebook.append_page(ms, null);
                    ms.show();
                    ui_merge_id = add_main_window_menu_entry();
                }
                Idle.add( () => {
                    int ms_num = win.tracklistnotebook.page_num(ms);
                    ms.visible = true;
                    win.tracklistnotebook.set_current_page(ms_num);
                    return false;
                });
            }
            else {
                Idle.add( () => {
                    win.tracklistnotebook.set_current_page(0);
                    ms.visible = false;
                    return false;
                });
            }
        });
        wu = w;
        return wu;
    }
    
    public override void remove_main_view() {
        int ms_num = win.tracklistnotebook.page_num(ms);
        if(ms_num > -1)
            win.tracklistnotebook.remove_page(ms_num);
    }
    
    private Gtk.ActionGroup action_group;
    
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
        print("ubu show\n");
//        win.select_view_by_name(UBUNTUONE_MUSIC_STORE_NAME);
    }

    private void on_preview_mp3(string uri, string title) {
        global.stop(); // if playing from tracklist
        gst_player.stop(); // for tracklist-less playing
        Timeout.add_seconds(1, () => {
            gst_player.uri = uri;
            gst_player.play();
            Timeout.add_seconds(1, () => {
                print("set title %s\n", title);
                global.current_title = title;
                string _uri = uri;
                win.set_displayed_title(ref _uri, "title", title);
                return false;
            });
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
public class MusicStore : GLib.Object {
    private unowned UbuntuOnePlugin plugin;
    
    public MusicStore(UbuntuOnePlugin plugin) {
        this.plugin = plugin;
        DockableMedia d = new DockableUbuntuOneMS();
        main_window.msw.insert_dockable(d);
    }
    
    ~MusicStore() {
        main_window.msw.remove_dockable(UBUNTUONE_MUSIC_STORE_NAME);
    }
}

