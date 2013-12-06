/* xnoise-settings-widget.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
using Xnoise.PluginModule;
using Xnoise.Resources;


private class Xnoise.SettingsWidget : Gtk.Box {
    private Builder builder;
    private const string SETTINGS_UI_FILE = Config.XN_UIDIR + "settings.ui";
    private Notebook notebook;
//    private SpinButton sb;
//    private int fontsizeMB;
    private CheckButton switch_useLyrics;
    private CheckButton switch_usetray;
//    private CheckButton switch_compact;
//    private CheckButton switch_usestop;
    private CheckButton switch_quitifclosed;
//    private CheckButton switch_use_notifications;
//    private CheckButton switch_compact_media_selector;
    private CheckButton switch_continue_last_song;
    private AddMediaWidget add_media_widget;
    private SizeGroup plugin_label_sizegroup;
    
    private enum NotebookTabs {
        GENERAL = 0,
        MEDIA,
        N_FIXED_TABS
    }

    private enum DisplayColums {
        TOGGLE,
        TEXT,
        N_COLUMNS
    }
    
    public signal void sign_finish();
    public void select_general_tab() {
        if(this.notebook == null)
            return;
        this.notebook.set_current_page(NotebookTabs.GENERAL);
    }
    
    public SettingsWidget() {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.setup_widgets();
        initialize_members();
        connect_signals();
    }
    
    private void connect_signals() {
//        assert(switch_usestop != null);
//        switch_usestop.clicked.connect(this.on_checkbutton_usestop_clicked);
        
        assert(switch_useLyrics != null);
        switch_useLyrics.clicked.connect(this.on_checkbutton_use_lyrics_clicked);
        
        assert(switch_usetray != null);
        switch_usetray.clicked.connect(this.on_checkbutton_usetray_clicked);
        
//        assert(switch_compact != null);
//        switch_compact.clicked.connect(this.on_checkbutton_compact_clicked);
        
        assert(switch_quitifclosed != null);
        switch_quitifclosed.clicked.connect(this.on_checkbutton_quitifclosed_clicked);
        
//        assert(switch_use_notifications != null);
//        switch_use_notifications.clicked.connect(this.on_switch_use_notifications_clicked);
        
//        assert(switch_compact_media_selector != null);
//        switch_compact_media_selector.clicked.connect(this.on_switch_compact_media_selector_clicked);
        
        assert(switch_continue_last_song != null);
        switch_continue_last_song.clicked.connect(this.on_switch_continue_last_song_clicked);
        
//        sb.changed.connect(this.on_mb_font_changed);
    }

    private void initialize_members() {
        //Visible Cols
        
        //Treelines
        switch_useLyrics.active = Params.get_bool_value("use_lyrics");
        
        switch_usetray.active = !Params.get_bool_value("not_use_systray");
        
        //compact layout / Application menu
//        switch_compact.active = Params.get_bool_value("compact_layout");
        
        //use stop button
        switch_quitifclosed.active = Params.get_bool_value("quit_if_closed");
        
//        switch_usestop.active = Params.get_bool_value("usestop");
        
//        switch_use_notifications.active = !Params.get_bool_value("not_use_notifications");
        
//        if(Params.get_string_value("media_source_selector_type") == "combobox")
//            switch_compact_media_selector.active = true;
//        else
//            switch_compact_media_selector.active = false;
        
        switch_continue_last_song.active = Params.get_bool_value("continue_last_song");
    }

    private void on_checkbutton_usetray_clicked() {
        if(this.switch_usetray.active) {
            Params.set_bool_value("not_use_systray", false);
            tray_icon.visible = true;
        }
        else {
            Params.set_bool_value("not_use_systray", true);
            tray_icon.visible = false;
        }
    }
    
    private void on_checkbutton_use_lyrics_clicked() {
        if(this.switch_useLyrics.active) {
            Params.set_bool_value("use_lyrics", true);
            main_window.active_lyrics = true;
        }
        else {
            Params.set_bool_value("use_lyrics", false);
            main_window.active_lyrics = false;
        }
    }
//    
//    private void on_checkbutton_compact_clicked() {
//        if(this.switch_compact.active) {
//            Params.set_bool_value("compact_layout", true);
//            main_window.compact_layout = true;
//        }
//        else {
//            Params.set_bool_value("compact_layout", false);
//            main_window.compact_layout = false;
//        }
//    }
    
//    private void on_switch_use_notifications_clicked() {
//        if(this.switch_use_notifications.active) {
//            Params.set_bool_value("not_use_notifications", false);
//            Main.instance.use_notifications = true;
//        }
//        else {
//            Params.set_bool_value("not_use_notifications", true);
//            Main.instance.use_notifications = false;
//        }
//    }
    
    private void on_checkbutton_quitifclosed_clicked() {
        if(this.switch_quitifclosed.active) {
            Params.set_bool_value("quit_if_closed", true);
        }
        else {
            Params.set_bool_value("quit_if_closed", false);
        }
    }
    
//    private void on_checkbutton_usestop_clicked() {
//        if(this.switch_usestop.active) {
//            Params.set_bool_value("usestop", true);
//            main_window.usestop = true;
//        }
//        else {
//            Params.set_bool_value("usestop", false);
//            main_window.usestop = false;
//        }
//    }
//    
//    private void on_switch_compact_media_selector_clicked() {
//        if(!this.switch_compact_media_selector.active) {
//            Params.set_string_value("media_source_selector_type", "tree");
//            main_window.msw.media_source_selector_type = "tree";
//        }
//        else {
//            Params.set_string_value("media_source_selector_type", "combobox");
//            main_window.msw.media_source_selector_type = "combobox";
//        }
//    }

    private void on_switch_continue_last_song_clicked() {
        if(this.switch_continue_last_song.active) {
            Params.set_bool_value("continue_last_song", true);
        }
        else {
            Params.set_bool_value("continue_last_song", false);
        }
    }

    private void add_plugin_tabs() {
        int count = 0;
        
        foreach(string name in plugin_loader.plugin_htable.get_keys()) {
            unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(name);
            if((p.activated) && (p.configurable)) {
                Widget? w = p.settingwidget();
                
                if(w!=null) {
                    string n = name.substring(0, 1).up() + name.substring(1, name.length - 1);
                    var l = new Gtk.Label(n);
                    l.max_width_chars = 10;
                    sg_tab.add_widget(l);
                    var scw = new ScrolledWindow(null, null);
                    scw.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
                    scw.add_with_viewport(w);
                    notebook.append_page(scw, l);
                    scw.show_all();
                }
                
                count++;
            }
        }
        this.number_of_tabs = NotebookTabs.N_FIXED_TABS + count;
    }
    
    public void select_media_tab() {
        if(this.notebook == null)
            return;
        print("select media tab\n");
        this.notebook.set_current_page(NotebookTabs.MEDIA);
    }

    private void remove_plugin_tabs() {
        //remove all plugin tabs, before re-adding them
        int number_of_plugin_tabs = notebook.get_n_pages();
        for(int i = NotebookTabs.N_FIXED_TABS; i < number_of_plugin_tabs; i++) {
            notebook.remove_page(-1); //remove last page
        }
    }

    private int number_of_tabs;
    private void reset_plugin_tabs(string name) {
        //just remove all dynamically added tabs and recreate them
        remove_plugin_tabs();
        add_plugin_tabs();
        this.show_all();
    }

    private SizeGroup sg_tab = new SizeGroup(SizeGroupMode.HORIZONTAL);
    
    private bool setup_widgets() {
        builder = new Builder();
        try {
            this.builder.add_from_file(SETTINGS_UI_FILE);
            
            var general_label = this.builder.get_object("label1") as Gtk.Label;
            general_label.set_text(_("General"));
            var media_label = this.builder.get_object("media_label") as Gtk.Label;
            media_label.set_text(_("Media"));
            sg_tab.add_widget(media_label);
            
            plugin_label_sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
            
            switch_useLyrics = this.builder.get_object("cb_uselyrics") as Gtk.CheckButton;
            switch_useLyrics.can_focus = false;
            switch_useLyrics.set_label(_("Download lyrics"));
            switch_useLyrics.tooltip_text = _("Automatic lyrics fetching from the internet");
//            
            switch_usetray = this.builder.get_object("cb_usetray") as Gtk.CheckButton;
            switch_usetray.can_focus = false;
            switch_usetray.set_label(_("Use systray icon"));
            switch_usetray.tooltip_text = _("Use a status icon on your panel for showing, hiding and controlling xnoise");
            
//            switch_compact = this.builder.get_object("cb_compact") as CheckButton;
//            switch_compact.can_focus = false;
//            switch_compact.set_label(_("Use menu button"));
//            switch_compact.tooltip_text = _("Use an application menu button integrated into the main window");
            
//            switch_usestop = this.builder.get_object("cb_usestop") as CheckButton;
//            switch_usestop.can_focus = false;
//            switch_usestop.set_label(_("Show Stop button"));
//            switch_usestop.tooltip_text = _("Show a stop button along with the other playback control buttons");
//            
            switch_quitifclosed = this.builder.get_object("cb_quitifclosed") as CheckButton;
            switch_quitifclosed.can_focus = false;
            switch_quitifclosed.set_label(_("Quit on window close"));
            switch_quitifclosed.tooltip_text = _("Quit xnoise if the main window is closed");

//            switch_use_notifications = this.builder.get_object("cb_use_notifications") as CheckButton;
//            switch_use_notifications.can_focus = false;
//            switch_use_notifications.set_label(_("Use desktop notifications"));
//            switch_use_notifications.tooltip_text = _("Use desktop notifications that inform about played media while the main window of xnoise is not visible");
            
//            switch_compact_media_selector = this.builder.get_object("cb_compact_media_selector") as CheckButton;
//            switch_compact_media_selector.can_focus = true;
//            switch_compact_media_selector.set_label(_("Use combo box selector for media types"));
//            switch_compact_media_selector.tooltip_text = _("Use a combo box for selecting media types like music, video or streams");
            
            switch_continue_last_song = this.builder.get_object("cb_continue_last_song") as CheckButton;
            switch_continue_last_song.can_focus = true;
            switch_continue_last_song.set_label(_("Continue with last played song"));
            switch_continue_last_song.tooltip_text = _("After restart continue with last played song");
            
            notebook = this.builder.get_object("notebook1") as Gtk.Notebook;
            notebook.scrollable = false;
            notebook.show_border = false;
            this.add(notebook);

//            var fontsize_label = this.builder.get_object("fontsize_label") as Gtk.Label;
//            fontsize_label.label = _("Media browser fontsize");
            
//            sb = this.builder.get_object("spinbutton1") as Gtk.SpinButton;
//            sb.configure(new Gtk.Adjustment(8.0, 7.0, 14.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
//            sb.set_numeric(true);
            
            var mediabox = this.builder.get_object("mediabox") as Gtk.Box;
            add_media_widget = new AddMediaWidget();
            mediabox.pack_start(add_media_widget, true, true, 0);
            var web_service_box = this.builder.get_object("web_service_box") as Gtk.Box;
            var web_service_parent_box = this.builder.get_object("box21") as Gtk.Box;
            var lyric_provider_box = this.builder.get_object("lyric_provider_box") as Gtk.Box;
            var lyric_parent_box = this.builder.get_object("box20") as Gtk.Box;
            var additionals_box = this.builder.get_object("box22") as Gtk.Box;
            var additionals_parent_box = this.builder.get_object("additionals_box") as Gtk.Box;
            var gui_box = this.builder.get_object("box6") as Gtk.Box;
            var gui_parent_box = this.builder.get_object("box5") as Gtk.Box;
            
            //Category headlines
            var gui_label = this.builder.get_object("label2") as Gtk.Label;
            gui_label.use_markup = true;
            gui_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("User Interface:")));
            
            var lyric_provider_label = this.builder.get_object("lyric_provider_label") as Gtk.Label;
            lyric_provider_label.use_markup = true;
            lyric_provider_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("Lyrics:")));
            
            var additionals_label = this.builder.get_object("additionals_label") as Gtk.Label;
            additionals_label.use_markup = true;
            additionals_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("Additional:")));
            
            var web_service_label = this.builder.get_object("web_service_label") as Gtk.Label;
            web_service_label.use_markup = true;
            web_service_label.set_markup(Markup.printf_escaped("<b>%s</b>", _("Web Services:").strip()));
            insert_plugin_switches(lyric_provider_box, PluginCategory.LYRICS_PROVIDER, lyric_parent_box);
            insert_plugin_switches(web_service_box, PluginCategory.WEB_SERVICE, web_service_parent_box);
            insert_plugin_switches(gui_box, PluginCategory.GUI, gui_parent_box);
            insert_plugin_switches(additionals_box, PluginCategory.ADDITIONAL, additionals_parent_box);
            insert_plugin_switches(additionals_box, PluginCategory.UNSPECIFIED, additionals_parent_box);
            insert_plugin_switches(additionals_box, PluginCategory.ALBUM_ART_PROVIDER, additionals_parent_box);
            
            add_plugin_tabs();
            this.set_size_request(420, -1);
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK, "Failed to build settings window! \n%s", e.message);
            msg.run();
        }
        return true;
    }
    
    private void insert_plugin_switches(Box box, PluginCategory cat, Box parent_category) {
        List<unowned string> list = plugin_loader.plugin_htable.get_keys();
        list.sort(strcmp);
        list.reverse();
        foreach(string plugin_name in list) {
            if(plugin_loader.plugin_htable.lookup(plugin_name).info.user_activatable == false)
                continue;
            if(plugin_loader.plugin_htable.lookup(plugin_name).info.category != cat)
                continue;
            var plugin_switch = new PluginSwitch(plugin_name, this.plugin_label_sizegroup);
            plugin_switch.margin_left = 5;
            box.pack_start(plugin_switch,
                           false,
                           false,
                           0
                           );
            plugin_switch.sign_plugin_activestate_changed.connect(reset_plugin_tabs);
        }
        if(box.get_children().length() > 0) {
            parent_category.set_no_show_all(false);
            parent_category.show_all();
        }
        else {
            parent_category.hide();
            parent_category.set_no_show_all(true);
        }
    }
}

