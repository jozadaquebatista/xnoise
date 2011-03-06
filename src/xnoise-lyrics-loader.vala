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
	private List<unowned ILyricsProvider> providers = new List<unowned ILyricsProvider>();
	
	private unowned ILyricsProvider db_provider = null;
	
	private unowned ILyricsProvider provider = null;
	private unowned Main xn;
	public string artist;
	public string title;

	private ulong activation_cb = 0;
	private ulong deactivation_cb = 0;
	
	public signal void sign_fetched(string artist, string title, string credits, string identifier, string text, string provider);

	public LyricsLoader() {
		xn = Main.instance;
		activation_cb = xn.plugin_loader.sign_plugin_activated.connect(this.on_plugin_activated);
	}

	private void on_plugin_activated(PluginLoader sender, Plugin p) {
		//TODO: use new lyrics plugin hash table instead !?!
		if(!p.is_lyrics_plugin)
			return;
		
		//TODO: check for databaselyrics and handle it seperately
		
		unowned ILyricsProvider prov = p.loaded_plugin as ILyricsProvider;
		
		if(prov == null) 
			return;
		
		providers.prepend(prov);
		
		if(this.provider == null)
			this.provider = prov;
		
		if(prov.priority < provider.priority)
			this.provider = prov;
		
		if(deactivation_cb != 0) {
			p.disconnect(deactivation_cb);
			deactivation_cb = 0;
		}
	}

	public void remove_lyrics_provider(ILyricsProvider lp) {
		if(this.provider.equals(lp)) {
			this.provider = null;
		}
		
		foreach(unowned ILyricsProvider x in providers)
			if(x.equals(lp)) {
				providers.remove(x);
				break;
			}
		
		if(providers.length() > 0) {
			this.provider = providers.first().data;
		}
		//TODO: this.provider has to point to highest prio
	}

	public bool fetch() {
		if(this.provider == null) {
			sign_fetched(artist, title, "", "", "Enable a lyrics provider plugin for lyrics fetching to work", "");
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
	private void lyrics_fetched_cb(string artist, string title, string credits, string identifier, string text, string providername) {
		if((text != null) && (text != "")) {
			sign_fetched(artist, title, credits, identifier, text, providername);
		}
		else {
			sign_fetched(artist, title, credits, identifier, "no lyrics found...", providername);
		}
	}
}

