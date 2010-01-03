/* xnoise-settings-dialog.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
 * 	Jörn Magens
 */

using Gtk;

public errordomain Xnoise.SettingsDialogError {
	FILE_NOT_FOUND,
	GENERAL_ERROR
}


public class Xnoise.SettingsDialog : Gtk.Builder {
	private Main xn;
	private const string SETTINGS_UI_FILE = Config.UIDIR + "settings.ui";
	private PluginManagerTree plugin_manager_tree;
	private Notebook notebook;
	private SpinButton sb;
	private RadioButton radioButtonmin;
	private int fontsizeMB;
	private VBox vboxplugins;
	private TreeView visibleColTv;
	private ListStore visibleColTvModel;

	private bool show_length_col;
	private bool show_trackno_col;

	public Gtk.Dialog dialog;

	public signal void sign_finish();

	public SettingsDialog(ref Main xn) {
		this.xn = xn;
		try {
			this.setup_widgets();
		}
		catch(SettingsDialogError e) {
			print("Error setting up settings dialog: %s\n", e.message);
			return;
		}
		// TODO: move to new function
		show_length_col = (par.get_int_value("use_length_column") == 1 ? true : false);
		show_trackno_col = (par.get_int_value("use_tracknumber_column") == 1 ? true : false);

		sb.configure(new Gtk.Adjustment(8.0, 7.0, 14.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
		if((par.get_int_value("fontsizeMB") >= 7)&&
		    (par.get_int_value("fontsizeMB") <= 14))
			sb.set_value((double)par.get_int_value("fontsizeMB"));
		else
			sb.set_value(9.0);
		sb.set_numeric(true);
		this.setup_viz_cols_tv();
		this.put_data_to_viz_cols_tv();
		this.dialog.show_all();
	}

//	~SettingsDialog() {
//		print("destruct SettingsDialog\n");
//	}

	private void on_mb_font_changed(Gtk.Editable sender) {
		if((int)(((Gtk.SpinButton)sender).value) < 7 ) ((Gtk.SpinButton)sender).value = 7;
		if((int)(((Gtk.SpinButton)sender).value) > 15) ((Gtk.SpinButton)sender).value = 15;
		fontsizeMB = (int)((Gtk.SpinButton)sender).value;
		xn.main_window.mediaBr.fontsizeMB = fontsizeMB;
		//TODO:immediatly do something with the new value
	}

	private void on_ok_button_clicked() {
		int buf = 0;
		if(show_length_col)
			buf = 1;
		else
			buf = 0;
		par.set_int_value("use_length_column", buf);
		if(show_trackno_col)
			buf = 1;
		else
			buf = 0;
		par.set_int_value("use_tracknumber_column", buf);
		xn.tl.column_tracknumber_visible = show_trackno_col;
		xn.tl.column_length_visible = show_length_col;
		this.dialog.destroy();
		par.write_all_parameters_to_file();
		sign_finish();
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
		sign_finish();
	}

	private void on_radio_buttonmin_toggled(Gtk.ToggleButton sender) {
		if(sender.active)
			par.set_int_value("show_on_startup", 1);
		else
			par.set_int_value("show_on_startup", 0);
	}

	private void add_plugin_tabs() {
		foreach(string name in this.xn.plugin_loader.plugin_htable.get_keys()) {
			weak Plugin p = this.xn.plugin_loader.plugin_htable.lookup(name);
			if((p.activated) && (p.configurable)) {
			  	Widget? w = p.settingwidget();
				if(w!=null) notebook.append_page(w, new Gtk.Label(name));
			}
		}
	}

	private void remove_plugin_tabs() {
		//remove all tabs
		int number_of_plugin_tabs = notebook.get_n_pages();
		for(int i=5; i<=number_of_plugin_tabs; i++) {
			notebook.remove_page(-1); //remove last page
		}
	}

	private void reset_plugin_tabs(string name) {
		//just remove all tabs and rebuild them
		remove_plugin_tabs();
		add_plugin_tabs();
		this.dialog.show_all();
	}
	private enum DisplayColums {
		TOGGLE,
		TEXT,
		N_COLUMNS
	}

	private void put_data_to_viz_cols_tv() {
		TreeIter iter;
		visibleColTvModel.prepend(out iter);
		visibleColTvModel.set(iter,
			DisplayColums.TOGGLE, this.show_length_col,
			DisplayColums.TEXT, "Length"
			);
		visibleColTvModel.prepend(out iter);
		visibleColTvModel.set(iter,
			DisplayColums.TOGGLE, this.show_trackno_col,
			DisplayColums.TEXT, "Track number"
			);
	}

	private void setup_viz_cols_tv() {
		visibleColTvModel = new ListStore(DisplayColums.N_COLUMNS,
		                                  typeof(bool), typeof(string));

		var toggle = new CellRendererToggle ();
		toggle.toggled.connect((toggle, path_as_string) => {
			var treepath = new TreePath.from_string(path_as_string);
			TreeIter iter;
			string? text = null;
			bool val = false;
			visibleColTvModel.get_iter(out iter, treepath);
            visibleColTvModel.set(iter,
                                  DisplayColums.TOGGLE, !toggle.active
                                  );
			visibleColTvModel.get(iter,
			                      DisplayColums.TEXT, ref text,
			                      DisplayColums.TOGGLE, ref val
			                      );
			switch(text) {
				case "Length":
					this.show_length_col = val;
					//xn.tl.column_length_visible = val;
					break;
				case "Track number":
					this.show_trackno_col = val;
					//xn.tl.column_tracknumber_visible = val;
					break;
				default: break;
			}
        });

		visibleColTv.model = visibleColTvModel;

        var columnToggle = new TreeViewColumn ();
        columnToggle.pack_start(toggle, false);
        columnToggle.add_attribute(toggle,
                                   "active", DisplayColums.TOGGLE
                                   );
        visibleColTv.append_column(columnToggle);

        var renderer = new CellRendererText ();

        var columnText = new TreeViewColumn ();
        columnText.pack_start(renderer, true);
        columnText.add_attribute(renderer,
                                 "text", DisplayColums.TEXT
                                 );
        visibleColTv.append_column(columnText);
 	}

	private bool setup_widgets() throws SettingsDialogError {
		try {
			File f = File.new_for_path(SETTINGS_UI_FILE);
			if(!f.query_exists(null)) throw new SettingsDialogError.FILE_NOT_FOUND("Ui file not found!");

			this.add_from_file(SETTINGS_UI_FILE);
			this.dialog              = this.get_object("dialog1") as Gtk.Dialog;

			radioButtonmin           = this.get_object("radiobutton1") as Gtk.RadioButton;
			radioButtonmin.can_focus = false;
			//Set initial value
			radioButtonmin.active = (par.get_int_value("show_on_startup") == 1 ? true : false);
			radioButtonmin.toggled.connect(this.on_radio_buttonmin_toggled);

			var okButton             = this.get_object("buttonOK") as Gtk.Button;
			okButton.can_focus       = false;
			okButton.clicked.connect(this.on_ok_button_clicked);

			var cancelButton         = this.get_object("button1") as Gtk.Button;
			cancelButton.can_focus   = false;
			cancelButton.clicked.connect(this.on_cancel_button_clicked);

			var vizcols_label        = this.get_object("vizcols_label") as Gtk.Label;
			vizcols_label.label      = _("Visible extra columns for tracklist:");
			visibleColTv             = this.get_object("vizcols_tv") as Gtk.TreeView;

			sb                       = this.get_object("spinbutton1") as Gtk.SpinButton;
			sb.set_value(8.0);
			sb.changed.connect(this.on_mb_font_changed);

			vboxplugins              = this.get_object("vboxplugins") as Gtk.VBox;

			notebook                 = this.get_object("notebook1") as Gtk.Notebook;

			this.dialog.set_icon_from_file (Config.UIDIR + "xnoise_16x16.png");
			this.dialog.set_position(Gtk.WindowPosition.CENTER);

			add_plugin_tabs();

			plugin_manager_tree = new PluginManagerTree(ref xn);
			vboxplugins.pack_start(plugin_manager_tree, true, true, 0);

			plugin_manager_tree.sign_plugin_activestate_changed.connect(reset_plugin_tabs);
		}
		catch (GLib.Error e) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
				Gtk.ButtonsType.OK, "Failed to build settings window! \n" + e.message);
			msg.run();
			return false;
		}
		return true;
	}
}
