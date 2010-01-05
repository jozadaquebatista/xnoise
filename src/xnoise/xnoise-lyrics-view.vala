/* xnoise-lyrics-view.vala
 *
 * Copyright (C) 2009  softshaker
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
 */

public class Xnoise.LyricsView : Gtk.TextView {
	private LyricsLoader cur_loader = null;
	private Main xn;
	private Gtk.TextBuffer textbuffer;
	private uint timeout = 0;
	private string artist = "";
	private string title = "";

	public LyricsView() {
		xn = Main.instance();
		LyricsLoader.init();
		this.textbuffer = new Gtk.TextBuffer(null);
		this.set_buffer(textbuffer);
		this.set_editable(false);
		this.set_left_margin(8);
		this.set_wrap_mode(Gtk.WrapMode.WORD);
		xn.gPl.sign_uri_changed.connect(on_uri_changed);
		xn.gPl.sign_tag_changed.connect(on_tag_changed);
	}

	// Use the timeout because gPl is sending the sign_tag_changed signals
	// sometimes very often at the beginning of a track.
	private bool on_timout_elapsed() {
		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed()) return false;

		if(cur_loader != null)	cur_loader.sign_fetched -= on_lyrics_ready;
		artist = remove_linebreaks(xn.gPl.currentartist);
		title  = remove_linebreaks(xn.gPl.currenttitle );
		//print("1. %s - %s\n", artist, title);

		// Look into db in case gPl does not provide the tag
		if((artist=="unknown artist")||(title =="unknown title" )) {
			var dbb = new DbBrowser();
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

		if(cur_loader != null) cur_loader.sign_fetched -= on_lyrics_ready;

		cur_loader = new LyricsLoader(artist, title);
		cur_loader.sign_fetched.connect(on_lyrics_ready);
		cur_loader.fetch();
		return false;
	}

	private void on_tag_changed(string uri) {
		if(timeout!=0)
			GLib.Source.remove(timeout);

		timeout = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT_IDLE,
		                                        3, //3 Seconds is still ok
		                                        on_timout_elapsed);
	}

	private void on_uri_changed(string uri) {
		textbuffer.set_text("LYRICS VIEWER", -1);
	}
	private uint source = 0;
	private string provider = "";
	private string content = "";
	private void on_lyrics_ready(string _provider, string _content) {
		this.provider = _provider;
		this.content  = _content;
		if(source!=0)
			GLib.Source.remove(source);

		source = Idle.add(set_text);
	}

	private bool set_text() {
		// Do not execute if source has been removed in the meantime
		if(MainContext.current_source().is_destroyed()) return false;

		textbuffer.set_text(content + "\n\n" + provider, -1);
		return false;
	}
}
