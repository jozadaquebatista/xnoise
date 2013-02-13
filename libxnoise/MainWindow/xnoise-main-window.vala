/* xnoise-main-window.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;

[CCode (cname = "gdk_window_ensure_native")]
private extern bool ensure_native(Gdk.Window window);

//[CCode (cname = "gtk_widget_style_get_property")]
//private extern void widget_style_get_property(Gtk.Widget widget, string property_name, GLib.Value val);

public class Xnoise.MainWindow : Gtk.Window, IParams {
    private const string MAIN_UI_FILE      = Config.XN_UIDIR + "main_window.ui";
    private const string MENU_UI_FILE      = Config.XN_UIDIR + "main_ui.xml";
    private unowned Main xn;
    private VolumeSliderButton volume_slider;
    private int _posX;
    private int _posY;
    private Gtk.Box contentvbox;
    private uint aimage_timeout;
    private Gtk.Toolbar main_toolbar;
    private ToolItem eqButtonTI;
    private Button repeatButton;
    private TrackListViewWidget tracklistview_widget;
    private VideoViewWidget videoview_widget;
    private LyricsViewWidget lyricsview_widget;
    private string mainview_page_buffer;
    private Image repeatimage; 
    private Box menuvbox;
    private Box mainvbox;
    private Box infobox;
    private MenuBar menubar;
    private ImageMenuItem config_button_menu_root;
    private Gtk.Menu config_button_menu;
    private bool _media_browser_visible;
    private ulong active_notifier = 0;
    private ScreenSaverManager ssm = null;
    private List<Gtk.Action> actions_list = null;
    internal Box media_browser_box;
    private Xnoise.AppMenuButton app_menu_button;
    private string temporary_mainview_name;
    private bool window_maximized;
    private SettingsWidget settings_widget;
    private Gtk.Window eqdialog;
    private Gtk.Notebook bottom_notebook;
    private Gtk.Notebook content_notebook;
    private AlbumImage albumimage;
    private Gtk.Entry album_search_entry;
    private unowned TrackList trackList;
    internal SerialButton album_view_sorting;
    internal SerialButton album_view_direction;
    internal AlbumArtView album_art_view;
    internal ToggleButton album_view_toggle;
    internal bool quit_if_closed;
    internal ScrolledWindow musicBrScrollWin = null;
    internal ScrolledWindow trackListScrollWin = null;
    internal Gtk.ActionGroup action_group;
    internal FullscreenToolbar fullscreentoolbar;
    internal Box videovbox;
    internal unowned VideoScreen videoscreen;
    internal CustomPaned hpaned;
    internal Entry search_entry;
    internal PlayPauseButton playPauseButton;
    internal ControlButton previousButton;
    internal ControlButton nextButton;
    internal ControlButton stopButton;
    internal TrackInfobar track_infobar;
    internal MusicBrowser musicBr = null;
    internal Gtk.Window fullscreenwindow;
    public SerialButton main_view_sbutton;
    public unowned LyricsView lyricsView { get; private set; }
    public bool is_fullscreen = false;
    public MainViewNotebook mainview_box { get; private set; }
    public MediaSoureWidget msw;
    
    private Gtk.UIManager _ui_manager = new Gtk.UIManager();
    public Gtk.UIManager ui_manager {
        get { return _ui_manager;  }
        set { _ui_manager = value; }
    }
    
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
                if(!main_view_sbutton.has_item(LYRICS_VIEW_NAME)) {
                    main_view_sbutton.insert(LYRICS_VIEW_NAME, SHOWLYRICS);
                }
            }
            else {
                main_view_sbutton.del(LYRICS_VIEW_NAME);
            }
            Idle.add( () => {
                foreach(Gtk.Action a in action_group.list_actions())
                    if(a.name == "ShowLyricsAction") a.set_visible(value);
                return false;
            });
            _active_lyrics = value;
        }
    }
    
    private void set_sensitive_toggle_action_state(string name, bool state) {
//        in_update_toggle_action = true;
        Idle.add( () => {
            unowned Gtk.ToggleAction? tax = null;
            foreach(Gtk.Action a in action_group.list_actions()) {
                tax = a as Gtk.ToggleAction;
                
                if(tax != null && tax.name == name) {
                    tax.set_sensitive(state);
                    break;
                }
            }
//            Idle.add( () => {
//                in_update_toggle_action = false;
//                return false;
//            });
            return false;
        });
    }

    internal void update_toggle_action_state(string name, bool state) {
        in_update_toggle_action = true;
        Idle.add( () => {
            unowned Gtk.ToggleAction? tax = null;
            foreach(Gtk.Action a in action_group.list_actions()) {
                tax = a as Gtk.ToggleAction;
                
                if(tax != null && tax.name == name) {
                    tax.set_active(state);
                    break;
                }
            }
            Idle.add( () => {
                in_update_toggle_action = false;
                return false;
            });
            return false;
        });
    }
    
    public bool media_browser_visible { 
        get {
            return _media_browser_visible;
        } 
        set {
            _media_browser_visible = value;
            if(!value) {
                hpaned_position_buffer = hpaned.get_position(); // buffer last position
                media_browser_box.hide();
                hpaned.set_position(0);
            }
            else {
                media_browser_box.show();
                if(hpaned_position_buffer > 20) { // min value
                    hpaned.set_position(hpaned_position_buffer);
                }
                else {
                    hpaned.set_position(200); //use this if nothing else is available
                }
            }
            Params.set_bool_value("media_browser_hidden", !value);
        }
    }
    
    public PlayerRepeatMode repeatState { get; set; }
    public bool fullscreenwindowvisible { get; set; }

    private signal void sign_drag_over_content_area();

    public enum PlayerRepeatMode {
        NOT_AT_ALL = 0,
        SINGLE,
        ALL,
        RANDOM
    }

    private const Gtk.ActionEntry[] action_entries = {
        { "FileMenuAction", null, N_("_File") },
            { "OpenAction", Gtk.Stock.OPEN, null, "<Ctrl>o", N_("open file"), on_file_add },
            { "OpenLocationAction", Gtk.Stock.NETWORK, N_("Open _Stream"), "<Control>l", N_("open remote location"), on_location_add },
            { "AddRemoveAction", Gtk.Stock.ADD, N_("_Add or Remove media"), null, N_("manage the content of the xnoise media library"), on_menu_add},
            { "QuitAction", Gtk.Stock.QUIT, null, null, null, quit_now},
        { "EditMenuAction", null, N_("_Edit") },
            { "ClearTrackListAction", Gtk.Stock.CLEAR, N_("C_lear tracklist"), "<Alt>c", N_("Clear the tracklist"), on_remove_all_button_clicked },
            { "RescanLibraryAction", Gtk.Stock.REFRESH, N_("_Rescan collection"), null, N_("Rescan collection"), on_reload_collection_button_clicked },
            { "IncreaseVolumeAction", null, N_("_Increase volume"), "<Control>plus", N_("Increase playback volume"), increase_volume },
            { "DecreaseVolumeAction", null, N_("_Decrease volume"), "<Control>minus", N_("Decrease playback volume"), decrease_volume },
            { "PreviousTrackAction", Gtk.Stock.MEDIA_PREVIOUS, N_("_Previous track"), "<Control>p", N_("Go to previous track"), menu_prev },
            { "PlayPauseAction", Gtk.Stock.MEDIA_PLAY, N_("_Toggle play"), "<Control>KP_Space", N_("Toggle playback status"), menutoggle_playpause },
            { "NextTrackAction", Gtk.Stock.MEDIA_NEXT, N_("_Next track"), "<Control>n", N_("Go to next track"), menu_next },
            { "SettingsAction", Gtk.Stock.PREFERENCES, null, null, null, on_settings_edit },
        { "ViewMenuAction", null, N_("_View") },
            { "ShowTracklistAction", Gtk.Stock.INDEX, N_("_Tracklist"), "<Alt>1", N_("Go to the tracklist."), on_show_tracklist_menu_clicked },
            { "ShowLyricsAction", Gtk.Stock.EDIT, N_("_Lyrics"), "<Alt>3", N_("Go to the lyrics view."), on_show_lyrics_menu_clicked},
            { "ShowVideoAction", Gtk.Stock.LEAVE_FULLSCREEN, N_("_Now Playing"), "<Alt>2",
               N_("Go to the 'Now Playing' screen in the main window."), on_show_video_menu_clicked},
        { "HelpMenuAction", null, N_("_Help") },
            { "AboutAction", Gtk.Stock.ABOUT, null, null, null, on_help_about},
            { "HelpFAQ", Gtk.Stock.DIALOG_QUESTION, N_("_Frequently Asked Questions"), null, N_("_Open Frequently Asked Questions in web browser"), on_help_faq },
            { "HelpKeyboard", Gtk.Stock.DIALOG_QUESTION, N_("_Keyboard Shortcuts"), null, N_("_Open Keyboard Shortcuts in web browser"), on_keyboard_shortcuts_web },
        { "ConfigMenuAction", null, N_("_Config") }
    };

    private Gtk.ToggleActionEntry[] toggle_action_entries;

    private const Gtk.TargetEntry[] target_list = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0},
        {"text/uri-list", TargetFlags.OTHER_APP, 0}
    };

    private bool _usestop;
    public bool usestop {
        get {
            return _usestop;
        }
        set {
            if(value == true) {
                stopButton.set_no_show_all(false);
                stopButton.show_all();
            }
            else {
                stopButton.set_no_show_all(true);
                stopButton.hide();
            }
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
                
                app_menu_button.show();
            }
            else {
                if(menubar.get_parent() == null) {
                    menuvbox.add(menubar);
                    menubar.show();
                }
                app_menu_button.hide();
            }
            _compact_layout = value;
        }
    }

    public MainWindow() {
        this.xn = Main.instance;
        Params.iparams_register(this);
        
        toggle_action_entries = {};
        ToggleActionEntry ta = ToggleActionEntry();
        ta.name = "ShowMediaBrowserAction";
        ta.stock_id = Gtk.Stock.EDIT;
        ta.label =  N_("_Show Media Browser");
        ta.accelerator = "<Ctrl>M";
        ta.callback = toggle_media_browser_visibility;
        ta.is_active = !Params.get_bool_value("media_browser_hidden");
        toggle_action_entries += ta;
        
        ta = ToggleActionEntry();
        ta.name = "VideoFullscreenAction";
        ta.stock_id = Gtk.Stock.FULLSCREEN;
        ta.label =  N_("Show _Video Fullscreen");
        ta.accelerator = "<Alt>F";
        ta.callback = toggle_fullscreen;
        ta.is_active = fullscreenwindowvisible;
        toggle_action_entries += ta;

        ta = ToggleActionEntry();
        ta.name = "ShowAlbumArtViewAction";
        ta.stock_id = Gtk.Stock.ORIENTATION_PORTRAIT;
        ta.label =  N_("Show _Album Art view");
        ta.accelerator = "<Ctrl>B";
        ta.callback = toggle_bottom_view;
        ta.is_active = false;
        toggle_action_entries += ta;
        
        setup_widgets();
        
        //initialization of videoscreen
        initialize_video_screen();
        
        //initialize screen saver management
        ssm = new ScreenSaverManager();
        
        active_notifier = this.notify["is-active"].connect(buffer_position);
        this.notify["repeatState"].connect(on_repeatState_changed);
        this.notify["fullscreenwindowvisible"].connect(on_fullscreenwindowvisible);
        global.notify["media-import-in-progress"].connect(on_media_import_notify);
        
        mainview_page_buffer = TRACKLIST_VIEW_NAME;
        
        global.caught_eos_from_player.connect(on_caught_eos_from_player);
        global.tag_changed.connect(this.set_displayed_title);
        gst_player.sign_video_playing.connect( () => { 
            //handle stop signal from gst player
            if(!this.fullscreenwindowvisible) {
                Idle.add( () => {
                    mainview_page_buffer = VIDEOVIEW_NAME;
//                    buffer_last_page = (int)TrackListNoteBookTab.VIDEO;
                    Params.set_string_value("MainViewName", VIDEOVIEW_NAME);
                    if(aimage_timeout != 0) {
                        Source.remove(aimage_timeout);
                        aimage_timeout = 0;
                    }
                    return false;
                });
                main_view_sbutton.select(VIDEOVIEW_NAME, true);
            }
        });
        Idle.add( () => {
            msw.set_focus_on_selector();
            return false;
        });
        this.window_state_event.connect(on_window_state_event);
        Idle.add(() => {
            window_in_foreground = true;
            return false;
        });
    }
    
    public bool window_in_foreground { get; private set; default = true; }
    
    private bool on_window_state_event(Gdk.EventWindowState e) {
        if((e.new_window_state & Gdk.WindowState.MAXIMIZED) == Gdk.WindowState.MAXIMIZED) {
            window_maximized = true;
        }
        else {
            window_maximized = false;
        }
        if(this.is_active) {
            window_in_foreground = true;
        }
        else {
            window_in_foreground = false;
        }
        if((e.new_window_state & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN) {
            is_fullscreen = true;
        }
        else if((e.new_window_state & Gdk.WindowState.ICONIFIED) == Gdk.WindowState.ICONIFIED) {
            window_in_foreground = false;
            this.get_position(out _posX, out _posY);
            is_fullscreen = false;
            if(eqdialog != null) {
                eqdialog.destroy();
                eqdialog = null;
            }
        }
        else {
            is_fullscreen = false;
        }
        return false;
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
            target_list,
            Gdk.DragAction.COPY|
            Gdk.DragAction.DEFAULT
        );
        Gtk.drag_dest_set(
            lyricsView,
            Gtk.DestDefaults.MOTION,
            target_list,
            Gdk.DragAction.COPY|
            Gdk.DragAction.DEFAULT
        );
        videoscreen.button_press_event.connect(on_video_da_button_press);
        sign_drag_over_content_area.connect(() => {
            //switch to tracklist for dropping
            if(!fullscreenwindowvisible) {
                main_view_sbutton.select(TRACKLIST_VIEW_NAME, true);
            }
        });
        videoscreen.drag_motion.connect( (sender,context,x,y,t) => {
            print("videoscreen d m\n");
            temporary_mainview_name = VIDEOVIEW_NAME;
            sign_drag_over_content_area();
            return true;
        });
        
        lyricsView.drag_motion.connect((sender,context,x,y,t) => {
            temporary_mainview_name = LYRICS_VIEW_NAME;
            sign_drag_over_content_area();
            return true;
        });
        
    }
    
    internal void restore_tab() {
        if(temporary_mainview_name != TRACKLIST_VIEW_NAME) {
            mainview_box.select_main_view(temporary_mainview_name);
            main_view_sbutton.select(temporary_mainview_name, true);
            temporary_mainview_name = TRACKLIST_VIEW_NAME;
        }
    }
    
    private void on_caught_eos_from_player() {
        this.change_track(ControlButton.Function.NEXT, true);
    }

    private void on_keyboard_shortcuts_web() {
        try {
            Gtk.show_uri(get_window().get_screen(), WEB_KEYBOARD_SC, Gdk.CURRENT_TIME);
        } 
        catch(Error e) {
            print("Unable to display xnoise keyboard shortcuts: %s\n", e.message);
        }
    }

    private void on_help_faq() {
        try {
            Gtk.show_uri(get_window().get_screen(), WEB_FAQ, Gdk.CURRENT_TIME);
        } 
        catch(Error e) {
            print("Unable to display xnoise FAQ: %s\n", e.message);
        }
    }

    private void on_fullscreenwindowvisible(GLib.ParamSpec pspec) {
        handle_screensaver();
        if(fullscreenwindowvisible)
            global.player_state_changed.connect(handle_screensaver);
        
        main_view_sbutton.set_sensitive(VIDEOVIEW_NAME, !fullscreenwindowvisible);
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
    
    internal void restore_tracks() {
        //restore last state
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.restore_lastused_job);
        db_worker.push_job(job);
    }

    private bool cancel = false;
    private bool restore_lastused_job(Worker.Job xjob) {
        uint lastused_cnt = 0;
        var job = new Worker.Job(Worker.ExecutionType.REPEATED, this.add_lastused_titles_to_tracklist_job);
        job.set_arg("msg_id", (uint)0);
        if((lastused_cnt = db_reader.count_lastused_items()) > 1500) {
            Timeout.add(200, () => {
                var button = new Gtk.Button.from_stock(Gtk.Stock.CANCEL);
                uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                        UserInfo.ContentClass.INFO,
                                        _("Restoring %u tracks in the tracklist. This is a large number and can make startup of xnoise slower.".printf(lastused_cnt)),
                                        false,
                                        4,
                                        button);
                button.clicked.connect( () => {
                    Idle.add(() => {
                        userinfo.popdown(msg_id);
                        return false;
                    });
                    cancel = true;
                    print("cancelled initial track restore\n");
                });
                job.set_arg("msg_id", msg_id);
                return false;
            });
        }
        job.big_counter[0] = 0;
        db_worker.push_job(job);
        return false;
    }

    private int LIMIT = 300;
    private bool add_lastused_titles_to_tracklist_job(Worker.Job job) {
        tl.set_model(null);
        job.track_dat = db_reader.get_some_lastused_items(LIMIT, job.big_counter[0]);
        job.big_counter[0] += job.track_dat.length;
        TrackData[] track_dat = job.track_dat;
        Idle.add( () => {
            if(track_dat == null || track_dat[0] == null)
                return false;
            foreach(TrackData? td in track_dat) {
                if(td == null)
                    continue;
                tlm.insert_title(null, ref td, false);
            }
            return false;
        });
        if(job.track_dat.length < LIMIT || cancel) {
            print("got %d tracks for tracklist\n", job.big_counter[0]);
            Idle.add(() => {
                tl.set_model(tlm);
                if(userinfo != null)
                    userinfo.popdown((uint)job.get_arg("msg_id"));
                return false;
            });
            return false;
        }
        else {
            return true;
        }
    }
    
    private FirstStartWidget first_start_widget = null;
    
    internal void ask_for_initial_media_import() {
        Idle.add(() => {
            album_view_toggle.set_active(false);
            media_browser_visible = false;
            return false;
        });
        first_start_widget = new FirstStartWidget();
        first_start_widget.show();
        if(first_start_widget.parent == null) {
            content_notebook.append_page(first_start_widget, null);
            content_notebook.set_current_page(content_notebook.page_num(first_start_widget));
        }
        first_start_widget.finish_button.clicked.connect( () =>  {
            Idle.add(() => {
                main_view_sbutton.select(TRACKLIST_VIEW_NAME);
                show_content();
                content_notebook.remove_page(content_notebook.page_num(first_start_widget));
                first_start_widget.destroy();
                first_start_widget = null;
                if(!global.media_import_in_progress) {
                    if(actions_list == null)
                        actions_list = action_group.list_actions();
                    foreach(Gtk.Action a in actions_list) {
                        if(a.name == "AddRemoveAction" ||
                           a.name == "RescanLibraryAction"||
                           a.name == "ShowTracklistAction"||
                           a.name == "ShowLyricsAction"||
                           a.name == "ShowVideoAction") {
                            a.sensitive = true;
                        }
                    }
                }
                media_browser_visible = true;
                return false;
            });
        });
        first_start_widget.closebutton.clicked.connect( () => {
            Idle.add(() => {
                main_view_sbutton.select(TRACKLIST_VIEW_NAME);
                show_content();
                content_notebook.remove_page(content_notebook.page_num(first_start_widget));
                first_start_widget.destroy();
                first_start_widget = null;
                if(!global.media_import_in_progress) {
                    if(actions_list == null)
                        actions_list = action_group.list_actions();
                    foreach(Gtk.Action a in actions_list) {
                        if(a.name == "AddRemoveAction" ||
                           a.name == "RescanLibraryAction"||
                           a.name == "ShowTracklistAction"||
                           a.name == "ShowLyricsAction"||
                           a.name == "ShowVideoAction") {
                        print("set actions to sensitive\n");
                            a.sensitive = true;
                        }
                    }
                }
                media_browser_visible = true;
                return false;
            });
        });
        Idle.add(() => {
            content_notebook.set_current_page(content_notebook.page_num(first_start_widget));
            if(actions_list == null)
                actions_list = action_group.list_actions();
            foreach(Gtk.Action a in actions_list) {
                if(a.name == "AddRemoveAction" ||
                   a.name == "RescanLibraryAction"||
                   a.name == "ShowTracklistAction"||
                   a.name == "ShowLyricsAction"||
                   a.name == "ShowVideoAction") {
                    print("set actions to not sensitive\n");
                    a.sensitive = false;
                }
            }
            return false;
        });
    }

    public void toggle_fullscreen() {
        if(in_update_toggle_action)
            return;
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
            
            main_view_sbutton.select(TRACKLIST_VIEW_NAME);
            
            fullscreenwindowvisible = true;
            fullscreentoolbar.show();
            Idle.add( () => {
                this.videoscreen.trigger_expose();
                return false;
            });
            if(aimage_timeout != 0) {
                Source.remove(aimage_timeout);
                aimage_timeout = 0;
            }
            mainview_page_buffer = TRACKLIST_VIEW_NAME;
            mainview_box.select_main_view(mainview_page_buffer);
        }
        else {
            this.videoscreen.get_window().unfullscreen();
            this.videoscreen.reparent(videovbox);
            fullscreenwindow.hide();
            videoscreen.set_vexpand(true);
            videoscreen.set_hexpand(true);
            
            main_view_sbutton.select(VIDEOVIEW_NAME);
            
            fullscreenwindowvisible = false;
            this.videovbox.show_all();
            fullscreentoolbar.hide();
            Idle.add( () => {
                this.videoscreen.trigger_expose();
                return false;
            });
        }
        update_toggle_action_state("VideoFullscreenAction", _fullscreenwindowvisible);
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
                repeatimage.destroy();
                repeatimage = IconRepo.get_themed_image_icon("xn-no-repeat-symbolic", IconSize.LARGE_TOOLBAR);
                repeatimage.show();
                repeatButton.add(repeatimage);
                repeatButton.set_tooltip_text(_("Playback mode: ") + _("No repeat, one after another"));
                break;
            }
            case PlayerRepeatMode.SINGLE : {
                repeatimage.destroy();
                repeatimage = IconRepo.get_themed_image_icon("xn-repeat-single-symbolic", IconSize.LARGE_TOOLBAR);
                repeatimage.show();
                repeatButton.add(repeatimage);
                repeatButton.has_tooltip = true;
                repeatButton.set_tooltip_text(_("Playback mode: ") + _("Repeat single track"));
                break;
            }
            case PlayerRepeatMode.ALL : {
                repeatimage.destroy();
                repeatimage = IconRepo.get_themed_image_icon("xn-repeat-all-symbolic", IconSize.LARGE_TOOLBAR);
                repeatimage.show();
                repeatButton.add(repeatimage);
                repeatButton.has_tooltip = true;
                repeatButton.set_tooltip_text(_("Playback mode: ") + _("Repeat all"));
                break;
            }
            case PlayerRepeatMode.RANDOM : {
                repeatimage.destroy();
                repeatimage = IconRepo.get_themed_image_icon("xn-shuffle-symbolic", IconSize.LARGE_TOOLBAR);
                repeatimage.show();
                repeatButton.add(repeatimage);
                repeatButton.has_tooltip = true;
                repeatButton.set_tooltip_text(_("Playback mode: ") + _("Random playlist track playing"));
                break;
            }
        }
    } 

    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
        //print("%d : %d\n",(int)e.keyval, (int)e.state);
        switch(e.keyval) {
            case Gdk.Key.F11:
                return true;
            default:
                break;
        }
        return false;
    }
    
    private void colorize_search_background(bool colored = false) {
        if(colored) {
            search_entry.get_style_context().add_class(Gtk.STYLE_CLASS_INFO);
            album_search_entry.get_style_context().add_class(Gtk.STYLE_CLASS_INFO);
        }
        else {
            search_entry.get_style_context().remove_class(Gtk.STYLE_CLASS_INFO);
            album_search_entry.get_style_context().remove_class(Gtk.STYLE_CLASS_INFO);
        }
    }
    
    private void menutoggle_playpause() {
        playPauseButton.on_clicked(playPauseButton);
    }

    private void menu_next() {
        if(global.player_state == PlayerState.STOPPED)
            return;
        this.change_track(ControlButton.Function.NEXT);
    }
    
    private void menu_prev() {
        if(global.player_state == PlayerState.STOPPED)
            return;
        this.change_track(ControlButton.Function.PREVIOUS);
    }
    
    private void increase_volume() {
        change_volume(0.1);
    }
    
    private void decrease_volume() {
        change_volume(-0.1);
    }
    
    internal void change_volume(double delta_fraction) {
        volume_slider.button.value += delta_fraction;
    }
    
    private bool on_key_pressed(Gtk.Widget sender, Gdk.EventKey e) {
        //print("%u : %u  . space: %u\n", e.keyval, e.state, (uint)Gdk.Key.space);
        switch(e.keyval) {
            case Gdk.Key.b: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK)
                    return false;
                toggle_bottom_view();
                return true;
            }
            case Gdk.Key.c: {
                if((e.state & ModifierType.MOD1_MASK) != ModifierType.MOD1_MASK)
                    return false;
                on_remove_all_button_clicked();
                return true;
            }
            case Gdk.Key.p: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK)
                    return false;
                menu_prev();
                return true;
            }
            case Gdk.Key.n: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK)
                    return false;
                menu_next();
                return true;
            }
            case Gdk.Key.space: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                playPauseButton.on_clicked(playPauseButton);
                return true;
            }
            case Gdk.Key.plus: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK)
                    return false;
                change_volume(0.04);
                return true;
            }
            case Gdk.Key.minus: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                change_volume(-0.04);
                return true;
            }
            case Gdk.Key.f: {
                if((e.state & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK) {
                    if(album_view_toggle.get_active()) {
                        album_search_entry.grab_focus();
                        return true;
                    }
                    search_entry.grab_focus();
                    return true;
                }
                if((e.state & ModifierType.MOD1_MASK) == ModifierType.MOD1_MASK) {
                    main_window.toggle_fullscreen();
                    return true;
                }
                return false;
            }
            case Gdk.Key.d: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                search_entry.text = EMPTYSTRING;
                global.searchtext = EMPTYSTRING;
                colorize_search_background(false);
                return true;
            }
            case Gdk.Key.@1: {
                if((e.state & ModifierType.MOD1_MASK) != ModifierType.MOD1_MASK) // ALT Modifier
                    return false;
                on_show_tracklist_menu_clicked();
                return true;
            }
            case Gdk.Key.@2: {
                if((e.state & ModifierType.MOD1_MASK) != ModifierType.MOD1_MASK) // ALT Modifier
                    return false;
                if(!fullscreenwindowvisible)
                    on_show_video_menu_clicked();
                return true;
            }
            case Gdk.Key.@3: {
                if((e.state & ModifierType.MOD1_MASK) != ModifierType.MOD1_MASK) // ALT Modifier
                    return false;
                if(active_lyrics == false)
                    return false;
                on_show_lyrics_menu_clicked();
                return true;
            }
            case Gdk.Key.m: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                toggle_media_browser_visibility();
                return true;
            }
            case Gdk.Key.o: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                on_file_add();
                return true;
            }
            case Gdk.Key.q: {
                if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK) // Ctrl Modifier
                    return false;
                quit_now();
                return true;
            }
            case Gdk.Key.F11: {
                this.toggle_mainwindow_fullscreen();
                return true;
            }
            default:
                break;
        }
        return false;
    }
    
    private void quit_now() {
        this.get_position(out _posX, out _posY);
        this.hide();
        window_in_foreground = false;
        xn.quit();
    }

    private void on_show_video_menu_clicked() {
        Idle.add( () => {
            album_view_toggle.set_active(false);
            mainview_page_buffer = VIDEOVIEW_NAME;
            if(aimage_timeout != 0) {
                Source.remove(aimage_timeout);
                aimage_timeout = 0;
            }
            return false;
        });
        main_view_sbutton.select(VIDEOVIEW_NAME, true);
    }

    private void on_show_tracklist_menu_clicked() {
        Idle.add( () => {
            album_view_toggle.set_active(false);
            mainview_page_buffer = TRACKLIST_VIEW_NAME;
            if(aimage_timeout != 0) {
                Source.remove(aimage_timeout);
                aimage_timeout = 0;
            }
            return false;
        });
        main_view_sbutton.select(TRACKLIST_VIEW_NAME, true);
    }

    private void on_show_lyrics_menu_clicked() {
        Idle.add( () => {
            album_view_toggle.set_active(false);
            mainview_page_buffer = LYRICS_VIEW_NAME;
            if(aimage_timeout != 0) {
                Source.remove(aimage_timeout);
                aimage_timeout = 0;
            }
            return false;
        });
        main_view_sbutton.select(LYRICS_VIEW_NAME, true);
    }

    // This is used for the main window
    private void toggle_mainwindow_fullscreen() {
        //print("toggle_mainwindow_fullscreen\n");
        if(is_fullscreen) {
            //print("was fullscreen before\n");
            this.unfullscreen();
        }
        else {
            this.fullscreen();
        }
    }

    public void toggle_window_visbility() {
        if(this.has_toplevel_focus && this.visible) {
            this.get_position(out _posX, out _posY);
            this.hide();
            window_in_foreground = false;
        }
        if(window_in_foreground) {
            window_in_foreground = false;
            //print("window_in_foreground is now false\n");
        }
        if(active_notifier != 0) {
            this.disconnect(active_notifier);
            active_notifier = 0;
        }
        else if(this.get_window().is_visible() == true) {
            this.move(_posX, _posY);
            this.show_all();
            this.present();
            active_notifier = this.notify["is-active"].connect(buffer_position);
        }
        else {
            this.move(_posX, _posY);
            this.show_all();
            this.present();
            active_notifier = this.notify["is-active"].connect(buffer_position);
        }
    }

    public void show_window() {
        if(this.get_window().is_visible() == true) {
            this.present();
        }
        else {
            this.set_no_show_all(false);
            this.show_all();
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
        
        if(Params.get_bool_value("window_maximized")) {
            this.maximize();
        }
        else {
            this.unmaximize();
        }
        
        this.repeatState = (PlayerRepeatMode)Params.get_int_value("repeatstate");
        int hp_position = Params.get_int_value("hp_position");
        if (hp_position > 0)
            this.hpaned.set_position(hp_position);
        
        Idle.add( () => {
            string x = Params.get_string_value("MainViewName"); //TODO
            switch(x) {
                case TRACKLIST_VIEW_NAME: {
                    main_view_sbutton.select(TRACKLIST_VIEW_NAME, false);
                    this.mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
                    break;
                }
                case VIDEOVIEW_NAME: {
                    main_view_sbutton.select(VIDEOVIEW_NAME, false);
                    this.mainview_box.select_main_view(VIDEOVIEW_NAME);
                    break;
                }
                default: {
                    main_view_sbutton.select(TRACKLIST_VIEW_NAME, false);
                    this.mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
                    break;
                }
            }
            return false;
        });
        
        Timeout.add_seconds(1, () => {
            if(tray_icon == null)
                tray_icon = new TrayIcon();
            if(Params.get_bool_value("not_use_systray")) {
                tray_icon.visible = false;
            }
            else {
                tray_icon.visible = !Application.hidden_window;
            }
//            else if(!Params.get_string_value("activated_plugins").contains("soundmenu") &&
//               !Params.get_bool_value("not_use_systray")) { // not using soundmenu, close quits
//                tray_icon.visible = false;
//            }
//            else if(Params.get_string_value("activated_plugins").contains("soundmenu") &&
//               Params.get_bool_value("quit_if_closed")) { // using soundmenu, close quits
//                tray_icon.visible = false;
//            }
            return false;
        });
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
        
        Params.set_bool_value("window_maximized", window_maximized);
        
        Params.set_int_value("hp_position", this.hpaned.get_position());
        
        Params.set_int_value("repeatstate", repeatState);
        Params.set_bool_value("usestop", this.usestop);
        Params.set_bool_value("compact_layout", this.compact_layout);
        Params.set_int_value("not_show_art_on_hover_image", (not_show_art_on_hover_image == true ? 1 : 0));
    }

    //END REGION IParameter


    internal void stop() {
        global.player_state = PlayerState.STOPPED;
        global.current_uri = null;
    }

    // This function changes the current song to the next or previous in the
    // tracklist. handle_repeat_state should be true if the calling is not
    // coming from a button, but, e.g. from a EOS signal handler
    internal void change_track(ControlButton.Function direction, bool handle_repeat_state = false) {
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
        if(repeatState == PlayerRepeatMode.RANDOM) {
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
                        // print(" ! path_is_last_row\n");
                        if(direction == ControlButton.Function.NEXT) {
                            path.next();
                        }
                        else if(direction == ControlButton.Function.PREVIOUS) {
                            if(path.to_string() != "0") // only do something if are not in the first row
                                path.prev();
                            else
                                return;
                        }
                    }
                    else {
                        // print("path_is_last_row\n");
                        if(direction == ControlButton.Function.NEXT) {
                            if(repeatState == PlayerRepeatMode.ALL) {
                                // only jump to first is repeat all is set
                                trackList.tracklistmodel.get_first_row(ref path);
                            }
                            else {
                                stop();
                                return;
                            }
                        }
                        else if(direction == ControlButton.Function.PREVIOUS) {
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
        if(global.player_state == PlayerState.PLAYING) {
            trackList.scroll_to_iter(ref iter);
        }
        if(path.to_string() == tmp_path.to_string()) {
            if((repeatState == PlayerRepeatMode.SINGLE)||((repeatState == PlayerRepeatMode.ALL && rowcount == 1))) {
                // Explicit restart
                global.do_restart_of_current_track();
            }
        }
    }

    private void on_reload_collection_button_clicked() {
        album_view_toggle.set_active(false);
        media_importer.reimport_media_groups();
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

    //hide or show button
    private int hpaned_position_buffer = 0;
    private bool in_update_toggle_action = false;
    internal void toggle_media_browser_visibility() {
        if(in_update_toggle_action)
            return;
        if(media_browser_visible)
            media_browser_visible = false;
        else
            media_browser_visible = true;
        
        update_toggle_action_state("ShowMediaBrowserAction", _media_browser_visible);
    }

    private bool on_close() {
        if(eqdialog != null) {
            eqdialog.destroy();
            eqdialog = null;
        }
        if(active_notifier != 0) {
            this.disconnect(active_notifier);
            active_notifier = 0;
        }
        
        if(!quit_if_closed) {
            this.get_position(out _posX, out _posY);
            this.hide();
            Timeout.add(500, () => {
                window_in_foreground = false;
                return false;
            });
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

    private void on_menu_add() {
        album_view_toggle.set_active(false);
        content_notebook.set_current_page(content_notebook.page_num(settings_widget));
        settings_widget.select_media_tab();
    }
    
    internal void show_content() {
        content_notebook.set_current_page(content_notebook.page_num(contentvbox));
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
                    action.action(item, null, null);
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
        fcdialog.set_local_only(true);
        fcdialog.set_modal(true);
        fcdialog.set_transient_for(main_window);
        fcdialog.set_current_folder(Environment.get_home_dir());
        if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
            GLib.SList<string> res = fcdialog.get_uris();
            if(!(res == null || res.data == EMPTYSTRING)) {
                Item[] its = {};
                foreach(string s in res) {
                    Item? item = ItemHandlerManager.create_item(s);
                    if(item.type == ItemType.UNKNOWN) {
                        print("itemtype unknown\n");
                        continue;
                    }
                    its += item;
                }
                ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
                if(tmp == null)
                    return;
                unowned Action? action = tmp.get_action(ItemType.LOCAL_AUDIO_TRACK, ActionContext.REQUESTED, ItemSelectionType.MULTIPLE);
                
                Worker.Job tj = new Worker.Job(); // transporter for items in Value
                tj.items = its;
                if(action != null) {
                    action.action(Item(ItemType.LOCAL_AUDIO_TRACK), null, tj);
                }
                else {
                    print("action was null\n");
                }
            }
        }
        fcdialog.destroy();
        fcdialog = null;
    }
    
    private void on_settings_edit() {
        album_view_toggle.set_active(false);
        settings_widget.select_general_tab();
        content_notebook.set_current_page(content_notebook.page_num(settings_widget));
//        mainview_box.select_main_view(settings_widget.get_view_name());
    }

    internal void set_displayed_title(string? newuri, string? tagname, string? tagvalue) {
        string text, album, artist, title, organization, location, genre;
        string basename = null;
        if((newuri == EMPTYSTRING)|(newuri == null)) {
            text = "<b>XNOISE</b> - ready to rock! ;-)";
            track_infobar.title_text = text;
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
                   title==UNKNOWN_TITLE) {
                    if((basename == null)||(basename == EMPTYSTRING)) {
                        text = Markup.printf_escaped("<b>...</b>");
                    }
                    else {
                        text = Markup.printf_escaped("<b>%s</b>", prepare_name_from_filename(basename));
                    }
                }
                else if(album==UNKNOWN_ALBUM &&
                        artist==UNKNOWN_ARTIST) {
                    text = Markup.printf_escaped("<b>%s</b>", title.replace("\\", " "));
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
                        text = "<b>XNOISE</b> - ready to rock! ;-)";
                }
                else if(album==UNKNOWN_ALBUM &&
                        artist==UNKNOWN_ARTIST) {
                    text = Markup.printf_escaped("<b>%s</b>", title.replace("\\", " "));
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
        track_infobar.title_text = text; //song_title_label.set_text(text);
    }


    internal void handle_control_button_click(ControlButton sender, ControlButton.Function dir) {
        if(dir == ControlButton.Function.NEXT || dir == ControlButton.Function.PREVIOUS) {
            if(global.in_preview)
                return;
            
            if(global.player_state == PlayerState.STOPPED)
                return;
            
            this.change_track(dir);
        }
        else if(dir == ControlButton.Function.STOP) {
            gst_player.stop();
            this.stop();
        }
    }
    
    /* disables (or enables) the AddRemoveAction and the RescanLibraryAction in the menus if
       music is (not anymore) being imported */ 
    private void on_media_import_notify(GLib.Object sender, ParamSpec spec) {
        if(first_start_widget != null)
            return;
        if(actions_list == null)
            actions_list = action_group.list_actions();
        foreach(Gtk.Action a in actions_list) {
            if(a.name == "AddRemoveAction" || a.name == "RescanLibraryAction") {
                a.sensitive = !global.media_import_in_progress;
            }
        }
    }
    
    private void on_serial_button_clicked(SerialButton sender, string name) {
        this.mainview_box.select_main_view(name);
        if(name == TRACKLIST_VIEW_NAME)
            tl.grab_focus();
    }
    
    private void setup_widgets() {
        try {
            Builder gb = new Gtk.Builder();
            gb.add_from_file(MAIN_UI_FILE);
            
            unowned IconTheme theme = IconTheme.get_default();

            bottom_notebook  = gb.get_object("bottom_notebook") as Gtk.Notebook;
            
            
//content_notebook = gb.get_object("content_nb") as Gtk.Notebook;
            content_notebook = new Notebook();
            content_notebook.show_border = false;
            content_notebook.show_tabs = false;
            var contentvbox = new Box(Orientation.VERTICAL, 0);
            var infobox = new Box(Orientation.VERTICAL, 0);
            contentvbox.pack_start(infobox, false, false, 0);
            hpaned = new CustomPaned();
            media_browser_box = new Box(Orientation.VERTICAL, 0);
            media_browser_box.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
            hpaned.pack1(media_browser_box, false, false);
            hpaned.pack2(contentvbox, true, false);
            content_notebook.append_page(hpaned, null);
            bottom_notebook.append_page(content_notebook, null);
            
            ///BOX FOR MAIN MENU
            menuvbox = gb.get_object("menuvbox") as Gtk.Box;
            //UIMANAGER FOR MENUS, THIS ALLOWS INJECTION OF ENTRIES BY PLUGINS
            action_group = new Gtk.ActionGroup("XnoiseActions");
            action_group.set_translation_domain(Config.GETTEXT_PACKAGE);
            action_group.add_actions(action_entries, this);
            action_group.add_toggle_actions(toggle_action_entries, this);
            
            _ui_manager.insert_action_group(action_group, 0);
            try {
                _ui_manager.add_ui_from_file(MENU_UI_FILE);
            }
            catch(GLib.Error e) {
                print("%s\n", e.message);
            }
        
            menubar = (MenuBar)_ui_manager.get_widget("/MainMenu");
            menuvbox.pack_start(menubar, false, false, 0);
        
            config_button_menu_root = (ImageMenuItem)_ui_manager.get_widget("/ConfigButtonMenu/ConfigMenu");
            config_button_menu = (Gtk.Menu)config_button_menu_root.get_submenu();
            
            this.mainvbox = gb.get_object("mainvbox") as Gtk.Box;
            this.title = "xnoise media player";
            set_default_icon_name("xnoise");
            
//            this.infobox = gb.get_object("infobox") as Gtk.Box;
            
//            contentvbox = gb.get_object("contentvbox") as Gtk.Box;
            mainview_box = new MainViewNotebook();
            contentvbox.pack_start(mainview_box, true, true, 0);
            
            
            var hide_button = new Gtk.Button();
            
            // use standard icon theme or local fallback
            Gtk.Image hide_button_image;
            if(theme.has_icon("go-first-symbolic"))
                hide_button_image = IconRepo.get_themed_image_icon("go-first-symbolic",
                                                                   IconSize.MENU
                );
            else
                hide_button_image = IconRepo.get_themed_image_icon("xn-go-first-symbolic",
                                                                   IconSize.MENU
                );
            
            hide_button.add(hide_button_image);
            hide_button.can_focus = false;
            hide_button.clicked.connect(this.toggle_media_browser_visibility);
            hide_button.set_relief(ReliefStyle.NONE);
            var tbx = new Box(Orientation.HORIZONTAL, 0);
            tbx.pack_start(hide_button, false, false, 0);
            var removeSelectedButton = new Gtk.Button();
            Gtk.Image remsel_button_image;
            if(theme.has_icon("list-remove-symbolic"))
                remsel_button_image = IconRepo.get_themed_image_icon("list-remove-symbolic",
                                                                     IconSize.MENU
                );
            else
                remsel_button_image = IconRepo.get_themed_image_icon("xn-list-remove-symbolic",
                                                                     IconSize.MENU
                );
            
            removeSelectedButton.add(remsel_button_image);
            removeSelectedButton.can_focus = false;
            removeSelectedButton.set_relief(ReliefStyle.NONE);
            tbx.pack_start(removeSelectedButton, false, false, 0);
            removeSelectedButton.clicked.connect( () => {
                tl.remove_selected_rows();
            });
            removeSelectedButton.set_tooltip_text(_("Remove selected titles"));
            
            //REMOVE TITLE OR ALL TITLES BUTTONS
            var removeAllButton = new Gtk.Button();
            Gtk.Image remove_button_image;
            if(theme.has_icon("user-trash-symbolic"))
                remove_button_image = IconRepo.get_themed_image_icon("user-trash-symbolic",
                                                                     IconSize.MENU
                );
            else
                remove_button_image = IconRepo.get_themed_image_icon("xn-user-trash-symbolic",
                                                                     IconSize.MENU
                );
            
            removeAllButton.add(remove_button_image);
            removeAllButton.can_focus      = false;
            removeAllButton.set_relief(ReliefStyle.NONE);
            tbx.pack_start(removeAllButton, false, false, 0);
            removeAllButton.clicked.connect( () => {
                global.position_reference = null;
                var store = (ListStore)tlm;
                store.clear();
            });
            removeAllButton.set_tooltip_text(_("Remove all"));
            var posjumper = new Gtk.Button();
            Gtk.Image posjumper_image;
            if(theme.has_icon("format-justify-fill-symbolic"))
                posjumper_image = IconRepo.get_themed_image_icon("format-justify-fill-symbolic",
                                                                     IconSize.MENU
                );
            else
                posjumper_image = IconRepo.get_themed_image_icon("xn-format-justify-fill-symbolic",
                                                                     IconSize.MENU
                );
            posjumper.add(posjumper_image);
            posjumper.can_focus      = false;
            posjumper.set_relief(ReliefStyle.NONE);
            tbx.pack_start(posjumper, false, false, 0);
            posjumper.clicked.connect( () => {
                if(global.position_reference == null || !global.position_reference.valid())
                    return;
                TreePath path = global.position_reference.get_path();
                var store = (ListStore)tlm;
                TreeIter iter;
                store.get_iter(out iter, path);
                tl.set_focus_on_iter(ref iter);
            });
            posjumper.set_tooltip_text(_("Jump to current position"));
            var bottom_box = new Box(Orientation.HORIZONTAL, 0);
            bottom_box.pack_start(tbx, false, false, 0);
            main_view_sbutton = new SerialButton();
            main_view_sbutton.insert(TRACKLIST_VIEW_NAME, SHOWTRACKLIST);
            main_view_sbutton.insert(VIDEOVIEW_NAME, SHOWVIDEO);
            main_view_sbutton.insert(LYRICS_VIEW_NAME, SHOWLYRICS);
            
            bottom_box.pack_start(new Label(""), true, true, 0);
            bottom_box.pack_start(main_view_sbutton, false, false, 0);
            contentvbox.pack_start(bottom_box, false, false, 0);
            this.notify["media-browser-visible"].connect( (s, val) => {
                if(this.media_browser_visible == true) {
                    hide_button.remove(hide_button_image);
                    if(theme.has_icon("go-first-symbolic"))
                        hide_button_image = IconRepo.get_themed_image_icon("go-first-symbolic",
                                                                           IconSize.MENU
                        );
                    else
                        hide_button_image = IconRepo.get_themed_image_icon("xn-go-first-symbolic",
                                                                           IconSize.MENU
                        );
                    hide_button_image.show();
                    hide_button.add(hide_button_image);
                    hide_button.set_tooltip_text(HIDE_LIBRARY);
                }
                else {
                    hide_button.remove(hide_button_image);
                    if(theme.has_icon("go-last-symbolic"))
                        hide_button_image = IconRepo.get_themed_image_icon("go-last-symbolic",
                                                                           IconSize.MENU
                        );
                    else
                        hide_button_image = IconRepo.get_themed_image_icon("xn-go-last-symbolic",
                                                                           IconSize.MENU
                        );
                    hide_button_image.show();
                    hide_button.add(hide_button_image);
                    hide_button.set_tooltip_text(SHOW_LIBRARY);
                }
            });
            
            
            mainview_box.notify["current-name"].connect( () => {
                if(mainview_box.current_name == TRACKLIST_VIEW_NAME) {
                    removeSelectedButton.set_no_show_all(false);
                    removeSelectedButton.show_all();
                    posjumper.set_no_show_all(false);
                    posjumper.show_all();
                    removeAllButton.set_no_show_all(false);
                    removeAllButton.show_all();
                }
                else {
                    removeSelectedButton.set_no_show_all(true);
                    removeSelectedButton.hide();
                    posjumper.set_no_show_all(true);
                    posjumper.hide();
                    removeAllButton.set_no_show_all(true);
                    removeAllButton.hide();
                }
            });
            
            
            ///Tracklist (right)
            this.trackList = tl;
            tracklistview_widget = new TrackListViewWidget(this);
            trackListScrollWin = tracklistview_widget.scrolled_window;
            mainview_box.add_main_view(tracklistview_widget);
            
            videoview_widget = new VideoViewWidget(this);
            videoscreen = gst_player.videoscreen;
            videovbox = videoview_widget.videovbox;
            mainview_box.add_main_view(videoview_widget);
            
            //lyrics
            lyricsview_widget = new LyricsViewWidget(this);
            this.lyricsView = lyricsview_widget.lyricsView;
            mainview_box.add_main_view(lyricsview_widget);
            
            settings_widget = new SettingsWidget();
            content_notebook.append_page(settings_widget, null);
//            mainview_box.add_main_view(settings_widget);
            
            mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
            
            //--------------------
            var toolbarbox = gb.get_object("toolbarbox") as Gtk.Box;
            main_toolbar = new Gtk.Toolbar();
            main_toolbar.set_style(ToolbarStyle.ICONS);
            main_toolbar.set_icon_size(IconSize.LARGE_TOOLBAR);
            main_toolbar.set_show_arrow(false);
            toolbarbox.pack_start(main_toolbar, true, true, 0);
//            main_toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
            //-----------------
            
            main_view_sbutton.sign_selected.connect(on_serial_button_clicked);
            //---------------------
            
            //REPEAT MODE SELECTOR
            var repeatButtonTI = new ToolItem();
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
            repeatButton = new Gtk.Button();
            repeatButton.can_focus = false;
            repeatButton.clicked.connect(this.on_repeat_button_clicked);
            repeatimage = IconRepo.get_themed_image_icon("xn-repeat-all-symbolic", IconSize.LARGE_TOOLBAR);
            repeatButton.add(repeatimage);
            repeatButton.set_relief(ReliefStyle.NONE);
            var eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            box.pack_start(repeatButton, false, false, 0);
            eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            repeatButtonTI.add(box);
            //--------------------
            
            //PLAYING TITLE IMAGE
            this.albumimage = new AlbumImage();
            ToolItem albumimageTI = new ToolItem();
            albumimageTI.add(albumimage);
            aimage_timeout = 0;
            albumimage.button_press_event.connect(ai_button_clicked);
            albumimage.enter_notify_event.connect(ai_ebox_enter);
            albumimage.leave_notify_event.connect( (s, e) => {
                if(not_show_art_on_hover_image)
                    return false;
                if(fullscreenwindowvisible)
                    return false;
                if(aimage_timeout != 0) {
                    Source.remove(aimage_timeout);
                    aimage_timeout = 0;
                    return false;
                }
                mainview_box.select_main_view(mainview_page_buffer);
                main_view_sbutton.select(mainview_page_buffer, true);
                return false;
            });
            //--------------------
            msw = new MediaSoureWidget(this);
            this.search_entry = msw.search_entry;
            this.search_entry.set_tooltip_text(_("Select search with <Ctrl-F>") +
                                               "\n"+
                                               _("Remove search filter with <Ctrl-D>")
            );
//            this.hpaned = gb.get_object("paned1") as Gtk.Paned;
//            this.hpaned.draw.connect( (s, cr) => {
//                Gdk.RGBA col = main_window.msw.get_style_context().get_background_color(StateFlags.NORMAL);
//                cr.set_source_rgb(col.red, col.green, col.blue);
//                cr.rectangle(0, 0, s.get_allocated_width(), s.get_allocated_height());
//                cr.fill();
//                return true;
//            });
//            media_browser_box = gb.get_object("media_browser_box") as Gtk.Box;
//            hpaned.remove(media_browser_box);
            
            
            media_browser_box.pack_start(msw, true, true, 0);
            //----------------
            
            eqButtonTI = new ToolItem();
            
            box = new Gtk.Box(Orientation.VERTICAL, 0);
            var eqButton = new Button();
            eqButton.set_tooltip_text(_("Open equalizer"));
            Image eqi = IconRepo.get_themed_image_icon("xn-equalizer-symbolic", IconSize.LARGE_TOOLBAR);
            eqi.show();
            eqButton.add(eqi);
            eqButton.can_focus = false;
            eqButton.set_relief(ReliefStyle.NONE);
            eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            box.pack_start(eqButton, false, false, 0);
            eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            //--
            eqButton.clicked.connect( () => {
                if(eqdialog != null)
                    return;
                var eq_widget = new EqualizerWidget(gst_player.equalizer);
                eqdialog = new Gtk.Window();
                eqdialog.set_resizable(false);
                eqdialog.set_has_resize_grip(false);
                eqdialog.add(eq_widget);
                eqdialog.type_hint = Gdk.WindowTypeHint.DIALOG;
                eqdialog.window_position = WindowPosition.CENTER_ON_PARENT;
                eq_widget.closebutton.clicked.connect( () => { eqdialog.destroy(); eqdialog = null; });
                eqdialog.set_title("xnoise - " + _("Equalizer"));
                eqdialog.key_press_event.connect( (s,e) => {
                    switch(e.keyval) {
                        case Gdk.Key.q: {
                            if((e.state & ModifierType.CONTROL_MASK) != ModifierType.CONTROL_MASK)
                                return false;
                            main_window.quit_now();
                            break;
                        }
                        default:
                            break;
                    }
                    return false;
                });
                eqdialog.show_all();
                eqdialog.delete_event.connect(  () => {
                    //print("remove equalizer window\n");
                    eqdialog = null;
                    return false;
                });
            });
            eqButtonTI.add(box);
            
            var albumart_toggleb = new ToolItem();
            
            box = new Gtk.Box(Orientation.VERTICAL, 0);
            album_view_toggle = new ToggleButton();
            album_view_toggle.set_tooltip_text(_("Toggle visibility of album art view") +
                                               "\n" +
                                               _("<Ctrl+B>")
            );
            var aart_im = IconRepo.get_themed_image_icon("xn-grid-symbolic", IconSize.LARGE_TOOLBAR);
            album_view_toggle.add(aart_im);
            album_view_toggle.can_focus = false;
            album_view_toggle.set_relief(ReliefStyle.NONE);
            eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            box.pack_start(album_view_toggle, false, false, 0);
            eb = new Gtk.EventBox();
            eb.visible_window = false;
            box.pack_start(eb, true, true, 0);
            albumart_toggleb.add(box);
            
            album_view_toggle.notify["active"].connect( () => {
                if(album_view_toggle.active) {
                    bottom_notebook.set_current_page(1);
                    album_art_view.grab_focus();
                    update_toggle_action_state("ShowAlbumArtViewAction", true);
                    set_sensitive_toggle_action_state("ShowMediaBrowserAction", false);
                }
                else {
                    bottom_notebook.set_current_page(0);
                    tl.grab_focus();
                    update_toggle_action_state("ShowAlbumArtViewAction", false);
                    set_sensitive_toggle_action_state("ShowMediaBrowserAction", true);
                }
            });
            //VOLUME SLIDE BUTTON
            volume_slider = new VolumeSliderButton(gst_player);

            //PLAYBACK CONTROLLS
            this.previousButton = new ControlButton(ControlButton.Function.PREVIOUS);
            this.previousButton.sign_clicked.connect(handle_control_button_click);
            this.previousButton.set_can_focus(false);
            this.playPauseButton = new PlayPauseButton();
            this.stopButton = new ControlButton(ControlButton.Function.STOP);
            this.stopButton.set_no_show_all(true);
            this.stopButton.sign_clicked.connect(handle_control_button_click);
            this.nextButton = new ControlButton(ControlButton.Function.NEXT);
            this.nextButton.sign_clicked.connect(handle_control_button_click);
            
            //PROGRESS BAR
            this.track_infobar = new TrackInfobar(gst_player);
            this.track_infobar.set_expand(true);
            
           //AppMenuButton for compact layout
            app_menu_button = new AppMenuButton(config_button_menu, _("Show application main menu"));
            app_menu_button.set_no_show_all(true);
            
            
            //---------------------
            main_toolbar.insert(albumimageTI, -1);
            main_toolbar.insert(previousButton, -1);
            main_toolbar.insert(playPauseButton, -1);
            main_toolbar.insert(stopButton, -1);
            main_toolbar.insert(nextButton, -1);
            main_toolbar.insert(this.track_infobar, -1);
            main_toolbar.insert(repeatButtonTI, -1);
            main_toolbar.insert(eqButtonTI, -1);
            main_toolbar.insert(albumart_toggleb, -1);
            main_toolbar.insert(volume_slider, -1);
            main_toolbar.insert(app_menu_button, -1);
            main_toolbar.can_focus = false;
            
            this.search_entry.icon_press.connect( (s, p0, p1) => { 
                // s:Entry, p0:Position, p1:Gdk.Event
                if(p0 == Gtk.EntryIconPosition.SECONDARY) {
                    ((Entry)s).text = EMPTYSTRING;
                    global.searchtext = EMPTYSTRING;
                    colorize_search_background(false);
                }
            });
            album_art_view = new AlbumArtView(new AlbumArtCellArea());
            var album_art_overlay = new Overlay();
            
            var spinner = new Spinner();
            spinner.start();
            spinner.set_size_request(160, 160);
            album_art_overlay.add_overlay(spinner);
            spinner.halign = Align.CENTER;
            spinner.valign = Align.CENTER;
            spinner.set_no_show_all(true);
            album_art_view.show();
            spinner.show();
            album_art_view.notify.connect( (s,p) => {
                if(p.name != "in-loading" && p.name != "in-import")
                    return;
                if(album_art_view.in_loading || album_art_view.in_import) {
                    spinner.start();
                    spinner.set_no_show_all(false);
                    spinner.show_all();
                }
                else {
                    spinner.stop();
                    spinner.hide();
                    spinner.set_no_show_all(true);
                }
            });
            var aa_contr_bx = new Box(Orientation.HORIZONTAL, 0);
            
            //Both searches shall share the same buffer
            var entry_buffer = msw.search_entry.get_buffer();
            msw.search_entry.get_style_context().remove_class(STYLE_CLASS_SIDEBAR);
            msw.search_entry.get_style_context().add_class(STYLE_CLASS_ENTRY);
            entry_buffer.notify["text"].connect( () => { 
                //print("buffer text changed\n");
                global.searchtext = entry_buffer.text;
                if(entry_buffer.text != EMPTYSTRING) {
                    colorize_search_background(true);
                }
                else {
                    colorize_search_background(false);
                }
            });
            album_search_entry = new Entry.with_buffer(entry_buffer);
            album_search_entry.width_chars = 24;
            album_search_entry.secondary_icon_stock = Gtk.Stock.CLEAR;
            album_search_entry.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, false);
            album_search_entry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
            album_search_entry.set_sensitive(true);
            album_search_entry.set_tooltip_text(_("Select search with <Ctrl-F>") +
                                                "\n"+
                                                _("Remove search filter with <Ctrl-D>")
            );
            album_search_entry.set_placeholder_text (_("Search..."));
            album_search_entry.icon_press.connect( (s, p0, p1) => { 
                // s:Entry, p0:Position, p1:Gdk.Event
                if(p0 == Gtk.EntryIconPosition.SECONDARY) {
                    ((Entry)s).text = EMPTYSTRING;
                    global.searchtext = EMPTYSTRING;
                }
            });
            aa_contr_bx.pack_start(album_search_entry, false, false, 0);
            album_view_sorting = new SerialButton();
            album_view_sorting.insert("ARTIST",    _("Artist"));
            album_view_sorting.insert("ALBUM" ,    _("Album") );
            album_view_sorting.insert("GENRE",     _("Genre") );
            album_view_sorting.insert("YEAR",      _("Year")  );
            album_view_sorting.insert("PLAYCOUNT", _("Count") );
            aa_contr_bx.pack_start(album_view_sorting, false, false, 1);
            aa_contr_bx.pack_start(new Label(""), true, true, 0);
            album_view_direction = new SerialButton(SerialButton.Presentation.IMAGE);
            album_view_direction.insert("ASC" , _("Ascending"), 
                new Image.from_icon_name("go-up-symbolic", IconSize.MENU));
            album_view_direction.insert("DESC", _("Descending"), 
                new Image.from_icon_name("go-down-symbolic", IconSize.MENU));
            aa_contr_bx.pack_start(album_view_direction, false, false, 1);
//            var sg01 = new SizeGroup(SizeGroupMode.HORIZONTAL);
//            sg01.add_widget(album_view_sorting);
//            sg01.add_widget(album_view_direction);
            var aabx = new Box(Orientation.VERTICAL, 0);
            aabx.pack_start(aa_contr_bx, false, false, 2);
            var aasw = new ScrolledWindow(null, null);
            aasw.set_shadow_type(ShadowType.IN);
            aasw.add(album_art_view);
            album_art_overlay.add(aasw);
            aabx.pack_start(album_art_overlay, true, true, 2);
            bottom_notebook.append_page(aabx);
            //Fullscreen window
            this.fullscreenwindow = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
            this.fullscreenwindow.set_title("Xnoise media player - Fullscreen");
            this.fullscreenwindow.set_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK);
            this.fullscreenwindow.realize();

            //Toolbar shown in the fullscreen window
            this.fullscreentoolbar = new FullscreenToolbar(fullscreenwindow);
            
            this.add(mainvbox);

            bool tmp_media_browser_visible = !Params.get_bool_value("media_browser_hidden");
            if(!tmp_media_browser_visible) {
//                hpaned_position_buffer = Params.get_int_value("hp_position");
//                hpaned.set_position(0);
                Idle.add( () => {
//                    media_browser_box.hide();
//                    hpaned.set_position(0);
                    media_browser_visible = false;
                    return false;
                });
            }
            else {
                media_browser_visible = true;
            }
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
        mainview_box.switch_page.connect( (s,np,p) => {
            IMainView? mv = (IMainView)np;
            string? nme = null;
            if(np == null || (nme = mv.get_view_name()) == null)
                return;
            main_view_sbutton.select(nme, false);
            global.sign_main_view_changed(nme);
            Params.set_string_value("MainViewName", nme);
        });
        
        this.delete_event.connect(this.on_close); //only send to tray
        this.key_release_event.connect(this.on_key_released);
        this.key_press_event.connect(this.on_key_pressed);
    }
    
    public void reset_mainview_to_tracklist() {
        main_view_sbutton.select(TRACKLIST_VIEW_NAME, true);
    }
    
    private void toggle_bottom_view() {
        if(in_update_toggle_action)
            return;
        album_view_toggle.set_active(!album_view_toggle.get_active());
        update_toggle_action_state("ShowAlbumArtViewAction", album_view_toggle.get_active());
    }
    
    internal void set_bottom_view(int tab) {
        album_view_toggle.set_active(tab == 0 ? false : true);
    }
    
    internal void show_status_info(Xnoise.InfoBar bar) {
        infobox.pack_start(bar, false, false, 0);
        bar.show_all();
    }
    
    private bool ai_button_clicked(Gtk.Widget sender, Gdk.EventButton e) {
        if(!((e.button==1)&&(e.type==Gdk.EventType.@2BUTTON_PRESS))) {
            return false; //exit here, if it's no double-click
        }
        else {
            toggle_fullscreen();
        }
        return true;
    }
    
    private bool ai_ebox_enter(Gtk.Widget sender, Gdk.EventCrossing e) {
        if(not_show_art_on_hover_image)
            return false;
        if(fullscreenwindowvisible)
            return false;
        aimage_timeout = Timeout.add(300, () => {
            mainview_page_buffer = this.mainview_box.get_current_main_view_name();
            main_view_sbutton.select(VIDEOVIEW_NAME, true);
            this.aimage_timeout = 0;
            return false;
        });
        return false;
    }
}


