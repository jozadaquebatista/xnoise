using GLib;
using Gtk;
using Xnoise;	
	
public class Xnoise.TrayIcon : StatusIcon {
	private Menu traymenu;
	private unowned Main xn;
	private Image playpause_popup_image;
	private const int TOOLTIP_IMAGE_SIZE = 48;
	
	public TrayIcon() {
		set_from_file(Config.UIDIR + "xnoise_bruit_48x48.png");
		this.has_tooltip = true;
		xn = Main.instance;
		construct_traymenu();
		this.query_tooltip.connect(on_query_tooltip);
		
		
		popup_menu.connect(this.traymenu_popup);
		activate.connect(xn.main_window.toggle_window_visbility);
		scroll_event.connect(this.on_scrolled);
		button_press_event.connect(this.on_clicked);
	}
	
	private void construct_traymenu() {
		traymenu = new Menu();

		playpause_popup_image = new Image();
		playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
		xn.gPl.sign_playing.connect( () => {
			this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PAUSE, IconSize.MENU);
		});
		xn.gPl.sign_stopped.connect( () => {
			if(this.playpause_popup_image==null) print("this.playpause_popup_image == null\n");
			this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
		});
		xn.gPl.sign_paused.connect( () => {
			this.playpause_popup_image.set_from_stock(Gtk.Stock.MEDIA_PLAY, IconSize.MENU);
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
		playpauseItem.activate.connect(xn.main_window.playPauseButton.on_menu_clicked);
		traymenu.append(playpauseItem);

		var previousImage = new Image();
		previousImage.set_from_stock(Gtk.Stock.MEDIA_PREVIOUS, IconSize.MENU);
		var previousLabel = new Label(_("Previous"));
		previousLabel.set_alignment(0, 0);
		var previousItem = new MenuItem();
		var previousHbox = new HBox(false,1);
		previousHbox.set_spacing(10);
		previousHbox.pack_start(previousImage, false, true, 0);
		previousHbox.pack_start(previousLabel, true, true, 0);
		previousItem.add(previousHbox);
		previousItem.activate.connect( () => {
			xn.main_window.handle_control_button_click(xn.main_window.previousButton, ControlButton.Direction.PREVIOUS);
		});
		traymenu.append(previousItem);

		var nextImage = new Image();
		nextImage.set_from_stock(Gtk.Stock.MEDIA_NEXT, IconSize.MENU);
		var nextLabel = new Label(_("Next"));
		nextLabel.set_alignment(0, 0);
		var nextItem = new MenuItem();
		var nextHbox = new HBox(false,1);
		nextHbox.set_spacing(10);
		nextHbox.pack_start(nextImage, false, true, 0);
		nextHbox.pack_start(nextLabel, true, true, 0);
		nextItem.add(nextHbox);
		nextItem.activate.connect( () => {
			xn.main_window.handle_control_button_click(xn.main_window.nextButton, ControlButton.Direction.NEXT);
		});
		traymenu.append(nextItem);

		var separator = new SeparatorMenuItem();
		traymenu.append(separator);

		var exitImage = new Image();
		exitImage.set_from_stock(Gtk.Stock.QUIT, IconSize.MENU);
		var exitLabel = new Label(_("Exit"));
		exitLabel.set_alignment(0, 0);
		var exitItem = new MenuItem();
		var exitHbox = new HBox(false,1);
		exitHbox.set_spacing(10);
		exitHbox.pack_start(exitImage, false, true, 0);
		exitHbox.pack_start(exitLabel, true, true, 0);
		exitItem.add(exitHbox);
		exitItem.activate.connect(xn.quit);
		traymenu.append(exitItem);

		traymenu.show_all();
	}

	private bool on_clicked(Gdk.EventButton e) {
		switch(e.button) {
			case 2:
				//ugly, we should move play/resume code out of there.
				xn.main_window.playPauseButton.on_clicked(new Gtk.Button());
				break;
			default:
				break;
		}
		return false;
	}

	private bool on_scrolled(Gtk.StatusIcon sender, Gdk.Event event) {
		if(global.player_state != PlayerState.STOPPED) {
			if(event.scroll.direction == Gdk.ScrollDirection.DOWN) {
				xn.main_window.change_track(ControlButton.Direction.PREVIOUS, true);
			}
			else if(event.scroll.direction == Gdk.ScrollDirection.UP) {
				xn.main_window.change_track(ControlButton.Direction.NEXT, true);
			}
		}
		return false;
	}
	
	private void traymenu_popup(StatusIcon i, uint button, uint activateTime) {
		traymenu.popup(null, null, i.position_menu, 0, activateTime);
	}
	
	// todo: use global string constants for uknown_[title,album,artist] and state!
	// for now they are left uni18ned
	private bool on_query_tooltip(int x, int y, bool keyboard_mod, Tooltip tp) {
		string state = "";
		string? uri = global.current_uri;
		switch(global.player_state) {
			case PlayerState.STOPPED: {
				state = "stopped";
				break;
			}
			case PlayerState.PLAYING: {
				state = "playing";
				break;
			}
			case PlayerState.PAUSED: {
				state = "paused";
				break;
			}
			default: {
				state = "stopped";
				break;
			}
		}
		state = Markup.escape_text(state);
	
		if(global.player_state == PlayerState.STOPPED || uri == null || uri == "") {
			tp.set_markup(" xnoise media player \n" +
				          "<span rise=\"6000\" style =\"italic\"> ready to rock ;)</span>");
			return true;
		}
	
		string? title = global.current_title;
		string? artist = global.current_artist;
		string? album = global.current_album;
	
		string? filename = null;
		if(uri != null) {
			File f = File.new_for_uri(uri);
			if(f != null) {
				filename = f.get_basename();
				filename = Markup.escape_text(filename);
			}
		}
	
		//if neither title nor artist are known, show filename instead
		//if there is no title, the title is the same as the filename
		//shouldn't global rather return null if there is no title?
	
		//todo: handle streams, change label layout, pack into a box with padding and use Tooltip.set_custom
		if((title == null && artist == null && filename != null) || (filename == title /*&& artist == null*/)) {
			tp.set_markup("\n<b>" + prepare_name_from_filename(filename) + " </b><span size=\"xx-small\">\n</span>" +
			              "<span size=\"small\" style=\"italic\" rise=\"6000\">" +
			              state + "</span>\n");
		}
		else {
			if(album == null)
				album = "unknown album";
			if(artist == null)
				artist = "unknown artist";
			if(title == null)
				title = "unknown title";
			album = Markup.escape_text(album);
			artist = Markup.escape_text(artist);
			title = Markup.escape_text(title);
			
			tp.set_markup("<span weight=\"bold\">" + 
			              title +   " </span>\n<span size=\"small\" rise=\"6000\" style=\"italic\">" + 
			              state + "</span><span size=\"xx-small\">\n</span>" +
			              "<span size=\"small\" weight=\"light\">     by </span>" + 
			              artist + " \n" +
			              "<span size=\"small\" weight=\"light\">     on </span> " + 
			              album);
		}
		
		return true;
	}
}
