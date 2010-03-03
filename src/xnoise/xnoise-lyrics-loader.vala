/* xnoise-lyrics-loader.vala
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

/* TODO: * try different sources in order of their priority if backends fail to find lyrics
	 * ensure everything's radio-stream-proof
	 * make preferences options
	 * lyrics loader should use top prio provider and if it doesn't find lyrics try the next one
*/
//TODO: use priorities
public class Xnoise.LyricsLoader : GLib.Object {
	private static ILyricsProvider provider;
	private static Main xn;
//	private uint backend_iter;
	public string artist;
	public string title;

	public signal void sign_fetched(string artist, string title, string credits, string identifier, string text);

	public LyricsLoader() {
		this.artist = artist;
		this.title = title;
		xn = Main.instance;
		xn.plugin_loader.sign_plugin_activated.connect(LyricsLoader.on_plugin_activated);
	}

	private static void on_plugin_activated(Plugin p) {
		//TODO: use new lyrics plugin hash table instead !?!
		if(!p.is_lyrics_plugin)
			return;

		ILyricsProvider provider = p.loaded_plugin as ILyricsProvider;

		if(provider == null) 
			return;
		
		LyricsLoader.provider = provider;
		p.sign_deactivated.connect(LyricsLoader.on_backend_deactivated);
	}

	private static void on_backend_deactivated() {
		LyricsLoader.provider = null;
	}

	public bool fetch() {
		if(this.provider == null) {
			sign_fetched(artist, title, "", "", "Enable a lyrics provider plugin for lyrics fetching to work");
			return false;
		}

		Idle.add( () => {
			var p = this.provider.from_tags(artist, title);
			if(p == null)
				return false;
			p.sign_lyrics_fetched.connect(on_lyrics_fetched);
			p.ref(); //prevent destruction before ready
			p.find_lyrics();
			return false;
		});
		return true;
	}
	
	//forward result
	private void on_lyrics_fetched(string artist, string title, string credits, string identifier, string text) {
		if((text != null)&&(text != "")) {
			sign_fetched(artist, title, credits, identifier, text);
		}
		else {
			sign_fetched(artist, title, credits, identifier, "no lyrics found...");
		}
	}
}

