/* xnoise-lyrics-loader.vala
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

/* TODO: * try different sources in order of their priority if backends fail to find lyrics
	 * ensure everything's radio-stream-proof
	 * make preferences options
	 * lyrics loader should use top prio provider and if it doesn't find lyrics try the next one
*/
//TODO: use priorities
public class Xnoise.LyricsLoader : GLib.Object {
	
	private unowned ILyricsProvider db_provider = null;
	private Providers providers;
	
	private unowned ILyricsProvider provider = null;
	private unowned Main xn;
	private string artist;
	private string title;

	private ulong activation_cb = 0;
	
	private class Providers : GLib.Object {
		//TODO: initial setup of priorities
		private List<unowned ILyricsProvider> list = new List<unowned ILyricsProvider>();
		
		public int length {
			get {
				return (int)list.length();
			}
		}
		
		public bool empty() {
			if(length > 0)
				return false;
			return true;
		}
		
		public Providers() {
		}
		
		public void add(ILyricsProvider provider) {
			list.prepend(provider);
		}
		
		public void remove(ILyricsProvider provider) {
			foreach(unowned ILyricsProvider x in list)
				if(x.equals(provider)) {
					list.remove(x);
					break;
				}
		}

		public unowned ILyricsProvider? highest_prio() {
			unowned ILyricsProvider res = null;
			foreach(unowned ILyricsProvider x in list) {
				if(res == null) {
					res = x;
					continue;
				}
				if(res.priority > x.priority)
					res = x;
			}
			return res;
		}
		
		public unowned ILyricsProvider? next_prio(ILyricsProvider? current) {
			unowned ILyricsProvider res = null;
			if(current == null)
				return highest_prio();
			
			foreach(unowned ILyricsProvider x in list) {
				
				if(current.priority > x.priority)
					res = x;
			}
			return res;
		}
	}
	
	public signal void sign_fetched(string _artist, string _title, string _credits, string _identifier, string _text, string _provider);

	public LyricsLoader() {
		xn = Main.instance;
		providers = new Providers();
		activation_cb = xn.plugin_loader.sign_plugin_activated.connect(this.on_plugin_activated);
	}

	private void on_plugin_activated(PluginLoader sender, Plugin p) {
		//TODO: use new lyrics plugin hash table instead !?!
		if(!p.is_lyrics_plugin)
			return;
		
		unowned ILyricsProvider prov = p.loaded_plugin as ILyricsProvider;
		
		if(prov == null) 
			return;
		
		if(p.info.name == "DatabaseLyrics") {
			db_provider = p.loaded_plugin as ILyricsProvider;
			return;
		}
		
		providers.add(prov);
		
		if(this.provider == null)
			this.provider = prov;
		
		if(prov.priority < provider.priority)
			this.provider = prov;
	}

	public void remove_lyrics_provider(ILyricsProvider lp) {
		if(this.provider.equals(lp))
			this.provider = null;
		
		if(this.db_provider.equals(lp)) {
			this.db_provider = null;
			return;
		}
		
		providers.remove(lp);
		
		if(!providers.empty()) 
			this.provider = providers.highest_prio();
	}

	public bool fetch(string _artist, string _title, bool use_db_provider = true) {
		this.artist = _artist;
		this.title  = _title;
		
		// always highest prio for databaseprovider
		if(db_provider != null && use_db_provider) {
			Idle.add( () => {
				ILyrics* dbp = null;
				dbp = this.db_provider.from_tags(this, artist, title, lyrics_fetched_cb);
				if(dbp == null)
					return false;
				dbp->find_lyrics();
				return false;
			});
			return true;
		}
		
		if(this.provider == null) {
			sign_fetched(artist, title, "", "", _("Enable a lyrics provider plugin for lyrics fetching to work"), "");
			return false;
		}
		
		Idle.add( () => {
			ILyrics* p = this.provider.from_tags(this, artist, title, lyrics_fetched_cb);
			if(p == null)
				return false;
			p->find_lyrics();
			return false;
		});
		return true;
	}
	
	//forward result
	private void lyrics_fetched_cb(string _artist, string _title, string _credits, string _identifier, string _text, string _providername) {
		// print("got lyrics reply from %s %s %s %s\n", _providername, _artist, _title, _identifier);
		if(_providername == "DatabaseLyrics") {
			if(_artist == this.artist && _title == this.title &&
			   (_text == null || _text == "")) {
				print("NEXT lyrics provider\n");
				fetch(_artist, _title, false);
				return;
			}
		}
		if((_text != null) && (_text.strip() != "")) {
			sign_fetched(_artist, _title, _credits, _identifier, _text, _providername);
		}
		else {
			sign_fetched(_artist, _title, "", _identifier, "no lyrics found...", _providername);
		}
	}
}

