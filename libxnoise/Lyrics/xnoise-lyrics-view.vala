/* xnoise-lyrics-view.vala
 *
 * Copyright (C) 2009-2010  softshaker
 * Copyright (C) 2011  Jörn Magens
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
 *     softshaker  softshaker googlemail.com
 *     Jörn Magens
 */

using Gtk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Services;



public class Xnoise.LyricsViewWidget : Gtk.Box, IMainView {
    
    private const string UI_FILE = Config.UIDIR + "lyrics.ui";
    private unowned MainWindow win;
    
    internal LyricsView lyricsView;
    internal SerialButton sbutton;
    
    public LyricsViewWidget(MainWindow win) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.win = win;
        create_widgets();
    }
    
    public string get_view_name() {
        return LYRICS_VIEW_NAME;
    }
    
    private void create_widgets() {
        try {
            Builder gb = new Gtk.Builder();
            gb.add_from_file(UI_FILE);
            Gtk.Box inner_box = gb.get_object("vbox5") as Gtk.Box;
            var scrolledlyricsview = gb.get_object("scrolledlyricsview") as Gtk.ScrolledWindow;
            this.lyricsView = new LyricsView();
            scrolledlyricsview.add(lyricsView);
            scrolledlyricsview.show_all();
            
            this.pack_start(inner_box, true, true, 0);
            
            var bottombox = gb.get_object("box5") as Gtk.Box;  //LYRICS
            
            sbutton = new SerialButton();
            sbutton.insert(SHOWTRACKLIST);
            sbutton.insert(SHOWVIDEO);
            sbutton.insert(SHOWLYRICS);
            bottombox.pack_start(sbutton, false, false, 0);
            
            var hide_button_2 = gb.get_object("hide_button_2") as Gtk.Button;
            hide_button_2.can_focus = false;
            hide_button_2.clicked.connect(win.toggle_media_browser_visibility);
            var hide_button_image = gb.get_object("hide_button_image_2") as Gtk.Image;
            
            win.notify["media-browser-visible"].connect( (s, val) => {
                if(win.media_browser_visible == true) {
                    hide_button_image.set_from_stock(  Gtk.Stock.GOTO_FIRST, Gtk.IconSize.MENU);
                    hide_button_2.set_tooltip_text(  HIDE_LIBRARY);
                }
                else {
                    hide_button_image.set_from_stock(  Gtk.Stock.GOTO_LAST, Gtk.IconSize.MENU);
                    hide_button_2.set_tooltip_text(  SHOW_LIBRARY);
                }
            });

        }
        catch(GLib.Error e) {
            var msg = new Gtk.MessageDialog(null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.OK,
                                            "Failed to build tracklist widget! \n" + e.message);
            msg.run();
            return;
        }
    }
}

public class Xnoise.LyricsView : Gtk.TextView {
    private LyricsLoader loader = null;
    private Main xn;
    private Gtk.TextBuffer textbuffer;
    private uint timeout = 0;
    private string artist = EMPTYSTRING;
    private string title = EMPTYSTRING;
    private uint source = 0;
    
    public LyricsView() {
        xn = Main.instance;
        loader = new LyricsLoader();
        loader.sign_fetched.connect(on_lyrics_ready);
        loader.sign_using_provider.connect(on_using_provider);
        this.textbuffer = new Gtk.TextBuffer(null);
        this.set_buffer(textbuffer);
        this.set_editable(false);
        this.set_left_margin(8);
        this.set_wrap_mode(Gtk.WrapMode.WORD);
        global.uri_changed.connect(on_uri_changed);
        var font_description = new Pango.FontDescription();
        font_description.set_family("Sans");
        font_description.set_size((int)(12 * Pango.SCALE)); // TODO: make this configurable
        this.modify_font(font_description);
        
        global.sign_notify_tracklistnotebook_switched.connect( (s,p) => {
            if(p != TrackListNoteBookTab.LYRICS)
                return;
            if(prepare_for_comparison(artist) == prepare_for_comparison(global.current_artist) &&
               prepare_for_comparison(title)  == prepare_for_comparison(global.current_title)) {
                if((global.current_artist == null)||(artist == EMPTYSTRING)||(global.current_artist == UNKNOWN_ARTIST)||
                   (global.current_title == null) ||(title  == EMPTYSTRING) ||(global.current_title == UNKNOWN_TITLE)) {
                    set_text_via_idle(_("Insufficient track information. Not searching for lyrics."));
                    return;
                }
                return; // Do not search if we already have lyrics
            }
            set_text("LYRICS VIEWER\n\nwaiting...");
            if(timeout!=0) {
                GLib.Source.remove(timeout);
                timeout = 0;
            }
            timeout = GLib.Timeout.add_seconds(1, on_timout_elapsed);
        });
    }
    