private class CustomPaned : Gtk.Paned {
    
    private bool child1_shrink = true;
    private bool child2_shrink = true;
    
    private unowned Widget child1;
    private unowned Widget child2;
    private Gdk.Window child1_window;
    private Gdk.Window child2_window;
    private Gdk.Window handle;
    private Gdk.CursorType cursor_type;
    
    
    private Gdk.Rectangle handle_pos;
    
    public CustomPaned() {
        GLib.Object(orientation:Orientation.HORIZONTAL);
        handle_pos = Gdk.Rectangle();
        this.cursor_type = Gdk.CursorType.SB_H_DOUBLE_ARROW;
    }
    
    
//    private Gdk.Window create_child_window(Widget? child) {
//        Gdk.Window window;
//        Gdk.WindowAttr attributes = Gdk.WindowAttr();
//        Gdk.WindowAttributesType attributes_mask;
//        
//        attributes.window_type = Gdk.WindowType.CHILD;
//        attributes.wclass = Gdk.WindowWindowClass.INPUT_OUTPUT;
//        attributes.event_mask = this.get_events() | Gdk.EventMask.EXPOSURE_MASK;
//        
//        if (child != null) {
//            Gtk.Allocation allocation;
//            int handle_size;
//            
//            this.style_get("handle-size", out handle_size, null);
//            
//            this.get_allocation (out allocation);
//            
//            if(this.orientation == Orientation.HORIZONTAL &&
//               child == this.child2 && this.child1 != null &&
//               child1.get_visible())
//                attributes.x = handle_pos.x;// + handle_size;
//            else
//                attributes.x = allocation.x;
//            
//            if(this.orientation == Orientation.VERTICAL &&
//               child == this.child2 && this.child1 != null &&
//               this.child1.get_visible())
//                attributes.y = this.handle_pos.y;// + handle_size;
//            else
//                attributes.y = allocation.y;
//            
//            child.get_allocation(out allocation);
//            attributes.width = allocation.width;
//            attributes.height = allocation.height;
//            attributes_mask = WindowAttributesType.X | WindowAttributesType.Y;
//        }
//        else {
//            attributes.width = 1;
//            attributes.height = 1;
//            attributes_mask = 0;
//        }
//        
//        window = new Gdk.Window(this.get_window(), attributes, attributes_mask);
////        window.set_user_data (this); //???
//        this.get_style_context().set_background(window);
//        
//        if(child != null)
//            child.set_parent_window(window);
//        return window;
//    }

//    private Gdk.Cursor xcursor;
//    public override void realize() {
//        Gdk.Window window;
//        Gdk.WindowAttr attributes = Gdk.WindowAttr();
//        Gdk.WindowAttributesType attributes_mask;
//        
//        this.set_realized(true);
//        
//        window = this.get_parent_window();
//        this.set_window(window);
//        
//        attributes.window_type = Gdk.WindowType.CHILD;
//        attributes.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
//        attributes.x = this.handle_pos.x;
//        attributes.y = this.handle_pos.y;
//        attributes.width = this.handle_pos.width;
//        attributes.height = this.handle_pos.height;
//        attributes.event_mask = this.get_events();
//        attributes.event_mask |= (Gdk.EventMask.BUTTON_PRESS_MASK |
//        Gdk.EventMask.BUTTON_RELEASE_MASK |
//        Gdk.EventMask.ENTER_NOTIFY_MASK |
//        Gdk.EventMask.LEAVE_NOTIFY_MASK |
//        Gdk.EventMask.POINTER_MOTION_MASK);
//        attributes_mask = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y;
//        if(this.is_sensitive ()) {
//            xcursor = new Gdk.Cursor.for_display(this.get_display(), this.cursor_type);
//            attributes.cursor = xcursor;
//            attributes_mask |= Gdk.WindowAttributesType.CURSOR;
//        }

//        this.handle = new Gdk.Window(window, attributes, attributes_mask);
////        this.handle.set_user_data(paned); // ???
//        if((attributes_mask & Gdk.WindowAttributesType.CURSOR) == Gdk.WindowAttributesType.CURSOR)
//            attributes.cursor = null;
////          g_object_unref (attributes.cursor);

//        this.child1_window = create_child_window (this.child1);
//        this.child2_window = create_child_window (this.child2);
//    }
    
