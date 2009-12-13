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
	
	public LyricsView() {
		xn = Main.instance();
		LyricsLoader.init();
		this.textbuffer = new Gtk.TextBuffer(null);
		this.set_buffer(textbuffer);
		this.set_editable(false);
		this.set_left_margin(10);
		this.set_wrap_mode(Gtk.WrapMode.WORD);
		xn.gPl.sign_uri_changed.connect(on_uri_change);
	}
	
	private void on_uri_change(string uri) {
		//message("called");
		if(cur_loader != null)	cur_loader.sign_fetched -= on_lyrics_ready;
		textbuffer.set_text("LYRICS VIEWER", -1);
		if((uri==null)|(uri=="")) return;
		File file = File.new_for_uri(uri);
		if(!file.has_uri_scheme("file")) return;
		var tr = new TagReader();
		TrackData t = tr.read_tag(file.get_path());
		if(cur_loader != null) cur_loader.sign_fetched -= on_lyrics_ready;

		cur_loader = new LyricsLoader(t.Artist, t.Title);
		cur_loader.sign_fetched.connect(on_lyrics_ready);
		cur_loader.fetch();
	}
	
	private void on_lyrics_ready(string provider, string content) {
		textbuffer.set_text(content+"\n\n"+provider, -1);
	}
}
