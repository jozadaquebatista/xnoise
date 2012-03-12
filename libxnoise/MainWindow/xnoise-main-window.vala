/* xnoise-main-window.vala
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
 * 	Jörn Magens
 */

using Gtk;

using Xnoise;
using Xnoise.Services;

[CCode (cname = "gdk_window_ensure_native")]
public extern bool ensure_native(Gdk.Window window);

[CCode (cname = "gtk_widget_style_get_property")]
public extern void widget_style_get_property(Gtk.Widget widget, string property_name, GLib.Value val);

public class Xnoise.MainWindow : Gtk.Window, IParams {
	private const string MAIN_UI_FILE     = Config.UIDIR + "main_window.ui";
	private const string MENU_UI_FILE     = Config.UIDIR + "main_ui.xml";
	private const string SHOWVIDEO        = _("Now Playing");
	private const string SHOWTRACKLIST    = _("Tracklist");
	private const string SHOWLYRICS       = _("Lyrics");
	private const string SHOWMEDIABROWSER = _("Show Media");
	private const string HIDEMEDIABROWSER = _("Hide Media");
	private unowned Main xn;
	private uint search_idlesource = 0;
	private UIManager ui_manager = new UIManager();
	private VolumeSliderButton volumeSliderButton;
	private int _posX;
	private int _posY;
	private uint aimage_timeout;
	private Gtk.Image config_button_image;
	private Gtk.Toolbar main_toolbar;
	private Button collapsebutton;
	private Button hide_button;
	private Button hide_button_1;
	private Button hide_button_2;
	private Image hide_button_image;
	private Image hide_button_image_1;
	private Image hide_button_image_2;
	private Button showlyricsbuttonVid;
	private Button showlyricsbuttonTL;
	private Button showtracklistbuttonVid;
	private Button showtracklistbuttonLY;
	private Button showvideobuttonTL;
	private Button showvideobuttonLY;
	private Button repeatButton;
	private int buffer_last_page;
	private Image repeatimage; 
	private Box menuvbox;
	private Box mainvbox;
	private Box infobox;
	private MenuBar menubar;
	private ImageMenuItem config_button_menu_root;
	private Gtk.Menu config_button_menu;
	private bool _media_browser_visible = true;
	private ulong active_notifier = 0;
	private ScreenSaverManager ssm = null;
	private List<Gtk.Action> actions_list = null;
	private Box mbbox01;
	public bool quit_if_closed;
	public ScrolledWindow mediaBrScrollWin = null;
	public ScrolledWindow trackListScrollWin = null;
	public Gtk.ActionGroup action_group;
	public bool _seek;
	public bool is_fullscreen = false;
	public bool drag_on_content_area = false;
	public TrackListNoteBookTab temporary_tab = TrackListNoteBookTab.TRACKLIST;
	public FullscreenToolbar fullscreentoolbar;
	public Box videovbox;
	public LyricsView lyricsView;
	public VideoScreen videoscreen;
	public Paned hpaned;
	public Entry searchEntryMB;
	public PlayPauseButton playPauseButton;
	public ControlButton previousButton;
	public ControlButton nextButton;
	public ControlButton stopButton;
	public Notebook browsernotebook;
	public Notebook tracklistnotebook;
	public AlbumImage albumimage;
	public TrackInfobar songProgressBar;
	public MediaBrowser mediaBr = null;
	public TrackList trackList;
	public Gtk.Window fullscreenwindow;
	public Gtk.Button config_button;
	private Gtk.ToolItem config_buttonTI;
	private static const string HIDE_LIBRARY = _("Hide Library");
	private static const string SHOW_LIBRARY = _("Show Library");
	
	private bool _not_show_art_on_hover_image;
	public bool not_show_art_on_hover_image {
		get { return _not_show_art_on_hover_image;  }
		set { _not_show_art_on_hover_image = value; }
	}
	
	private bool _active_lyrics;
	public bool active_lyrics {
		get {
			return _active_lyrics;
		}
		set {
			if(value == true) {
				showlyricsbuttonVid.show();
				showlyricsbuttonTL.show();
			}
			else {
				showlyricsbuttonVid.hide();
				showlyricsbuttonTL.hide();
			}
			Idle.add( () => {
				foreach(Gtk.Action a in action_group.list_actions())
					if(a.name == "ShowLyricsAction") a.set_visible(value);
				return false;
			});
			_active_lyrics = value;
		}
	}
	
	private bool media_browser_visible { 
		get {
			return _media_browser_visible;
		} 
		set {
			if((value == true) && (_media_browser_visible != value)) {
				hide_button_image.set_from_stock(Gtk.Stock.GO_BACK, Gtk.IconSize.MENU);
				hide_button_image_1.set_from_stock(Gtk.Stock.GO_BACK, Gtk.IconSize.MENU);
				hide_button_image_2.set_from_stock(Gtk.Stock.GO_BACK, Gtk.IconSize.MENU);
				hide_button.set_tooltip_text(HIDE_LIBRARY);
				hide_button_1.set_tooltip_text(HIDE_LIBRARY);
				hide_button_2.set_tooltip_text(HIDE_LIBRARY);
			}
			else if((value == false) && (_media_browser_visible != value)) {
				hide_button_image.set_from_stock(Gtk.Stock.GO_FORWARD, Gtk.IconSize.MENU);
				hide_button_image_1.set_from_stock(Gtk.Stock.GO_FORWARD, Gtk.IconSize.MENU);
				hide_button_image_2.set_from_stock(Gtk.Stock.GO_FORWARD, Gtk.IconSize.MENU);
				hide_button.set_tooltip_text(SHOW_LIBRARY);
				hide_button_1.set_tooltip_text(SHOW_LIBRARY);
				hide_button_2.set_tooltip_text(SHOW_LIBRARY);
			}
			_media_browser_visible = value;
		}
	}
	
	public PlayerRepeatMode repeatState { get; set; }
	public bool fullscreenwindowvisible { get; set; }

	public signal void sign_drag_over_content_area();

	public enum PlayerRepeatMode {
		NOT_AT_ALL = 0,
		SINGLE,
		ALL,
		RANDOM
	}

