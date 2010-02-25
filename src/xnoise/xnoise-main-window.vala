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
	private const string MAIN_UI_FILE  = Config.UIDIR + "main_window.ui";
	private const string MENU_UI_FILE  = Config.UIDIR + "main_ui.xml";
	private const string APPICON       = Config.UIDIR + "xnoise_16x16.png";
	private const string SHOWVIDEO     = _("Video");
	private const string SHOWTRACKLIST = _("Tracklist");
	private Main xn;
	private ActionGroup action_group;
	private UIManager ui_manager = new UIManager();
	private Label song_title_label;
	public bool _seek;
	private HPaned hpaned;
	private VolumeSliderButton volumeSliderButton;
	private int _posX_buffer;
	private int _posY_buffer;
	private Button collapsebutton;
	private Button showlyricsbuttonVid;
	private Button showlyricsbuttonTL;
	private Button showtracklistbuttonVid;
	private Button showtracklistbuttonLY;
	private Button showvideobuttonTL;
	private Button showvideobuttonLY;
	private Button repeatButton01;
	private Button repeatButton02;
	private Button repeatButton03;
	private int buffer_last_page;
	private Image repeatImage01;
	private Image repeatImage02;
	private Image repeatImage03;
	private Label repeatLabel01;
	private Label repeatLabel02;
	private Label repeatLabel03;
	private VBox menuvbox;
	private VBox mainvbox;
	private FullscreenToolbar fullscreentoolbar;
	private VBox videovbox;
	private VBox contentvbox;
	public bool is_fullscreen = false;
	public bool drag_on_da = false;
	public LyricsView lyricsView;
	public VideoScreen videoscreen;
	public Entry searchEntryMB;
	public PlayPauseButton playPauseButton;
	public PreviousButton previousButton;
	public NextButton nextButton;
	public StopButton stopButton;
	public Notebook browsernotebook;
	public Notebook tracklistnotebook;
	public AlbumImage albumimage;
	public SongProgressBar songProgressBar;
	public double current_volume; //keep it global for saving to params
	public MediaBrowser mediaBr;
	public TrackList trackList;
	public Gtk.Window fullscreenwindow;

	public int repeatState { get; set; }
	public bool fullscreenwindowvisible { get; set; }

	public signal void sign_pos_changed(double fraction);
	public signal void sign_volume_changed(double fraction);
	public signal void sign_drag_over_da();

	private enum Repeat {
		NOT_AT_ALL = 0,
		SINGLE,
		ALL,
		RANDOM
	}

	public enum Direction {
		NEXT = 0,
		PREVIOUS,
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
			{ "AboutAction", STOCK_ABOUT, null, null, null, on_help_about}
	};

	private const Gtk.TargetEntry[] target_list = {
		{"text/uri-list", 0, 0}
	};

	public UIManager get_ui_manager() {
		return ui_manager;
	}

	public MainWindow() {
		this.xn = Main.instance;
		par.iparams_register(this);
		xn.gPl.sign_volume_changed.connect(
			(val) => {this.current_volume = val;}
		);
		create_widgets();

		//initialization of videoscreen
		initialize_video_screen();

		//restore last state
		add_lastused_titles_to_tracklist();

		notify["repeatState"].connect(on_repeatState_changed);
		notify["fullscreenwindowvisible"].connect(on_fullscreenwindowvisible);

		buffer_last_page = 0;

		global.caught_eos_from_player.connect(on_caught_eos_from_player);
		xn.gPl.sign_tag_changed.connect(this.set_displayed_title);
		xn.gPl.sign_video_playing.connect( () => { 
			//handle stop signal from gst player
			if(!this.fullscreenwindowvisible)
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
		});
		this.sign_pos_changed.connect( (s, fraction) => {
			xn.gPl.gst_position = fraction;
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
		videoscreen.button_press_event.connect(on_video_da_button_press);
		sign_drag_over_da.connect(() => {
			//switch to tracklist for dropping
			if(!fullscreenwindowvisible)
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.TRACKLIST);
		});
		videoscreen.drag_motion.connect(this.on_da_drag_motion);
	}

	private void on_caught_eos_from_player() {
		this.change_song(Direction.NEXT, true);
	}

	private bool on_da_drag_motion(Gtk.Widget sender, Gdk.DragContext context, int x, int y, uint timestamp) {
		drag_on_da = true;
		sign_drag_over_da();
		return true;
	}

	private void on_fullscreenwindowvisible(GLib.ParamSpec pspec) {
		this.showvideobuttonTL.set_sensitive(!fullscreenwindowvisible);
		this.showvideobuttonLY.set_sensitive(!fullscreenwindowvisible);
	}

	private void add_lastused_titles_to_tracklist() {
		var dbBr = new DbBrowser();
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
		return false;
	}

	private void on_repeatState_changed(GLib.ParamSpec pspec) {
		switch(this.repeatState) {
			case Repeat.NOT_AT_ALL : {
				//TODO: create some other images
				repeatLabel01.label = _("no repeat");
				repeatImage01.stock = Gtk.STOCK_EXECUTE;
				repeatLabel02.label = _("no repeat");
				repeatImage02.stock = Gtk.STOCK_EXECUTE;
				repeatLabel03.label = _("no repeat");
				repeatImage03.stock = Gtk.STOCK_EXECUTE;
				break;
			}
			case Repeat.SINGLE : {
				repeatLabel01.label = _("repeat single");
				repeatImage01.stock = Gtk.STOCK_REDO;
				repeatLabel02.label = _("repeat single");
				repeatImage02.stock = Gtk.STOCK_REDO;
				repeatLabel03.label = _("repeat single");
				repeatImage03.stock = Gtk.STOCK_REDO;
				break;
			}
			case Repeat.ALL : {
				repeatLabel01.label = _("repeat all");
				repeatImage01.stock = Gtk.STOCK_REFRESH;
				repeatLabel02.label = _("repeat all");
				repeatImage02.stock = Gtk.STOCK_REFRESH;
				repeatLabel03.label = _("repeat all");
				repeatImage03.stock = Gtk.STOCK_REFRESH;
				break;
			}
			case Repeat.RANDOM : {
				repeatLabel01.label = _("random play");
				repeatImage01.stock = Gtk.STOCK_JUMP_TO;
				repeatLabel02.label = _("random play");
				repeatImage02.stock = Gtk.STOCK_JUMP_TO;
				repeatLabel03.label = _("random play");
				repeatImage03.stock = Gtk.STOCK_JUMP_TO;
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
		StatusIcon icon = new StatusIcon.from_file(Config.UIDIR + "xnoise_16x16.png");
		icon.set_tooltip_text("Xnoise media player");
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
		previousItem.activate.connect(previousButton.on_clicked);
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
		nextItem.activate.connect(nextButton.on_clicked);
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
	private const int KEY_ESC = 0xFF1B;
	private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//		print("%d\n",(int)e.keyval);
		switch(e.keyval) {
			case KEY_F11:
				this.toggle_mainwindow_fullscreen();
				break;
			case KEY_ESC:
				this.toggle_window_visbility();
				break;
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
		int posX, posY, wi, he;
		this.get_position(out posX, out posY);
		par.set_int_value("posX", posX);
		par.set_int_value("posY", posY);

		this.get_size(out wi, out he);
		par.set_int_value("width", wi);
		par.set_int_value("height", he);

		par.set_int_value("hp_position", this.hpaned.get_position());

		par.set_int_value("repeatstate", repeatState);

		par.set_double_value("volume", current_volume);
	}

	//END REGION IParameter


	private void stop() {
		global.track_state = GlobalInfo.TrackState.STOPPED;
		global.current_uri = null;
	}

	// This function changes the current song to the next or previous in the
	// tracklist. handle_repeat_state should be true when the calling is not
	// coming from a button, but, e.g. from a EOS signal handler
	public void change_song(MainWindow.Direction direction, bool handle_repeat_state = false) {
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

		// handle RANDOM
		if((repeatState == Repeat.RANDOM)) {
			this.trackList.tracklistmodel.get_random_row(ref path);
		}
		else {
			if(!used_next_pos) {
				// get next or previous path
				if((!(handle_repeat_state && (repeatState == Repeat.SINGLE)))) {
					if(path == null) return;
					if(!this.trackList.tracklistmodel.path_is_last_row(ref path,
					                                                   out trackList_is_empty)
					                                                   ) {
						//print(" ! path_is_last_row\n");
						if(direction == Direction.NEXT) {
							path.next();
						}
						else if((direction == Direction.PREVIOUS)&&
								(path.to_string() != "0")) {
							path.prev();
						}
					}
					else {
						//print("path_is_last_row\n");
						if(direction == Direction.NEXT) {
							if(repeatState == Repeat.ALL) {
								// only jump to first is repeat all is set
								trackList.tracklistmodel.get_first_row(ref path);
							}
							else {
								stop();
							}
						}
						else if((direction == Direction.PREVIOUS)&&
						        (path.to_string() != "0")) {
							path.prev();
						}
					}
				}
			}
		}

		if(path == null) {
			stop();
			return;
		}

		if(!trackList.tracklistmodel.get_iter(out iter, path)) return;

		global.position_reference = new TreeRowReference(trackList.tracklistmodel, path);

		if(global.track_state == GlobalInfo.TrackState.PLAYING) trackList.set_focus_on_iter(ref iter);
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

	private SettingsDialog setingsD;
	private void on_settings_edit() {
		setingsD = new SettingsDialog();
		setingsD.sign_finish.connect( () => {
			setingsD = null;
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
			var dbb = new DbBrowser();
			TrackData td;
			if(dbb.get_trackdata_for_uri(newuri, out td)) {
				artist = td.Artist;
				album = td.Album;
				title = td.Title;
			}
			else {
				if(xn.gPl.currentartist!=null) {
					artist = remove_linebreaks(xn.gPl.currentartist);
				}
				else {
					artist = "unknown artist";
				}
				if(xn.gPl.currenttitle!=null) {
					title = remove_linebreaks(xn.gPl.currenttitle);
				}
				else {
					title = "unknown title";
				}
				if(xn.gPl.currentalbum!=null) {
					album = remove_linebreaks(xn.gPl.currentalbum);
				}
				else {
					album = "unknown album";
				}
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
			if(xn.gPl.currentartist!=null)
				artist = remove_linebreaks(xn.gPl.currentartist);
			else
				artist = "unknown artist";

			if(xn.gPl.currenttitle!=null)
				title = remove_linebreaks(xn.gPl.currenttitle);
			else
				title = "unknown title";

			if(xn.gPl.currentalbum!=null)
				album = remove_linebreaks(xn.gPl.currentalbum);
			else
				album = "unknown album";

			if(xn.gPl.currentorg!=null)
				organization = remove_linebreaks(xn.gPl.currentorg);
			else
				organization = "unknown organization";

			if(xn.gPl.currentgenre!=null)
				genre = remove_linebreaks(xn.gPl.currentgenre);
			else
				genre = "unknown genre";

			if(xn.gPl.currentlocation!=null)
				location = remove_linebreaks(xn.gPl.currentlocation);
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

	private bool on_trayicon_scrolled(Gtk.StatusIcon sender, Gdk.Event event) {
		if(event.scroll.direction == Gdk.ScrollDirection.DOWN) {
			double temp = this.xn.gPl.volume - 0.02;
			if(temp < 0.0) temp = 0.0;
			this.xn.gPl.volume = temp;
			return false;
		}
		else if(event.scroll.direction == Gdk.ScrollDirection.UP) {
			double temp = this.xn.gPl.volume + 0.02;
			if(temp > 1.0) temp = 1.0;
			this.xn.gPl.volume = temp;
			return false;
		}
		return true;
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
			repeatButton01                = gb.get_object("repeatButton01") as Gtk.Button;
			repeatButton01.can_focus      = false;
			repeatButton01.clicked.connect(this.on_repeat_button_clicked);
			repeatLabel01                 = gb.get_object("repeatLabel01") as Gtk.Label;
			repeatImage01                 = gb.get_object("repeatImage01") as Gtk.Image;
			repeatButton02                = gb.get_object("repeatButton02") as Gtk.Button;
			repeatButton02.can_focus      = false;
			repeatButton02.clicked.connect(this.on_repeat_button_clicked);
			repeatLabel02                 = gb.get_object("repeatLabel02") as Gtk.Label;
			repeatImage02                 = gb.get_object("repeatImage02") as Gtk.Image;
			repeatButton03                = gb.get_object("repeatButton03") as Gtk.Button;
			repeatButton03.can_focus      = false;
			repeatButton03.clicked.connect(this.on_repeat_button_clicked);
			repeatLabel03                 = gb.get_object("repeatLabel03") as Gtk.Label;
			repeatImage03                 = gb.get_object("repeatImage03") as Gtk.Image;
			//--------------------

			//PLAYING TITLE IMAGE
			var aibox                     = gb.get_object("aibox") as Gtk.HBox;

			this.albumimage = new AlbumImage();
			EventBox ebox = new EventBox(); 
			ebox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK|Gdk.EventMask.LEAVE_NOTIFY_MASK);

			ebox.add(albumimage);
			aibox.add(ebox);

			ebox.enter_notify_event.connect( (s, e) => {
				buffer_last_page = this.tracklistnotebook.get_current_page();
				this.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
				return false;
			});

			ebox.leave_notify_event.connect( (s, e) => {
				this.tracklistnotebook.set_current_page(buffer_last_page);
				return false;
			});

			//--------------------

			//PLAYING TITLE NAME
			this.song_title_label           = gb.get_object("song_title_label") as Gtk.Label;
			this.song_title_label.use_markup= true;
			//--------------------

			this.hpaned = gb.get_object("hpaned1") as Gtk.HPaned;
			//----------------

			//VOLUME SLIDE BUTTON
			this.volumeSliderButton = new VolumeSliderButton();
			var vbVol = gb.get_object("vboxVolumeButton") as Gtk.VBox;
			vbVol.pack_start(volumeSliderButton, false, false, 1);

			//PLAYBACK CONTROLLS
			var playback_hbox = gb.get_object("playback_hbox") as Gtk.HBox;
			this.previousButton = new PreviousButton();
			playback_hbox.pack_start(previousButton,false,false,0);
			this.playPauseButton = new PlayPauseButton();
			playback_hbox.pack_start(playPauseButton,false,false,0);
			this.stopButton = new StopButton();
			playback_hbox.pack_start(stopButton,false,false,0);
			this.nextButton = new NextButton();
			playback_hbox.pack_start(nextButton,false,false,0);

			//PROGRESS BAR
			var songprogress_viewport = gb.get_object("songprogress_viewport") as Gtk.Viewport;
			this.songProgressBar = new SongProgressBar();
			//playback_hbox.pack_start(songProgressBar,false,false,0);
			songprogress_viewport.add(songProgressBar);
			//---------------------

			///BOX FOR MAIN MENU
			menuvbox                     = gb.get_object("menuvbox") as Gtk.VBox;

			///Tracklist (right)
			this.trackList = xn.tl; //new TrackList();
			this.trackList.set_size_request(100,100);
			var trackListScrollWin = gb.get_object("scroll_tracklist") as Gtk.ScrolledWindow;
			trackListScrollWin.set_policy(Gtk.PolicyType.AUTOMATIC,Gtk.PolicyType.ALWAYS);
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
				var entry = (Gtk.Entry)s;
				if((int)e.keyval == KEY_ENTER ||
				    entry.get_text().size() == 0 ) {
					this.mediaBr.on_searchtext_changed(entry);
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
					this.mediaBr.on_searchtext_changed((Gtk.Entry)s);
				}
				if(p0 == Gtk.EntryIconPosition.SECONDARY) {
					s.text = "";
					entry.modify_base(StateType.NORMAL, null);
					this.mediaBr.on_searchtext_changed((Gtk.Entry)s);
				}
			});
			
			var sexyentryBox = gb.get_object("sexyentryBox") as Gtk.HBox;
			sexyentryBox.add(searchEntryMB);
			
			collapsebutton = gb.get_object("collapsebutton") as Gtk.Button;
			var labelcoll =  gb.get_object("labelcoll") as Gtk.Label;
			labelcoll.label = _("Collapse");
			collapsebutton.clicked.connect( () => {
				mediaBr.collapse_all();
			});

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
		}
		catch (GLib.Error e) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
			    Gtk.ButtonsType.OK, "Failed to build main window! \n" + e.message);
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

		var menubar = (MenuBar)ui_manager.get_widget("/MainMenu");
		menuvbox.pack_start(menubar, false, false, 0);
		this.add(mainvbox);

		// TODO: Move these popup actions to uimanager
		this.trayicon.popup_menu.connect(this.trayicon_menu_popup);
		this.trayicon.activate.connect(this.toggle_window_visbility);
		this.trayicon.scroll_event.connect(this.on_trayicon_scrolled);

		this.delete_event.connect(this.on_close); //only send to tray
		this.key_release_event.connect(this.on_key_released);
		this.window_state_event.connect(this.on_window_state_change);
	}
	
	public void display_info_bar(InfoBar bar) {
		contentvbox.pack_start(bar, false, false, 0);
		bar.show();
	}


	/**
	* A NextButton is a Gtk.Button that initiates playback of the previous item
	*/
	public class NextButton : Gtk.Button {
		private Main xn;
		public NextButton() {
			this.xn = Main.instance;
			var img = new Gtk.Image.from_stock(STOCK_MEDIA_NEXT, Gtk.IconSize.SMALL_TOOLBAR);
			this.set_image(img);
			this.relief = Gtk.ReliefStyle.NONE;
			this.can_focus = false;
			this.clicked.connect(this.on_clicked);
		}

		public void on_clicked() {
			this.xn.main_window.change_song(Direction.NEXT);
		}
	}

	/**
	* A PreviousButton is a Gtk.Button that initiates playback of the previous item
	*/
	public class PreviousButton : Gtk.Button {
		private Main xn;
		public PreviousButton() {
			this.xn = Main.instance;
			var img = new Gtk.Image.from_stock(STOCK_MEDIA_PREVIOUS, Gtk.IconSize.SMALL_TOOLBAR);
			this.set_image(img);
			this.relief = Gtk.ReliefStyle.NONE;
			this.can_focus = false;
			this.clicked.connect(this.on_clicked);
		}

		public void on_clicked() {
			this.xn.main_window.change_song(Direction.PREVIOUS);
		}
	}

	/**
	* A StopButton is a Gtk.Button that stops playback
	*/
	public class StopButton : Gtk.Button {
		private Main xn;
		public StopButton() {
			xn = Main.instance;
			var img = new Gtk.Image.from_stock(STOCK_MEDIA_STOP, Gtk.IconSize.SMALL_TOOLBAR);
			this.set_image (img);
			this.relief = Gtk.ReliefStyle.NONE;
			this.can_focus = false;
			this.clicked.connect(this.on_clicked);
		}
		private void on_clicked() {
			this.xn.main_window.stop();
		}
	}


	/**
	* A PlayPauseButton is a Gtk.Button that accordingly pauses, unpauses or starts playback
	*/
	public class PlayPauseButton: Gtk.Button {
		private Main xn;
		private Gtk.Image playImage;
		private Gtk.Image pauseImage;

		public PlayPauseButton() {
			xn = Main.instance;
			this.can_focus = false;
			this.relief = Gtk.ReliefStyle.NONE;

			this.playImage = new Image.from_stock(STOCK_MEDIA_PLAY, IconSize.SMALL_TOOLBAR);
			this.pauseImage = new Image.from_stock(STOCK_MEDIA_PAUSE, IconSize.SMALL_TOOLBAR);
			this.update_picture();

			this.clicked.connect(this.on_clicked);
			xn.gPl.sign_paused.connect(this.update_picture);
			xn.gPl.sign_stopped.connect(this.update_picture);
			xn.gPl.sign_playing.connect(this.update_picture);
		}

		public void on_menu_clicked(Gtk.MenuItem sender) {
			handle_click();
		}

		public void on_clicked(Gtk.Widget sender) {
			handle_click();
		}

		/**
		 * This method is used to handle play/pause commands from different signal handler sources
		 */
		private void handle_click() {
			//FIXME : This is slow as hell with playbin2. Why?
			Idle.add(
				handle_click_async
			);
		}
		
		private bool handle_click_async() {
			if(global.current_uri == null) {
				string uri = xn.tl.tracklistmodel.get_uri_for_current_position();
				if((uri != "")&&(uri != null)) 
					global.current_uri = uri;
			}

			if(global.track_state == GlobalInfo.TrackState.PLAYING) {
				global.track_state = GlobalInfo.TrackState.PAUSED;
			}
			else {
				global.track_state = GlobalInfo.TrackState.PLAYING;
			}
			return false;
		}

		public void update_picture() {
			if(xn.gPl.playing == true)
				this.set_play_picture();
			else
				this.set_pause_picture();
		}

		public void set_play_picture() {
			this.set_image(pauseImage);
		}

		public void set_pause_picture() {
			this.set_image(playImage);
		}
	}


	/**
	* A SongProgressBar is a Gtk.ProgressBar that shows the playback position in the
	* currently played item and changes it upon user input
	*/
	public class SongProgressBar : Gtk.ProgressBar {
		private Main xn;

		public SongProgressBar() {
			xn = Main.instance;

			this.discrete_blocks = 10;
			this.set_size_request(-1,18);

			this.set_events(Gdk.EventMask.BUTTON1_MOTION_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
			this.button_press_event.connect(this.on_press);
			this.button_release_event.connect(this.on_release);

			xn.gPl.sign_song_position_changed.connect(set_value);
			global.caught_eos_from_player.connect(on_eos);
			xn.gPl.sign_stopped.connect(on_stopped);

			this.set_text("00:00 / 00:00");
			this.fraction = 0.0;
		}

		private bool on_press(Gdk.EventButton e) {
			if((xn.gPl.playing)|(xn.gPl.paused)) {
				xn.gPl.seeking = true;
				this.motion_notify_event.connect(on_motion_notify);
			}
			return false;
		}

		private bool on_release(Gdk.EventButton e) {
			if((xn.gPl.playing)|(xn.gPl.paused)) {
				double thisFraction;

				double mouse_x, mouse_y;
				mouse_x = e.x;
				mouse_y = e.y;

				Allocation progress_loc = this.allocation;
				thisFraction = mouse_x / progress_loc.width;

				this.motion_notify_event.disconnect(on_motion_notify);

				xn.gPl.seeking = false;
				if(thisFraction < 0.0) thisFraction = 0.0;
				if(thisFraction > 1.0) thisFraction = 1.0;
				this.set_fraction(thisFraction);
				this.xn.main_window.sign_pos_changed(thisFraction);

				set_value((uint)((thisFraction * xn.gPl.length_time) / 1000000), (uint)(xn.gPl.length_time / 1000000));
			}
			return false;
		}

		private bool on_motion_notify(Gdk.EventMotion e) {
			double thisFraction;
			double mouse_x, mouse_y;
			mouse_x = e.x;
			mouse_y = e.y;
			Allocation progress_loc = this.allocation;
			thisFraction = mouse_x / progress_loc.width;

			if(thisFraction < 0.0) thisFraction = 0.0;
			if(thisFraction > 1.0) thisFraction = 1.0;

			this.set_fraction(thisFraction);
			this.xn.main_window.sign_pos_changed(thisFraction);

			return false;
		}

		private void on_eos() {
			set_value(0,0);
		}

		private void on_stopped() {
			set_value(0,0);
		}

		public void set_value(uint pos, uint len) {
			if(len > 0) {
				int dur_min, dur_sec, pos_min, pos_sec;
				double fraction = (double)pos/(double)len;
				if(fraction<0.0) fraction = 0.0;
				if(fraction>1.0) fraction = 1.0;
				this.set_fraction(fraction);

				this.set_sensitive(true);

				dur_min = (int)(len / 60000);
				dur_sec = (int)((len % 60000) / 1000);
				pos_min = (int)(pos / 60000);
				pos_sec = (int)((pos % 60000) / 1000);
				string timeinfo = "%02d:%02d / %02d:%02d".printf(pos_min, pos_sec, dur_min, dur_sec);
				this.set_text(timeinfo);
			}
			else {
				this.set_fraction(0.0);
				this.set_text("00:00 / 00:00");
				this.set_sensitive(false);
			}
		}
	}


	/**
	* A VolumeSliderButton is a Gtk.VolumeButton used to change the volume
	*/
	public class VolumeSliderButton : Gtk.VolumeButton {
		private Main xn;
		public VolumeSliderButton() {
			this.xn = Main.instance;
			this.can_focus = false;
			this.relief = Gtk.ReliefStyle.NONE;
			this.set_value(0.3); //Default value
			this.value_changed.connect(on_change);
			this.xn.gPl.sign_volume_changed.connect(on_volume_change);
		}

		private void on_change() {
			this.xn.gPl.volume = get_value();
		}

		private void on_volume_change(double val) {
			this.set_sensitive(false);
			this.value_changed.disconnect(on_change);
			this.set_value(val);
			this.value_changed.connect(on_change);
			this.set_sensitive(true);
		}
	}


	private class FullscreenToolbar {
		private Main xn;
		private const uint hide_delay = 3000;
		private Gtk.Window window;
		private Gtk.Window fullscreenwindow;
		private MainWindow.SongProgressBar bar;
		private uint hide_event_id;
		private bool hide_lock;

		public FullscreenToolbar(Gtk.Window fullscreenwindow) {
			xn = Main.instance;
			this.hide_lock = false;
			this.fullscreenwindow = fullscreenwindow;
			window = new Gtk.Window (Gtk.WindowType.POPUP);

			var mainbox = new Gtk.HBox(false,8);

			var nextbutton = new MainWindow.NextButton();
			var plpabutton = new MainWindow.PlayPauseButton();
			var previousbutton = new MainWindow.PreviousButton();
			var leavefullscreen = new LeaveVideoFSButton();
			var volume = new MainWindow.VolumeSliderButton();

			bar = new MainWindow.SongProgressBar();
			var vp = new Gtk.Alignment(0,0.5f,0,0);
			vp.add (bar);

			mainbox.pack_start(previousbutton,false,false,0);
			mainbox.pack_start(plpabutton,false,false,0);
			mainbox.pack_start(nextbutton,false,false,0);
			mainbox.pack_start(vp,true,false,0);
			//mainbox.pack_start(ai_frame,false,false,0);
			mainbox.pack_start(leavefullscreen,false,false,0);
			mainbox.pack_start(volume,false,false,0);


			window.add(mainbox);
			fullscreenwindow.motion_notify_event.connect(on_pointer_motion);
			window.enter_notify_event.connect(on_pointer_enter_toolbar);
			fullscreenwindow.enter_notify_event.connect(on_pointer_enter_fswindow);
			fullscreenwindow.key_release_event.connect(this.on_key_released);
			resize ();
		}

		private const int KEY_ESC = 0xFF1B;
		private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
			switch(e.keyval) {
				case KEY_ESC: {
					this.xn.main_window.toggle_fullscreen();
				}
				break;
				default:
				break;
			}
			return false;
		}

		public void resize() {
			Gdk.Screen screen;
			Gdk.Rectangle rect;

			screen = fullscreenwindow.get_screen();
			screen.get_monitor_geometry (screen.get_monitor_at_window (fullscreenwindow.window),out rect);

			this.window.resize(rect.width, 30);
			bar.set_size_request(rect.width/2,18);
		}

		private bool hide_timer_elapsed () {
			if (!this.hide_lock) this.hide();
			return false;
		}

		public void launch_hide_timer () {
			hide_event_id = Timeout.add (hide_delay, hide_timer_elapsed);
		}


		private bool on_pointer_enter_fswindow (Gdk.EventCrossing ev) {
			this.hide_lock = false;
			fullscreenwindow.motion_notify_event.connect(on_pointer_motion);
			return false;
		}

		private bool on_pointer_enter_toolbar (Gdk.EventCrossing ev) {
			this.hide_lock = true;
			if(hide_event_id != 0) GLib.Source.remove (hide_event_id);
			fullscreenwindow.motion_notify_event.disconnect(on_pointer_motion);
			return false;
		}
		public bool on_pointer_motion (Gdk.EventMotion ev) {
			if(!window.window.is_visible()) window.show_all();
			if(hide_lock == true) return false;
			if(hide_event_id != 0) {
				 GLib.Source.remove (hide_event_id);
				 hide_event_id = 0;
			}
			launch_hide_timer();
			return false;
		}


		public void show() {
			window.show_all();
			launch_hide_timer();
		}

		public void hide() {
			window.hide();
			if(hide_event_id != 0) {
				 GLib.Source.remove (hide_event_id);
				 hide_event_id = 0;
			}
		}

		/**
		* A LeaveVideoFSButton is a Gtk.Button that switches off the fullscreen state of the video fullscreen window
		* The only occurance for now is here. So it's placed in the FullscreenToolbar class
		*/
		public class LeaveVideoFSButton : Gtk.Button {
			private Main xn;
			public LeaveVideoFSButton() {
				this.xn = Main.instance;
				var img = new Gtk.Image.from_stock(Gtk.STOCK_LEAVE_FULLSCREEN , Gtk.IconSize.SMALL_TOOLBAR);
				this.set_image(img);
				this.relief = Gtk.ReliefStyle.NONE;
				this.can_focus = false;
				this.clicked.connect(this.on_clicked);
				this.set_tooltip_text(_("Leave fullscreen"));
			}

			public void on_clicked() {
				this.xn.main_window.videoscreen.window.unfullscreen();
				this.xn.main_window.videoscreen.reparent(this.xn.main_window.videovbox);
				this.xn.main_window.fullscreenwindow.hide_all();
				this.xn.main_window.tracklistnotebook.set_current_page(TrackListNoteBookTab.VIDEO);
				this.xn.main_window.fullscreenwindowvisible = false;
				this.xn.main_window.videovbox.show();
				this.xn.main_window.fullscreentoolbar.hide();
			}
		}
	}

}


