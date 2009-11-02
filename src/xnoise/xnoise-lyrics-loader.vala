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
 * 	softshaker  softshaker googlemail.com
 */

/* TODO: * try different sources in order of their priority if backends fail to find lyrics
	 * ensure everything's radio-stream-proof
	 * find a suitable integration into the gui [importance++]
	 * make preferences options
	 * -> merge into default branch
	 * ensure backends can be killed while downloading 
	 	(goody, they are threaded and sooner or later will exit anyway)	 	
	 * launch synchronous backends in a thread but make it possibly for backends 
	 	to be async on their own (e.g. leoslyrics could use an async soup session) (goody) */
	 	
	 	

public interface Xnoise.Lyrics : GLib.Object {
	public abstract void* fetch();
	public abstract string get_text();
	public abstract string get_identifier();
	public abstract string get_credits();

	public signal void sign_lyrics_fetched(string text);
	public signal void sign_lyrics_done(Lyrics instance);
}




public interface Xnoise.ILyricsProvider : GLib.Object {
	public abstract Lyrics from_tags(string artist, string title);
}



	
public class Xnoise.LyricsView : Gtk.TextView {
	private LyricsLoader cur_loader = null;
	private Main xn;
	private Gtk.TextBuffer textbuffer;

	
	public LyricsView() {
		xn = Main.instance();
		LyricsLoader.init();
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

	
	private void on_lyrics_ready(string provider, string content) {
		textbuffer.set_text(content+"\n\n"+provider, -1);
		
	}
}
	
	


public class Xnoise.LyricsLoader : GLib.Object {
	public Lyrics lyrics;
	
	private static ILyricsProvider provider;
	private static Main xn;
	public string artist;
	public string title;
	
	public delegate Lyrics LyricsCreatorDelg(string artist, string title);
	public signal void sign_fetched(string provider, string content);
	private uint backend_iter;
	weak Thread fetcher_thread;



	public static void init() {
		xn = Main.instance();
		xn.plugin_loader.sign_plugin_activated += LyricsLoader.on_plugin_activated;
	}
	
	public LyricsLoader(string artist, string title) {
		
		this.artist = artist;
		this.title = title;
		backend_iter = 0;	
	}
	
	
/*	~LyricsLoader() {
		message("LyricsLoader destroyed");
		message(artist);
		message(title);
	}*/


	private static void on_plugin_activated(Plugin p) {
		ILyricsProvider provider = p.loaded_plugin as ILyricsProvider;
		if (provider == null) return;
		LyricsLoader.provider = provider;
		p.sign_deactivated.connect(LyricsLoader.on_backend_deactivated);
	}
		

	private static void on_backend_deactivated() {
		LyricsLoader.provider = null;
	}


	private static void on_done(Lyrics instance) {
		instance.unref();
	}
	
	
	private void on_fetched(string text) {
		message(text);
		sign_fetched(this.lyrics.get_credits(), text);
		this.lyrics = null;
	}

	
	public string get_text() {
		return lyrics.get_text();
	}

	
	/*private bool on_timeout() {
		//drop lrics
		this.lyrics.sign_lyrics_fetched -= this.on_fetched;
		
		//if (this.backend_iter < this.backends.length) fetch();
		
		message("dropped");
		return false;
	}*/
	
		
	public bool fetch() {
	
		if(this.provider == null) {
			sign_fetched("", "Enable a lyrics provider plugin for lyrics fetching to work");
			return false;
		}
		
		//this.lyrics = this.backend/*s[this.backend_iter]*/(artist, title);
		
		
		this.lyrics = this.provider.from_tags(artist, title);
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
	