	private const Gtk.ActionEntry[] action_entries = {
		{ "FileMenuAction", null, N_("_File") },
			{ "OpenAction", Gtk.Stock.OPEN, null, null, N_("open file"), on_file_add},
			{ "OpenLocationAction", Gtk.Stock.NETWORK, N_("Open _Location"), null,
			   N_("open remote location"), on_location_add },
			{ "AddRemoveAction", Gtk.Stock.ADD, N_("_Add or Remove media"), null,
			   N_("manage the content of the xnoise media library"), on_menu_add},
			{ "QuitAction", Gtk.Stock.QUIT, null, null, null, quit_now},
		{ "EditMenuAction", null, N_("_Edit") },
			{ "ClearTrackListAction", Gtk.Stock.CLEAR, N_("C_lear tracklist"), null,
			   N_("Clear the tracklist"), on_remove_all_button_clicked},
			{ "RescanLibraryAction", Gtk.Stock.REFRESH, N_("R_escan collection"), null,
			   N_("R_escan collection"), on_reload_collection_button_clicked},
			{ "SettingsAction", Gtk.Stock.PREFERENCES, null, null, null, on_settings_edit},
		{ "ViewMenuAction", null, N_("_View") },
			{ "ShowTracklistAction", Gtk.Stock.INDEX, N_("_Tracklist"), null,
			   N_("Go to the tracklist."), on_show_tracklist_menu_clicked},
			{ "ShowVideoAction", Gtk.Stock.LEAVE_FULLSCREEN, N_("_Now Playing"), null,
			   N_("Go to the now playing screen in the main window."), on_show_video_menu_clicked},
			{ "ShowLyricsAction", Gtk.Stock.EDIT, N_("_Lyrics"), null,
			   N_("Go to the lyrics view."), on_show_lyrics_menu_clicked},
		{ "HelpMenuAction", null, N_("_Help") },
			{ "AboutAction", Gtk.Stock.ABOUT, null, null, null, on_help_about},
		{ "ConfigMenuAction", null, N_("_Config") }
	};

