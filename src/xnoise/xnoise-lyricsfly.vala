/* xnoise-lyricsfly.vala
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
 * 	sotshaker
 */

// Plugin for lyricsfly.com using its PHP API


using GLib;
using Soup;
using Xml;

// In order for lyricsfly to work properly, we have to sign up for an xnoise key, which is free

public class LyricsLyricsfly : GLib.Object, Xnoise.Lyrics {

	private static Session session;
	
	private string artist;
	private string title;
		
	private static const string my_identifier= "Leoslyrics";
	private static const string auth = "fa7ed8a95b2aa9f70-temporary.API.access";
	private static const string text_url = "http://lyricsfly.com/api/api.php?i=%s&a=%s&t=%s";
	private static const string xp_text = "/start/sg[1]/tx";
	
	private static bool _is_initialized = false;
	
	private string text;
	private bool? availability;
	
	public signal void sign_lyrics_fetched(string text);
	
	
	public LyricsLyricsfly(string artist, string title) {
		if (_is_initialized == false) {
			message ("initting");
			session = new SessionAsync();
			Xml.Parser.init ();
			
			_is_initialized = true;
		}

		this.artist = artist;
		this.title = title;
		availability = null;
		
		session = new SessionAsync();
	}
	
	
	public static Xnoise.Lyrics from_tags(string artist, string title) {
		return new LyricsLyricsfly(artist, title);
	}
	
	
	public bool fetch_text() {
		var gettext_str = new StringBuilder();
		gettext_str.printf (text_url, Soup.URI.encode(auth, null), Soup.URI.encode(artist, null), Soup.URI.encode(title, null));
		var text_msg = new Message ("GET", gettext_str.str);
		message(gettext_str.str);
		
		uint status;
		status = session.send_message(text_msg);
		
		message(status.to_string());
		if (status != KnownStatusCode.OK) return false;
		message("still there");
		if (text_msg.response_body.data == null) return false;

		// Web API call ok, do the xml processing
		message(text_msg.response_body.data);
		Xml.Doc* xmldoc = Xml.Parser.read_doc(text_msg.response_body.data);
		if (xmldoc == null) return false;
		
		XPathContext xp_cont = new XPathContext(xmldoc);
		
		var xp_result = xp_cont.eval_expression(xp_text);
		if (xp_result->nodesetval->is_empty()) {
			message("empty"); 
			delete xmldoc;
			availability = false;
			return false;
		}
		
		var text_result_node = xp_result->nodesetval->item(0);
		if (text_result_node == null) {
			message("no item");
			delete xmldoc;
			availability = false;
			return false;
		}
		text = text_result_node->get_content();
		message(text);
		delete xmldoc;
				
		return true;
	}
	
		
	public bool? available() {
		return availability;
	}
	
	
	public void* fetch() {
		bool retval;
		if (available() == null) retval = fetch_text();
		sign_lyrics_fetched(text);
		return null;
	}
	
	
	public string get_text() {
		return text;
	}
	
	
	public string get_identifier() {
		return my_identifier;
	}
	
	
}



