/* xnoise-azlyrics.vala
 *
 * Copyright (C) 2012  Jörn Magens
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
 * 	Jörn Magens <shuerhaaken@googlemail.com>
 */

using Soup;

using Xnoise;
using Xnoise.Services;
using Xnoise.PluginModule;

public class Xnoise.AzlyricsPlugin : GLib.Object, IPlugin, ILyricsProvider {
	private unowned PluginModule.Container p;
	private unowned Container _owner;
	
	public unowned Main xn { get; set; }

	public Container owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public string name {
		get {
			return AZLYRICS;
		}
	}
	
	public string provider_name {
		get {
			return AZLYRICS;
		}
	}
	
	public int priority { get; set; default = 1; }
	
	public bool init() {
		priority = 1;
		p = plugin_loader.plugin_htable.lookup("DatabaseLyrics");
		if(p == null) {
			if(this.owner != null)
				Idle.add( () => {
					owner.deactivate();
					return false;
				}); 
			return false;
		}
		if(!p.activated)
			plugin_loader.activate_single_plugin(p.info.name);
		
		if(!p.activated) {
			print("cannot start DatabaseLyrics plugin\n");
			if(this.owner != null)
				Idle.add( () => {
					owner.deactivate();
					return false;
				}); 
			return false;
		}
		p.sign_deactivated.connect(dblyrics_deactivated);
		return true;
	}

	public void uninit() {
		main_window.lyricsView.lyrics_provider_unregister(this); // for lyricsloader
	}
	
	~AzlyricsPlugin() {
		//print("dtor AzlyricsPlugin\n");
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public Xnoise.ILyrics* from_tags(LyricsLoader loader, string artist, string title, LyricsFetchedCallback cb) {
		return (ILyrics*)new Azlyrics(loader, _owner, artist, title, cb);
	}

	private uint deactivation_source = 0;
	private void dblyrics_deactivated() {
		if(deactivation_source != 0)
			Source.remove(deactivation_source);
		deactivation_source = Idle.add( () => {
			
			if(this.owner != null) {
				Idle.add( () => {
					owner.deactivate();
					return false;
				}); 
			}
			return false;
		});
	}
}


private static const string AZLYRICS = "Azlyrics";


public class Xnoise.Azlyrics : GLib.Object, ILyrics {
	private string artist;
	private string title;
	private const int SECONDS_FOR_TIMEOUT = 12;
	private uint timeout;
	private static const string search_url = "http://www.azlyrics.com/lyrics/%s/%s.html";
	private static const string my_credits = "Lyrics provided by azlyrics.com";
	private static const string additional_escape_chars = "&/%\"&=´`'~#§()?!";
	private string search_str = null;
	private Soup.Session session;
	private unowned PluginModule.Container owner;
	private unowned LyricsLoader loader;
	private unowned LyricsFetchedCallback cb = null;
	
	public Azlyrics(LyricsLoader _loader, PluginModule.Container _owner, string artist, string title, LyricsFetchedCallback _cb) {
		this.artist = artist;
		this.title = title;
		this.owner = _owner;
		this.loader = _loader;
		this.cb = _cb;
		
		this.owner.sign_deactivated.connect( () => {
			destruct();
		});
		
		session = new Soup.SessionAsync();
		Xml.Parser.init();
		
		timeout = 0;
	}
	
	~Azlyrics() {
		print("remove Azlyrics IL\n");
	}

	public uint get_timeout() {
		return timeout;
	}
	
	public string get_credits() {
		return my_credits;
	}
	
	public string get_identifier() {
		return AZLYRICS;
	}
	
	protected bool timeout_elapsed() {
		if(MainContext.current_source().is_destroyed())
			return false;
		
		Idle.add( () => {
			if(this.cb != null)
				this.cb(artist, title, get_credits(), get_identifier(), EMPTYSTRING, AZLYRICS);
			return false;
		});
		
		timeout = 0;
		Timeout.add_seconds(1, () => {
			destruct();
			return false;
		});
		return false;
	}
	
	private static string prepare_string(ref string? s) {
		if(s == null)
			return EMPTYSTRING;
		string scopy = s.down();
		unichar uc = 0;
		int i = 0;
		StringBuilder sb = new StringBuilder();
		while(scopy.get_next_char(ref i, out uc)) {
			if(uc.isalnum())
				sb.append_unichar(uc);
		}
		return (owned)sb.str;
	}
	
	private void find_lyrics() {
		search_str = search_url.printf(prepare_string(ref artist), prepare_string(ref title));
		print("Azlyrics: search_str is %s\n", search_str);
		var search_msg = new Soup.Message("GET", search_str);
		session.queue_message(search_msg, search_cb);
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
	}
	
	private static const string START_LYRICS = "<!-- start of lyrics -->";
	private static const string END_LYRICS   = "<!-- end of lyrics -->";
	
	private void search_cb(Session sess, Message mesg) {
		//print("Azlyrics: search_cb() called\n");
		if(mesg.response_body == null || mesg.response_body.data == null) {
			Idle.add( () => {
				if(this.cb != null)
					this.cb(artist, title, get_credits(), get_identifier(), EMPTYSTRING, AZLYRICS);
				return false;
			});
			return;
		}
		string text = EMPTYSTRING;
		unowned string cont = (string)mesg.response_body.data;
		
		int start_idx = cont.index_of(START_LYRICS, 0) + START_LYRICS.length;
		int end_idx   = cont.index_of(END_LYRICS, start_idx);
		
		if(start_idx != -1 && end_idx != -1 && end_idx > start_idx)
			text = cont.substring(start_idx, end_idx - start_idx).replace("<br>","").replace("<i>","").replace("</i>","");
		
		//print("Azlyrics: %s\n", text);
		Idle.add( () => {
			if(this.cb != null)
				this.cb(artist, title, get_credits(), get_identifier(), text, AZLYRICS);
			this.destruct();
			return false;
		});
	}
}
