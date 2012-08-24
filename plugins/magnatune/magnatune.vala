/* magnatune.vala
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
using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.PluginModule;


private static const string MAGNATUNE_MUSIC_STORE_NAME = "MagnatuneMusicStore";

public class MagnatunePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private unowned PluginModule.Container _owner;
    private MagMusicStore music_store;

    public PluginModule.Container owner {
        get { return _owner;  }
        set { _owner = value; }
    }
    
    public string name { get { return "magnatune_music_store"; } }
    
    public bool init() {
        this.music_store = new MagMusicStore(this);
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
        return new MagnatuneSettings(this);
    }

    public bool has_settings_widget() {
        return true;
    }
    

    public signal void login_state_change();
    
    internal string username;
    internal string password;
    
    public void login(string username, string password) {
        if(username == null || username == EMPTYSTRING ||
           password == null || password == EMPTYSTRING)
            return;
        this.username = username;
        this.password = password;
        
        Idle.add( () => {
            login_state_change();
            return false;
        });
    }
}



public class MagnatuneSettings : Gtk.Box {
    private unowned Main xn;
    private unowned MagnatunePlugin magn_plugin;
    private Entry user_entry;
    private Entry pass_entry;
    private Label feedback_label;
    private Button b;
    private string username_last;
    private string password_last;
    
    
    public MagnatuneSettings(MagnatunePlugin magn_plugin) {
        GLib.Object(orientation:Gtk.Orientation.VERTICAL, spacing:10);
        this.magn_plugin = magn_plugin;
        this.xn = Main.instance;
        setup_widgets();
        
        this.magn_plugin.login_state_change.connect(do_user_feedback);
        this.set_vexpand(true);
        this.set_hexpand(true);
        user_entry.text = Xnoise.Params.get_string_value("magnatune_user");
        pass_entry.text = Xnoise.Params.get_string_value("magnatune_pass");
        
        if(user_entry.text != EMPTYSTRING && pass_entry.text != EMPTYSTRING) {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_AVAILABLE));
        }
        else {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_NOT_AVAILABLE));
        }
        b.clicked.connect(on_entry_changed);
    }

    //show if user is logged in
    private void do_user_feedback() {
        print("do_user_feedback\n");
        if(user_entry.text != EMPTYSTRING && pass_entry.text != EMPTYSTRING) {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_AVAILABLE));
            feedback_label.set_use_markup(true);
        }
        else {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_NOT_AVAILABLE));
            feedback_label.set_use_markup(true);
        }
    }
    
    private const string USER_PASSWORD_AVAILABLE     = _("Username/Password available!");
    private const string USER_PASSWORD_NOT_AVAILABLE = _("Username/Password not available!");
    
    private void on_entry_changed() {
        //print("take over entry\n");
        string username = EMPTYSTRING, password = EMPTYSTRING;
        if(user_entry.text != null)
            username = user_entry.text.strip();
        if(pass_entry.text != null)
            password = pass_entry.text.strip();
        if(username_last == user_entry.text.strip() && password_last == pass_entry.text.strip())
            return; // no need to spam!
        if(username != EMPTYSTRING && password != EMPTYSTRING) {
            //print("got login data\n");
            Xnoise.Params.set_string_value("magnatune_user", username);
            Xnoise.Params.set_string_value("magnatune_pass", password);
            username_last = username;
            password_last = password;
            Idle.add( () => {
                Xnoise.Params.write_all_parameters_to_file();
                return false;
            });
            do_user_feedback();
            magn_plugin.login(username, password);
        }
    }
    
    private void setup_widgets() {
        var headline_label = new Gtk.Label("");
        headline_label.margin_top    = 5;
        headline_label.margin_bottom = 5;
        headline_label.set_alignment(0.0f, 0.5f);
        headline_label.set_markup("<span size=\"xx-large\"><b> " + Markup.printf_escaped(_("Magnatune")) + "</b></span>");
        headline_label.use_markup= true;
        this.pack_start(headline_label, false, false, 0);
        
        Gdk.Pixbuf image;
        unowned IconTheme theme = IconTheme.get_default();
        try {
            if(theme.has_icon("xn-magnatune")) {
                image = theme.load_icon("xn-magnatune", 80, IconLookupFlags.FORCE_SIZE);
                var b = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                b.pack_start(new Gtk.Image.from_pixbuf(image), false, false, 0);
                b.pack_start(new Gtk.Label(""), true, true, 0);
                this.pack_start(b, false, false, 5);
            }
        }
        catch(Error e) {
            image = null;
        }
        
        var title_label = new Label("<b>%s</b>".printf(_("Please enter your Magnatune username and password.")));
        title_label.set_use_markup(true);
        title_label.set_single_line_mode(true);
        title_label.set_alignment(0.0f, 0.5f);
        title_label.set_ellipsize(Pango.EllipsizeMode.END);
        title_label.ypad = 8;
        this.pack_start(title_label, false, false, 0);
        
        var hbox1 = new Box(Orientation.HORIZONTAL, 2);
        var user_label = new Label("%s".printf(_("Username:")));
        user_label.xalign = 0.0f;
        hbox1.pack_start(user_label, false, false, 0);
        user_entry = new Entry();
        user_entry.set_width_chars(35);
        hbox1.pack_start(user_entry, false, false, 0);
        hbox1.pack_start(new Label(""), false, false, 0);
        
        var hbox2 = new Box(Orientation.HORIZONTAL, 2);
        var pass_label = new Label("%s".printf(_("Password:")));
        pass_label.xalign = 0.0f;
        hbox2.pack_start(pass_label, false, false, 0);
        pass_entry = new Entry();
        pass_entry.set_width_chars(35);
        pass_entry.set_visibility(false);
        
        hbox2.pack_start(pass_entry, false, false, 0);
        hbox2.pack_start(new Label(""), false, false, 0);
        
        var sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
        sizegroup.add_widget(user_label);
        sizegroup.add_widget(pass_label);
        
        this.pack_start(hbox1, false, false, 4);
        this.pack_start(hbox2, false, false, 4);
        
        var hbox3 = new Box(Orientation.HORIZONTAL, 2);
        b = new Button.from_stock(Gtk.Stock.APPLY);
        hbox3.pack_start(b, false, false, 0);
        hbox3.pack_start(new Label(""), true, true, 0);
        this.pack_start(hbox3, false, false, 0);
        this.border_width = 4;
        
        //feedback
        feedback_label = new Label("<b><i>%s</i></b>".printf(USER_PASSWORD_NOT_AVAILABLE));
        if(user_entry.text != EMPTYSTRING && pass_entry.text != EMPTYSTRING) {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_AVAILABLE));
        }
        else {
            feedback_label.set_markup("<b><i>%s</i></b>".printf(USER_PASSWORD_NOT_AVAILABLE));
        }
        feedback_label.set_use_markup(true);
        feedback_label.set_single_line_mode(true);
        feedback_label.set_alignment(0.1f, 0.5f);
        feedback_label.ypad = 20;
        this.pack_start(feedback_label, false, false, 0);
    }
}




//The Magnatune Music Store.
private class MagMusicStore : GLib.Object {
    private DockableMagnatuneMS msd;
    private unowned MagnatunePlugin plugin;
    
    public MagMusicStore(MagnatunePlugin plugin) {
        this.plugin = plugin;
        msd = new DockableMagnatuneMS(this.plugin);
        main_window.msw.insert_dockable(msd);
    }
    
    ~MagMusicStore() {
        main_window.msw.select_dockable_by_name("MusicBrowserDockable");
        if(msd == null)
            return;
        if(msd.action_group != null) {
            main_window.ui_manager.remove_action_group(msd.action_group);
        }
        if(msd.ui_merge_id != 0)
            main_window.ui_manager.remove_ui(msd.ui_merge_id);
        main_window.msw.remove_dockable_in_idle(MAGNATUNE_MUSIC_STORE_NAME);
    }
}


