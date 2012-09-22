/* xnoise-settings-widget.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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


public class Xnoise.SettingsWidget : Gtk.Box {
    private unowned Main xn;
    private const string SETTINGS_UI_FILE = Config.UIDIR + "settings.ui";
    private PluginManagerTree plugin_manager_tree;
    private Notebook notebook;
    private SpinButton sb;
    private int fontsizeMB;
    private ScrolledWindow scrollWinPlugins;
    private Switch switch_showL;
    private Switch switch_compact;
    private Switch switch_usestop;
    private Switch switch_hoverimage;
    private Switch switch_quitifclosed;
    private Switch switch_equalizer;
    private AddMediaWidget add_media_widget;
    
    private enum NotebookTabs {
        GENERAL = 0,
        PLUGINS,
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
        this.xn = Main.instance;
        try {
            this.setup_widgets();
        }
        catch(Error e) {
            print("Error setting up settings dialog: %s\n", e.message);
                return;
        }
        initialize_members();
        connect_signals();
        this.show_all();
    }

    private void connect_signals() {
        assert(switch_usestop != null);
        switch_usestop.notify["active"].connect(this.on_checkbutton_usestop_clicked);
        
        assert(switch_showL != null);
        switch_showL.notify["active"].connect(this.on_checkbutton_show_lines_clicked);
        
        assert(switch_hoverimage != null);
        switch_hoverimage.notify["active"].connect(this.on_checkbutton_mediabr_hoverimage_clicked);
        
        assert(switch_compact != null);
        switch_compact.notify["active"].connect(this.on_checkbutton_compact_clicked);
        
        assert(switch_quitifclosed != null);
        switch_quitifclosed.notify["active"].connect(this.on_checkbutton_quitifclosed_clicked);
        
        assert(switch_equalizer != null);
        switch_equalizer.notify["active"].connect(this.on_switch_use_equalizer_clicked);
        
        sb.changed.connect(this.on_mb_font_changed);
    }

    private void initialize_members() {
        //Visible Cols
        
        //Treelines
        switch_showL.active = Params.get_bool_value("use_treelines");
        
        //compact layout / Application menu
        switch_compact.active = Params.get_bool_value("compact_layout");
        
        //use stop button
        switch_quitifclosed.active = Params.get_bool_value("quit_if_closed");
        
        switch_equalizer.active = !Params.get_bool_value("not_use_eq");
        
        switch_usestop.active = Params.get_bool_value("usestop");
        
        //not_show_art_on_hover_image
        switch_hoverimage.active = !Params.get_bool_value("not_show_art_on_hover_image");
        
        // SpinButton
        if((Params.get_int_value("fontsizeMB") >= 7)&&
            (Params.get_int_value("fontsizeMB") <= 14))
            sb.set_value((double)Params.get_int_value("fontsizeMB"));
        else
            sb.set_value(9.0);
    }

    private void on_mb_font_changed(Gtk.Editable sender) {
        if((int)(((Gtk.SpinButton)sender).value) < 7 ) ((Gtk.SpinButton)sender).value = 7;
        if((int)(((Gtk.SpinButton)sender).value) > 15) ((Gtk.SpinButton)sender).value = 15;
        fontsizeMB = (int)((Gtk.SpinButton)sender).value;
//        main_window.musicBr.fontsizeMB = fontsizeMB;
        global.fontsize_dockable = fontsizeMB;
        Params.set_int_value("fontsizeMB", fontsizeMB);
    }

    private void on_checkbutton_show_lines_clicked() {
        if(this.switch_showL.active) {
            Params.set_bool_value("use_treelines", true);
            main_window.musicBr.use_treelines = true;
        }
        else {
            Params.set_bool_value("use_treelines", false);
            main_window.musicBr.use_treelines = false;
        }
    }
    
    private void on_checkbutton_compact_clicked() {
        if(this.switch_compact.active) {
            Params.set_bool_value("compact_layout", true);
            main_window.compact_layout = true;
        }
        else {
            Params.set_bool_value("compact_layout", false);
            main_window.compact_layout = false;
        }
    }
    
    private void on_switch_use_equalizer_clicked() {
        if(!this.switch_equalizer.active) {
            Params.set_bool_value("not_use_eq", true);
            main_window.use_eq = false;
            gst_player.activate_equalizer();
        }
        else {
            Params.set_bool_value("not_use_eq", false);
            main_window.use_eq = true;
            gst_player.deactivate_equalizer();
        }
    }
    
    private void on_checkbutton_quitifclosed_clicked() {
        if(this.switch_quitifclosed.active) {
            Params.set_bool_value("quit_if_closed", true);
            main_window.quit_if_closed = true;
        }
        else {
            Params.set_bool_value("quit_if_closed", false);
            main_window.quit_if_closed = false;
        }
    }
    
    private void on_checkbutton_usestop_clicked() {
        if(this.switch_usestop.active) {
            Params.set_bool_value("usestop", true);
            main_window.usestop = true;
        }
        else {
            Params.set_bool_value("usestop", false);
            main_window.usestop = false;
        }
    }
    
    private void on_checkbutton_mediabr_hoverimage_clicked() {
        if(!this.switch_hoverimage.active) {
            Params.set_bool_value("not_show_art_on_hover_image", true);
            main_window.not_show_art_on_hover_image = true;
        }
        else {
            Params.set_bool_value("not_show_art_on_hover_image", false);
            main_window.not_show_art_on_hover_image = false;
        }
    }
    
    private void on_back_button_clicked() {
        Params.write_all_parameters_to_file();
        main_window.dialognotebook.set_current_page(0);
        sign_finish();
    }

    private void add_plugin_tabs() {
        int count = 0;
        foreach(string name in plugin_loader.plugin_htable.get_keys()) {
            unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(name);
            if((p.activated) && (p.configurable)) {
                Widget? w = p.settingwidget();
                
                if(w!=null) {
                    var l = new Gtk.Label(name);
                    sizegroup.add_widget(l);
                    notebook.append_page(w, l);
                }
                
                count++;
            }
        }
        this.number_of_tabs = NotebookTabs.N_FIXED_TABS + count;
    }
    
    public void select_media_tab() {
        if(this.notebook == null)
            return;
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

    private Gtk.SizeGroup sizegroup;
    
    private Builder builder;
    private bool setup_widgets() {
        builder = new Builder();
        try {
            this.builder.add_from_file(SETTINGS_UI_FILE);
            var headline_general = this.builder.get_object("headline_general") as Gtk.Label;
            headline_general.set_markup("<span size=\"xx-large\"><b> "
                                        + Markup.printf_escaped(_("General")) +
                                        "</b></span>");
            headline_general.use_markup= true;
            
            var general_label = this.builder.get_object("label1") as Gtk.Label;
            general_label.set_text(_("Settings"));
            var plugins_label = this.builder.get_object("label6") as Gtk.Label;
            plugins_label.set_text(_("Plugins"));
            var media_label = this.builder.get_object("media_label") as Gtk.Label;
            media_label.set_text(_("Media"));
            
            sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
            sizegroup.add_widget(general_label);
            sizegroup.add_widget(plugins_label);
            sizegroup.add_widget(media_label);
            
            switch_showL = this.builder.get_object("switch_showlines") as Gtk.Switch;
            switch_showL.can_focus = false;
            var label_showL = this.builder.get_object("label_showlines") as Gtk.Label;
            label_showL.label = _("Grid lines in media browser");
            
            switch_hoverimage = this.builder.get_object("switch_hoverimage") as Gtk.Switch;
            switch_hoverimage.can_focus = false;
            var label_hoverimage = this.builder.get_object("label_hoverimage") as Gtk.Label;
            label_hoverimage.label = _("Show picture on hover album image");
            
            switch_compact = this.builder.get_object("switch_compact") as Gtk.Switch;
            switch_compact.can_focus = false;
            var label_compact = this.builder.get_object("label_compact") as Gtk.Label;
            label_compact.label = _("Application Menu");
            
            switch_usestop = this.builder.get_object("switch_usestop") as Gtk.Switch;
            switch_usestop.can_focus = false;
            var label_usestop = this.builder.get_object("label_usestop") as Gtk.Label;
            label_usestop.label = _("Stop button");
            
            switch_quitifclosed = this.builder.get_object("switch_quitifclosed") as Gtk.Switch;
            switch_quitifclosed.can_focus = false;
            var label_quitifclosed = this.builder.get_object("label_quitifclosed") as Gtk.Label;
            label_quitifclosed.label = _("Quit on close");
            
            switch_equalizer = this.builder.get_object("switch_equalizer") as Gtk.Switch;
            switch_equalizer.can_focus = false;
            var label_equalizer = this.builder.get_object("label_equalizer") as Gtk.Label;
            label_equalizer.label = _("Equalizer");
            
            notebook = this.builder.get_object("notebook1") as Gtk.Notebook;
            var back_action_box = new Box(Orientation.HORIZONTAL, 0);
            var back_button = new Gtk.Button.from_stock(Gtk.Stock.GO_BACK);
            back_action_box.pack_start(back_button, false, false, 0);
            back_action_box.pack_start(new Label(""), true, true, 0);
            back_button.clicked.connect(this.on_back_button_clicked);
            notebook.set_action_widget(back_action_box, PackType.START);
            back_action_box.show_all();
            notebook.scrollable = false;
            this.pack_start(notebook, true, true, 0);

            var fontsize_label = this.builder.get_object("fontsize_label") as Gtk.Label;
            fontsize_label.label = _("Media browser fontsize:");
            
            sb = this.builder.get_object("spinbutton1") as Gtk.SpinButton;
            sb.configure(new Gtk.Adjustment(8.0, 7.0, 14.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
            sb.set_numeric(true);
            
            scrollWinPlugins = this.builder.get_object("scrollWinPlugins") as Gtk.ScrolledWindow;
            scrollWinPlugins.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
            
            var headline_plugin = this.builder.get_object("headline_plugin") as Gtk.Label;
            headline_plugin.set_markup("<span size=\"xx-large\"><b> " +
                                       Markup.printf_escaped(_("Plugins")) +
                                       "</b></span>");
            var mediabox = this.builder.get_object("mediabox") as Gtk.Box;
            add_media_widget = new AddMediaWidget();
            mediabox.pack_start(add_media_widget, true, true, 0);
            headline_plugin.use_markup= true;
            Timeout.add_seconds(2, () => {
                add_plugin_tabs();
                plugin_manager_tree = new PluginManagerTree();
                scrollWinPlugins.add(plugin_manager_tree);
                
                plugin_manager_tree.sign_plugin_activestate_changed.connect(reset_plugin_tabs);
                this.show_all();
                return false;
            });
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK, "Failed to build settings window! \n" + e.message);
            msg.run();
        }
        return true;
    }
}