    public new void pack1(Widget child, bool resize, bool shrink) {
        child1_shrink = shrink;
        child1 = child;
        base.pack1(child, resize, shrink);
    }
    
    public new void pack2(Widget child, bool resize, bool shrink) {
        child2_shrink = shrink;
        child2 = child;
        base.pack2(child, resize, shrink);
    }
    
    private static void get_preferred_size_for_size(Widget widget, Orientation  orientation,
                                             int size,
                                             out int minimum,
                                             out int natural) {
      if(orientation == Orientation.HORIZONTAL)
        if(size < 0)
          widget.get_preferred_width(out minimum, out natural);
        else
          widget.get_preferred_width_for_height(size, out minimum, out natural);
      else
        if(size < 0)
          widget.get_preferred_height(out minimum, out natural);
        else
          widget.get_preferred_height_for_width(size, out minimum, out natural);
    }
    
    public new void get_preferred_size(Orientation orientation,
                                       int size,
                                       out int minimum,
                                       out int natural) {
      int child_min, child_nat;
        
      minimum = natural = 0;
        
      if(get_child1() != null && get_child1().get_visible()) {
          get_preferred_size_for_size(get_child1(), orientation, size, out child_min, out child_nat);
          if (child1_shrink && this.orientation == orientation)
                minimum = 0;
          else
            minimum = child_min;
          natural = child_nat;
        }
        
      if(get_child2() != null && get_child1().get_visible()) {
          get_preferred_size_for_size(get_child2(), orientation, size, out child_min, out child_nat);
            
          if (this.orientation == orientation) {
              if (!child2_shrink)
                 minimum += child_min;
              natural += child_nat;
            }
          else {
              minimum = int.max(minimum, child_min);
              natural = int.max(natural, child_nat);
            }
        }
        
      if (get_child1() != null && get_child1().get_visible() &&
          get_child2() != null && get_child2().get_visible()) {
          int handle_size = 0;
          this.style_get ("handle-size", out handle_size, null);
            
          if(this.orientation == orientation) {
              minimum += handle_size;
              natural += handle_size;
            }
        }
    }

