/* xnoise-main-window.vala
 *
 * Copyright (C) 2009  Jörn Magens
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

using GLib;
using Gtk;

public class Xnoise.MainWindow : Gtk.Builder, IParameter {
	private const string MAIN_UI_FILE = Config.DATADIR + "/ui/main_window.ui";
	private Label song_title_label;
	private bool _seek;
	private bool is_fullscreen = false;
	private HPaned hpaned;
	private Gtk.VolumeButton VolumeSlider;
	private Sexy.IconEntry searchEntryMB;
	private ToggleButton toggleMB;
	private ToggleButton toggleStream;
	private Gtk.VBox notebookVBox;
	private Gtk.Notebook noteb;
	private int _posX_buffer;
	private int _posY_buffer;
//	private Action menuChildFullScreen;

	public Button playPauseButton; 
	public Button repeatButton;
	public Image repeatImage;
	public Label repeatLabel;
	public ProgressBar songProgressBar;
	public double current_volume; //keep it global for saving to keyfile
	public MusicBrowser musicBr;
	public TrackList trackList;
	public Window window;

	public int repeatState { get; set; }

	public signal void sign_pos_changed(double fraction);
	public signal void sign_volume_changed(double fraction);
		
	public MainWindow() {
		Params paramter = Params.instance();
		paramter.data_register(this);
		create_widgets();
		notify["repeatState"]+=on_repeatState_changed;
		add_lastused_titles_to_tracklist();
	}
	
	private void create_widgets() {
		try {
			assert(GLib.FileUtils.test(MAIN_UI_FILE, FileTest.EXISTS));
			
			this.add_from_file(MAIN_UI_FILE);
			this.window = this.get_object("window1") as Gtk.Window;

			this.playPauseButton           = this.get_object("playPauseButton") as Gtk.Button;
			playPauseButton.can_focus      = false;
			this.playPauseButton.clicked   += this.on_playpause_button_clicked;
			
			var stopButton                 = this.get_object("stopButton") as Gtk.Button;
			stopButton.can_focus           = false;
			stopButton.clicked             += this.on_stop_button_clicked;
			
			var nextButton                 = this.get_object("nextButton") as Gtk.Button;
			nextButton.can_focus           = false;
			nextButton.clicked             += this.on_next_button_clicked;
			
			var previousButton             = this.get_object("previousButton") as Gtk.Button;
			previousButton.can_focus       = false;
			previousButton.clicked         += this.on_previous_button_clicked;
			
			var removeAllButton            = this.get_object("removeAllButton") as Gtk.Button;
			removeAllButton.can_focus      = false;
			removeAllButton.clicked        += this.on_remove_all_button_clicked;
			removeAllButton.set_tooltip_text(_("Remove all"));
		
			var removeSelectedButton       = this.get_object("removeSelectedButton") as Gtk.Button;
			removeSelectedButton.can_focus = false;
			removeSelectedButton.clicked   += this.on_remove_selected_button_clicked;
			removeSelectedButton.set_tooltip_text(_("Remove selected titles"));
			
			this.repeatButton              = this.get_object("repeatButton") as Gtk.Button;
			repeatButton.can_focus         = false;
			this.repeatButton.clicked      += this.on_repeat_button_clicked;
			this.repeatLabel               = this.get_object("repeatLabel") as Gtk.Label;
			this.repeatImage               = this.get_object("repeatImage") as Gtk.Image;
				
			this.song_title_label           = this.get_object("song_title_label") as Gtk.Label;
			this.song_title_label.use_markup= true;
			
			this.songProgressBar            = this.get_object("songProgressBar") as Gtk.ProgressBar; 
			this.songProgressBar.button_press_event   += on_progressbar_press;
			this.songProgressBar.button_release_event += on_progressbar_release;
			this.songProgressBar.set_text("00:00 / 00:00");
			this.songProgressBar.fraction = 0.0;
			
			this.hpaned = this.get_object("hpaned1") as Gtk.HPaned;
			
			notebookVBox = this.get_object("vbox6") as Gtk.VBox;
			toggleMB = new Gtk.ToggleButton(); 
			toggleMB.label = _("Music Browser");
			toggleMB.can_focus = false;
			toggleMB.active = true; //initial value
			toggleMB.clicked += notebookMB_clicked;

			toggleStream = new Gtk.ToggleButton(); 
			toggleStream.label = _("Stream Browser") ;
			toggleStream.can_focus      = false;
			toggleStream.clicked += notebookStream_clicked;
			
			notebookVBox.pack_start(toggleMB, false, false, 0);
			notebookVBox.pack_start(toggleStream, false, false, 0);

			this.VolumeSlider = new Gtk.VolumeButton();
			this.VolumeSlider.can_focus = false;
			this.VolumeSlider.set_value(0.2);
			this.VolumeSlider.value_changed += on_volume_slider_change;
			var vbVol = this.get_object("vboxVolumeButton") as Gtk.VBox; 
			vbVol.pack_start(VolumeSlider, false, false, 1);
			
			///MAIN WINDOW MENU	
			var menuChildAdd          = this.get_object("imagemenuitem1") as Gtk.Action; 
			menuChildAdd.label        =_("_Add music"); 
			var menuChildSettings     = this.get_object("imagemenupref") as Gtk.Action;
			menuChildSettings.label   = _("_Settings"); 
			var menuChildQuit         = this.get_object("imagemenuitem3") as Gtk.Action; 
			menuChildQuit.label       = _("_Quit");
			var menuChildAbout        = this.get_object("imagemenuitem10") as Gtk.Action;
			menuChildAbout.label      = _("A_bout");
			var menuChildFullScreen   = this.get_object("menuitemfullscreen") as Gtk.Action;
			menuChildFullScreen.label = _("_Fullscreen");

			menuChildAdd.activate        += this.on_menu_add;
			menuChildSettings.activate   += this.on_settings_edit;
			menuChildQuit.activate       += this.quit_now;
			menuChildAbout.activate      += this.on_help_about;
			menuChildFullScreen.activate += this.on_fullscreen_clicked; 
			
			///Tracklist (right)
			this.trackList = new TrackList();
			this.trackList.set_size_request(300,300);
			var trackListScrollWin = this.get_object("scroll_tracklist") as Gtk.ScrolledWindow;
			trackListScrollWin.set_policy(Gtk.PolicyType.AUTOMATIC,Gtk.PolicyType.ALWAYS);
			trackListScrollWin.add(this.trackList);
			
			///MusicBrowser (left)
			this.musicBr = new MusicBrowser();
			this.musicBr.set_size_request(300,300);
			var musicBrScrollWin = this.get_object("scroll_music_br") as Gtk.ScrolledWindow;
			musicBrScrollWin.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC);
			musicBrScrollWin.add(this.musicBr);
			noteb = this.get_object("notebook1") as Gtk.Notebook;
				
			//search entry (left) ; TODO: IconEntry has been moved to Gtk+ as of version 2.14 - use Gtk+ IconEntry 
			//as soon as Fedora 12 and ubuntu 9.04 is there
			var searchImage = new Image.from_stock(Gtk.STOCK_FIND, IconSize.BUTTON);
			this.searchEntryMB = new Sexy.IconEntry();
			this.searchEntryMB.set_icon(Sexy.IconEntryPosition.PRIMARY, searchImage);
			this.searchEntryMB.set_icon_highlight(Sexy.IconEntryPosition.SECONDARY, true) ;
			this.searchEntryMB.add_clear_button();
			this.searchEntryMB.set_sensitive(true);
			this.searchEntryMB.changed += musicBr.on_searchtext_changed;

			var sexyentryBox = this.get_object("sexyentryBox") as Gtk.HBox; 
			sexyentryBox.add(searchEntryMB);
			
			this.window.set_icon_from_file (Config.UIDIR + "/xnoise_16x16.png");
		} 
		catch (GLib.Error err) {
			var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, 
				Gtk.ButtonsType.OK, "Failed to build main window! \n" + err.message);
			msg.run();
			return;
		}
	
		this.window.title = "xnoise music player";

		this.trayicon = create_tray_icon();
		this.menu     = add_menu_to_trayicon();				

		this.trayicon.popup_menu       += this.trayicon_menu_popup;
		this.trayicon.activate         += this.toggle_window_visbility;
		
		this.window.delete_event       += this.on_close; //only send to tray
		this.window.key_release_event  += this.on_key_released;
		this.window.window_state_event += this.on_window_state_change;
	}

	private void notebookMB_clicked(Gtk.ToggleButton sender) {
		if(sender.active) {
			this.toggleStream.clicked -= notebookStream_clicked;
			this.toggleStream.active = false;
			this.toggleStream.clicked += notebookStream_clicked;
			this.noteb.set_current_page(0);
		}
		else {
			this.toggleMB.clicked -= notebookMB_clicked;
			this.toggleMB.active = true;
			this.toggleMB.clicked += notebookMB_clicked;
		}
	}

	private void notebookStream_clicked(Gtk.ToggleButton sender) {
		if(sender.active) {
			this.toggleMB.clicked -= notebookMB_clicked;
			this.toggleMB.active = false;
			this.toggleMB.clicked += notebookMB_clicked;
			this.noteb.set_current_page(1);
		}
		else {
			this.toggleStream.clicked -= notebookStream_clicked;
			this.toggleStream.active = true;
			this.toggleStream.clicked += notebookStream_clicked;
		}
	}

	private void add_lastused_titles_to_tracklist() {
		//TODO: write tracks to tracklist
//		print("add_lastused_titles_to_tracklist\n");
	}

	private void on_repeatState_changed(MainWindow sender) {
		switch(this.repeatState) {
			case Repeat.NOT_AT_ALL : {
				repeatLabel.label = "no repeat";
				repeatImage.stock = Gtk.STOCK_EXECUTE; //TODO: create some other images
				break;
			}
			case Repeat.SINGLE : {
				repeatLabel.label = "repeat single";
				repeatImage.stock = Gtk.STOCK_REDO; 
				break;
			}
			case Repeat.ALL : {
				repeatLabel.label = "repeat all";
				repeatImage.stock = Gtk.STOCK_REFRESH; 
				break;
			}
		}
	}
		
	private bool on_window_state_change(Gtk.Window sender, Gdk.EventWindowState e) {
		if(e.new_window_state==Gdk.WindowState.FULLSCREEN) {
			is_fullscreen = true;
		}
		else {
			is_fullscreen = false;
		}
		return false;
	}

	private StatusIcon create_tray_icon() {
//		StatusIcon icon = new StatusIcon();
//		icon.file = Config.UIDIR + "/xnoise_16x16.png";
		StatusIcon icon = new StatusIcon.from_file(Config.UIDIR + "/xnoise_16x16.png");
//		icon.set_tooltip_text("xnoise");
		return icon;
	}

	private StatusIcon trayicon;
	private Menu menu;
	public Image playpause_popup_image;
	
	private Menu add_menu_to_trayicon() {
		var traymenu = new Menu();
		playpause_popup_image = new Image();
		playpause_popup_image.set_from_stock(STOCK_MEDIA_PLAY, IconSize.MENU);
		var playLabel = new Label("Play/Pause");
		playLabel.set_alignment(0, 0);
		playLabel.set_width_chars(20);
		var playpauseItem = new MenuItem();
		var playHbox = new HBox(false,1);
		playHbox.set_spacing(10);
		playHbox.pack_start(playpause_popup_image, false, true, 0);
		playHbox.pack_start(playLabel, true, true, 0);
		playpauseItem.add(playHbox);
		playpauseItem.activate += on_playpause_button_clicked;
		traymenu.append(playpauseItem);

		var previousImage = new Image();
		previousImage.set_from_stock(STOCK_MEDIA_PREVIOUS, IconSize.MENU);
		var previousLabel = new Label("Previous");
		previousLabel.set_alignment(0, 0);
		var previousItem = new MenuItem();
		var previousHbox = new HBox(false,1);
		previousHbox.set_spacing(10);
		previousHbox.pack_start(previousImage, false, true, 0);
		previousHbox.pack_start(previousLabel, true, true, 0);
		previousItem.add(previousHbox);
		previousItem.activate += on_previous_button_clicked;
		traymenu.append(previousItem);

		var nextImage = new Image();
		nextImage.set_from_stock(STOCK_MEDIA_NEXT, IconSize.MENU);
		var nextLabel = new Label("Next");
		nextLabel.set_alignment(0, 0);
		var nextItem = new MenuItem();
		var nextHbox = new HBox(false,1);
		nextHbox.set_spacing(10);
		nextHbox.pack_start(nextImage, false, true, 0);
		nextHbox.pack_start(nextLabel, true, true, 0);
		nextItem.add(nextHbox);
		nextItem.activate += on_next_button_clicked;
		traymenu.append(nextItem);

		var separator = new SeparatorMenuItem();
		traymenu.append(separator);

		var exitImage = new Image();
		exitImage.set_from_stock(STOCK_QUIT, IconSize.MENU);
		var exitLabel = new Label("Exit");
		exitLabel.set_alignment(0, 0);
		var exitItem = new MenuItem();
		var exitHbox = new HBox(false,1);
		exitHbox.set_spacing(10);
		exitHbox.pack_start(exitImage, false, true, 0);
		exitHbox.pack_start(exitLabel, true, true, 0);
		exitItem.add(exitHbox);
		exitItem.activate += quit_now;
		traymenu.append(exitItem);

		traymenu.show_all();
		return traymenu;
	}

	private void trayicon_menu_popup(StatusIcon i, uint button, uint activateTime) {
		menu.popup(null, null, null, 0, activateTime); 
	}

	private const int KEY_F11 = 0xFFC8; 
	private const int KEY_ESC = 0xFF1B;
	private bool on_key_released(Gtk.Window sender, Gdk.EventKey e) {
//		print("%d\n",(int)e.keyval);
		switch(e.keyval) {
			case KEY_F11:
				this.toggle_fullscreen();
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
		Main.instance().quit();
	}

////	private string[] final_tracklist; 
//	private GLib.List<string> final_tracklist; 
//	public void save_tracklist() {
////		final_tracklist = new string[0];
//		final_tracklist = new GLib.List<string>();
//		print("write tracks into db....\n");
//		this.trackList.get_track_ids(ref final_tracklist);	
////		print("%s\n", final_tracklist[0]);
//		var dbwr = new DbWriter();
//		dbwr.write_final_track_ids_to_db(ref final_tracklist);
//		final_tracklist = null;
//	}

	
	private void on_fullscreen_clicked(Action s) {
			this.toggle_fullscreen();
	}
			
	private void toggle_fullscreen() {
		if(is_fullscreen) {
			print("was fullscreen before\n");
			this.window.unfullscreen();	
		}
		else {
			this.window.fullscreen();					
		}
	}
	
	private void toggle_window_visbility() {
		if (this.window.is_active) {
			this.window.get_position(out _posX_buffer, out _posY_buffer);
			this.window.hide();
		}
		else if (this.window.visible=true) {
			this.window.move(_posX_buffer, _posY_buffer);
			this.window.present();
		}
		else {
			this.window.move(_posX_buffer, _posY_buffer);
			this.window.present();
		}
	}

//	private void playlist_play_double_clicked_song_cb(TrackList sender, string uri, TreePath path){ 
//		Main.instance().gPl.Uri = uri;
//		Main.instance().gPl.playSong ();
//		if (Main.instance().gPl.playing == false) {
//			playpause_button_set_pause_picture ();
//			Main.instance().gPl.play();
//		}
//		Gdk.Pixbuf pixbuf;
//		TreeIter iter;
//		try {
//			pixbuf = new Gdk.Pixbuf.from_file("ui/track.png");
//		}
//		catch (GLib.Error e) {
//			print("Error: %s\n", e.message);
//		}
//		trackList.model.get_iter(out iter, path);
//		trackList.reset_play_status_for_playlisttitle();
//		trackList.set_state_picture_for_title_in_playlist(iter, PLTrackStatus.PLAYING);
//	}

//	private void playlist_active_path_changed_cb(TrackList sender){ 
//		TreePath path;
//		if (!trackList.get_active_path(out path)) return;
//		string uri = trackList.get_uri_for_path(path);
//		if ((uri!=null) && (uri!="")) {
//			Main.instance().gPl.Uri = uri;
//			Main.instance().gPl.playSong();
//		}
//	}

	public void add_uris_to_tracklist(string[]? uris) {
		if(uris!=null) {
			if(uris[0]==null) return;
			int i = 0;
			TreeIter iter, iter_2;
			trackList.reset_play_status_for_title();				
			foreach(string uri in uris) {
				TagReader tr = new TagReader();
				TrackData t = tr.read_tag_from_file(uri);
				if (i==0) {
					iter = trackList.insert_title(TrackStatus.PLAYING, 
					                              null, 
					                              (int)t.Tracknumber,
					                              t.Title, 
					                              t.Album, 
					                              t.Artist, 
					                              uri);
					trackList.set_state_picture_for_title(iter, TrackStatus.PLAYING);
					iter_2 = iter;
				}
				else {
					iter = trackList.insert_title(TrackStatus.STOPPED, 
					                              null, 
					                              (int)t.Tracknumber,
					                              t.Title, 
					                              t.Album, 
					                              t.Artist, 
					                              uri);	
					trackList.set_state_picture_for_title(iter);
				}
				tr = null;
				i++;
			}
			Main.instance().add_track_to_gst_player(uris[0]);
		}
	}
	
////REGION IParameter
	public void read_data(KeyFile file) throws KeyFileError {
		this.repeatState = file.get_integer("settings", "repeatstate");
		if(!this.is_fullscreen) {
			int posX, posY, wi, he, hp_position;
			posX = file.get_integer("settings", "posX");
			posY = file.get_integer("settings", "posY");
			this.window.move(posX, posY);

			wi =  file.get_integer("settings", "width");
			he = file.get_integer("settings", "height");
			if (wi > 0 && he > 0) {
				this.window.resize(wi, he);
			}
		
			hp_position = file.get_integer("settings", "hp_position");
			if (wi > 0 && he > 0) {
				this.hpaned.set_position(hp_position);
			}
		}

		double volSlider = file.get_double("settings", "volume");
		if(volSlider > 0.0) {
			VolumeSlider.set_value(volSlider);
//			volume_slide_changed(volSlider);
			sign_volume_changed(volSlider); // will automatically set this.current_volume
		}
		else {
			VolumeSlider.set_value(0.3);
//			volume_slide_changed(0.2);
			sign_volume_changed(0.3); // will automatically set this.current_volume
		}
	}

	public void write_data(KeyFile file) {
		int posX, posY, wi, he;
		file.set_integer("settings", "repeatstate", repeatState);
		this.window.get_position(out posX, out posY);
		file.set_integer("settings", "posX", posX);
		file.set_integer("settings", "posY", posY);
		this.window.get_size(out wi, out he);
		file.set_integer("settings", "width", wi);
		file.set_integer("settings", "height", he);
		file.set_integer("settings", "hp_position", this.hpaned.get_position());
		file.set_double("settings", "volume", current_volume);
	}
////END REGION IParameter

	private void on_volume_slider_change() {
		sign_volume_changed(VolumeSlider.get_value());
	}

	public void playpause_button_set_play_picture() {
		var playImage = new Image.from_stock(STOCK_MEDIA_PLAY, IconSize.BUTTON);
		playPauseButton.set_image(playImage);
	}

	public void playpause_button_set_pause_picture() {
		var pauseImage = new Image.from_stock(STOCK_MEDIA_PAUSE, IconSize.BUTTON);
		playPauseButton.set_image(pauseImage);
	}

	private void on_stop_button_clicked() {
		stop();
	}

	private void stop() {
		Main.instance().gPl.stop();
		Main.instance().gPl.Uri = "";
		playpause_button_set_play_picture ();
		trackList.reset_play_status_for_title();
		
		//save position
		int rowcount = -1;
		rowcount = (int)trackList.model.iter_n_children(null);
		if(!(rowcount>0)) {
			return;
		}
		TreeIter iter;
		TreePath path;
		trackList.get_active_path(out path);
		trackList.model.get_iter(out iter, path); 
		trackList.model.set(iter, TrackListColumn.STATE, TrackStatus.POSITION_FLAG, -1);
	}

	private void on_playpause_button_clicked() { //TODO: maybe use the stored position
		if ((Main.instance().gPl.playing == false) 
			&& ((trackList.not_empty()) 
			|| (Main.instance().gPl.Uri != ""))) {   // not running and track available set to play
				if (Main.instance().gPl.Uri == "") { // play selected track, if available....
					GLib.List<TreePath> pathlist;
					weak TreeSelection ts;
					ts = trackList.get_selection();
					pathlist = ts.get_selected_rows(null);
					if (pathlist.nth_data(0)!=null) {
						string uri = trackList.get_uri_for_path(pathlist.nth_data(0));
						trackList.on_activated(uri, pathlist.nth_data(0));
					}
					else {
						//.....or play previous song
						this.change_song(Direction.PREVIOUS);
					}
				}
				playpause_popup_image.set_from_stock(STOCK_MEDIA_PAUSE, IconSize.MENU);
				playpause_button_set_pause_picture();
				trackList.set_play_picture();
				Main.instance().gPl.play();
		}
		else { 
			if (trackList.model.iter_n_children(null)>0) { 
				playpause_popup_image.set_from_stock(STOCK_MEDIA_PLAY, IconSize.MENU);
				playpause_button_set_play_picture();
				trackList.set_pause_picture();
				Main.instance().gPl.pause();
			}
			else { //if there is no track -> stop
				stop();
			}
		}
	}

	private void on_previous_button_clicked() {
		change_song(Direction.PREVIOUS);
	}

	public void change_song(int direction, bool handle_repeat_state = false) {
		TreeIter iter;
		TreePath path = null;
		int rowcount = -1;
		rowcount = (int)trackList.model.iter_n_children(null);
		if(!(rowcount>0)) {
			stop();
			return;
		}
		
		if(!trackList.get_active_path(out path)) { 
			stop();
			return;
		}
		
		if((!Main.instance().gPl.playing)&&(!Main.instance().gPl.paused)) {
			trackList.reset_play_status_for_title();
			return;
		}
		
		if(!(handle_repeat_state && (repeatState==Repeat.SINGLE))) {
			print("handle next or previous\n");
			if(direction == Direction.NEXT)     path.next();
			if(direction == Direction.PREVIOUS) path.prev();
		}

		if(trackList.model.get_iter(out iter, path)) {       //goto next song, if possible...
			print("goto next title or same\n");
			trackList.reset_play_status_for_title();
			trackList.set_state_picture_for_title(iter, TrackStatus.PLAYING);
			if(Main.instance().gPl.paused) this.trackList.set_pause_picture();
			trackList.set_focus_on_iter(ref iter);
		} 
		else if((trackList.model.get_iter_first(out iter))&&
		        (((handle_repeat_state)&&
		        (repeatState==Repeat.ALL))||(!handle_repeat_state))) {                                       //...or goto first song, if possible ...
			print("goto first\n");
			trackList.reset_play_status_for_title();
			trackList.set_state_picture_for_title(iter, TrackStatus.PLAYING);
			if(Main.instance().gPl.paused) this.trackList.set_pause_picture();
			trackList.set_focus_on_iter(ref iter);
		}
		else {
			print("goto stop\n");
			Main.instance().gPl.stop();                      //...or stop
			playpause_button_set_play_picture ();
			trackList.reset_play_status_for_title();
			trackList.set_focus_on_iter(ref iter);
			Main.instance().gPl.Uri="";                      //...or stop
		}
	}

	private void on_next_button_clicked() {
		//TODO: Main.instance().gPl.currentTag.reset();
		this.change_song(Direction.NEXT);
	}	

	private void on_remove_all_button_clicked() {
		ListStore store;
		store = (ListStore)trackList.get_model();
		store.clear();
	}
	
	private void on_repeat_button_clicked() {
		int temprepeatState = this.repeatState;
		temprepeatState += 1;
		if(temprepeatState>2) temprepeatState = 0;
		repeatState = temprepeatState;
//		repeatLabel.label = "repeat single track";
	}
	
	private void on_remove_selected_button_clicked() {
		trackList.remove_selected_row();
	}

	private bool on_progressbar_press(Gtk.ProgressBar pb, Gdk.EventButton e) { 
		if((Main.instance().gPl.playing)|(Main.instance().gPl.paused)) {
			_seek = true;
			Main.instance().gPl.seeking = true;
			songProgressBar.motion_notify_event += on_progressbar_motion_notify;				
		}
		return false;
	}

	private bool on_progressbar_release(Gtk.ProgressBar pb, Gdk.EventButton e) { 
		if((Main.instance().gPl.playing)|(Main.instance().gPl.paused)) {
			double thisFraction; 
			double mouse_x, mouse_y;
			mouse_x = e.x;
			mouse_y = e.y;
			Allocation progress_loc = songProgressBar.allocation;
			thisFraction = mouse_x / progress_loc.width; 
			songProgressBar.motion_notify_event -= on_progressbar_motion_notify;
			_seek = false;//TODO: check if this is used any more
			Main.instance().gPl.seeking = false;
			if(thisFraction < 0.0) thisFraction = 0.0;
			if(thisFraction > 1.0) thisFraction = 1.0;
			songProgressBar.set_fraction(thisFraction);
			this.sign_pos_changed(thisFraction);
		}
		return false;
	}

	private bool on_progressbar_motion_notify(Gtk.ProgressBar pb, Gdk.EventMotion e) { 
		double thisFraction;
		double mouse_x, mouse_y;
		mouse_x = e.x;
		mouse_y = e.y;
		Allocation progress_loc = songProgressBar.allocation;
		thisFraction = mouse_x / progress_loc.width; 
		if(thisFraction < 0.0) thisFraction = 0.0;
		if(thisFraction > 1.0) thisFraction = 1.0;
		songProgressBar.set_fraction(thisFraction);
		this.sign_pos_changed(thisFraction); 
		return false;
	}

	public void progressbar_set_value(uint pos,uint len) {
		int dur_min, dur_sec, pos_min, pos_sec;
		if(len > 0) {
			double fraction = (double)pos/(double)len;
			if(fraction<0.0) fraction = 0.0;
			if(fraction>1.0) fraction = 1.0;
			songProgressBar.set_fraction(fraction);
			songProgressBar.set_sensitive(true);
			dur_min = (int)(len / 60000);
			dur_sec = (int)((len % 60000) / 1000);
			pos_min = (int)(pos / 60000);
			pos_sec = (int)((pos % 60000) / 1000);
			string timeinfo = "%02d:%02d / %02d:%02d".printf(pos_min, pos_sec, dur_min, dur_sec);
			songProgressBar.set_text(timeinfo);
		} 
		else {
			songProgressBar.set_fraction(0.0);
			songProgressBar.set_sensitive(false);
		}
	}

	private bool on_close() {
		this.window.get_position(out _posX_buffer, out _posY_buffer);
		this.window.hide();
		return true;
	}

	private void on_help_about(Gtk.Action item) {
		var dialog = new AboutDialog ();
		dialog.run();
		dialog.destroy();
	}

	private MusicFolderDialog mfd;
	private void on_menu_add(Gtk.Action sender) {
		mfd = new MusicFolderDialog();
		mfd.sign_finish += () => {
			mfd = null;
			Idle.add(musicBr.change_model_data);	
		};
	}
	
	private SettingsDialog setingsD;
	private void on_settings_edit(Gtk.Action sender) {
		setingsD = new SettingsDialog();
	}

	public void set_displayed_title(string? newuri) {
		string text;
		string path = null;
		if((newuri!=null) && (newuri!="")) {
			try {
				path = GLib.Filename.from_uri(newuri);
			}
			catch(GLib.ConvertError e) {
				print("%s\n", e.message);
			}
		}
		if((path!=null) && (path!="")) {
			var tr = new TagReader(); //TODO: Do this with gstreamer, so that streams can be handled, too
			TrackData tags = tr.read_tag_from_file(path);
			string artist = tags.Artist;
			string album  = tags.Album; 
			string title  = tags.Title; 
			if(tags.Artist!="") {
				text = Markup.printf_escaped("<b>%s</b>\n<i>%s</i> <b>%s</b> <i>%s</i> <b>%s</b>", 
					title, 
					_("by"), 
					artist, 
					_("on"), 
					album
					);
			}
			else { //in this case there is no information for this title (see TagReader)
				text = Markup.printf_escaped("<b>%s</b>",
					title
					);				
			}
		}
		else {
			if((!Main.instance().gPl.playing)&&
				(!Main.instance().gPl.paused)) {
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
		song_title_label.set_text(text);
		song_title_label.use_markup = true;
	}
}

