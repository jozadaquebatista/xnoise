/* xnoise-settings-dialog.vala
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
 * 	Jörn Magens
 */

using Gtk;

public errordomain Xnoise.SettingsDialogError {
	FILE_NOT_FOUND,
	GENERAL_ERROR
}


public class Xnoise.SettingsDialog : Gtk.Builder {
	private unowned Main xn;
	private const string SETTINGS_UI_FILE = Config.UIDIR + "settings.ui";
/*
	private const int NUMBER_OF_NON_PLUGIN_TABS = 4;
*/
	private PluginManagerTree plugin_manager_tree;
	private Notebook notebook;
	private SpinButton sb;
	private int fontsizeMB;
	private ScrolledWindow scrollWinPlugins;
	private TreeView visibleColTv;
	private ListStore visibleColTvModel;
	private CheckButton checkB_showL;
	private CheckButton checkB_compact;
	private CheckButton checkB_mediaBrLinebreaks;
	private HBox ai_hbox;
	private HBox ly_hbox;
	private bool show_album_col;
	private bool show_length_col;
	private bool show_trackno_col;
	private ListStore ai_model;
	private ListStore ly_model;
	private TreeView ai_tv;
	private TreeView ly_tv;
	private Button ai_down_button;
	private Button ly_down_button;
	private Button ai_up_button;
	private Button ly_up_button;
	
	private enum NotebookTabs {
		GENERAL,
		PLUGINS,
		COVER_IMAGES,
		LYRICS,
		N_COLUMNS
	}

	private enum DisplayColums {
		TOGGLE,
		TEXT,
		N_COLUMNS
	}

	private enum AIProvider {
		STATE,
		NAME,
		RANKING,
		N_COLUMNS
	}

	private enum LyricsProvider {
		STATE,
		NAME,
		RANKING,
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

		setup_viz_cols_tv();
		setup_albumimage_provider_tv();
		setup_lyrics_provider_tv();

		notebook.switch_page.connect(on_notebook_switched_page);
		dialog.show_all();
	}

	private void on_notebook_switched_page(Notebook sender, NotebookPage page, uint page_num) {
		// refresh table
		if(page_num == NotebookTabs.COVER_IMAGES)
			this.put_data_to_ai_tv();

		if(page_num == NotebookTabs.LYRICS)
			this.put_data_to_ly_tv();
	}

