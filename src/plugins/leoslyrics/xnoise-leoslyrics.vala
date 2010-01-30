/* xnoise-leoslyrics.vala
 *
 * Copyright (C) 2009 softshaker
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
 * 	Jörn Magens
 */

//using Xnoise;
using Gtk;
using Soup;
using Xml;

// Plugin for leoslyrics.com PHP API

public class Xnoise.LeoslyricsPlugin : GLib.Object, IPlugin, ILyricsProvider {
	public Main xn { get; set; }
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
		return new Leoslyrics(artist, title);
	}
}



public class Xnoise.Leoslyrics : GLib.Object, ILyrics {
	private const int SECONDS_FOR_TIMEOUT = 15;
	
	private SessionAsync session;
	private uint timeout;
	private static const string my_identifier = "Leoslyrics";
	private static const string my_credits = "These Lyrics are provided by http://www.leoslyrics.com";
	private static const string auth = "xnoise";
	private static const string check_url = "http://api.leoslyrics.com/api_search.php?auth=%s&artist=%s&songtitle=%s";
	private static const string text_url = "http://api.leoslyrics.com/api_lyrics.php?auth=%s&hid=%s";
	private static const string xp_hid = "/leoslyrics/searchResults/result/@hid[1]";
	private static const string xp_text = "/leoslyrics/lyric/text";
	private string artist;
	private string title;
	
	private string hid;

	private signal void sign_hid_fetched();

	public Leoslyrics(string _artist, string _title) {
		this.artist = _artist;
		this.title  = _title;
		session = new SessionAsync ();
		Xml.Parser.init();
		hid = "";
		this.artist = artist;
		this.title = title;
		
		sign_hid_fetched.connect(on_sign_hid_fetched);
		timeout = 0;
	}
	
	~Leoslyrics() {
		if(timeout != 0)
			Source.remove(timeout);
	}

	private string get_credits() {
		return my_credits;
	}
	
	private string get_identifier() {
		return my_identifier;
	}

	private void remove_timeout() {
		if(timeout != 0)
			Source.remove(timeout);
	}
	
	private void fetch_hid() {
		var gethid_str = new StringBuilder();
		gethid_str.printf(check_url, 
		                  auth, 
		                  replace_underline_with_blank_encoded(Soup.URI.encode(artist, null)),
		                  replace_underline_with_blank_encoded(Soup.URI.encode(title, null))
		                  );
		//print("gethid_str.str: %s\n\n", gethid_str.str);
		var hid_msg = new Soup.Message("GET", gethid_str.str);
		session.queue_message(hid_msg, fetch_hid_cb);
	}

	private void fetch_hid_cb(Session sess, Message mesg) {
		if(this == null) {
			remove_timeout();
			return;
		}
		
		if(mesg.response_body.data == null) {
			remove_timeout();
			this.unref();
			return;
		}

		if(((string)mesg.response_body.data == null) || ((string)mesg.response_body.data == "")) {
			remove_timeout();
			this.unref();
			return;
		}

		Xml.Doc* doc = Xml.Parser.read_doc((string)mesg.response_body.data);
		if(doc == null) {
			remove_timeout();
			this.unref();
			return;
		}

		XPathContext xp_cont = new XPathContext(doc);

		var xp_result = xp_cont.eval_expression(xp_hid);
		if(xp_result->nodesetval->is_empty()) {
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}

		var hid_result_node = xp_result->nodesetval->item (0);
		if(hid_result_node == null) {
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}

		hid = hid_result_node->get_content();
		delete doc;

		if(hid == "") {
			remove_timeout();
			this.unref();
			return;
		}

		sign_hid_fetched();
	}

	private void fetch_text() {
		if(this == null) {
			remove_timeout();
			return;
		}

		var get_text_str = new StringBuilder();
		get_text_str.printf(text_url, auth, hid);
		var text_msg = new Message("GET", get_text_str.str);

		session.queue_message(text_msg, fetch_txt_cb);
	}

	private void fetch_txt_cb(Session sess, Message mesg) {
		if(this == null) {
			remove_timeout();
			return;
		}

		if(mesg.response_body.data == null) {
			remove_timeout();
			this.unref();
			return;
		}

		if(((string)mesg.response_body.data == null) || ((string)mesg.response_body.data == "")) {
			remove_timeout();
			this.unref();
			return;
		}
		//print("(string)mesg.response_body.data fetch txt: \n%s", (string)mesg.response_body.data);
		Xml.Doc* doc = Xml.Parser.parse_memory((string)mesg.response_body.data, (int)mesg.response_body.length);
		
		if(doc == null) {
			remove_timeout();
			this.unref();
			return;
		}

		XPathContext* xpath = new XPathContext(doc);
		XPathObject* result = xpath->eval_expression(xp_text);
		
		if(result->nodesetval->is_empty()) {
			//print("empty\n");
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}
		if(result == null) {
			//message("no item");
			delete doc;
			remove_timeout();
			this.unref();
			return;
		}

		string lyrics_text = "";
		lyrics_text = result->nodesetval->item(0)->get_content();

		string reply_artist = "";
		result = xpath->eval_expression("/leoslyrics/lyric/artist/name");
		if(result->nodesetval->is_empty()) {
			reply_artist = "";
		}
		else {
			reply_artist = result->nodesetval->item(0)->get_content();
		}

		string reply_title = "";
		result = xpath->eval_expression("/leoslyrics/lyric/title");
		if(result->nodesetval->is_empty()) {
			reply_title = "";
		}
		else {
			reply_title = result->nodesetval->item(0)->get_content();
		}
		
		sign_lyrics_fetched(reply_artist.down(), reply_title.down(), get_credits(), get_identifier(), lyrics_text);

		delete doc;
		remove_timeout();
		this.unref();
	}

	public void find_lyrics() {
		fetch_hid();

		//Add timeout for response
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
	}

	private bool timeout_elapsed() {
		if(MainContext.current_source().is_destroyed())
			return false;
		this.unref();
		return false;
	}

	// this signal handler continues the downloading of lyrics
	private void on_sign_hid_fetched(Leoslyrics sender) {
		if(hid == "") {
			print("on_sign_hid_fetched empty\n");
			sign_lyrics_fetched("", "", "", "", "");
			remove_timeout();
			this.unref();
			return;
		}
		fetch_text();
	}
}

