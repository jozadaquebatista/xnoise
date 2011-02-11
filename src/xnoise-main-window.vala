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

[CCode (cname = "gtk_widget_style_get_property")]
public extern void widget_style_get_property(Gtk.Widget widget, string property_name, GLib.Value val);

public class Xnoise.MainWindow : Gtk.Window, IParams {
	private const string MAIN_UI_FILE     = Config.UIDIR + "main_window.ui";
	private const string MENU_UI_FILE     = Config.UIDIR + "main_ui.xml";
	private const string SHOWVIDEO        = _("Video");
	private const string SHOWTRACKLIST    = _("Tracklist");
	private const string SHOWMEDIABROWSER = _("Show Media");
	private const string HIDEMEDIABROWSER = _("Hide Media");
	private unowned Main xn;
	private uint search_idlesource = 0;
	public Gtk.ActionGroup action_group;
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
	private ulong active_notifier = 0;
	private ScreenSaverManager ssm = null;
	private List<Gtk.Action> actions_list = null;
	public ScrolledWindow mediaBrScrollWin = null;
	public ScrolledWindow trackListScrollWin = null;
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
				hide_button.label   = _("Hide Media");
				hide_button_1.label = _("Hide Media");
				hide_button_2.label = _("Hide Media");
			}
			else if((value == false) && (_media_browser_visible != value)) {
				hide_button.label   = _("Show Media");
				hide_button_1.label = _("Show Media");
				hide_button_2.label = _("Show Media");
			}
			_media_browser_visible = value;
		} 
	}
	
	public PlayerRepeatMode repeatState { get; set; }
	public bool fullscreenwindowvisible { get; set; }

	public signal void sign_pos_changed(double fraction);
	public signal void sign_volume_changed(double fraction);
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
			{ "OpenLocationAction", Gtk.Stock.NETWORK, N_("Open _Location"), null, N_("open remote location"), on_location_add },
			{ "AddRemoveAction", Gtk.Stock.ADD, N_("_Add or Remove media"), null, N_("manage the content of the xnoise media library"), on_menu_add},
			{ "QuitAction", Gtk.Stock.QUIT, null, null, null, quit_now},
		{ "EditMenuAction", null, N_("_Edit") },
			{ "ClearTrackListAction", Gtk.Stock.CLEAR, N_("C_lear tracklist"), null, N_("Clear the tracklist"), on_remove_all_button_clicked},
			{ "SettingsAction", Gtk.Stock.PREFERENCES, null, null, null, on_settings_edit},
		{ "ViewMenuAction", null, N_("_View") },
			{ "ShowTracklistAction", Gtk.Stock.INDEX, N_("_Tracklist"), null, N_("Go to the tracklist."), on_show_tracklist_menu_clicked},
			{ "ShowVideoAction", Gtk.Stock.LEAVE_FULLSCREEN, N_("_Video screen"), null, N_("Go to the video screen in the main window."), on_show_video_menu_clicked},
			{ "ShowLyricsAction", Gtk.Stock.EDIT, N_("_Lyrics"), null, N_("Go to the lyrics view."), on_show_lyrics_menu_clicked},
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
				stopButton.hide();
			}
			else {
				if(a_frame_config_button != null && config_button.get_realized()) 
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
		var job = new Worker.Job(999, Worker.ExecutionType.ONCE, null, this.add_lastused_titles_to_tracklist);
		worker.push_job(job);

		active_notifier = this.notify["is-active"].connect(buffer_position);
		this.notify["repeatState"].connect(on_repeatState_changed);
		this.notify["fullscreenwindowvisible"].connect(on_fullscreenwindowvisible);
		global.notify["media-import-in-progress"].connect(on_media_import_notify);

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
		
		this.check_resize.connect(on_resized);
		
	}
	
	private void buffer_position() {
		this.get_position(out _posX_buffer, out _posY_buffer);
	}
	
	private void on_resized() {
		if(this.get_window() == null)
			return;
		int w, x;
		this.get_size(out w, out x);
		if(w != window_width) {
			this.trackList.handle_resize();
			window_width = w;
		}
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

	private void add_lastused_titles_to_tracklist(Worker.Job job) {
		DbBrowser dbBr = null;
		try {
			dbBr = new DbBrowser();
		}
		catch(Error e) {
			print("%s\n", e.message);
			return;
		}
		if(dbBr == null)
			return;
		string[] uris = dbBr.get_lastused_uris();
		var psVideo = new PatternSpec("video*");
		var psAudio = new PatternSpec("audio*");
		for(int i = 0; i < uris.length; i++) {
			File file = File.new_for_uri(uris[i]);
			if(!(file.get_uri_scheme() in global.remote_schemes)) {
				TrackData td;
				if(dbBr.get_trackdata_for_uri(uris[i], out td)) {
					string current_uri = uris[i];
					Idle.add( () => {
						this.trackList.tracklistmodel.insert_title(null,
							                                       (int)td.Tracknumber,
							                                       td.Title,
							                                       td.Album,
							                                       td.Artist,
							                                       td.Length,
							                                       false,
							                                       current_uri);
						
						return false;
					});
				}
				else {
					string artist = "", album = "", title = "";
					int length = 0;
					string current_uri = uris[i];
					File f;
					FileType filetype;
					TrackData tags;
					string mime;
					string attr = FILE_ATTRIBUTE_STANDARD_TYPE + "," +
								  FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
					try {
						f = File.new_for_uri(current_uri);
						FileInfo info = f.query_info(
									      attr,
									      FileQueryInfoFlags.NONE,
									      null);
						filetype = info.get_file_type();
						string content = info.get_content_type();
						mime = GLib.ContentType.get_mime_type(content);
					}
					catch(GLib.Error e){
						print("%s\n", e.message);
						return;
					}
					if((filetype == GLib.FileType.REGULAR)&
					   ((psAudio.match_string(mime))|(psVideo.match_string(mime)))) {
						uint tracknumb;
						if(!(psVideo.match_string(mime))) {
							var tr = new TagReader(); 
							tags = tr.read_tag(f.get_path());
							artist         = tags.Artist;
							album          = tags.Album;
							title          = tags.Title;
							tracknumb      = tags.Tracknumber;
							length         = tags.Length;
//							lengthString = make_time_display_from_seconds(tags.Length);
						}
						else { 
							artist         = "";
							album          = "";
							title          = f.get_basename();
							tracknumb      = 0;
							length         = 0;
						}
					}
					Idle.add( () => {
						this.trackList.tracklistmodel.insert_title(null,
							                                       (int)td.Tracknumber,
							                                       title,
							                                       album,
							                                       artist,
							                                       length,
							                                       false,
							                                       current_uri);
						
						return false;
					});
				}
			}
			else {
				TrackData td;
				if(dbBr.get_trackdata_for_stream(uris[i], out td)) {
					string current_uri = uris[i];
					Idle.add( () => {
						this.trackList.tracklistmodel.insert_title(null,
							                                       0,
							                                       td.Title,
							                                       "",
							                                       "",
							                                       0,
							                                       false,
							                                       current_uri);
						
						return false;
					});
				}
			}
		}
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
	
	public void position_config_menu(Menu menu, out int x, out int y, out bool push) {
		//the upper right corner of the popup menu should be just beneath the lower right corner of the button

		int o_x = 0, o_y = 0;
		this.get_window().get_position(out o_x, out o_y);
		Requisition req; 
		config_button.get_child_requisition(out req);
		/* get_allocation is broken in vapi - we should remove this direct field access as soon as it is fixed */
		//Did you file a bug for this?
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
			fullscreenwindow.hide_all();

			this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
			fullscreenwindowvisible = false;
			this.videovbox.show();
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
				repeatLabel.label = _("no repeat");
				//repeatImage.stock = Gtk.Stock.EXECUTE;
				break;
			}
			case PlayerRepeatMode.SINGLE : {
				repeatLabel.label = _("repeat single");
				//repeatImage.stock = Gtk.Stock.REDO;
				break;
			}
			case PlayerRepeatMode.ALL : {
				repeatLabel.label = _("repeat all");
				//repeatImage.stock = Gtk.Stock.REFRESH;
				break;
			}
			case PlayerRepeatMode.RANDOM : {
				repeatLabel.label = _("random play");
				//repeatImage.stock = Gtk.Stock.JUMP_TO;
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

	public void toggle_window_visbility() {
		if(active_notifier != 0) {
			this.disconnect(active_notifier);
			active_notifier = 0;
		}
		if(this.is_active) {
			this.get_position(out _posX_buffer, out _posY_buffer);
			this.hide();
		}
		else if(this.get_window().is_visible() == true) {
			this.move(_posX_buffer, _posY_buffer);
			this.present();
			active_notifier = this.notify["is-active"].connect(buffer_position);
		}
		else {
			this.move(_posX_buffer, _posY_buffer);
			this.present();
			active_notifier = this.notify["is-active"].connect(buffer_position);
		}
	}

	public void show_window() {
		if(this.get_window().is_visible() == true) {
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
		this.repeatState = (PlayerRepeatMode)par.get_int_value("repeatstate");
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
		if(active_notifier != 0) {
			this.disconnect(active_notifier);
			active_notifier = 0;
		}
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
//			Idle.add(mediaBr.change_model_data);
		});
	}

	private void on_location_add() {
		//TODO: Update Tag info presented in tracklist
		var radiodialog = new Gtk.Dialog();
		radiodialog.set_modal(true);
		radiodialog.set_keep_above(true);

		var radioentry = new Gtk.Entry();
		radioentry.set_width_chars(50);
		radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
		radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
		radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
			if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = "";
		});
		((Gtk.VBox)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);

		var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
		radiocancelbutton.clicked.connect( () => {
			radiodialog.close();
			radiodialog = null;
		});

		var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
		radiookbutton.clicked.connect( () => {

			if((radioentry.text!=null) && (radioentry.text.strip() != "")) {
				var uri = radioentry.text.strip();
				File f = File.new_for_uri(uri);
				this.trackList.tracklistmodel.insert_title(null,
				                                           0,
				                                           prepare_name_from_filename(f.get_basename()),
				                                           "",
				                                           "",
				                                           0,
				                                           false,
				                                           uri);
			}
			radiodialog.close();
			radiodialog = null;
		});

		radiodialog.destroy_event.connect( () => {
			radiodialog = null;
			return true;
		});

		radiodialog.set_title(_("Enter the URL of the file to open"));
		radiodialog.show_all();

		var display = radiodialog.get_display();
		Gdk.Atom atom = Gdk.SELECTION_CLIPBOARD;
		Clipboard clipboard = Clipboard.get_for_display(display,atom);
		string text = clipboard.wait_for_text();
		if(text != null && "://" in text) {
			//it's url, then paste in text input
			radioentry.text = text;
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
		fcdialog.set_current_folder(Environment.get_home_dir());
		if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
			GLib.SList<string> res = fcdialog.get_uris();
			if(!(res == null || res.data == "")) {
				string[] media_files = {};
				foreach(string s in res) {
					media_files += s;
				}
				media_files += null; 
				this.trackList.tracklistmodel.add_uris(media_files);
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
						text = Markup.printf_escaped("<b>%s</b>", prepare_name_from_filename(basename));
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
	
	private void on_hpaned_position_changed() {
		hpaned_resized = true;
		if(this.hpaned.position == 0)
			media_browser_visible = false;
		else
			media_browser_visible = true;
			
		if(this.get_window() != null) {
			this.trackList.handle_resize();
		}
	}
	
	/* disables (or enables) the AddRemoveAction in the menus if
	   music is (not anymore) being imported */ 
	private void on_media_import_notify(GLib.Object sender, ParamSpec spec) {
		if(actions_list == null)
			actions_list = action_group.list_actions();
		foreach(Gtk.Action a in actions_list) {
			if(a.name == "AddRemoveAction") {
				a.sensitive = !global.media_import_in_progress;
				break;
			}
		}
	}
	
	private bool hpaned_button_one;
	private bool hpaned_resized = false;
	private bool on_hpaned_button_event(Gdk.EventButton e) {
		if(e.button == 1 && e.type == Gdk.EventType.BUTTON_PRESS)
			hpaned_button_one = true;
		else if(e.button == 1 && e.type == Gdk.EventType.BUTTON_RELEASE) {
			if(hpaned_resized && hpaned_button_one)  {
				hpaned_resized = false;
				this.mediaBr.resize_line_width(this.hpaned.position);
			}
			hpaned_button_one = false;
		}
		return false;
	}

	
	private void create_widgets() {
		try {
			Builder gb = new Gtk.Builder();
			gb.add_from_file(MAIN_UI_FILE);

			this.mainvbox = gb.get_object("mainvbox") as Gtk.VBox;
			this.title = "xnoise media player";
			this.set_default_icon_name("xnoise");
			
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
			this.hpaned.notify["position"].connect(on_hpaned_position_changed);
			this.hpaned.button_press_event.connect(on_hpaned_button_event);
			this.hpaned.button_release_event.connect(on_hpaned_button_event);
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
			trackListScrollWin = gb.get_object("scroll_tracklist") as Gtk.ScrolledWindow;
			trackListScrollWin.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS);
			trackListScrollWin.add(this.trackList);
			//trackListScrollWin.hadjustment.changed.connect(on_tracklistwin_resized);


			///MediaBrowser (left)
			this.mediaBr = new MediaBrowser();
			this.mediaBr.set_size_request(100,100);
			mediaBrScrollWin = gb.get_object("scroll_music_br") as Gtk.ScrolledWindow;
			mediaBrScrollWin.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC);
			mediaBrScrollWin.add(this.mediaBr);
			browsernotebook    = gb.get_object("notebook1") as Gtk.Notebook;
			tracklistnotebook  = gb.get_object("tracklistnotebook") as Gtk.Notebook;

			this.searchEntryMB = new Gtk.Entry();
			this.searchEntryMB.primary_icon_stock = Gtk.Stock.FIND;
			this.searchEntryMB.secondary_icon_stock = Gtk.Stock.CLEAR;
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, true);
			this.searchEntryMB.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
			this.searchEntryMB.set_sensitive(true);
			this.searchEntryMB.key_release_event.connect( (s, e) => {
				var entry = (Entry)s;
				if(search_idlesource != 0)
					Source.remove(search_idlesource);
				search_idlesource = Idle.add( () => {
					this.mediaBr.on_searchtext_changed();
					this.search_idlesource = 0;
					return false;
				});
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
					this.mediaBr.on_searchtext_changed();
				}
				if(p0 == Gtk.EntryIconPosition.SECONDARY) {
					s.text = "";
					entry.modify_base(StateType.NORMAL, null);
					this.mediaBr.on_searchtext_changed();
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
			this.fullscreenwindow.set_default_icon_name("xnoise");
			this.fullscreenwindow.set_events (Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
			this.fullscreenwindow.realize();

			//Toolbar shown in the fullscreen window
			this.fullscreentoolbar = new FullscreenToolbar(fullscreenwindow);
			
			//Config button for compact layout		
			//render the preferences icon with a down arrow next to it
			config_button_image = new Gtk.Image.from_stock(Gtk.Stock.PREFERENCES, Gtk.IconSize.LARGE_TOOLBAR);
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
		config_button_menu = (Menu)config_button_menu_root.get_submenu();
		config_button.clicked.connect(() => {
			config_button_menu.popup(null, null, position_config_menu, 0, Gtk.get_current_event_time());
		});
		if(par.get_int_value("compact_layout") > 0) compact_layout = true;
		else compact_layout = false;

		this.delete_event.connect(this.on_close); //only send to tray
		this.key_release_event.connect(this.on_key_released);
		this.key_press_event.connect(this.on_key_pressed);
		this.window_state_event.connect(this.on_window_state_change);
	}
	
	public void display_info_bar(Gtk.InfoBar bar) {
		contentvbox.pack_start(bar, false, false, 0);
		bar.show();
	}
	
	public void show_status_info(Xnoise.InfoBar bar) {
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