	private const Gtk.TargetEntry[] target_list = {
		{"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
		{"text/uri-list", TargetFlags.OTHER_APP, 0}
	};

	public UIManager get_ui_manager() {
		return ui_manager;
	}
	
	private bool _usestop;
	public bool usestop {
		get {
			return _usestop;
		}
		set {
			if(value == true)
				stopButton.show();
			else
				stopButton.hide();
			_usestop = value;
		}
	}
	
	private bool _compact_layout;
	public bool compact_layout {
		get {
			return _compact_layout;
		}
		set {
			if(value) {
				if(menubar.get_parent() != null)
					menuvbox.remove(menubar);
				
				config_buttonTI.show();
				config_button.show_all();
			}
			else {
				if(menubar.get_parent() == null) {
					menuvbox.add(menubar);
					menubar.show();
				}
				config_buttonTI.hide();
			}
			_compact_layout = value;
		}
	}

	public MainWindow() {
		this.xn = Main.instance;
		Params.iparams_register(this);
		create_widgets();
		
		//initialization of videoscreen
		initialize_video_screen();
		
		//initialize screen saver management
		ssm = new ScreenSaverManager();
		
		//restore last state
		var job = new Worker.Job(Worker.ExecutionType.ONCE, this.restore_lastused_job);
		db_worker.push_job(job);
	
		active_notifier = this.notify["is-active"].connect(buffer_position);
		this.notify["repeatState"].connect(on_repeatState_changed);
		this.notify["fullscreenwindowvisible"].connect(on_fullscreenwindowvisible);
		global.notify["media-import-in-progress"].connect(on_media_import_notify);
		
		buffer_last_page = 0;
		
		global.caught_eos_from_player.connect(on_caught_eos_from_player);
		global.tag_changed.connect(this.set_displayed_title);
		gst_player.sign_video_playing.connect( () => { 
			//handle stop signal from gst player
			if(!this.fullscreenwindowvisible)
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
		});
	}
	
	private void buffer_position() {
		this.get_position(out _posX, out _posY);
	}
	
	private void initialize_video_screen() {
		videoscreen.realize();
		ensure_native(videoscreen.get_window());
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
		handle_screensaver();
		if(fullscreenwindowvisible)
			global.player_state_changed.connect(handle_screensaver);
		
		this.showvideobuttonTL.set_sensitive(!fullscreenwindowvisible);
		this.showvideobuttonLY.set_sensitive(!fullscreenwindowvisible);
	}
	
	private void handle_screensaver() {
		if(fullscreenwindowvisible) {
			if (global.player_state == PlayerState.PLAYING) ssm.inhibit();
			else ssm.uninhibit();
		}
		else {
			global.player_state_changed.disconnect(handle_screensaver);
			ssm.uninhibit();
		}
	}
	
	private uint msg_id = 0;
	private bool restore_lastused_job(Worker.Job xjob) {
		uint lastused_cnt = 0;
		if((lastused_cnt = db_browser.count_lastused_items()) > 1500) {
			Timeout.add(200, () => {
				msg_id = userinfo.popup(UserInfo.RemovalType.TIMER_OR_CLOSE_BUTTON,
				                        UserInfo.ContentClass.INFO,
				                        _("Restoring %u tracks in the tracklist. This is a large number and can make startup of xnoise slower.".printf(lastused_cnt)),
				                        false,
				                        4,
				                        null);
				return false;
			});
		}
		var job = new Worker.Job(Worker.ExecutionType.REPEATED, this.add_lastused_titles_to_tracklist_job);
		job.big_counter[0] = 0;
		db_worker.push_job(job);
		return false;
	}

	private int LIMIT = 300;
	private bool add_lastused_titles_to_tracklist_job(Worker.Job job) {
		tl.set_model(null);
		job.items = db_browser.get_some_lastused_items(LIMIT, job.big_counter[0]);
		job.big_counter[0] += job.items.length;
		TrackData[] tda = {};
		TrackData[] tmp;
		string searchtext = EMPTYSTRING;
		foreach(Item? item in job.items) {
			tmp = item_converter.to_trackdata(item, ref searchtext);
			if(tmp == null) {
				var ttd = new TrackData();
				ttd.item = item;
				ttd.title = (item.text == null ? item.uri : item.text);
				tda += ttd;
				continue;
			}
			else {
				tda += tmp[0];
			}
		}
		var xjob = new Worker.Job(Worker.ExecutionType.ONCE, this.add_some_lastused_job);
		xjob.track_dat = tda;
		db_worker.push_job(xjob);
		if(job.items.length < LIMIT) {
			tl.set_model(tlm);
			print("got %d tracks for tracklist\n", job.big_counter[0]);
			if(userinfo != null)
				userinfo.popdown(msg_id);
			return false;
		}
		else {
			return true;
		}
	}
	
	private bool add_some_lastused_job(Worker.Job job) {
		Idle.add( () => {
			foreach(TrackData td in job.track_dat) {
				this.trackList.tracklistmodel.insert_title(null,
				                                           ref td,
				                                           false);
			}
			return false;
		});
		return false;
	}
	
	public void ask_for_initial_media_import() {
		uint msg_id = 0;
		var add_media_button = new Gtk.Button.with_label(_("Add media"));
		msg_id = userinfo.popup(UserInfo.RemovalType.CLOSE_BUTTON,
		                        UserInfo.ContentClass.QUESTION,
		                        _("You started xnoise for the first time. Do you want to import media into the library?"),
		                        false,
		                        5,
		                        add_media_button);
		add_media_button.clicked.connect( () => {
			on_media_add_on_first_start(msg_id);
		});
		
	}
	
	private void on_media_add_on_first_start(uint msg_id) {
		Idle.add( () => {
			userinfo.popdown(msg_id);
			return false;
		});
		mfd = new AddMediaDialog();
		mfd.sign_finish.connect( () => {
			mfd = null;
//			Idle.add(mediaBr.change_model_data);
		});
	}
	
	public void position_config_menu(Gtk.Menu menu, out int x, out int y, out bool push) {
		//the upper right corner of the popup menu should be just beneath the lower right corner of the button
		
		int o_x = 0, o_y = 0;
		this.get_window().get_position(out o_x, out o_y);
		Requisition req; 
		config_button.get_child_requisition(out req);
		Allocation alloc;
		config_button.get_allocation(out alloc);
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
			monitor = screen.get_monitor_at_window(this.videoscreen.get_window());
			screen.get_monitor_geometry(monitor, out rectangle);
			fullscreenwindow.move(rectangle.x, rectangle.y);
			fullscreenwindow.fullscreen();
			this.videoscreen.get_window().fullscreen();
			fullscreenwindow.show_all();
			this.videoscreen.reparent(fullscreenwindow);
			this.videoscreen.get_window().process_updates(true);
			
			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
			fullscreenwindowvisible = true;
			fullscreentoolbar.show();
			Idle.add( () => {
				this.videoscreen.trigger_expose();
				return false;
			});
		}
		else {
			this.videoscreen.get_window().unfullscreen();
			this.videoscreen.reparent(videovbox);
			fullscreenwindow.hide();
			videoscreen.set_vexpand(true);
			videoscreen.set_hexpand(true);
			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
			fullscreenwindowvisible = false;
			this.videovbox.show_all();
			fullscreentoolbar.hide();
			Idle.add( () => {
				this.videoscreen.trigger_expose();
				return false;
			});
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
			case PlayerRepeatMode.NOT_AT_ALL : {
				//TODO: create some other images
				repeatimage.set_from_icon_name("xn-no-repeat", IconSize.LARGE_TOOLBAR);
				repeatButton.set_tooltip_text(_("no repeat"));
				break;
			}
			case PlayerRepeatMode.SINGLE : {
				repeatimage.set_from_icon_name("xn-repeat-single", IconSize.LARGE_TOOLBAR);
				repeatButton.has_tooltip = true;
				repeatButton.set_tooltip_text(_("repeat single"));
				break;
			}
			case PlayerRepeatMode.ALL : {
				repeatimage.set_from_icon_name("xn-repeat-all", IconSize.LARGE_TOOLBAR);
				repeatButton.has_tooltip = true;
				repeatButton.set_tooltip_text(_("repeat all"));
				break;
			}
			case PlayerRepeatMode.RANDOM : {
				repeatimage.set_from_icon_name("xn-shuffle", IconSize.LARGE_TOOLBAR);
				repeatButton.has_tooltip = true;
				repeatButton.set_tooltip_text(_("random play"));
				break;
			}
		}
	}

