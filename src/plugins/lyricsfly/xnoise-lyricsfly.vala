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


public class Xnoise.LyricsLyricsflyPlugin : GLib.Object, Xnoise.IPlugin, Xnoise.ILyricsProvider {
	public Xnoise.Main xn { get; set; }
	public string name { 
		get {
			return "Lyricsfly";
		} 
	}

	public bool init() {
		//LyricsLoader.register_backend(this.name, this.from_tags);
		return true;
	}

	public Gtk.Widget? get_settings_widget() {
		return null;
	}

	public Gtk.Widget? get_singleline_settings_widget() {
		return null;
	}

	public bool has_settings_widget() {
		return false;
	}
	
	public bool has_singleline_settings_widget() {
		return false;
	}

	public Xnoise.ILyrics from_tags(string artist, string title) {
		return new LyricsLyricsfly(artist, title);
	} 
}

public class Xnoise.LyricsLyricsfly : Object, ILyrics {
	private const int SECONDS_FOR_TIMEOUT = 15;
	// Maybe add this key as a construct only property. Then it can be an individual key for each user
	
	private SessionAsync session;
	private uint timeout;
	private static const string my_identifier= "Lyricsfly";
	
	//this temporary key is only valid for one week
	private static const string auth = "0febc5f3fcf7b93b3-temporary.API.access";
	
	private static const string text_url = "http://lyricsfly.com/api/api.php?i=%s&a=%s&t=%s";
	private static const string xp_text = "/start/sg[1]/tx";
	private static const string xp_artist = "/start/sg[1]/ar";
	private static const string xp_title = "/start/sg[1]/tt";
	private static const string my_credits = "These Lyrics are provided by http://www.lyricsfly.com";
	private string artist;
	private string title;
	
	private string hid;

	private signal void sign_hid_fetched();

	public LyricsLyricsfly(string _artist, string _title) {
		this.artist = _artist;
		this.title  = _title;
		session = new SessionAsync();
		Xml.Parser.init ();
		hid = "";
		
		this.artist = artist;
		this.title = title;
		
		timeout = 0;
	}
	
	~LyricsLyricsfly() {
		if(timeout != 0)
			Source.remove(timeout);
		print("destruct LFmIP\n");
	}

	public string get_identifier() {return my_identifier;}
	public string get_credits() {return my_credits;}


	private void remove_timeout() {
		if(timeout != 0)
			Source.remove(timeout);
	}

	private void fetch_text() {
		var gettext_str = new StringBuilder();
		gettext_str.printf(text_url, 
		                   Soup.URI.encode(auth, null), 
		                   Soup.URI.encode(artist, null), 
		                   Soup.URI.encode(title, null)
		                   );

		var mesg = new Message ("GET", gettext_str.str);

		//message(gettext_str.str);

		session.queue_message(mesg, fetch_txt_cb);
	}

	private void fetch_txt_cb(Session sess, Message mesg) {
		if(this == null)
			return;

		if(mesg.response_body.data == null) {
			remove_timeout();
			this.unref();
			return;
		}

		if(((string)mesg.response_body.flatten().data == null) || ((string)mesg.response_body.data == "")) {
			remove_timeout();
			this.unref();
			return;
		}

		// Web API reply available, do xml processing
		//message("response:\n" + (string)mesg.response_body.data + "\nend response\n");
		
		Xml.Doc* doc = Xml.Parser.read_doc((string)mesg.response_body.flatten().data);
		if(doc == null) {
			remove_timeout();
			this.unref();
			return;
		}
		
		XPath.Context xp_cont = new XPath.Context(doc);
		
		var xp_result = xp_cont.eval_expression(xp_text);
		if (xp_result->nodesetval->is_empty()) {
			//message("empty"); 
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}
		
		var text_result_node = xp_result->nodesetval->item(0);
		if(text_result_node == null) {
			//message("no item");
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}
		string lyrics_text = text_result_node->get_content();
		lyrics_text = remove_single_character(lyrics_text, "[br]");
		//message(lyrics_text);

		string reply_artist = "";
		xp_result = xp_cont.eval_expression(xp_artist);
		if(!xp_result->nodesetval->is_empty()) {
			var artist_result_node = xp_result->nodesetval->item(0);
			if(artist_result_node != null) {
				reply_artist = artist_result_node->get_content();
			}
		}
		

		string reply_title = "";
		xp_result = xp_cont.eval_expression(xp_title);
		if(!xp_result->nodesetval->is_empty()) {
			var title_result_node = xp_result->nodesetval->item(0);
			if(title_result_node != null) {
				reply_title = title_result_node->get_content();
			}
		}

		//print("%s - %s \n", reply_artist, reply_title);
		sign_lyrics_fetched(reply_artist, reply_title, get_credits(), get_identifier(), lyrics_text);
		
		remove_timeout();
		delete doc;
		this.unref();
	}

	public void find_lyrics() {
		fetch_text();
	}
}



