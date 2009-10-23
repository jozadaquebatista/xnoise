/* xnoise-lyrics-loader.vala
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
 * 	softshaker
 */

/* TODO: 1. melt LyricsView and LyricsLoader
	 2. try different sources in order of their priority if backends fail to find lyrics
	 3. ensure everything's radio-stream-proof
	 4. make this a plugin
	 5. find a suitable integration into the gui
	 6. make preferences options
	 7. REMOVE MY FEDORA WORKAROUNDS IN THE MAKEFILE
	 8. -> merge into default branch
	 9. ensure backends can be killed while downloading 
	 	(goody, they are threaded and sooner or later will exit anyway)
	 10. launch synchronous backends in a thread but make it possibly for backends 
	 	to be async on their own (e.g. leoslyrics could use an async soup session) (goody) */

public interface Xnoise.Lyrics : GLib.Object {
	public abstract void* fetch();
	public abstract string get_text();
	public abstract string get_identifier();

	//public abstract Lyrics from_tags(string artist, string title);
	public signal void sign_lyrics_fetched(string text);
	public signal void sign_lyrics_done(Lyrics instance);
}


public class Xnoise.LyricsView : Gtk.TextView {
	private LyricsLoader cur_loader = null;
	private Main xn;
	private Gtk.TextBuffer textbuffer;

	
	public LyricsView() {
		xn = Main.instance();
		this.textbuffer = new Gtk.TextBuffer(null);
		this.set_buffer(textbuffer);
		xn.gPl.sign_uri_changed += on_uri_change;
	}
		

	private void on_uri_change(/*TagType tag, */string uri) {
		message("called");
		if (cur_loader != null)	cur_loader.sign_fetched -= on_lyrics_ready;
		//if(tag != TagType.TITLE) return;
		TagReader tr = new TagReader();
		File file = File.new_for_uri(uri);

		//TODO: only for local files, so streams will not lead to a crash
		TrackData t = tr.read_tag_from_file(file.get_path());
		if(cur_loader != null) cur_loader.sign_fetched -= on_lyrics_ready;

		cur_loader = new LyricsLoader(t.Artist, t.Title);
		cur_loader.sign_fetched += on_lyrics_ready;
		cur_loader.fetch();
	}

	
	private void on_lyrics_ready(string content) {
		textbuffer.set_text(content, -1);
	}
}
	
	


public class Xnoise.LyricsLoader : GLib.Object {
	public Lyrics lyrics;
	
	private static LyricsCreatorDelg backend;
	public string artist;
	public string title;
	
	public delegate Lyrics LyricsCreatorDelg(string artist, string title);
	private static LyricsCreatorDelg default_backend;
	private LyricsCreatorDelg backend_choice;
	
	public static bool register_backend(string name, LyricsCreatorDelg delg) {
		backend = delg;
		return true;
	}


	public signal void sign_fetched(string content);

	
	private uint backend_iter;

	
	weak Thread fetcher_thread;

	
	private void register_backends() {
		backend = Leoslyrics.from_tags;
	}

	
	public LyricsLoader(string artist, string title) {
		register_backends();
		Xml.Parser.init();
		this.artist = artist;
		this.title = title;
		backend_iter = 0;	
	}
	
	
	~LyricsLoader() {
		message("++++++++++++++++++++++++++++LyricsLoader destroyed:");
		message(artist);
		message(title);
	}


	private static void on_done(Lyrics instance) {
		instance.unref();
	}
	
	
	private void on_fetched(string text) {
		message(text);
		sign_fetched(text);
		this.lyrics = null;
	}

	
	public string get_text() {
		return lyrics.get_text();
	}

	
	private bool on_timeout() {
		//drop lrics
		this.lyrics.sign_lyrics_fetched -= this.on_fetched;
		//if (this.backend_iter < this.backends.length) fetch();
		message("dropped");
		return false;
	}

		
	public bool fetch() {
		this.lyrics = this.backend/*s[this.backend_iter]*/(artist, title);
		this.lyrics.ref();
		this.lyrics.sign_lyrics_fetched += this.on_fetched;
		this.lyrics.sign_lyrics_done +=on_done;
		this.fetcher_thread = Thread.create (lyrics.fetch, true);
		//fetcher_thread.join();
		//lyrics.fetch();
		//backend_iter++;
		//Timeout.add(5000, on_timeout);
		return true; 
	}

}
	