	private bool on_window_state_change(Gtk.Widget sender, Gdk.EventWindowState e) {
		if(e.new_window_state==Gdk.WindowState.FULLSCREEN) {
			is_fullscreen = true;
		}
		else if(e.new_window_state==Gdk.WindowState.ICONIFIED) {
			this.get_position(out _posX, out _posY);
			is_fullscreen = false;
		}
		else {
			is_fullscreen = false;
		}
		return false;
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
	private const int Q_KEY = 0x0071;
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
					searchEntryMB.text = EMPTYSTRING;
					searchEntryMB.override_background_color(StateFlags.NORMAL, null);
					this.mediaBr.on_searchtext_changed();
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
					if(active_lyrics == false)
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
					if(e.state != 0x0014) // Ctrl Modifier
						return false;
					toggle_media_browser_visibility();
					break;
				}
			case Q_KEY: {
					if(e.state != 0x0014) // Ctrl Modifier
						return false;
					quit_now();
					break;
				}
			default:
				break;
		}
		return false;
	}
	
	private void quit_now() {
		this.get_position(out _posX, out _posY);
		this.hide();
		xn.quit();
	}

	private void on_show_video_menu_clicked() {
		Idle.add( () => {
			buffer_last_page = TrackListNoteBookTab.VIDEO;
			if(aimage_timeout != 0) {
				Source.remove(aimage_timeout);
				aimage_timeout = 0;
			}
			return false;
		});
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
	}

	private void on_show_tracklist_menu_clicked() {
		Idle.add( () => {
			buffer_last_page = TrackListNoteBookTab.TRACKLIST;
			if(aimage_timeout != 0) {
				Source.remove(aimage_timeout);
				aimage_timeout = 0;
			}
			return false;
		});
		this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
	}

	private void on_show_lyrics_menu_clicked() {
		Idle.add( () => {
			buffer_last_page = TrackListNoteBookTab.LYRICS;
			if(aimage_timeout != 0) {
				Source.remove(aimage_timeout);
				aimage_timeout = 0;
			}
			return false;
		});
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

	public void toggle_window_visbility() {
		if(active_notifier != 0) {
			this.disconnect(active_notifier);
			active_notifier = 0;
		}
		if(this.is_active) {
			this.get_position(out _posX, out _posY);
			this.hide();
		}
		else if(this.get_window().is_visible() == true) {
			this.move(_posX, _posY);
			this.present();
			active_notifier = this.notify["is-active"].connect(buffer_position);
		}
		else {
			this.move(_posX, _posY);
			this.present();
			active_notifier = this.notify["is-active"].connect(buffer_position);
		}
	}

	public void show_window() {
		if(this.get_window().is_visible() == true) {
			this.present();
		}
		else {
			this.move(_posX, _posY);
			this.present();
		}
	}


	//REGION IParameter

	public void read_params_data() {
		int posX = Params.get_int_value("posX");
		int posY = Params.get_int_value("posY");
		this.move(posX, posY);
		int wi = Params.get_int_value("width");
		int he = Params.get_int_value("height");
		if(wi > 0 && he > 0)
			this.resize(wi, he);
		
		this.repeatState = (PlayerRepeatMode)Params.get_int_value("repeatstate");
		int hp_position = Params.get_int_value("hp_position");
		if (hp_position > 0) {
			this.hpaned.set_position(hp_position);
		}
		
		quit_if_closed              = Params.get_bool_value("quit_if_closed");
		not_show_art_on_hover_image = Params.get_bool_value("not_show_art_on_hover_image");
		usestop                     = Params.get_bool_value("usestop");
		compact_layout              = Params.get_bool_value("compact_layout");
	}

	public void write_params_data() {
		Params.set_int_value("posX", _posX);
		Params.set_int_value("posY", _posY);
		int  wi, he;
		this.get_size(out wi, out he);
		Params.set_int_value("width", wi);
		Params.set_int_value("height", he);
		
		Params.set_int_value("hp_position", this.hpaned.get_position());
		
		Params.set_int_value("repeatstate", repeatState);
		Params.set_bool_value("usestop", this.usestop);
		Params.set_bool_value("compact_layout", this.compact_layout);
		Params.set_int_value("not_show_art_on_hover_image", (not_show_art_on_hover_image == true ? 1 : 0));
	}

	//END REGION IParameter


	public void stop() {
		global.player_state = PlayerState.STOPPED;
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
		if((repeatState == PlayerRepeatMode.RANDOM)) {
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
				if((!(handle_repeat_state && (repeatState == PlayerRepeatMode.SINGLE)))) {
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
							if(repeatState == PlayerRepeatMode.ALL) {
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

		if(global.player_state == PlayerState.PLAYING)
			trackList.set_focus_on_iter(ref iter);

		if(path.to_string() == tmp_path.to_string()) {
			if((repeatState == PlayerRepeatMode.SINGLE)||((repeatState == PlayerRepeatMode.ALL && rowcount == 1))) {
				// Explicit restart
				global.do_restart_of_current_track();
			}
			else{
				// Explicit stop, because there is no more 
				stop();
			}
		}
	}

	private void on_reload_collection_button_clicked() {
		media_importer.reimport_media_groups();
	}

	private void on_posjumper_button_clicked() {
		if(global.position_reference == null || !global.position_reference.valid())
			return;
		TreePath path = global.position_reference.get_path();
		var store = (ListStore)trackList.get_model();
		TreeIter iter;
		store.get_iter(out iter, path);
		tl.set_focus_on_iter(ref iter);
	}

	private void on_remove_all_button_clicked() {
		global.position_reference = null;
		var store = (ListStore)trackList.get_model();
		store.clear();
	}

	private void on_repeat_button_clicked(Button sender) {
		PlayerRepeatMode temprepeatState = this.repeatState;
		temprepeatState = (PlayerRepeatMode)((int)temprepeatState + 1);
		if((int)temprepeatState > 3) temprepeatState = (PlayerRepeatMode)0;
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
			mbbox01.hide();
			hpaned.set_position(0);
			media_browser_visible = false;
		}
		else {
			mbbox01.show();
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
		if(active_notifier != 0) {
			this.disconnect(active_notifier);
			active_notifier = 0;
		}
		
		if(!quit_if_closed) {
			this.get_position(out _posX, out _posY);
			this.hide();
			return true;
		}
		else {
			Idle.add( () => {
				quit_now();
				return false;
			});
			return true;
		}
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
//			Idle.add(mediaBr.change_model_data);
		});
	}

	private void on_location_add() {
		var radiodialog = new Gtk.Dialog();
		radiodialog.set_modal(true);
		radiodialog.set_transient_for(main_window);
		
		var radioentry = new Gtk.Entry();
		radioentry.set_width_chars(50);
		radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
		radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
		radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
			if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = EMPTYSTRING;
		});
		((Gtk.Box)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);
		
		var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
		radiocancelbutton.clicked.connect( () => {
			radiodialog.close();
			radiodialog = null;
		});
		
		var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
		radiookbutton.clicked.connect( () => {
			if(radioentry.text != null && radioentry.text.strip() != EMPTYSTRING) {
				Item? item = ItemHandlerManager.create_item(radioentry.text.strip());
				if(item.type == ItemType.UNKNOWN) {
					print("itemtype unknown\n");
					radiodialog.close();
					radiodialog = null;
					return;
				}
				ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
				if(tmp == null)
					return;
				unowned Action? action = tmp.get_action(item.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);
				
				if(action != null) {
					action.action(item, null);
				}
				else {
					print("action was null\n");
				}
			}
			radiodialog.close();
			radiodialog = null;
		});
		
		radiodialog.destroy_event.connect( () => {
			radiodialog = null;
			return true;
		});
		
		radiodialog.set_title(_("Enter the URL for playing"));
		radiodialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
		radiodialog.show_all();
		
		var display = radiodialog.get_display();
		Gdk.Atom atom = Gdk.SELECTION_CLIPBOARD;
		Clipboard clipboard = Clipboard.get_for_display(display, atom);
		string text = clipboard.wait_for_text();
		if(text != null && "://" in text) {
			//it's url, then paste in text input
			radioentry.text = text.strip();
		}
	}
	
	private void on_file_add() {
		Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
			_("Select media file"),
			this,
			Gtk.FileChooserAction.OPEN,
			Gtk.Stock.CANCEL,
			Gtk.ResponseType.CANCEL,
			Gtk.Stock.OPEN,
			Gtk.ResponseType.ACCEPT,
			null);
		fcdialog.select_multiple = true;
		fcdialog.set_modal(true);
		fcdialog.set_transient_for(main_window);
		fcdialog.set_current_folder(Environment.get_home_dir());
		if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
			GLib.SList<string> res = fcdialog.get_uris();
			if(!(res == null || res.data == EMPTYSTRING)) {
				foreach(string s in res) {
					Item? item = ItemHandlerManager.create_item(s);
					if(item.type == ItemType.UNKNOWN) {
						print("itemtype unknown\n");
						continue;
					}
					ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
					if(tmp == null)
						return;
					unowned Action? action = tmp.get_action(item.type, ActionContext.REQUESTED, ItemSelectionType.SINGLE);
					
					if(action != null) {
						action.action(item, null);
					}
					else {
						print("action was null\n");
					}
				}
			}
		}
		fcdialog.destroy();
		fcdialog = null;
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
		if((newuri == EMPTYSTRING)|(newuri == null)) {
			text = "<b>XNOISE</b> - ready to rock! ;-)";
			songProgressBar.title_text = text; //song_title_label.set_text(text);
			return;
		}
		File file = File.new_for_uri(newuri);
		if(!gst_player.is_stream) {
			basename = file.get_basename();
			if(global.current_artist!=null) {
				artist = remove_linebreaks(global.current_artist);
			}
			else {
				artist = UNKNOWN_ARTIST;
			}
			if(global.current_title!=null) {
				title = remove_linebreaks(global.current_title);
			}
			else {
				title = prepare_name_from_filename(basename);//UNKNOWN_TITLE;
			}
			if(global.current_album!=null) {
				album = remove_linebreaks(global.current_album);
			}
			else {
				album = UNKNOWN_ALBUM;
			}
			if((newuri!=null) && (newuri!=EMPTYSTRING)) {
				text = Markup.printf_escaped("<b>%s</b> <i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>",
					title,
					_("by"),
					artist,
					_("on"),
					album
					);
				if(album==UNKNOWN_ALBUM &&
				   artist==UNKNOWN_ARTIST &&
				   title==UNKNOWN_TITLE)
					if((basename == null)||(basename == EMPTYSTRING)) {
						text = Markup.printf_escaped("<b>...</b>");
					}
					else {
						text = Markup.printf_escaped("<b>%s</b>", prepare_name_from_filename(basename));
					}
			}
			else {
				if((!gst_player.playing)&&
					(!gst_player.paused)) {
					text = "<b>XNOISE</b>\nready to rock! ;-)";
				}
				else {
					text = "<b>%s</b> <i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>".printf(
						UNKNOWN_TITLE_LOCALIZED,
						_("by"),
						UNKNOWN_ARTIST_LOCALIZED,
						_("on"),
						UNKNOWN_ALBUM_LOCALIZED
						);
				}
			}
		}
		else { // IS STREAM
			if(global.current_artist!=null)
				artist = remove_linebreaks(global.current_artist);
			else
				artist = UNKNOWN_ARTIST;

			if(global.current_title!=null)
				title = remove_linebreaks(global.current_title);
			else
				title = UNKNOWN_TITLE;

			if(global.current_album!=null)
				album = remove_linebreaks(global.current_album);
			else
				album = UNKNOWN_ALBUM;

			if(global.current_organization!=null)
				organization = remove_linebreaks(global.current_organization);
			else
				organization = UNKNOWN_ORGANIZATION;

			if(global.current_genre!=null)
				genre = remove_linebreaks(global.current_genre);
			else
				genre = UNKNOWN_GENRE;

			if(global.current_location!=null)
				location = remove_linebreaks(global.current_location);
			else
				location = UNKNOWN_LOCATION;

			if((newuri!=null) && (newuri!=EMPTYSTRING)) {
				text = Markup.printf_escaped("<b>%s</b> <i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>",
					title,
					_("by"),
					artist,
					_("on"),
					album
					);
				if(album==UNKNOWN_ALBUM &&
				   artist==UNKNOWN_ARTIST &&
				   title==UNKNOWN_TITLE) {

					if(organization!=UNKNOWN_ORGANIZATION)
						text = Markup.printf_escaped("<b>%s</b>", _(UNKNOWN_ORGANIZATION));
					else if(location!=UNKNOWN_LOCATION)
						text = Markup.printf_escaped("<b>%s</b>", _(UNKNOWN_LOCATION));
					else
						text = Markup.printf_escaped("<b>%s</b>", file.get_uri());
				}
			}
			else {
				if((!gst_player.playing) &&
				   (!gst_player.paused)) {
					text = "<b>XNOISE</b> - ready to rock! ;-)";
				}
				else {
					text = "<b>%s</b> <i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>".printf(
						UNKNOWN_TITLE_LOCALIZED,
						_("by"),
						UNKNOWN_ARTIST_LOCALIZED,
						_("on"),
						UNKNOWN_ALBUM_LOCALIZED
						);
				}
			}
		}
		songProgressBar.title_text = text; //song_title_label.set_text(text);
		//song_title_label.use_markup = true;
	}


	public void handle_control_button_click(ControlButton sender, ControlButton.Direction dir) {
		if(dir == ControlButton.Direction.NEXT || dir == ControlButton.Direction.PREVIOUS) {
			if(global.player_state == PlayerState.STOPPED)
				return;
			this.change_track(dir);
		}
		else if(dir == ControlButton.Direction.STOP) {
			this.stop();
		}
	}
	
	//	private void on_hpaned_position_changed() {
	//		hpaned_resized = true;
	//		if(this.hpaned.position == 0)
	//			media_browser_visible = false;
	//		else
	//			media_browser_visible = true;
			
	//		if(this.get_window() != null) {
	//			this.trackList.handle_resize();
	//		}
	//	}
	
	/* disables (or enables) the AddRemoveAction and the RescanLibraryAction in the menus if
	   music is (not anymore) being imported */ 
	private void on_media_import_notify(GLib.Object sender, ParamSpec spec) {
		if(actions_list == null)
			actions_list = action_group.list_actions();
		foreach(Gtk.Action a in actions_list) {
			if(a.name == "AddRemoveAction" || a.name == "RescanLibraryAction") {
				a.sensitive = !global.media_import_in_progress;
			}
		}
	}
	