    public override bool draw(Cairo.Context cr) {
        if(cairo_should_draw_window(cr, get_child1().get_window())) {
            cr.save ();
            cairo_transform_to_window(cr, this, get_child1().get_window());
            render_background(this.get_style_context (),
                             cr,
                             0, 0,
                             get_child1().get_window().get_width() + 1,
                             get_child1().get_window().get_height());
            cr.restore ();
        }

        if(cairo_should_draw_window(cr, get_child2().get_window())) {
            cr.save ();
            cairo_transform_to_window (cr, this, get_child2().get_window());
            render_background (this.get_style_context (),
                             cr,
                             0, 0,
                             get_child2().get_window().get_width(),
                             get_child2().get_window().get_height());
            cr.restore ();
        }

        if(cairo_should_draw_window(cr, this.get_window()) &&
            get_child1() != null && get_child1().get_visible() &&
            get_child2() != null && get_child2().get_visible()) {
            StyleContext context;
            StateFlags state;
            Allocation allocation;
            this.get_allocation(out allocation);
            context = this.get_style_context();
            state = this.get_state_flags();
            handle_pos.x = get_child1().get_allocated_width();
            handle_pos.y = 0;
            handle_pos.width = 1;
//            this.style_get("handle-size", out handle.width, null);
            handle_pos.height = allocation.height;
    
            //        
            ////      if(this.is_focus())
            ////        state |= GTK_STATE_FLAG_SELECTED;
            ////      if (this.handle_prelit)
            ////        state |= GTK_STATE_FLAG_PRELIGHT;
            context.save ();
            context.set_state(state);
            context.add_class(STYLE_CLASS_SIDEBAR); // SIDEBAR also worked
            Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL);
            cr.set_source_rgb(col.red, col.green, col.blue);
            cr.rectangle(handle_pos.x, handle_pos.y, handle_pos.width, handle_pos.height);
            cr.fill();
//            int handle_size = 0;
//            Allocation alloc = Allocation();
//            get_child1().get_allocation(out alloc);
//            this.style_get ("handle-size", out handle_size, null);
//            render_line(context, cr,
//                        handle_pos.x + handle_size - 1, handle_pos.y,
//                        handle_pos.x + handle_size - 1, handle_pos.y + handle_pos.height);
            
            context.restore();
        }
        //Chain up to draw children
        this.forall( (w) => {
            this.propagate_draw(w, cr);
        });
        return false;
    }
}


//internal class BgBox : Gtk.Box {
//    public BgBox(Orientation orientation = Orientation.VERTICAL, int spacing = 0) {
//        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
//        this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
//    }
//    
////    public override bool draw(Cairo.Context cr) {
////                cr.save();
////                cairo_transform_to_window(cr, this, this.get_window());
////                render_background(main_window.musicBr.get_style_context(),
////                                  cr,
////                                  0, 0,
////                                  this.get_window().get_width(),
////                                  this.get_window().get_height());
////                cr.restore();
////        //Chain up to draw children
////        this.forall( (w) => {
////            this.propagate_draw(w, cr);
////        });
////        return false;
////    }
//}

