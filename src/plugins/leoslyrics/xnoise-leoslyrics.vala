/* xnoise-leoslyrics.vala
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
 
//using Xnoise;
using Gtk;
using Soup;
using Xml;

// Plugin for leoslyrics.com PHP API

public class LeoslyricsPlugin : GLib.Object, Xnoise.IPlugin, Xnoise.ILyricsProvider {
	public Xnoise.Main xn { get; set; }
	public string name { 
		get {
			return "Leoslyrics";
		} 
	}
    
	public bool init() {
		//LyricsLoader.register_backend(this.name, this.from_tags);
		return true;
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public Xnoise.ILyrics from_tags(string artist, string title) {
		return new Leoslyrics(artist, title);
	} 
}



public class Leoslyrics : GLib.Object, Xnoise.ILyrics {
	private static SessionSync session;
	private Message hid_msg;
	
	private string artist;
	private string title;
		
	private static const string my_identifier = "Leoslyrics";
	private static const string my_credits = "These Lyrics are provided by http://www.leoslyrics.com";
	private static const string auth = "xnoise";
	private static const string check_url = "http://api.leoslyrics.com/api_search.php?auth=%s&artist=%s&songtitle=%s";
	private static const string text_url = "http://api.leoslyrics.com/api_lyrics.php?auth=%s&hid=%s";
	private static const string xp_hid = "/leoslyrics/searchResults/result/@hid[1]";
	private static const string xp_text = "/leoslyrics/lyric/text";
	
	private static bool _is_initialized = false;
	
	private string hid;
	private string text;
	private bool? availability;
		
	public Leoslyrics (string artist, string title) {
		if (_is_initialized == false) {
			//message("initting");
			session = new SessionSync ();
			Xml.Parser.init();
			
			_is_initialized = true;
		}
		
		hid = "";
		this.artist = artist;
		this.title = title;
		availability = null;
		
		var gethid_str = new StringBuilder();
		gethid_str.printf(check_url, auth, Soup.URI.encode(artist, null), Soup.URI.encode(title, null));
		
		//print("%s\n\n", gethid_str.str);
		hid_msg = new Message("GET", gethid_str.str);
	}
		
	
	public string get_identifier() {return my_identifier;}
	public string get_credits() {return my_credits;}
	
	public bool fetch_hid () {
		uint status;
		availability = false;
		
		status = session.send_message(hid_msg);
		if (status != KnownStatusCode.OK) return false;
		if (hid_msg.response_body.data == null) return false;
		
		//print("-------------------HID\n%s\n\n", hid);
		//message(hid_msg.response_body.data);
		
		// Web API call ok, do the xml processing
		
		Xml.Doc* xmldoc = Xml.Parser.read_doc(hid_msg.response_body.data);
		if (xmldoc == null) return false;
		
		XPathContext xp_cont = new XPathContext(xmldoc);
		
		var xp_result = xp_cont.eval_expression(xp_hid);
		if (xp_result->nodesetval->is_empty()) { 
			delete xmldoc;
			return false;
		}
		
		var hid_result_node = xp_result->nodesetval->item (0);
		if (hid_result_node == null) {
			delete xmldoc;
			return false;
		}

		hid = hid_result_node->get_content();
		delete xmldoc;
		
		if (hid == "") return false;
		
		availability = true;
		return true;
	}
	
	
	public bool fetch_text() {
		var gettext_str = new StringBuilder();
		gettext_str.printf(text_url, auth, hid);
		var text_msg = new Message("GET", gettext_str.str);
		
		uint status;
		status = session.send_message(text_msg);
		
		if (status != KnownStatusCode.OK) return false;
		if (text_msg.response_body.data == null) return false;

		// Web API call ok, do the xml processing
		
		Xml.Doc* xmldoc = Xml.Parser.read_doc(text_msg.response_body.data);
		if (xmldoc == null) return false;
		
		XPathContext xp_cont = new XPathContext(xmldoc);
		
		var xp_result = xp_cont.eval_expression(xp_text);
		if (xp_result->nodesetval->is_empty()) {
			//message("empty"); 
			delete xmldoc;
			availability = false;
			return false;
		}
		
		var text_result_node = xp_result->nodesetval->item(0);
		if (text_result_node == null) {
			//message("no item");
			delete xmldoc;
			availability = false;
			return false;
		}
		text = text_result_node->get_content();
		//message(text);
		delete xmldoc;
				
		return true;
	}
		
	
	public bool? available() {
		return availability;
	}
	
	public void* fetch () {
		if (available() == null) fetch_hid();
		if (!available() || hid == ""){
			sign_lyrics_done(this);
			return null;
		}
		fetch_text();
		sign_lyrics_fetched(text);
		//sign_lyrics_done(this);
		return null;
	}
	
	
	public string get_text() {
		return text;
	}
}