//	private bool hpaned_button_one;
//	private bool hpaned_resized = false;
//	private bool on_hpaned_button_event(Gdk.EventButton e) {
//		if(e.button == 1 && e.type == Gdk.EventType.BUTTON_PRESS)
//			hpaned_button_one = true;
//		else if(e.button == 1 && e.type == Gdk.EventType.BUTTON_RELEASE) {
//			if(hpaned_resized && hpaned_button_one)  {
//				hpaned_resized = false;
//				this.mediaBr.resize_line_width(this.hpaned.position);
//			}
//			hpaned_button_one = false;
//		}
//		return false;
//	}

	private void create_widgets() {
		try {
			Builder gb = new Gtk.Builder();
			gb.add_from_file(MAIN_UI_FILE);

			this.mainvbox = gb.get_object("mainvbox") as Gtk.Box;
			this.title = "xnoise media player";
			this.set_default_icon_name("xnoise");
			
			this.infobox = gb.get_object("infobox") as Gtk.Box;

			//DRAWINGAREA FOR VIDEO
			videoscreen = gst_player.videoscreen;
			videovbox = gb.get_object("videovbox") as Gtk.Box;
			videovbox.pack_start(videoscreen,true ,true ,0);
			
			//REMOVE TITLE OR ALL TITLES BUTTONS
			var removeAllButton            = gb.get_object("removeAllButton") as Gtk.Button;
			removeAllButton.can_focus      = false;
			removeAllButton.clicked.connect(this.on_remove_all_button_clicked);
			removeAllButton.set_tooltip_text(_("Remove all"));

			var removeSelectedButton       = gb.get_object("removeSelectedButton") as Gtk.Button;
			//removeSelectedButton.can_focus = false;
			removeSelectedButton.clicked.connect(this.on_remove_selected_button_clicked);
			removeSelectedButton.set_tooltip_text(_("Remove selected titles"));
			
			var posjumper                  = gb.get_object("posjumper") as Gtk.Button;
			posjumper.can_focus      = false;
			posjumper.clicked.connect(this.on_posjumper_button_clicked);
			posjumper.set_tooltip_text(_("Jump to current position"));

			//--------------------

			//SHOW VIDEO BUTTONS
			showvideobuttonTL                = gb.get_object("showvideobuttonTL") as Gtk.Button;
			showvideobuttonTL.can_focus      = false;
			showvideobuttonTL.set_relief(ReliefStyle.HALF);
			showvideobuttonTL.clicked.connect(this.on_show_video_button_clicked);
			showvideobuttonLY                = gb.get_object("showVideobuttonLY") as Gtk.Button;
			var vidlabel1                    = gb.get_object("showvideolabel") as Gtk.Label;
			vidlabel1.xalign                 = 0.1f;
			vidlabel1.label                  = SHOWVIDEO;
			var vidlabel2                    = gb.get_object("showvideolabelLY") as Gtk.Label;
			vidlabel2.xalign                 = 0.1f;
			vidlabel2.label                  = SHOWVIDEO;
			showvideobuttonLY.can_focus      = false;
			showvideobuttonLY.set_relief(ReliefStyle.HALF);
			showvideobuttonLY.clicked.connect(this.on_show_video_button_clicked);
			//--------------------

			//SHOW TRACKLIST BUTTONS
			showtracklistbuttonLY            = gb.get_object("showTLbuttonLY") as Gtk.Button;
			showtracklistbuttonLY.can_focus  = false;
			showtracklistbuttonLY.set_relief(ReliefStyle.HALF);
			showtracklistbuttonLY.clicked.connect(this.on_show_tracklist_button_clicked);
			showtracklistbuttonVid           = gb.get_object("showTLbuttonv") as Gtk.Button;
			var tllabel1                     = gb.get_object("showtracklistlabel") as Gtk.Label;
			tllabel1.xalign                  = 0.1f;
			tllabel1.label                   = SHOWTRACKLIST;
			var tllabel2                     = gb.get_object("label12") as Gtk.Label;
			tllabel2.xalign                  = 0.1f;
			tllabel2.label                   = SHOWTRACKLIST;
			showtracklistbuttonVid.can_focus = false;
			showtracklistbuttonVid.set_relief(ReliefStyle.HALF);
			showtracklistbuttonVid.clicked.connect(this.on_show_tracklist_button_clicked);
			//--------------------

			//SHOW LYRICS BUTTONS
			showlyricsbuttonTL               = gb.get_object("showLyricsbuttonTL") as Gtk.Button;
			showlyricsbuttonTL.can_focus     = false;
			showlyricsbuttonTL.set_relief(ReliefStyle.HALF);
			showlyricsbuttonTL.clicked.connect(this.on_show_lyrics_button_clicked);
			showlyricsbuttonTL.set_no_show_all(true);
			showlyricsbuttonTL.hide();
			showlyricsbuttonVid              = gb.get_object("showLyricsbuttonv") as Gtk.Button;
			showlyricsbuttonVid.set_no_show_all(true);
			var lylabel1                     = gb.get_object("label9") as Gtk.Label;
			lylabel1.xalign                  = 0.1f;
			lylabel1.label                   = SHOWLYRICS;
			var lylabel2                     = gb.get_object("label10") as Gtk.Label;
			lylabel2.xalign                  = 0.1f;
			lylabel2.label                   = SHOWLYRICS;
			showlyricsbuttonVid.can_focus    = false;
			showlyricsbuttonVid.set_relief(ReliefStyle.HALF);
			showlyricsbuttonVid.clicked.connect(this.on_show_lyrics_button_clicked);
			showlyricsbuttonVid.hide();
			//--------------------
			
			var buttons_sizegroup = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
			buttons_sizegroup.add_widget(showvideobuttonTL);
			buttons_sizegroup.add_widget(showvideobuttonLY);
			buttons_sizegroup.add_widget(showtracklistbuttonLY);
			buttons_sizegroup.add_widget(showtracklistbuttonVid);
			buttons_sizegroup.add_widget(showlyricsbuttonTL);
			buttons_sizegroup.add_widget(showlyricsbuttonVid);
			
			var toolbarbox = gb.get_object("toolbarbox") as Gtk.Box;
			main_toolbar = new Gtk.Toolbar();
			assert(main_toolbar != null);
			toolbarbox.pack_start(main_toolbar, true, true, 0);
			main_toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
			
			//REPEAT MODE SELECTOR
			repeatButton                = new Gtk.Button();
			repeatButton.can_focus      = false;
			repeatButton.clicked.connect(this.on_repeat_button_clicked);
			repeatimage                 = new Gtk.Image();
			repeatButton.add(repeatimage);
			var repeatButtonTI = new ToolItem();
			repeatButtonTI.add(repeatButton);
			//--------------------
			
			//PLAYING TITLE IMAGE
			this.albumimage = new AlbumImage();
			EventBox xb = new EventBox();
			xb.set_visible_window(false);
			xb.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
			xb.add(albumimage);
			ToolItem viewSelectorBin = new ToolItem();
			viewSelectorBin.add(xb);
			aimage_timeout = 0;
			xb.enter_notify_event.connect(ai_ebox_enter);
			
			xb.leave_notify_event.connect( (s, e) => {
				if(not_show_art_on_hover_image)
					return false;
				if(aimage_timeout != 0) {
					Source.remove(aimage_timeout);
					aimage_timeout = 0;
					return false;
				}
				this.tracklistnotebook.set_current_page(buffer_last_page);
				return false;
			});
			//--------------------
			this.hpaned = gb.get_object("paned1") as Gtk.Paned;
			mbbox01 = gb.get_object("mbbox01") as Gtk.Box;
			hpaned.remove(mbbox01);
			this.hpaned.pack1(mbbox01, false, false);
			//this.hpaned.notify["position"].connect(on_hpaned_position_changed);
			//----------------

			//VOLUME SLIDE BUTTON
			this.volumeSliderButton = new VolumeSliderButton(gst_player);
			var afVol = new ToolItem();
			afVol.add(volumeSliderButton);

			//PLAYBACK CONTROLLS
			this.previousButton = new ControlButton(ControlButton.Direction.PREVIOUS);
			this.previousButton.sign_clicked.connect(handle_control_button_click);
			this.previousButton.set_can_focus(false);
			this.playPauseButton = new PlayPauseButton();
			this.stopButton = new ControlButton(ControlButton.Direction.STOP);
			this.stopButton.set_no_show_all(true);
			this.stopButton.sign_clicked.connect(handle_control_button_click);
			this.nextButton = new ControlButton(ControlButton.Direction.NEXT);
			this.nextButton.sign_clicked.connect(handle_control_button_click);
			
			//PROGRESS BAR
			this.songProgressBar = new TrackInfobar(gst_player);
			this.songProgressBar.set_expand(true);
			
			//Config button for compact layout
			//render the preferences icon with a down arrow next to it
			config_button_image = new Gtk.Image.from_stock(Gtk.Stock.EXECUTE, Gtk.IconSize.LARGE_TOOLBAR);
			config_button = new Button();
			var config_hbox = new Box(Orientation.HORIZONTAL, 0);
			config_hbox.pack_start(config_button_image, false, false, 0);
			var config_arrow = new Arrow(ArrowType.DOWN, ShadowType.NONE);
			config_hbox.pack_start(config_arrow, false, false, 0);
			config_button.add(config_hbox);
			
			config_button.can_focus = false;
			config_button.set_tooltip_text(_("Show application main menu"));
			config_button.set_relief(Gtk.ReliefStyle.HALF);
			config_buttonTI = new ToolItem();
			config_buttonTI.add(config_button);
			config_buttonTI.set_no_show_all(true);
			
			//---------------------
			main_toolbar.insert(previousButton, -1);
			main_toolbar.insert(playPauseButton, -1);
			main_toolbar.insert(stopButton, -1);
			main_toolbar.insert(nextButton, -1);
			main_toolbar.insert(viewSelectorBin, -1);
			main_toolbar.insert(this.songProgressBar, -1);
			main_toolbar.insert(repeatButtonTI, -1);
			main_toolbar.insert(afVol, -1);
			main_toolbar.insert(config_buttonTI, -1);
			main_toolbar.can_focus = false;
			
			///BOX FOR MAIN MENU
			menuvbox                     = gb.get_object("menuvbox") as Gtk.Box;

			///Tracklist (right)
			this.trackList = tl; //new TrackList();
			this.trackList.set_size_request(100,100);
			trackListScrollWin = gb.get_object("scroll_tracklist") as Gtk.ScrolledWindow;
			trackListScrollWin.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS);
//			tl.set_container(hpaned);
			trackListScrollWin.add(this.trackList);
			
			///MediaBrowser (left)
			mediaBrScrollWin = new ScrolledWindow(null, null);//gb.get_object("scroll_music_br") as Gtk.ScrolledWindow;
//			mediaBrScrollWin.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC);
			this.mediaBr = new MediaBrowser(mediaBrScrollWin);
			this.mediaBr.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
//			this.mediaBr.set_size_request(100,100);
			mediaBrScrollWin.add(this.mediaBr);
			var mbbx = new Gtk.Box(Orientation.VERTICAL, 0);
			var sbx  = new Gtk.Box(Orientation.HORIZONTAL, 0);
			collapsebutton = new Gtk.Button();//gb.get_object("collapsebutton") as Gtk.Button;
			var coll_img   = new Gtk.Image.from_stock(Gtk.Stock.UNINDENT, Gtk.IconSize.MENU);//gb.get_object("imagecollapse") as Gtk.Image;
			collapsebutton.set_image(coll_img);
			coll_img.set_tooltip_text(_("Collapse all"));
			sbx.pack_start(collapsebutton, false, false, 0);
			
			this.searchEntryMB = new Gtk.Entry();
			this.searchEntryMB.primary_icon_stock = Gtk.Stock.FIND;
			this.searchEntryMB.secondary_icon_stock = Gtk.Stock.CLEAR;
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, true);
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
			this.searchEntryMB.set_sensitive(true);
			
			sbx.pack_start(searchEntryMB, true, true, 0);
			mbbx.pack_start(sbx, false, false, 0);
			mbbx.pack_start(mediaBrScrollWin, true, true, 0);
			
			mbbox01.pack_start(mbbx, true, true, 0);
			tracklistnotebook  = gb.get_object("tracklistnotebook") as Gtk.Notebook;
			tracklistnotebook.switch_page.connect( (s,np,p) => {
				global.sign_notify_tracklistnotebook_switched(p);
			});
			collapsebutton.clicked.connect( () => {
				mediaBr.collapse_all();
			});
			this.searchEntryMB.key_release_event.connect( (s, e) => {
				var entry = (Entry)s;
				if(search_idlesource != 0)
					Source.remove(search_idlesource);
				search_idlesource = Idle.add( () => {
					this.mediaBr.on_searchtext_changed();
					this.search_idlesource = 0;
					return false;
				});
				if(entry.text != EMPTYSTRING) {
					Gdk.RGBA color = Gdk.RGBA();
					if(!color.parse("rgba(233,150,122,1.0)")) //"DarkSalmon"#E18B6B11
						print("error parsing color\n");
					searchEntryMB.override_background_color(StateFlags.NORMAL, color);
				}
				else {
					searchEntryMB.override_background_color(StateFlags.NORMAL, null);
				}
				return false;
			});
			
			this.searchEntryMB.icon_press.connect( (s, p0, p1) => { 
				// s:Entry, p0:Position, p1:Gdk.Event
				var entry = (Gtk.Entry)s;
				if(p0 == Gtk.EntryIconPosition.PRIMARY) {
					this.mediaBr.on_searchtext_changed();
				}
				if(p0 == Gtk.EntryIconPosition.SECONDARY) {
					s.text = EMPTYSTRING;
					entry.override_background_color(StateFlags.NORMAL, null);
					this.mediaBr.on_searchtext_changed();
				}
			});
			
			
			hide_button = gb.get_object("hide_button") as Gtk.Button;
			hide_button.can_focus = false;
			hide_button.clicked.connect(this.toggle_media_browser_visibility);
			hide_button_image = gb.get_object("hide_button_image") as Gtk.Image;
			
			hide_button_1 = gb.get_object("hide_button_1") as Gtk.Button;
			hide_button_1.can_focus = false;
			hide_button_1.clicked.connect(this.toggle_media_browser_visibility);
			hide_button_image_1 = gb.get_object("hide_button_image_1") as Gtk.Image;
			
			hide_button_2 = gb.get_object("hide_button_2") as Gtk.Button;
			hide_button_2.can_focus = false;
			hide_button_2.clicked.connect(this.toggle_media_browser_visibility);
			hide_button_image_2 = gb.get_object("hide_button_image_2") as Gtk.Image;

			///Textbuffer for the lyrics
			var scrolledlyricsview = gb.get_object("scrolledlyricsview") as Gtk.ScrolledWindow;
			this.lyricsView = new LyricsView();
			scrolledlyricsview.add(lyricsView);
			scrolledlyricsview.show_all();

			//Fullscreen window
			this.fullscreenwindow = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			this.fullscreenwindow.set_title("Xnoise media player - Fullscreen");
			this.fullscreenwindow.set_default_icon_name("xnoise");
			this.fullscreenwindow.set_events (Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
			this.fullscreenwindow.realize();

			//Toolbar shown in the fullscreen window
			this.fullscreentoolbar = new FullscreenToolbar(fullscreenwindow);
			
			// GTk3 resize grip
			this.set_has_resize_grip(true);
		}
		catch(GLib.Error e) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
			                                Gtk.ButtonsType.OK,
			                                "Failed to build main window! \n" + e.message);
			msg.run();
			return;
		}


		//UIMANAGER FOR MENUS, THIS ALLOWS INJECTION OF ENTRIES BY PLUGINS
		action_group = new Gtk.ActionGroup("XnoiseActions");
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
		config_button_menu = (Gtk.Menu)config_button_menu_root.get_submenu();
		config_button.clicked.connect(() => {
			config_button_menu.popup(null, null, position_config_menu, 0, Gtk.get_current_event_time());
		});
		
		this.delete_event.connect(this.on_close); //only send to tray
		this.key_release_event.connect(this.on_key_released);
		this.key_press_event.connect(this.on_key_pressed);
		this.window_state_event.connect(this.on_window_state_change);
	}
	
	public void show_status_info(Xnoise.InfoBar bar) {
		infobox.pack_start(bar, false, false, 0);
		bar.show_all();
	}
	
	private bool ai_ebox_enter(Gtk.Widget sender, Gdk.EventCrossing e) {
		if(not_show_art_on_hover_image)
			return false;
		aimage_timeout = Timeout.add(300, () => {
			buffer_last_page = this.tracklistnotebook.get_current_page();
			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
			this.aimage_timeout = 0;
			return false;
		});
		return false;
	}
}


