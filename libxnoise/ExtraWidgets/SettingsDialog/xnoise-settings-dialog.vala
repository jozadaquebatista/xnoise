/* xnoise-settings-dialog.vala
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

public errordomain Xnoise.SettingsDialogError {
    FILE_NOT_FOUND,
    GENERAL_ERROR
}


public class Xnoise.SettingsDialog : Gtk.Builder {
    private unowned Main xn;
    private const string SETTINGS_UI_FILE = Config.UIDIR + "settings.ui";
    private PluginManagerTree plugin_manager_tree;
    private Notebook notebook;
    private SpinButton sb;
    private int fontsizeMB;
    private ScrolledWindow scrollWinPlugins;
    private CheckButton checkB_showL;
    private CheckButton checkB_compact;
    private CheckButton checkB_usestop;
    private CheckButton checkB_hoverimage;
    private CheckButton checkB_quitifclosed;
    
    private enum NotebookTabs {
        GENERAL = 0,
        PLUGINS,
        N_COLUMNS
    }

    private enum DisplayColums {
        TOGGLE,
        TEXT,
        N_COLUMNS
    }
    
    public Gtk.Dialog dialog;

    public signal void sign_finish();

    public SettingsDialog() {
        this.xn = Main.instance;
        try {
            this.setup_widgets();
        }
        catch(Error e) {
            print("Error setting up settings dialog: %s\n", e.message);
                return;
        }
        initialize_members();
        
        dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        dialog.show_all();
    }

    private void initialize_members() {
        //Visible Cols
        
        //Treelines
        if(Params.get_int_value("use_treelines") > 0)
            checkB_showL.active = true;
        else
            checkB_showL.active = false;
        
        //compact layout
        if(Params.get_int_value("compact_layout") > 0)
            checkB_compact.active = true;
        else
            checkB_compact.active = false;
            
        //use stop button
        if(Params.get_int_value("quit_if_closed") > 0)
            checkB_quitifclosed.active = true;
        else
            checkB_quitifclosed.active = false;
        
        if(Params.get_int_value("usestop") > 0)
            checkB_usestop.active = true;
        else
            checkB_usestop.active = false;
        
        //not_show_art_on_hover_image
        if(Params.get_int_value("not_show_art_on_hover_image") > 0)
            checkB_hoverimage.active = true;
        else
            checkB_hoverimage.active = false;
        
        // SpinButton
        sb.changed.disconnect(this.on_mb_font_changed);
        sb.configure(new Gtk.Adjustment(8.0, 7.0, 14.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
        if((Params.get_int_value("fontsizeMB") >= 7)&&
            (Params.get_int_value("fontsizeMB") <= 14))
            sb.set_value((double)Params.get_int_value("fontsizeMB"));
        else
            sb.set_value(9.0);
        sb.set_numeric(true);
        sb.changed.connect(this.on_mb_font_changed);
    }

    private void on_mb_font_changed(Gtk.Editable sender) {
        if((int)(((Gtk.SpinButton)sender).value) < 7 ) ((Gtk.SpinButton)sender).value = 7;
        if((int)(((Gtk.SpinButton)sender).value) > 15) ((Gtk.SpinButton)sender).value = 15;
        fontsizeMB = (int)((Gtk.SpinButton)sender).value;
        main_window.mediaBr.fontsizeMB = fontsizeMB;
    }

    private void on_checkbutton_show_lines_clicked(Gtk.Button sender) {
        if(this.checkB_showL.active) {
            Params.set_int_value("use_treelines", 1);
            main_window.mediaBr.use_treelines = true;
        }
        else {
            Params.set_int_value("use_treelines", 0);
            main_window.mediaBr.use_treelines = false;
        }
    }
    
    private void on_checkbutton_compact_clicked(Gtk.Button sender) {
        if(this.checkB_compact.active) {
            Params.set_int_value("compact_layout", 1);
            main_window.compact_layout = true;
        }
        else {
            Params.set_int_value("compact_layout", 0);
            main_window.compact_layout = false;
        }
    }
    
    private void on_checkbutton_quitifclosed_clicked(Gtk.Button sender) {
        if(this.checkB_quitifclosed.active) {
            Params.set_int_value("quit_if_closed", 1);
            main_window.quit_if_closed = true;
        }
        else {
            Params.set_int_value("quit_if_closed", 0);
            main_window.quit_if_closed = false;
        }
    }
    
    private void on_checkbutton_usestop_clicked(Gtk.Button sender) {
        if(this.checkB_usestop.active) {
            Params.set_int_value("usestop", 1);
            main_window.usestop = true;
        }
        else {
            Params.set_int_value("usestop", 0);
            main_window.usestop = false;
        }
    }
    
    private void on_checkbutton_mediabr_hoverimage_clicked(Gtk.Button sender) {
        if(this.checkB_hoverimage.active) {
            Params.set_int_value("not_show_art_on_hover_image", 1);
            main_window.not_show_art_on_hover_image = true;
        }
        else {
            Params.set_int_value("not_show_art_on_hover_image", 0);
            main_window.not_show_art_on_hover_image = false;
        }
    }
    
    private void on_close_button_clicked() {
        Params.write_all_parameters_to_file();
        this.dialog.destroy();
        sign_finish();
    }

    private void add_plugin_tabs() {
        int count = 0;
        foreach(string name in plugin_loader.plugin_htable.get_keys()) {
            unowned PluginModule.Container p = plugin_loader.plugin_htable.lookup(name);
            if((p.activated) && (p.configurable)) {
                Widget? w = p.settingwidget();
                
                if(w!=null)
                    notebook.append_page(w, new Gtk.Label(name));
                
                count++;
            }
        }
        this.number_of_tabs = NotebookTabs.N_COLUMNS + count;
    }

    private void remove_plugin_tabs() {
        //remove all plugin tabs, before re-adding them
        int number_of_plugin_tabs = notebook.get_n_pages();
        for(int i = NotebookTabs.N_COLUMNS; i < number_of_plugin_tabs; i++) {
            notebook.remove_page(-1); //remove last page
        }
    }

    private int number_of_tabs;
    private void reset_plugin_tabs(string name) {
        //just remove all tabs and rebuild them
        remove_plugin_tabs();
        add_plugin_tabs();
        this.dialog.show_all();
    }

    private bool setup_widgets() throws Error {
        try {
            File f = File.new_for_path(SETTINGS_UI_FILE);
            if(!f.query_exists(null)) throw new SettingsDialogError.FILE_NOT_FOUND("Ui file not found!");
            this.add_from_file(SETTINGS_UI_FILE);
            this.dialog = this.get_object("settingsDialog") as Gtk.Dialog;
            dialog.set_transient_for(main_window);
            this.dialog.set_modal(true);
            
            Label general_label = this.get_object("label1") as Gtk.Label;
            general_label.set_text(_("General"));
            Label plugins_label = this.get_object("label6") as Gtk.Label;
            plugins_label.set_text(_("Plugins"));
            
            checkB_showL = this.get_object("checkB_showlines") as Gtk.CheckButton;
            checkB_showL.can_focus = false;
            checkB_showL.clicked.connect(this.on_checkbutton_show_lines_clicked);
            checkB_showL.label = _("Enable grid lines in media browser");
            
            checkB_hoverimage = this.get_object("checkB_hoverimage") as Gtk.CheckButton;
            checkB_hoverimage.can_focus = false;
            checkB_hoverimage.clicked.connect(this.on_checkbutton_mediabr_hoverimage_clicked);
            checkB_hoverimage.label = _("Don't show video screen while hovering album image");
            
            checkB_compact = this.get_object("checkB_compact") as Gtk.CheckButton;
            checkB_compact.can_focus = false;
            checkB_compact.clicked.connect(this.on_checkbutton_compact_clicked);
            checkB_compact.label = _("Compact layout");
            
            checkB_usestop = this.get_object("checkB_usestop") as Gtk.CheckButton;
            checkB_usestop.can_focus = false;
            checkB_usestop.clicked.connect(this.on_checkbutton_usestop_clicked);
            checkB_usestop.label = _("Use stop button");
            
            checkB_quitifclosed = this.get_object("checkB_quitifclosed") as Gtk.CheckButton;
            checkB_quitifclosed.can_focus = false;
            checkB_quitifclosed.clicked.connect(this.on_checkbutton_quitifclosed_clicked);
            checkB_quitifclosed.label = _("Quit application if window is closed");
            
            var closeButton = this.get_object("buttonclose") as Gtk.Button;
            closeButton.can_focus = false;
            closeButton.clicked.connect(this.on_close_button_clicked);
            
            var fontsize_label = this.get_object("fontsize_label") as Gtk.Label;
            fontsize_label.label = _("Media browser fontsize:");
            
            sb = this.get_object("spinbutton1") as Gtk.SpinButton;
            sb.set_value(8.0);
            sb.changed.connect(this.on_mb_font_changed);
            
            scrollWinPlugins = this.get_object("scrollWinPlugins") as Gtk.ScrolledWindow;
            scrollWinPlugins.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
            
            notebook = this.get_object("notebook1") as Gtk.Notebook;
            
            this.dialog.set_default_icon_name("xnoise");
            this.dialog.set_position(Gtk.WindowPosition.CENTER);
            
            add_plugin_tabs();
            
            plugin_manager_tree = new PluginManagerTree();
            this.dialog.realize.connect(on_dialog_realized);
            scrollWinPlugins.add(plugin_manager_tree);
            
            plugin_manager_tree.sign_plugin_activestate_changed.connect(reset_plugin_tabs);
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK, "Failed to build settings window! \n" + e.message);
            msg.run();
            throw new SettingsDialogError.GENERAL_ERROR("Error creating Settings Dialog.\n");
        }
        return true;
    }
    
    private void on_dialog_realized() {
        Requisition req;
        dialog.get_child_requisition(out req);
        plugin_manager_tree.set_width(req.width);
    }
}
