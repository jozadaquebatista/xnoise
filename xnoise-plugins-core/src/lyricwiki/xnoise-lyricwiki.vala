/* xnoise-lyricwiki.vala
 *
 * Copyright (C) 2010  softshaker
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

using GLib;
using Soup;

public class Xnoise.LyricwikiPlugin : GLib.Object, IPlugin, ILyricsProvider {
	private unowned Xnoise.Plugin _owner;
	
	public Main xn { get; set; }

	public Xnoise.Plugin owner {
		get {
			return _owner;
		}
		set {
			_owner = value;
		}
	}

	public string name {
		get {
			return "Lyricwiki";
		}
	}

	public bool init() {
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
		return new Lyricwiki(artist, title);
	}
}

//TODO: find out how to suppress xml parser error messages
public class Xnoise.Lyricwiki : GLib.Object, ILyrics {
	private string artist;
	private string title;
	private const int SECONDS_FOR_TIMEOUT = 30;
	private uint timeout;
	private static const string search_url = "http://lyricwiki.org/Special:Search?search=%s:%s";
	private static const string lyric_node_name = "lyricbox";
	private static const string my_credits = "Lyrics provided by lyricwiki.com";
	private static const string my_identifier = "Lyricwiki";
	private static const string additional_escape_chars = "&/%\"&=´`'~#§()?!";
	private StringBuilder search_str = null;
	private Session session;
	
	public Lyricwiki(string artist, string title) {
		this.artist = artist;
		this.title = title;
		
		session = new SessionAsync ();
		Xml.Parser.init();
	
		timeout = 0;
	}
	
	public string get_credits() {
		return my_credits;
	}
	
	public string get_identifier() {
		return my_identifier;
	}
	
	private bool timeout_elapsed() {
		if(MainContext.current_source().is_destroyed())
			return false;
		this.unref();
		return false;
	}

	
	private void find_lyrics() {
		search_str = new StringBuilder();
		search_str.printf(search_url, 
		                  replace_underline_with_blank_encoded(Soup.URI.encode(artist, additional_escape_chars)),
		                  replace_underline_with_blank_encoded(Soup.URI.encode(title, additional_escape_chars))
		                  );
		//print("Lyricwiki: search_str is %s\n", search_str.str);
		var search_msg = new Soup.Message("GET", search_str.str);
		session.queue_message(search_msg, search_cb);
		timeout = Timeout.add_seconds(SECONDS_FOR_TIMEOUT, timeout_elapsed);
	}
	
	private void search_cb(Session sess, Message mesg) {
		//print("Lyrikwiki: search_cb() called\n");
		if (mesg.response_body.data == null)
			return;
	    	
	    	//print("Lyricwiki: parsing file\n");
	    	var doc = Html.Doc.read_doc(((string)mesg.response_body.data), search_str.str);
	    	//print("Lyricwiki: reading nodes\n");
	    	if(doc == null)
	    		return;
	    	if(doc->last == null) {
	    		delete doc;
	    		return;
	    	}
	    			
	    	Xml.Node *lyricnode = find_lyric_div(doc->last);
	    	if(lyricnode == null) {
	    		delete doc;
	    		return;
	    	}
	    	
	    	string lyrics = get_lyric_div_text(lyricnode);
	    	//print("Lyricwiki: lyrics: \n%s\n", lyrics);
	    	sign_lyrics_fetched(artist, title, get_credits(), get_identifier(), lyrics);
	}
		
	/* returns the value of a given node attribute attr_name */
	private string get_div_attr(Xml.Node *div, string attr_name) {
		Xml.Attr* property = div->properties;
		while(property != null) {
			if(property->name == attr_name)
				if(property->children != null)
					break;
			property = property->next;
		}
		
		if(property == null)
			return "";
		else if(property->children == null)
			return "";
		else if(property->children->content == null)
			return "";
			
		return property->children->content;
	}
	
	/* finds the <div> node which class is "lyricbox" */
	private Xml.Node* find_lyric_div(Xml.Node *node) {
		while(node != null) {
			if(get_div_attr(node, "class") == lyric_node_name)
				return node;
			if(node->children != null) {
				Xml.Node *nnode = find_lyric_div(node->children);
				if(nnode != null)
					return nnode;
			}
			node = node->next;
		}
		return null;
	}
	
	/* gets the text from the lyrics node retrieved with find_lyrics_div */
	private string get_lyric_div_text(Xml.Node *lyric_div) {
		string ret = "";
		Xml.Node *child = lyric_div->children;
		while(child != null) {
			if(child->name == "text")
				if(child->content != null)
					ret += child->content;
			if(child->name == "br")
				ret += "\n";
			child = child->next;
		}
		return ret;
	}
}