    public void lyrics_provider_unregister(ILyricsProvider lp) {
        loader.remove_lyrics_provider(lp);
    }
    
    public unowned LyricsLoader get_loader() {
        return loader;
    }

    private void on_uri_changed(string? uri) {
        if(uri == null || uri.strip() == EMPTYSTRING) {
            if(timeout!=0) {
                GLib.Source.remove(timeout);
                timeout = 0;
            }
            set_text(_("Player stopped. Not searching for lyrics."));
            return;
        }
        set_text("LYRICS VIEWER\n\nwaiting...");
        if(timeout != 0) {
            GLib.Source.remove(timeout);
            timeout = 0;
        }
        // Lyrics View is already visible...
        if(main_window.tracklistnotebook.get_current_page() == TrackListNoteBookTab.LYRICS) {
            timeout = GLib.Timeout.add_seconds(1, on_timout_elapsed);
        }
    }

    private bool on_timout_elapsed() {
        if(global.player_state == PlayerState.STOPPED) {
            set_text_via_idle(_("Player stopped. Not searching for lyrics."));
            timeout = 0;
            return false;
        }
        
        artist = prepare_for_comparison(global.current_artist);
        title  = prepare_for_comparison(global.current_title );
        
        //print("2. %s - %s\n", artist, title);
        if((global.current_artist == null)||(artist == EMPTYSTRING)||(global.current_artist == UNKNOWN_ARTIST)||
           (global.current_title == null) ||(title  == EMPTYSTRING) ||(global.current_title == UNKNOWN_TITLE)) {
            set_text_via_idle(_("Insufficient track information. Not searching for lyrics."));
            timeout = 0;
            return false;
        }

        // Do not execute if source has been removed in the meantime
        if(MainContext.current_source().is_destroyed()) {
            timeout = 0;
            return false;
        }
        loader.fetch(remove_linebreaks(global.current_artist), remove_linebreaks(global.current_title));
        timeout = 0;
        return false;
    }

    private void on_using_provider(string _provider, string _artist, string _title) {
        Idle.add( () => {
            if(prepare_for_comparison(_artist) == prepare_for_comparison(this.artist) && 
               prepare_for_comparison(_title) == prepare_for_comparison(this.title)) {
                //    Gtk.TextIter start_iter;
                //    Gtk.TextIter end_iter;
                //    textbuffer.get_start_iter (out start_iter);
                //    textbuffer.get_start_iter (out end_iter);
                //    string txt = textbuffer.get_text(start_iter, end_iter, true);
                //TODO: Howto append text ?
                set_text((_("\nTrying to find lyrics for \"%s\" by \"%s\"\n\nUsing %s ...")).printf(global.current_title, global.current_artist, _provider));
            }
            return false;
        });
    }

    private void on_lyrics_ready(string _artist, string _title, string _credits, string _identifier, string _text) {
        //check if returned track is the one we asked for:
        //print("%s - %s\n", prepare_for_comparison(this.artist), prepare_for_comparison(_artist));
        if(!((prepare_for_comparison(this.artist) == prepare_for_comparison(_artist))&&
             (prepare_for_comparison(this.title)  == prepare_for_comparison(_title)))) {
            //set_text((_("\nLyrics provider %s cannot find lyrics for \n\"%s\" by \"%s\".\n")).printf(_identifier, _title, _artist));
            return;
        }
        set_text_via_idle((_artist + " - " + _title + "\n\n" + _text + "\n\n" + _credits));
    }

    private void set_text_via_idle(string text) {
        if(source!=0)
            GLib.Source.remove(source);
        source = Idle.add( () => {
            set_text(text);
            return false;
        });
    }
    
    private void set_text(string text) {
        textbuffer.set_text(text, -1);
    }
}