	private void initialize_members() {
		//Visible Cols
		show_length_col = (par.get_int_value("use_length_column") == 1 ? true : false);
		show_trackno_col = (par.get_int_value("use_tracknumber_column") == 1 ? true : false);
		show_album_col = (par.get_int_value("use_album_column") == 1 ? true : false);
		
		//Treelines
		if(par.get_int_value("use_treelines") > 0)
			checkB_showL.active = true;
		else
			checkB_showL.active = false;
		
		//compact layout
		if(par.get_int_value("compact_layout") > 0)
			checkB_compact.active = true;
		else
			checkB_compact.active = false;
			
		//media browser line breaks
		if(par.get_int_value("mediabrowser_linebreaks") > 0)
			checkB_mediaBrLinebreaks.active = true;
		else
			checkB_mediaBrLinebreaks.active = false;

		// SpinButton
		sb.configure(new Gtk.Adjustment(8.0, 7.0, 14.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
		if((par.get_int_value("fontsizeMB") >= 7)&&
		    (par.get_int_value("fontsizeMB") <= 14))
			sb.set_value((double)par.get_int_value("fontsizeMB"));
		else
			sb.set_value(9.0);
		sb.set_numeric(true);
	}

	private void on_mb_font_changed(Gtk.Editable sender) {
		if((int)(((Gtk.SpinButton)sender).value) < 7 ) ((Gtk.SpinButton)sender).value = 7;
		if((int)(((Gtk.SpinButton)sender).value) > 15) ((Gtk.SpinButton)sender).value = 15;
		fontsizeMB = (int)((Gtk.SpinButton)sender).value;
		xn.main_window.mediaBr.fontsizeMB = fontsizeMB;
		//TODO:immediatly do something with the new value
	}

	private void on_checkbutton_show_lines_clicked(Gtk.Button sender) {
		if(this.checkB_showL.active) {
			par.set_int_value("use_treelines", 1);
			xn.main_window.mediaBr.use_treelines = true;
		}
		else {
			par.set_int_value("use_treelines", 0);
			xn.main_window.mediaBr.use_treelines = false;
		}
	}
	
	private void on_checkbutton_compact_clicked(Gtk.Button sender) {
		if(this.checkB_compact.active) {
			par.set_int_value("compact_layout", 1);
			xn.main_window.compact_layout = true;
		}
		else {
			par.set_int_value("compact_layout", 0);
			xn.main_window.compact_layout = false;
		}
	}
	
	private void on_checkbutton_mediabr_linebreaks_clicked(Gtk.Button sender) {
		if(this.checkB_mediaBrLinebreaks.active) {
			par.set_int_value("mediabrowser_linebreaks", 1);
			xn.main_window.mediaBr.use_linebreaks = true;
		}
		else {
			par.set_int_value("mediabrowser_linebreaks", 0);
			xn.main_window.mediaBr.use_linebreaks = false;
		}
	}
			

	private void on_ok_button_clicked() {
		
		int buf = 0;
		// show album column
		if(show_album_col)
			buf = 1;
		else
			buf = 0;
		par.set_int_value("use_album_column", buf);
		xn.tl.column_album_visible = show_album_col;
		
		// show length column
		if(show_length_col)
			buf = 1;
		else
			buf = 0;
		par.set_int_value("use_length_column", buf);
		xn.tl.column_length_visible = show_length_col;

		// show track number column
		if(show_trackno_col)
			buf = 1;
		else
			buf = 0;
		par.set_int_value("use_tracknumber_column", buf);
		xn.tl.column_tracknumber_visible = show_trackno_col;

		//write priorities for album image providers
		//TODO
		//write priorities for lyrics providers
		//TODO

		par.write_all_parameters_to_file();
		this.dialog.destroy();
		sign_finish();
	}

	private void on_cancel_button_clicked() {
		this.dialog.destroy();
		sign_finish();
	}

	private void add_plugin_tabs() {
		int count = 0;
		foreach(string name in this.xn.plugin_loader.plugin_htable.get_keys()) {
			unowned Plugin p = this.xn.plugin_loader.plugin_htable.lookup(name);
			if((p.activated) && (p.configurable)) {
			  	Widget? w = p.settingwidget();
				if(w!=null) notebook.append_page(w, new Gtk.Label(name));
				count++;
			}
		}
		this.number_of_tabs = NotebookTabs.N_COLUMNS + count;
	}

	private void remove_plugin_tabs() {
		//remove all tabs
		int number_of_plugin_tabs = notebook.get_n_pages();
		for(int i=5; i<=number_of_plugin_tabs; i++) {
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


	private void setup_lyrics_provider_tv() {
		ly_tv = new TreeView();
		ly_model = new ListStore(LyricsProvider.N_COLUMNS,
		                         typeof(bool),
		                         typeof(string),
		                         typeof(int));
		ly_tv.model = ly_model;

		var renderer = new CellRendererText();

		var columnText = new TreeViewColumn();

		columnText.pack_start(renderer, true);
		columnText.add_attribute(renderer,
		                         "text", LyricsProvider.NAME
		                         );
		columnText.add_attribute(renderer,
		                         "sensitive", LyricsProvider.STATE
		                         );
		ly_tv.append_column(columnText);

		ly_tv.headers_visible = false;

		ly_hbox.pack_start(ly_tv, true, true, 0);

		ly_tv.get_selection().set_mode(SelectionMode.SINGLE);

		put_data_to_ly_tv();
	}

	private void put_data_to_ly_tv() {
		TreeIter iter;
		int ranking = -1;
		ly_model.clear();
		string[]? ly_providers = par.get_string_list_value("album_image_providers");
		var ly_prov_list = xn.plugin_loader.lyrics_plugins_htable.get_keys();
		foreach(string name in ly_prov_list) {
			ranking = -1;
			if(ly_providers != null) {
				ranking = get_position_in_array(ly_providers, ref name);
			}
			ly_model.prepend(out iter);
			ly_model.set(iter,
			             LyricsProvider.STATE, this.xn.plugin_loader.lyrics_plugins_htable.lookup(name).activated,
			             LyricsProvider.NAME, name,
			             LyricsProvider.RANKING, ranking
			             );
		}
		//TODO: Sort on the base of RANKING in the treeview
	}

	private void setup_albumimage_provider_tv() {
		ai_tv = new TreeView();
		ai_model = new ListStore(AIProvider.N_COLUMNS,
		                         typeof(bool),
		                         typeof(string),
		                         typeof(int));
		ai_tv.model = ai_model;

		var renderer = new CellRendererText();

		var columnText = new TreeViewColumn();

		columnText.pack_start(renderer, true);
		columnText.add_attribute(renderer,
		                         "text", AIProvider.NAME
		                         );
		columnText.add_attribute(renderer,
		                         "sensitive", AIProvider.STATE
		                         );
		ai_tv.append_column(columnText);

		ai_tv.headers_visible = false;

		ai_hbox.pack_start(ai_tv, true, true, 0);

		ai_tv.get_selection().set_mode(SelectionMode.SINGLE);

		put_data_to_ai_tv();
	}

	private void put_data_to_ai_tv() {
		TreeIter iter;
		int ranking = -1;
		ai_model.clear();
		string[]? album_image_providers = par.get_string_list_value("album_image_providers");
		var ai_prov_list = xn.plugin_loader.image_provider_htable.get_keys();
		foreach(string name in ai_prov_list) {
			ranking = -1;
			if(album_image_providers!=null) {
				ranking = get_position_in_array(album_image_providers, ref name);
			}
			ai_model.prepend(out iter);
			ai_model.set(iter,
			             AIProvider.STATE, this.xn.plugin_loader.image_provider_htable.lookup(name).activated,
			             AIProvider.NAME, name,
			             AIProvider.RANKING, ranking
			             );
		}
		//TODO: Sort on the base of RANKING in the treeview
	}

	private int get_position_in_array(string[] array, ref string needle) {
		int position = 1;
		foreach(unowned string array_entry in array) {
			if(needle == array_entry) return position;
			position++;
		}
		return -1;
	}

	private void put_data_to_viz_cols_tv() {
		TreeIter iter;
		visibleColTvModel.prepend(out iter);
		visibleColTvModel.set(iter,
			DisplayColums.TOGGLE, this.show_album_col,
			DisplayColums.TEXT, "Album"
			);
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
		//TODO: Make a nicer way to handle column visibility and position
		visibleColTvModel = new ListStore(DisplayColums.N_COLUMNS,
		                                  typeof(bool), typeof(string));

		var toggle = new CellRendererToggle();
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
				case "Album":
					this.show_album_col = val;
					break;
				case "Length":
					this.show_length_col = val;
					break;
				case "Track number":
					this.show_trackno_col = val;
					break;
				default: break;
			}
        });

		visibleColTv.model = visibleColTvModel;

		var columnToggle = new TreeViewColumn();
		columnToggle.pack_start(toggle, false);
		columnToggle.add_attribute(toggle,
		                           "active", DisplayColums.TOGGLE
		                           );
		visibleColTv.append_column(columnToggle);

		var renderer = new CellRendererText();

		var columnText = new TreeViewColumn();
		columnText.pack_start(renderer, true);
		columnText.add_attribute(renderer,
		                         "text", DisplayColums.TEXT
		                         );
		visibleColTv.append_column(columnText);
		put_data_to_viz_cols_tv();
 	}

	// Move the provider up in ranking
	private void on_ai_up_button_clicked(Gtk.Button sender) {
		unowned TreeSelection sel = ai_tv.get_selection();
		TreeIter iter;
		TreeIter next_iter;
		List<TreePath> treepaths = sel.get_selected_rows(null);
		TreePath tp = (TreePath)treepaths.first().data;
		if(!ai_model.get_iter(out iter, tp)) 
			return;
		tp.prev();
		if(!ai_model.get_iter(out next_iter, tp)) 
			return;
		ai_model.move_before(ref iter, next_iter); //move
	}

	// Move the provider down in ranking
	private void on_ai_down_button_clicked(Gtk.Button sender) {
		unowned TreeSelection sel = ai_tv.get_selection();
		TreeIter iter;
		TreeIter next_iter;
		List<TreePath> treepaths = sel.get_selected_rows(null);
		TreePath tp = (TreePath)treepaths.first().data;
		if(!ai_model.get_iter(out iter, tp)) 
			return;
		tp.next();
		if(!ai_model.get_iter(out next_iter, tp)) 
			return;
		ai_model.move_after(ref iter, next_iter); //move
	}

	// Move the provider up in ranking
	private void on_ly_up_button_clicked(Gtk.Button sender) {
		unowned TreeSelection sel = ly_tv.get_selection();
		TreeIter iter;
		TreeIter next_iter;
		List<TreePath> treepaths = sel.get_selected_rows(null);
		TreePath tp = (TreePath)treepaths.first().data;
		if(!ly_model.get_iter(out iter, tp)) 
			return;
		tp.prev();
		if(!ly_model.get_iter(out next_iter, tp)) 
			return;
		ly_model.move_before(ref iter, next_iter); //move
	}

	// Move the provider down in ranking
	private void on_ly_down_button_clicked(Gtk.Button sender) {
		unowned TreeSelection sel = ly_tv.get_selection();
		TreeIter iter;
		TreeIter next_iter;
		List<TreePath> treepaths = sel.get_selected_rows(null);
		TreePath tp = (TreePath)treepaths.first().data;
		if(!ly_model.get_iter(out iter, tp)) 
			return;
		tp.next();
		if(!ly_model.get_iter(out next_iter, tp)) 
			return;
		ly_model.move_after(ref iter, next_iter); //move
	}

	private bool setup_widgets() throws Error {
		try {
			File f = File.new_for_path(SETTINGS_UI_FILE);
			if(!f.query_exists(null)) throw new SettingsDialogError.FILE_NOT_FOUND("Ui file not found!");

			this.add_from_file(SETTINGS_UI_FILE);
			this.dialog = this.get_object("settingsDialog") as Gtk.Dialog;
			this.dialog.set_modal(true);

			ai_up_button = this.get_object("ai_up_button") as Gtk.Button;
			ai_up_button.can_focus = false;
			ai_up_button.clicked.connect(this.on_ai_up_button_clicked);

			ai_down_button = this.get_object("ai_down_button") as Gtk.Button;
			ai_down_button.can_focus = false;
			ai_down_button.clicked.connect(this.on_ai_down_button_clicked);

			ly_up_button = this.get_object("ly_up_button") as Gtk.Button;
			ly_up_button.can_focus = false;
			ly_up_button.clicked.connect(this.on_ly_up_button_clicked);

			ly_down_button = this.get_object("ly_down_button") as Gtk.Button;
			ly_down_button.can_focus = false;
			ly_down_button.clicked.connect(this.on_ly_down_button_clicked);

			checkB_showL = this.get_object("checkB_showlines") as Gtk.CheckButton;
			checkB_showL.can_focus = false;
			checkB_showL.clicked.connect(this.on_checkbutton_show_lines_clicked);
			
			checkB_mediaBrLinebreaks = this.get_object("checkB_mediaBrLinebreaks") as Gtk.CheckButton;
			checkB_mediaBrLinebreaks.can_focus = false;
			checkB_mediaBrLinebreaks.clicked.connect(this.on_checkbutton_mediabr_linebreaks_clicked);
			
			checkB_compact = this.get_object("checkB_compact") as Gtk.CheckButton;
			checkB_compact.can_focus = false;
			checkB_compact.clicked.connect(this.on_checkbutton_compact_clicked);

			var okButton = this.get_object("buttonOK") as Gtk.Button;
			okButton.can_focus = false;
			okButton.clicked.connect(this.on_ok_button_clicked);

			var cancelButton = this.get_object("button1") as Gtk.Button;
			cancelButton.can_focus = false;
			cancelButton.clicked.connect(this.on_cancel_button_clicked);

			var vizcols_label = this.get_object("vizcols_label") as Gtk.Label;
			vizcols_label.label = _("Visible extra columns for tracklist:");
			visibleColTv = this.get_object("vizcols_tv") as Gtk.TreeView;

			sb = this.get_object("spinbutton1") as Gtk.SpinButton;
			sb.set_value(8.0);
			sb.changed.connect(this.on_mb_font_changed);

			ai_hbox = this.get_object("ai_hbox") as Gtk.HBox;
			ly_hbox = this.get_object("ly_hbox") as Gtk.HBox;
			
			scrollWinPlugins = this.get_object("scrollWinPlugins") as Gtk.ScrolledWindow;

			notebook = this.get_object("notebook1") as Gtk.Notebook;

			this.dialog.set_icon_from_file (Config.UIDIR + "xnoise_16x16.png");
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
