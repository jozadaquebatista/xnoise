/* xnoise-main-window.vala
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
[CCode (cname = "gdk_window_ensure_native")]
public extern bool ensure_native(Gdk.Window window);

public class Xnoise.MainWindow : Gtk.Window, IParams {
	private const string MAIN_UI_FILE     = Config.UIDIR + "main_window.ui";
	private const string MENU_UI_FILE     = Config.UIDIR + "main_ui.xml";
	private const string APPICON          = Config.UIDIR + "xnoise_bruit_48x48.png";
	private const string SHOWVIDEO        = _("Video");
	private const string SHOWTRACKLIST    = _("Tracklist");
	private const string SHOWMEDIABROWSER = _("Show Media");
	private const string HIDEMEDIABROWSER = _("Hide Media");
	private unowned Main xn;
	private ActionGroup action_group;
	private UIManager ui_manager = new UIManager();
	private Label song_title_label;
	private VolumeSliderButton volumeSliderButton;
	private int _posX_buffer;
	private int _posY_buffer;
	private uint aimage_timeout;
	private Gtk.Image config_button_image;
	private Gtk.AspectFrame a_frame_config_button = null;
	private Button collapsebutton;
	private Button hide_button;
	private Button hide_button_1;
	private Button hide_button_2;
	private Button showlyricsbuttonVid;
	private Button showlyricsbuttonTL;
	private Button showtracklistbuttonVid;
	private Button showtracklistbuttonLY;
	private Button showvideobuttonTL;
	private Button showvideobuttonLY;
	private Button repeatButton;
	private int buffer_last_page;
	private Label repeatLabel;
	private VBox menuvbox;
	private VBox mainvbox;
	private VBox contentvbox;
	private MenuBar menubar;
	private ImageMenuItem config_button_menu_root;
	private Menu config_button_menu;
	private bool _media_browser_visible;
	private double current_volume; //keep it global for saving to params
	private int window_width = 0;
	private ScreenSaverManager ssm = null;
	public bool _seek;
	public bool is_fullscreen = false;
	public bool drag_on_content_area = false;
	public TrackListNoteBookTab temporary_tab = TrackListNoteBookTab.TRACKLIST;
	public FullscreenToolbar fullscreentoolbar;
	public VBox videovbox;
	public LyricsView lyricsView;
	public VideoScreen videoscreen;
	public HPaned hpaned;
	public Entry searchEntryMB;
	public PlayPauseButton playPauseButton;
	public ControlButton previousButton;
	public ControlButton nextButton;
	public ControlButton stopButton;
	public Notebook browsernotebook;
	public Notebook tracklistnotebook;
	public AlbumImage albumimage;
	public TrackProgressBar songProgressBar;
	public MediaBrowser mediaBr = null;
	public TrackList trackList;
	public Gtk.Window fullscreenwindow;
	public Gtk.Button config_button;
	
	private bool media_browser_visible { 
		get {
			return _media_browser_visible;
		} 
		set {
			if((value == true) && (_media_browser_visible != value)) {
				hide_button.label   = HIDEMEDIABROWSER;
				hide_button_1.label = HIDEMEDIABROWSER;
				hide_button_2.label = HIDEMEDIABROWSER;
			}
			else if((value == false) && (_media_browser_visible != value)) {
				hide_button.label   = SHOWMEDIABROWSER;
				hide_button_1.label = SHOWMEDIABROWSER;
				hide_button_2.label = SHOWMEDIABROWSER;
			}
			_media_browser_visible = value;
		} 
	}
	
	public int repeatState { get; set; }
	public bool fullscreenwindowvisible { get; set; }

	public signal void sign_pos_changed(double fraction);
	public signal void sign_volume_changed(double fraction);
	public signal void sign_drag_over_content_area();

	private enum Repeat {
		NOT_AT_ALL = 0,
		SINGLE,
		ALL,
		RANDOM
	}

	private const ActionEntry[] action_entries = {
		{ "FileMenuAction", null, N_("_File") },
			{ "AddRemoveAction", Gtk.STOCK_ADD, N_("_Add or Remove media"), null, N_("manage the content of the xnoise media library"), on_menu_add},
			{ "QuitAction", STOCK_QUIT, null, null, null, quit_now},
		{ "EditMenuAction", null, N_("_Edit") },
			{ "SettingsAction", STOCK_PREFERENCES, null, null, null, on_settings_edit},
		{ "ViewMenuAction", null, N_("_View") },
			{ "ShowTracklistAction", Gtk.STOCK_INDEX, N_("_Tracklist"), null, N_("Go to the tracklist."), on_show_tracklist_menu_clicked},
			{ "ShowVideoAction", Gtk.STOCK_LEAVE_FULLSCREEN, N_("_Video screen"), null, N_("Go to the video screen in the main window."), on_show_video_menu_clicked},
			{ "ShowLyricsAction", Gtk.STOCK_EDIT, N_("_Lyrics"), null, N_("Go to the lyrics view."), on_show_lyrics_menu_clicked},
		{ "HelpMenuAction", null, N_("_Help") },
			{ "AboutAction", STOCK_ABOUT, null, null, null, on_help_about},
		{ "ConfigMenuAction", null, N_("_Config") }
	};

	private const Gtk.TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};

	public UIManager get_ui_manager() {
		return ui_manager;
	}
	
	private bool _compact_layout;
	public bool compact_layout {
		get {
			return _compact_layout;
		}
		set {
			if(value) {
				if(_compact_layout) return;
				if(menubar.get_parent() != null) {
					menuvbox.remove(menubar);
				}
				if(a_frame_config_button != null && config_button.get_parent() == null) 
					a_frame_config_button.add(config_button);
				config_button.show_all();
				if(config_button_menu.attach_widget != null)
					config_button_menu.detach();
				config_button_menu.attach_to_widget(config_button, (a, x) => {});
				stopButton.hide();
			}
			else {
				config_button_menu.detach();
				if(a_frame_config_button != null && config_button.is_realized()) 
					a_frame_config_button.remove(config_button);
				config_button.unrealize();
				if(menubar.get_parent() == null) {
					menuvbox.add(menubar);
					menubar.show();
				}
				stopButton.show_all();
			}
		}
	}

	public MainWindow() {
		this.xn = Main.instance;
		par.iparams_register(this);
		xn.gPl.sign_volume_changed.connect(
			(val) => { this.current_volume = val; }
		);
		create_widgets();

		//initialization of videoscreen
		initialize_video_screen();

		//initialize screen saver management
		ssm = new ScreenSaverManager();

		//restore last state
		add_lastused_titles_to_tracklist();

		notify["repeatState"].connect(on_repeatState_changed);
		notify["fullscreenwindowvisible"].connect(on_fullscreenwindowvisible);

		buffer_last_page = 0;

		global.caught_eos_from_player.connect(on_caught_eos_from_player);
		global.tag_changed.connect(this.set_displayed_title);
		xn.gPl.sign_video_playing.connect( () => { 
			//handle stop signal from gst player
			if(!this.fullscreenwindowvisible)
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
		});
		this.sign_pos_changed.connect( (s, fraction) => {
			xn.gPl.gst_position = fraction;
		});
		
		this.check_resize.connect( () => {
			if(this.window == null)
				return;
			int w, x;
			this.get_size(out w, out x);
			if(w != window_width) {
				window_width = w;
				this.trackList.handle_resize();
			}
		});
	}
	
	private void initialize_video_screen() {
		videoscreen.realize();
		ensure_native(videoscreen.window);
		// dummy drag'n'drop to get drag motion event
		Gtk.drag_dest_set(
			videoscreen,
			Gtk.DestDefaults.MOTION,
			this.target_list,
			Gdk.DragAction.COPY|
			Gdk.DragAction.DEFAULT
			);
		Gtk.drag_dest_set(
			lyricsView,
			Gtk.DestDefaults.MOTION,
			this.target_list,
			Gdk.DragAction.COPY|
			Gdk.DragAction.DEFAULT
			);
		videoscreen.button_press_event.connect(on_video_da_button_press);
		sign_drag_over_content_area.connect(() => {
			//switch to tracklist for dropping
			if(!fullscreenwindowvisible)
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
		});
		videoscreen.drag_motion.connect((sender,context,x,y,t) => {
			temporary_tab = TrackListNoteBookTab.VIDEO;
			sign_drag_over_content_area();
			return true;
		});
		
		lyricsView.drag_motion.connect((sender,context,x,y,t) => {
			temporary_tab = TrackListNoteBookTab.LYRICS;
			sign_drag_over_content_area();
			return true;
		});
		
	}

	private void on_caught_eos_from_player() {
		this.change_track(ControlButton.Direction.NEXT, true);
	}

	private void on_fullscreenwindowvisible(GLib.ParamSpec pspec) {
		if(fullscreenwindowvisible) ssm.inhibit();
		else ssm.uninhibit();
		
		this.showvideobuttonTL.set_sensitive(!fullscreenwindowvisible);
		this.showvideobuttonLY.set_sensitive(!fullscreenwindowvisible);
	}

	private void add_lastused_titles_to_tracklist() {
		DbBrowser dbBr = null;
		try {
			dbBr = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		string[] uris = dbBr.get_lastused_uris();
		foreach(unowned string uri in uris) {
			File file = File.new_for_commandline_arg(uri);
/*
			if(global.position_reference==null) {
				global.current_uri = uri;
				global.state_playing = true;
			}
*/
			if(file.get_uri_scheme() != "http") {
				TrackData td;
				if(dbBr.get_trackdata_for_uri(uri, out td)) {
					this.trackList.tracklistmodel.insert_title(null,
					                                           (int)td.Tracknumber,
					                                           td.Title,
					                                           td.Album,
					                                           td.Artist,
					                                           td.Length,
					                                           false,
					                                           uri);
				}
			}
			else {
				TrackData td;
				if(dbBr.get_trackdata_for_stream(uri, out td)) {
					this.trackList.tracklistmodel.insert_title(null,
					                                           0,
					                                           td.Title,
					                                           "",
					                                           "",
					                                           0,
					                                           false,
					                                           uri);
				}
			}
		}
	}
	
	public void position_config_menu(Menu menu, out int x, out int y, out bool push) {
		//the upper right corner of the popup menu should be just beneath the lower right corner of the button

		int o_x, o_y, o_height, o_width, o_depth;
		config_button.get_window().get_geometry(out o_x, out o_y, out o_width, out o_height, out o_depth);
		Requisition req; 
		config_button.get_child_requisition(out req);
		/* get_allocation is broken in vapi - we should remove this direct field access as soon as it is fixed */
		//Did you file a bug for this?
		Allocation alloc;
		alloc = config_button.allocation;
		x = o_x + alloc.x + req.width;
		y = o_y + alloc.y + req.height;
		
		Requisition menu_req;
		menu.get_child_requisition(out menu_req);
		x -= menu_req.width;
		push= true;
	}

	public void toggle_fullscreen() {
		if(!fullscreenwindowvisible) {
			int monitor;
			Gdk.Rectangle rectangle;
			Gdk.Screen screen = this.videoscreen.get_screen();
			monitor = screen.get_monitor_at_window(this.videoscreen.window);
			screen.get_monitor_geometry(monitor, out rectangle);
			fullscreenwindow.move(rectangle.x, rectangle.y);
			fullscreenwindow.fullscreen();
			this.videoscreen.window.fullscreen();
			fullscreenwindow.show_all();
			this.videoscreen.reparent(fullscreenwindow);
			this.videoscreen.window.process_updates(true);

			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
			fullscreenwindowvisible = true;
			fullscreentoolbar.show();
		}
		else {
			this.videoscreen.window.unfullscreen();
			this.videoscreen.reparent(videovbox);
			fullscreenwindow.hide_all();

			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
			fullscreenwindowvisible = false;
			this.videovbox.show();
			fullscreentoolbar.hide();
		}
	}

	private bool on_video_da_button_press(Gdk.EventButton e) {
		if(!((e.button==1)&&(e.type==Gdk.EventType.@2BUTTON_PRESS))) {
			return false; //exit here, if it's no double-click
		}
		else {
			toggle_fullscreen();
		}
		return true;
	}

	private void on_repeatState_changed(GLib.ParamSpec pspec) {
		switch(this.repeatState) {
			case Repeat.NOT_AT_ALL : {
				//TODO: create some other images
				repeatLabel.label = _("no repeat");
				//repeatImage.stock = Gtk.STOCK_EXECUTE;
				break;
			}
			case Repeat.SINGLE : {
				repeatLabel.label = _("repeat single");
				//repeatImage.stock = Gtk.STOCK_REDO;
				break;
			}
			case Repeat.ALL : {
				repeatLabel.label = _("repeat all");
				//repeatImage.stock = Gtk.STOCK_REFRESH;
				break;
			}
			case Repeat.RANDOM : {
				repeatLabel.label = _("random play");
				//repeatImage.stock = Gtk.STOCK_JUMP_TO;
				break;
			}
		}
	}

	private bool on_window_state_change(Gtk.Widget sender, Gdk.EventWindowState e) {
		if(e.new_window_state==Gdk.WindowState.FULLSCREEN) {
			is_fullscreen = true;
		}
		else if(e.new_window_state==Gdk.WindowState.ICONIFIED) {
			this.get_position(out _posX_buffer, out _posY_buffer);
			is_fullscreen = false;
		}
		else {
			is_fullscreen = false;
		}
		return false;
	}

	private StatusIcon create_tray_icon() {
		StatusIcon icon = new StatusIcon.from_file(Config.UIDIR + "xnoise_bruit_48x48.png");
		icon.set_tooltip_text("xnoise media player");
		icon.button_press_event.connect(on_trayicon_clicked);
		return icon;
	}

	private StatusIcon trayicon;
	private Menu menu;
	public Image playpause_popup_image;

	private Menu add_menu_to_trayicon() {
		var traymenu = new Menu();

		playpause_popup_image = new Image();
		playpause_popup_image.set_from_stock(STOCK_MEDIA_PLAY, IconSize.MENU);
		xn.gPl.sign_playing.connect( () => {
			this.playpause_popup_image.set_from_stock(STOCK_MEDIA_PAUSE, IconSize.MENU);
		});
		xn.gPl.sign_stopped.connect( () => {
			if(this.playpause_popup_image==null) print("this.playpause_popup_image == null\n");
			this.playpause_popup_image.set_from_stock(STOCK_MEDIA_PLAY, IconSize.MENU);
		});
		xn.gPl.sign_paused.connect( () => {
			this.playpause_popup_image.set_from_stock(STOCK_MEDIA_PLAY, IconSize.MENU);
		});

		var playLabel = new Label(_("Play/Pause"));
		playLabel.set_alignment(0, 0);
		playLabel.set_width_chars(20);
		var playpauseItem = new MenuItem();
		var playHbox = new HBox(false,1);
		playHbox.set_spacing(10);
		playHbox.pack_start(playpause_popup_image, false, true, 0);
		playHbox.pack_start(playLabel, true, true, 0);
		playpauseItem.add(playHbox);
		playpauseItem.activate.connect(playPauseButton.on_menu_clicked);
		traymenu.append(playpauseItem);

		var previousImage = new Image();
		previousImage.set_from_stock(STOCK_MEDIA_PREVIOUS, IconSize.MENU);
		var previousLabel = new Label(_("Previous"));
		previousLabel.set_alignment(0, 0);
		var previousItem = new MenuItem();
		var previousHbox = new HBox(false,1);
		previousHbox.set_spacing(10);
		previousHbox.pack_start(previousImage, false, true, 0);
		previousHbox.pack_start(previousLabel, true, true, 0);
		previousItem.add(previousHbox);
		previousItem.activate.connect( () => {
			this.handle_control_button_click(previousButton, ControlButton.Direction.PREVIOUS);
		});
		traymenu.append(previousItem);

		var nextImage = new Image();
		nextImage.set_from_stock(STOCK_MEDIA_NEXT, IconSize.MENU);
		var nextLabel = new Label(_("Next"));
		nextLabel.set_alignment(0, 0);
		var nextItem = new MenuItem();
		var nextHbox = new HBox(false,1);
		nextHbox.set_spacing(10);
		nextHbox.pack_start(nextImage, false, true, 0);
		nextHbox.pack_start(nextLabel, true, true, 0);
		nextItem.add(nextHbox);
		nextItem.activate.connect( () => {
			this.handle_control_button_click(nextButton, ControlButton.Direction.NEXT);
		});
		traymenu.append(nextItem);

		var separator = new SeparatorMenuItem();
		traymenu.append(separator);

		var exitImage = new Image();
		exitImage.set_from_stock(STOCK_QUIT, IconSize.MENU);
		var exitLabel = new Label(_("Exit"));
		exitLabel.set_alignment(0, 0);
		var exitItem = new MenuItem();
		var exitHbox = new HBox(false,1);
		exitHbox.set_spacing(10);
		exitHbox.pack_start(exitImage, false, true, 0);
		exitHbox.pack_start(exitLabel, true, true, 0);
		exitItem.add(exitHbox);
		exitItem.activate.connect(quit_now);
		traymenu.append(exitItem);

		traymenu.show_all();
		return traymenu;
	}

	private void trayicon_menu_popup(StatusIcon i, uint button, uint activateTime) {
		menu.popup(null, null, null, 0, activateTime);
	}

	private const int KEY_F11 = 0xFFC8;
	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
		//print("%d : %d\n",(int)e.keyval, (int)e.state);
		switch(e.keyval) {
			case KEY_F11:
				this.toggle_mainwindow_fullscreen();
				break;
			default:
				break;
		}
		return false;
	}
	
	private const int 1_KEY = 0x0031;
	private const int 2_KEY = 0x0032;
	private const int 3_KEY = 0x0033;
	private const int F_KEY = 0x0066;
	private const int D_KEY = 0x0064;
	private const int M_KEY = 0x006D;
	private const int SPACE_KEY = 0x0020;
	private bool on_key_pressed(Gtk.Widget sender, Gdk.EventKey e) {
		//print("%d : %d\n",(int)e.keyval, (int)e.state);
		switch(e.keyval) {
			case F_KEY: {
					if(e.state != 0x0014) // Ctrl Modifier
						return false;
					searchEntryMB.grab_focus();
				}
				return true;
			case D_KEY: {
					if(e.state != 0x0014) // Ctrl Modifier
						return false;
					searchEntryMB.text = "";
					searchEntryMB.modify_base(StateType.NORMAL, null);
					this.mediaBr.on_searchtext_changed("");
				}
				return true;
			case 1_KEY: {
					if(e.state != 0x0018) // ALT Modifier
						return false;
					this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
				}
				return true;
			case 2_KEY: {
					if(e.state != 0x0018) // ALT Modifier
						return false;
					this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
				}
				return true;
			case 3_KEY: {
					if(e.state != 0x0018) // ALT Modifier
						return false;
					this.tracklistnotebook.set_current_page(TrackListNoteBookTab.LYRICS);
				}
				return true;
			case SPACE_KEY: {
					if(searchEntryMB.has_focus)
						return false;
					playPauseButton.clicked();
				}
				return true;
			case M_KEY: {
					if(!this.searchEntryMB.has_focus)
						toggle_media_browser_visibility();
					break;
				}
			default:
				break;
		}
		return false;
	}
	
	private void quit_now() {
		xn.quit();
	}

	private void on_show_video_menu_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
	}

	private void on_show_tracklist_menu_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
	}

	private void on_show_lyrics_menu_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.LYRICS);
	}

	// This is used for the main window
	private void toggle_mainwindow_fullscreen() {
		if(is_fullscreen) {
			print("was fullscreen before\n");
			this.unfullscreen();
		}
		else {
			this.fullscreen();
		}
	}

	private void toggle_window_visbility() {
		if(this.is_active) {
			this.get_position(out _posX_buffer, out _posY_buffer);
			this.hide();
		}
		else if(this.window.is_visible()==true) {
			this.move(_posX_buffer, _posY_buffer);
			this.present();
		}
		else {
			this.move(_posX_buffer, _posY_buffer);
			this.present();
		}
	}


	//REGION IParameter

	public void read_params_data() {
		int posX = par.get_int_value("posX");
		int posY = par.get_int_value("posY");
		this.move(posX, posY);
		int wi = par.get_int_value("width");
		int he = par.get_int_value("height");
		if (wi > 0 && he > 0) {
			this.resize(wi, he);
		}
		this.repeatState = par.get_int_value("repeatstate");
		double volSlider = par.get_double_value("volume");
		if((volSlider < 0.0)||
		   (volSlider > 1.0)) {
			xn.gPl.volume = 0.5;
		}
		else {
			xn.gPl.volume = volSlider;
		}

		int hp_position = par.get_int_value("hp_position");
		if (hp_position > 0) {
			this.hpaned.set_position(hp_position);
		}
	}

	public void write_params_data() {
		int posX, posY;
		this.get_position(out posX, out posY);
		par.set_int_value("posX", posX);
		par.set_int_value("posY", posY);

		int  wi, he;
		this.get_size(out wi, out he);
		par.set_int_value("width", wi);
		par.set_int_value("height", he);

		par.set_int_value("hp_position", this.hpaned.get_position());

		par.set_int_value("repeatstate", repeatState);

		par.set_double_value("volume", current_volume);
	}

	//END REGION IParameter


	public void stop() {
		global.track_state = GlobalAccess.TrackState.STOPPED;
		global.current_uri = null;
	}

	// This function changes the current song to the next or previous in the
	// tracklist. handle_repeat_state should be true if the calling is not
	// coming from a button, but, e.g. from a EOS signal handler
	public void change_track(ControlButton.Direction direction, bool handle_repeat_state = false) {
		unowned TreeIter iter;
		bool trackList_is_empty;
		TreePath path = null;
		int rowcount = 0;
		bool used_next_pos = false;

		rowcount = (int)trackList.tracklistmodel.iter_n_children(null);

		// if no track is in the list, it does not make sense to go any further
		if(rowcount == 0) {
			stop();
			return;
		}
		// get_active_path sets first path, if active is not available
		if(!trackList.tracklistmodel.get_active_path(out path, out used_next_pos)) {
			stop();
			return;
		}
		TreePath tmp_path = null;
		tmp_path = path;
		if((repeatState == Repeat.RANDOM)) {
			// handle RANDOM
			if(!this.trackList.tracklistmodel.get_random_row(ref path) || 
			   (path.to_string() == tmp_path.to_string())) {
				if(!this.trackList.tracklistmodel.get_random_row(ref path)) //try once again
					return;
			}
		}
		else {
			if(!used_next_pos) {
				// get next or previous path
				if((!(handle_repeat_state && (repeatState == Repeat.SINGLE)))) {
					if(path == null) 
						return;
					if(!this.trackList.tracklistmodel.path_is_last_row(ref path,
					                                                   out trackList_is_empty)) {
						//print(" ! path_is_last_row\n");
						if(direction == ControlButton.Direction.NEXT) {
							path.next();
						}
						else if(direction == ControlButton.Direction.PREVIOUS) {
							if(path.to_string() != "0") // only do something if are not in the first row
								path.prev();
							else
								return;
						}
					}
					else {
						//print("path_is_last_row\n");
						if(direction == ControlButton.Direction.NEXT) {
							if(repeatState == Repeat.ALL) {
								// only jump to first is repeat all is set
								trackList.tracklistmodel.get_first_row(ref path);
							}
							else {
								stop();
							}
						}
						else if(direction == ControlButton.Direction.PREVIOUS) {
							if(path.to_string() != "0") // only do something if are not in the first row
								path.prev();
							else
								return;
						}
					}
				}
				else {
					tmp_path = path;
				}
			}
		}

		if(path == null) {
			stop();
			return;
		}
		if(!trackList.tracklistmodel.get_iter(out iter, path))
			return;

		global.position_reference = new TreeRowReference(trackList.tracklistmodel, path);

		if(global.track_state == GlobalAccess.TrackState.PLAYING)
			trackList.set_focus_on_iter(ref iter);

		if(path.to_string() == tmp_path.to_string()) {
			if((repeatState == Repeat.SINGLE)||((repeatState == Repeat.ALL && rowcount == 1))) {
				// Explicit restart
				global.do_restart_of_current_track();
			}
			else{
				// Explicit stop, because there is no more 
				stop();
			}
		}
	}

	private void on_remove_all_button_clicked() {
		global.position_reference = null;
		var store = (ListStore)trackList.get_model();
		store.clear();
	}

	private void on_repeat_button_clicked(Button sender) {
		int temprepeatState = this.repeatState;
		temprepeatState += 1;
		if(temprepeatState > 3) temprepeatState = 0;
		repeatState = temprepeatState;
	}

	private void on_remove_selected_button_clicked() {
		trackList.remove_selected_rows();
	}

	private void on_show_tracklist_button_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
	}

	private void on_show_video_button_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
	}
	
	//hide or show button
	private int hpaned_position_buffer = 0;
	private void toggle_media_browser_visibility() {
		if(media_browser_visible) {
			hpaned_position_buffer = hpaned.get_position(); // buffer last position
			hpaned.set_position(0);
			media_browser_visible = false;
		}
		else {
			if(hpaned_position_buffer > 20) { // min value
				hpaned.set_position(hpaned_position_buffer);
			}
			else {
				hpaned.set_position(200); //use this if nothing else is available
			}
			media_browser_visible = true;
		}
	}

	private void on_show_lyrics_button_clicked() {
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.LYRICS);
	}

	private bool on_close() {
		this.get_position(out _posX_buffer, out _posY_buffer);
		this.hide();
		return true;
	}

	private void on_help_about() {
		var dialog = new AboutDialog ();
		dialog.run();
		dialog.destroy();
	}

	private AddMediaDialog mfd;
	private void on_menu_add() {
		mfd = new AddMediaDialog();
		mfd.sign_finish.connect( () => {
			mfd = null;
			Idle.add(mediaBr.change_model_data);
		});
	}

	private void on_settings_edit() {
		var settingsD = new SettingsDialog();
		settingsD.sign_finish.connect( () => {
			settingsD = null;
		});
	}

	public void set_displayed_title(ref string? newuri, string? tagname, string? tagvalue) {
		string text, album, artist, title, organization, location, genre;
		string basename = null;
		if((newuri == "")|(newuri == null)) {
			text = "<b>XNOISE</b>\nready to rock! ;-)";
			song_title_label.set_text(text);
			song_title_label.use_markup = true;
			return;
		}
		File file = File.new_for_uri(newuri);
		if(!xn.gPl.is_stream) {
			basename = file.get_basename();
			if(global.current_artist!=null) {
				artist = remove_linebreaks(global.current_artist);
			}
			else {
				artist = "unknown artist";
			}
			if(global.current_title!=null) {
				title = remove_linebreaks(global.current_title);
			}
			else {
				title = "unknown title";
			}
			if(global.current_album!=null) {
				album = remove_linebreaks(global.current_album);
			}
			else {
				album = "unknown album";
			}
			if((newuri!=null) && (newuri!="")) {
				text = Markup.printf_escaped("<b>%s</b>\n<i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>",
					title,
					_("by"),
					artist,
					_("on"),
					album
					);
				if(album=="unknown album" &&
				   artist=="unknown artist" &&
				   title=="unknown title")
					if((basename == null)||(basename == "")) {
						text = Markup.printf_escaped("<b>...</b>");
					}
					else {
						text = Markup.printf_escaped("<b>%s</b>", basename);
					}
			}
			else {
				if((!xn.gPl.playing)&&
					(!xn.gPl.paused)) {
					text = "<b>XNOISE</b>\nready to rock! ;-)";
				}
				else {
					text = "<b>%s</b>\n<i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>".printf(
						_("unknown title"),
						_("by"),
						_("unknown artist"),
						_("on"),
						_("unknown album")
						);
				}
			}
		}
		else { // IS STREAM
			if(global.current_artist!=null)
				artist = remove_linebreaks(global.current_artist);
			else
				artist = "unknown artist";

			if(global.current_title!=null)
				title = remove_linebreaks(global.current_title);
			else
				title = "unknown title";

			if(global.current_album!=null)
				album = remove_linebreaks(global.current_album);
			else
				album = "unknown album";

			if(global.current_organization!=null)
				organization = remove_linebreaks(global.current_organization);
			else
				organization = "unknown organization";

			if(global.current_genre!=null)
				genre = remove_linebreaks(global.current_genre);
			else
				genre = "unknown genre";

			if(global.current_location!=null)
				location = remove_linebreaks(global.current_location);
			else
				location = "unknown location";

			if((newuri!=null) && (newuri!="")) {
				text = Markup.printf_escaped("<b>%s</b>\n<i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>",
					title,
					_("by"),
					artist,
					_("on"),
					album
					);
				if(album=="unknown album" &&
				   artist=="unknown artist" &&
				   title=="unknown title") {

					if(organization!="unknown organization")
						text = Markup.printf_escaped("<b>%s</b>", _("unknown organization"));
					else if(location!="unknown location")
						text = Markup.printf_escaped("<b>%s</b>", _("unknown location"));
					else
						text = Markup.printf_escaped("<b>%s</b>", file.get_uri());
				}
			}
			else {
				if((!xn.gPl.playing) &&
				   (!xn.gPl.paused)) {
					text = "<b>XNOISE</b>\nready to rock! ;-)";
				}
				else {
					text = "<b>%s</b>\n<i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>".printf(
						_("unknown title"),
						_("by"),
						_("unknown artist"),
						_("on"),
						_("unknown album")
						);
				}
			}
		}
		song_title_label.set_text(text);
		song_title_label.use_markup = true;
	}

	private bool on_trayicon_clicked(Gdk.EventButton e) {
		switch(e.button) {
			case 2:
				//ugly, we should move play/resume code out of there.
				this.playPauseButton.on_clicked(new Gtk.Button());
				break;
			default:
				break;
		}
		return false;
	}

	private const double VOL_CHANGE = 0.04;
	private bool on_trayicon_scrolled(Gtk.StatusIcon sender, Gdk.Event event) {
		if(event.scroll.direction == Gdk.ScrollDirection.DOWN) {
			double temp = 0.0;
			temp = this.xn.gPl.volume - VOL_CHANGE;
			if(temp < 0.0) temp = 0.0;
			this.xn.gPl.volume = temp;
		}
		else if(event.scroll.direction == Gdk.ScrollDirection.UP) {
			double temp = 0.0;
			temp = this.xn.gPl.volume + VOL_CHANGE;
			if(temp > 1.0) temp = 1.0;
			this.xn.gPl.volume = temp;
		}
		return false;
	}

	private void handle_control_button_click(ControlButton sender, ControlButton.Direction dir) {
		if(dir == ControlButton.Direction.NEXT || dir == ControlButton.Direction.PREVIOUS)
			this.change_track(dir);
		else if(dir == ControlButton.Direction.STOP)
			this.stop();
	}

	private void create_widgets() {
		try {
			Builder gb = new Gtk.Builder();
			gb.add_from_file(MAIN_UI_FILE);

			this.mainvbox = gb.get_object("mainvbox") as Gtk.VBox;
			this.title = "xnoise media player";
			this.set_icon_from_file(APPICON);
			
			this.contentvbox = gb.get_object("contentvbox") as Gtk.VBox;

			//DRAWINGAREA FOR VIDEO
			videoscreen = xn.gPl.videoscreen;
			videovbox = gb.get_object("videovbox") as Gtk.VBox;
			videovbox.pack_start(videoscreen,true,true,0);

			//REMOVE TITLE OR ALL TITLES BUTTONS
			var removeAllButton            = gb.get_object("removeAllButton") as Gtk.Button;
			removeAllButton.can_focus      = false;
			removeAllButton.clicked.connect(this.on_remove_all_button_clicked);
			removeAllButton.set_tooltip_text(_("Remove all"));

			var removeSelectedButton       = gb.get_object("removeSelectedButton") as Gtk.Button;
			//removeSelectedButton.can_focus = false;
			removeSelectedButton.clicked.connect(this.on_remove_selected_button_clicked);
			removeSelectedButton.set_tooltip_text(_("Remove selected titles"));
			//--------------------

			//SHOW VIDEO BUTTONS
			showvideobuttonTL                = gb.get_object("showvideobuttonTL") as Gtk.Button;
			showvideobuttonTL.can_focus      = false;
			showvideobuttonTL.clicked.connect(this.on_show_video_button_clicked);
			showvideobuttonLY                = gb.get_object("showVideobuttonLY") as Gtk.Button;
			showvideobuttonLY.can_focus      = false;
			showvideobuttonLY.clicked.connect(this.on_show_video_button_clicked);
			//--------------------

			//SHOW TRACKLIST BUTTONS
			showtracklistbuttonLY            = gb.get_object("showTLbuttonLY") as Gtk.Button;
			showtracklistbuttonLY.can_focus  = false;
			showtracklistbuttonLY.clicked.connect(this.on_show_tracklist_button_clicked);
			showtracklistbuttonVid           = gb.get_object("showTLbuttonv") as Gtk.Button;
			showtracklistbuttonVid.can_focus = false;
			showtracklistbuttonVid.clicked.connect(this.on_show_tracklist_button_clicked);
			//--------------------

			//SHOW LYRICS BUTTONS
			showlyricsbuttonTL               = gb.get_object("showLyricsbuttonTL") as Gtk.Button;
			showlyricsbuttonTL.can_focus     = false;
			showlyricsbuttonTL.clicked.connect(this.on_show_lyrics_button_clicked);
			showlyricsbuttonVid              = gb.get_object("showLyricsbuttonv") as Gtk.Button;
			showlyricsbuttonVid.can_focus    = false;
			showlyricsbuttonVid.clicked.connect(this.on_show_lyrics_button_clicked);
			//--------------------

			//REPEAT MODE SELECTOR
			repeatButton                = gb.get_object("repeatButton") as Gtk.Button;
			repeatButton.can_focus      = false;
			repeatButton.clicked.connect(this.on_repeat_button_clicked);
			repeatLabel                 = gb.get_object("repeatLabel") as Gtk.Label;
			//repeatImage                 = gb.get_object("repeatImage01") as Gtk.Image;
			
			//give the button a slim appearance
			RcStyle repeat_button_style = new RcStyle();
			repeat_button_style.xthickness = 0;
			repeat_button_style.ythickness = 0;
			repeatButton.modify_style(repeat_button_style);			
			
			//--------------------

			//PLAYING TITLE IMAGE
			var aibox                     = gb.get_object("aibox") as Gtk.HBox;
			
			this.albumimage = new AlbumImage();
			EventBox ebox = new EventBox(); 
			ebox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK|Gdk.EventMask.LEAVE_NOTIFY_MASK);
			
			ebox.add(albumimage);
			aibox.add(ebox);
			
			aimage_timeout = 0;
			
			ebox.enter_notify_event.connect(ai_ebox_enter);

			ebox.leave_notify_event.connect( (s, e) => {
				if(aimage_timeout != 0) {
					Source.remove(aimage_timeout);
					aimage_timeout = 0;
					return false;
				}
				this.tracklistnotebook.set_current_page(buffer_last_page);
				return false;
			});

			//--------------------

			//PLAYING TITLE NAME
			this.song_title_label           = gb.get_object("song_title_label") as Gtk.Label;
			this.song_title_label.use_markup= true;
			//--------------------

			this.hpaned = gb.get_object("hpaned1") as Gtk.HPaned;
			this.hpaned.notify["position"].connect(() => {
				if(this.hpaned.position == 0)
					media_browser_visible = false;
				else
					media_browser_visible = true;
					
				if(this.window != null)
					this.trackList.handle_resize();
			});
			//----------------

			//VOLUME SLIDE BUTTON
			this.volumeSliderButton = new VolumeSliderButton();
			var afVol = gb.get_object("aFrameVolumeButton") as Gtk.AspectFrame;
			afVol.add(volumeSliderButton);

			//PLAYBACK CONTROLLS
			var playback_hbox = gb.get_object("playback_hbox") as Gtk.HBox;
			this.previousButton = new ControlButton(ControlButton.Direction.PREVIOUS);
			this.previousButton.sign_clicked.connect(handle_control_button_click);
			playback_hbox.pack_start(previousButton, false, false, 0);
			previousButton.show();
			this.playPauseButton = new PlayPauseButton();
			playback_hbox.pack_start(playPauseButton, false, false, 0);
			this.playPauseButton.show();
			this.stopButton = new ControlButton(ControlButton.Direction.STOP);
			this.stopButton.sign_clicked.connect(handle_control_button_click);
			playback_hbox.pack_start(stopButton, false, false, 0);
			this.nextButton = new ControlButton(ControlButton.Direction.NEXT);
			this.nextButton.sign_clicked.connect(handle_control_button_click);
			playback_hbox.pack_start(nextButton, false, false, 0);
			nextButton.show();

			//PROGRESS BAR
			var songprogress_viewport = gb.get_object("songprogress_viewport") as Gtk.Viewport;
			this.songProgressBar = new TrackProgressBar();
			//playback_hbox.pack_start(songProgressBar,false,false,0);
			songprogress_viewport.add(songProgressBar);
			//---------------------

			///BOX FOR MAIN MENU
			menuvbox                     = gb.get_object("menuvbox") as Gtk.VBox;

			///Tracklist (right)
			this.trackList = xn.tl; //new TrackList();
			this.trackList.set_size_request(100,100);
			var trackListScrollWin = gb.get_object("scroll_tracklist") as Gtk.ScrolledWindow;
			trackListScrollWin.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS);
			trackListScrollWin.add(this.trackList);

			///MediaBrowser (left)
			this.mediaBr = new MediaBrowser();
			this.mediaBr.set_size_request(100,100);
			var mediaBrScrollWin = gb.get_object("scroll_music_br") as Gtk.ScrolledWindow;
			mediaBrScrollWin.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC);
			mediaBrScrollWin.add(this.mediaBr);
			browsernotebook    = gb.get_object("notebook1") as Gtk.Notebook;
			tracklistnotebook  = gb.get_object("tracklistnotebook") as Gtk.Notebook;

			this.searchEntryMB = new Gtk.Entry();
			this.searchEntryMB.primary_icon_stock = Gtk.STOCK_FIND;
			this.searchEntryMB.secondary_icon_stock = Gtk.STOCK_CLEAR;
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, true);
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
			this.searchEntryMB.set_sensitive(true);
			this.searchEntryMB.key_release_event.connect( (s, e) => {
				int KEY_ENTER = 0xFF0D;
				var entry = (Entry)s;
				if((int)e.keyval == KEY_ENTER) {
					this.mediaBr.on_searchtext_changed(entry.text);
				}
				if(entry.text != "") {
					Gdk.Color color;
					Gdk.Color.parse("DarkSalmon", out color);
					entry.modify_base(StateType.NORMAL, color);
				}
				else {
					entry.modify_base(StateType.NORMAL, null);
				}
				return false;
			});

			this.searchEntryMB.icon_press.connect( (s, p0, p1) => { 
				// s:Entry, p0:Position, p1:Gdk.Event
				var entry = (Gtk.Entry)s;
				if(p0 == Gtk.EntryIconPosition.PRIMARY) {
					this.mediaBr.on_searchtext_changed(entry.text);
				}
				if(p0 == Gtk.EntryIconPosition.SECONDARY) {
					s.text = "";
					entry.modify_base(StateType.NORMAL, null);
					this.mediaBr.on_searchtext_changed(entry.text);
				}
			});
			
			var sexyentryBox = gb.get_object("sexyentryBox") as Gtk.HBox;
			sexyentryBox.add(searchEntryMB);
			
			collapsebutton = gb.get_object("collapsebutton") as Gtk.Button;
			//var labelcoll =  gb.get_object("labelcoll") as Gtk.Label;
			//labelcoll.label = _("Collapse");
			collapsebutton.clicked.connect( () => {
				mediaBr.collapse_all();
			});

			hide_button = gb.get_object("hide_button") as Gtk.Button;
			hide_button.clicked.connect(this.toggle_media_browser_visibility);
			
			hide_button_1 = gb.get_object("hide_button_1") as Gtk.Button;
			hide_button_1.clicked.connect(this.toggle_media_browser_visibility);
			
			hide_button_2 = gb.get_object("hide_button_2") as Gtk.Button;
			hide_button_2.clicked.connect(this.toggle_media_browser_visibility); 

			///Textbuffer for the lyrics
			var scrolledlyricsview = gb.get_object("scrolledlyricsview") as Gtk.ScrolledWindow;
			this.lyricsView = new LyricsView();
			scrolledlyricsview.add(lyricsView);
			scrolledlyricsview.show_all();

			//Fullscreen window
			this.fullscreenwindow = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			this.fullscreenwindow.set_title("Xnoise media player - Fullscreen");
			this.fullscreenwindow.set_icon_from_file(APPICON);
			this.fullscreenwindow.set_events (Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
			this.fullscreenwindow.realize();

			//Toolbar shown in the fullscreen window
			this.fullscreentoolbar = new FullscreenToolbar(fullscreenwindow);
			
			//Config button for compact layout		
			//render the preferences icon with a down arrow next to it
			config_button_image = new Gtk.Image.from_stock(Gtk.STOCK_PREFERENCES, Gtk.IconSize.LARGE_TOOLBAR);
			config_button = new Button();
			var config_hbox = new HBox(false, 0);
			config_hbox.pack_start(config_button_image, false, false, 0);
			var config_arrow = new Arrow(ArrowType.DOWN, ShadowType.NONE);
			config_hbox.pack_start(config_arrow, false, false, 0);
			config_button.add(config_hbox);
			
			config_button.can_focus = false;
			config_button.set_relief(Gtk.ReliefStyle.NONE);
			a_frame_config_button = gb.get_object("aFrameConfigButton") as Gtk.AspectFrame;	
			
		}
		catch(GLib.Error e) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.OK,
			                                "Failed to build main window! \n" + e.message);
			msg.run();
			return;
		}

		//TRAYICON
		this.trayicon = create_tray_icon();
		this.menu     = add_menu_to_trayicon();

		//UIMANAGER FOR MENUS, THIS ALLOWS INJECTION OF ENTRIES BY PLUGINS
		action_group = new ActionGroup("XnoiseActions");
		action_group.set_translation_domain(Config.GETTEXT_PACKAGE);
		action_group.add_actions(action_entries, this);

		ui_manager.insert_action_group(action_group, 0);
		try {
			ui_manager.add_ui_from_file(MENU_UI_FILE);
		}
		catch(GLib.Error e) {
			print("%s\n", e.message);
		}
		
		
		menubar = (MenuBar)ui_manager.get_widget("/MainMenu");
		menuvbox.pack_start(menubar, false, false, 0);
		this.add(mainvbox);
		
		config_button_menu_root = (ImageMenuItem)ui_manager.get_widget("/ConfigButtonMenu/ConfigMenu");
		config_button_menu = (Menu)config_button_menu_root.get_submenu();
		config_button.clicked.connect(() => {
			config_button_menu.popup(null, null, position_config_menu, 0, Gtk.get_current_event_time());
		});
		if(par.get_int_value("compact_layout") > 0) compact_layout = true;
		else compact_layout = false;

		// TODO: Move these popup actions to uimanager
		this.trayicon.popup_menu.connect(this.trayicon_menu_popup);
		this.trayicon.activate.connect(this.toggle_window_visbility);
		this.trayicon.scroll_event.connect(this.on_trayicon_scrolled);

		this.delete_event.connect(this.on_close); //only send to tray
		this.key_release_event.connect(this.on_key_released);
		this.key_press_event.connect(this.on_key_pressed);
		this.window_state_event.connect(this.on_window_state_change);
	}
	
	public void display_info_bar(InfoBar bar) {
		contentvbox.pack_start(bar, false, false, 0);
		bar.show();
	}
	
	public void show_status_info(InfoBar bar) {
		contentvbox.pack_end(bar, false, false, 0);
		bar.show_all();
	}
	
	private bool ai_ebox_enter(Gtk.Widget sender, Gdk.EventCrossing e) {
		aimage_timeout = Timeout.add_seconds(1, () => {
					buffer_last_page = this.tracklistnotebook.get_current_page();
					if(global.image_path_large != null)
						this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
					this.aimage_timeout = 0;
					return false;
				});
		return false;
	}
}

