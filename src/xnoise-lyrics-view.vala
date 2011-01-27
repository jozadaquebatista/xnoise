/* xnoise-lyrics-view.vala
 *
 * Copyright (C) 2009-2010  softshaker
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

	private void on_uri_changed(string? uri) {
		textbuffer.set_text("LYRICS VIEWER\n\nwaiting...", -1);
		if(timeout!=0)
			GLib.Source.remove(timeout);

		timeout = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT_IDLE,
		                                        3,
		                                        on_timout_elapsed);
	}

	// Use the timeout because gPl is sending the tag_changed signals
	// sometimes very often at the beginning of a track.
	private bool on_timout_elapsed() {
		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed()) return false;

		artist = remove_linebreaks(global.current_artist);
		title  = remove_linebreaks(global.current_title );
		//print("1. %s - %s\n", artist, title);

		// Look into db in case gPl does not provide the tag
		if((artist=="unknown artist")||(title =="unknown title" )) {
			DbBrowser dbb;
			try {
				dbb = new DbBrowser();
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
		if((artist=="")||(artist==null)||(artist=="unknown artist")||
		   (title =="")||(title ==null)||(title =="unknown title" )) {
			return false;
		}

		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed()) return false;

		loader.artist = artist;
		loader.title  = title;
		set_text((_("\nTrying to find lyrics for \"%s\" by \"%s\"...")).printf(title, artist));
		loader.fetch();
		return false;
	}

	private void on_lyrics_ready(string _artist, string _title, string _credits, string _identifier, string _text) {
		//check if returned track is the one we asked for:
		if(!((prepare_for_comparison(this.artist) == prepare_for_comparison(_artist))&&
		     (prepare_for_comparison(this.title)  == prepare_for_comparison(_title)))) {
			set_text((_("\nLyrics provider %s cannot find lyrics for \n\"%s\" by \"%s\".\n")).printf(_identifier,title, artist));
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
		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed()) 
			return;

		textbuffer.set_text(text, -1);
	}
}
