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
 * 	softshaker  softshaker googlemail.com
 * 	Jörn Magens
 */

public class Xnoise.LyricsView : Gtk.TextView {
	private LyricsLoader loader = null;
	private Main xn;
	private Gtk.TextBuffer textbuffer;
	private uint timeout = 0;
	private string artist = "";
	private string title = "";
	private uint source = 0;

	public LyricsView() {
		xn = Main.instance;
		loader = new LyricsLoader();
		loader.sign_fetched.connect(on_lyrics_ready);
		this.textbuffer = new Gtk.TextBuffer(null);
		this.set_buffer(textbuffer);
		this.set_editable(false);
		this.set_left_margin(8);
		this.set_wrap_mode(Gtk.WrapMode.WORD);
		global.uri_changed.connect(on_uri_changed);
		
	}
	
	public void lyrics_provider_unregister(ILyricsProvider lp) {
		loader.remove_lyrics_provider(lp);
	}
	
	public unowned LyricsLoader get_loader() {
		return loader;
	}

	private bool initialized = false;
	private void on_uri_changed(string? uri) {
		if(!initialized) {
			//if switching to Lyrics View ...
			global.sign_notify_tracklistnotebook_switched.connect( (s,p) => {
				if(p != TrackListNoteBookTab.LYRICS)
					return;
				if(prepare_for_comparison(artist) == prepare_for_comparison(global.current_artist) &&
				   prepare_for_comparison(title) == prepare_for_comparison(global.current_title)) {
					return; // Do not search if we already have lyrics
				}
				//TODO: check if lyrics have already been found
				textbuffer.set_text("LYRICS VIEWER\n\nwaiting...", -1);
				if(timeout!=0) {
					GLib.Source.remove(timeout);
					timeout = 0;
				}
				timeout = GLib.Timeout.add_seconds(1, on_timout_elapsed);
			});
			initialized = true;
		}
		if(uri == null || uri.strip() == "") {
			if(timeout!=0) {
				GLib.Source.remove(timeout);
				timeout = 0;
			}
			textbuffer.set_text(_("Player stopped. Not searching for lyrics."), -1);
			return;
		}
		textbuffer.set_text("LYRICS VIEWER\n\nwaiting...", -1);
		if(timeout!=0) {
			GLib.Source.remove(timeout);
			timeout = 0;
		}
		
		// Lyrics View is already visible...
		if(Main.instance.main_window.tracklistnotebook.get_current_page() == TrackListNoteBookTab.LYRICS)
			timeout = GLib.Timeout.add_seconds(1, on_timout_elapsed);
	}

	//FIXME: This must be used wtih Worker.Job, so that there are no race conditions!
	// Use the timeout because gPl is sending the tag_changed signals
	// sometimes very often at the beginning of a track.
	private bool on_timout_elapsed() {
		if(global.player_state == PlayerState.STOPPED) {
			set_text_via_idle(_("Player stopped. Not searching for lyrics."));
			return false;
		}
		
		artist = prepare_for_comparison(global.current_artist);
		title  = prepare_for_comparison(global.current_title );
		
		// Look into db in case gPl does not provide the tag
		if((global.current_artist=="unknown artist")||(global.current_title =="unknown title" )) {
			DbBrowser dbb;
			try {
				dbb = new DbBrowser(); //TODO: Evil code in this context
			}
			catch(Error e) {
				print("%s\n", e.message);
				return false;
			}		
			TrackData td;
			if(dbb.get_trackdata_for_uri(xn.gPl.Uri, out td)) {
				artist = td.Artist;
				title  = td.Title;
			}
		}

		//print("2. %s - %s\n", artist, title);
		if((artist=="")||(artist==null)||(artist=="unknownartist")||
		   (title =="")||(title ==null)||(title =="unknowntitle" )) {
			return false;
		}

		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed())
			return false;
		set_text((_("\nTrying to find lyrics for \"%s\" by \"%s\"...")).printf(global.current_title, global.current_artist));
		loader.fetch(remove_linebreaks(global.current_artist), remove_linebreaks(global.current_title), true);
		return false;
	}

	private void on_lyrics_ready(string _artist, string _title, string _credits, string _identifier, string _text) {
		//check if returned track is the one we asked for:
		if(!((prepare_for_comparison(this.artist) == prepare_for_comparison(_artist))&&
		     (prepare_for_comparison(this.title)  == prepare_for_comparison(_title)))) {
			set_text((_("\nLyrics provider %s cannot find lyrics for \n\"%s\" by \"%s\".\n")).printf(_identifier, _title, _artist));
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
