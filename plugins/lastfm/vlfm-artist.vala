/* vlfm-artist.vala
 *
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
 * 	Jörn Magens
 */

using Xnoise;
using Xnoise.SimpleMarkup;

namespace Lastfm {

	public class Artist : GLib.Object {
		public string url;                  // Artist url
		public uint32 playcount = -1;       // Playcount
		//ht of size - image uri
		public HashTable<string, string> image_uris = null;
		public string[] similar;            // similar artists
		public string[] tags;               // artist tags
		public string[] corrections;
		public string name;
		private string api_key;
		public unowned Session parent_session;
		private string? username;
		private string? session_key;
		private string? lang;
		public EventData[] event_data;
		
		public signal void received_info(string artistname);
		public signal void received_corrections();
		public signal void received_events(string artistname);
		
		public Artist(Session session, string _name, string api_key, string? username = null, string? session_key = null, string? lang = null) {
			this.name = _name;
			this.api_key = api_key;
			this.parent_session = session;
			this.username = username;
			this.session_key = session_key;
			this.lang = lang;
			this.parent_session.login_successful.connect( (sender, un) => {
				assert(sender == this.parent_session);
				this.username = un;
			});
		}
		
		private string? current_city = null;
		
		public void get_events(string? city = null) {
			string artist_escaped;
			string buffer;
			current_city = city;
			
			artist_escaped = parent_session.web.escape(this.name);
			buffer = "%s?method=artist.getevents&api_key=%s&artist=%s&autocorrect=1".printf(ROOT_URL, this.api_key, artist_escaped);
			
			int id = parent_session.web.request_data(buffer);
			var rhc = new ResponseHandlerContainer(this.get_events_cb, id);
			parent_session.handlers.insert(id, rhc);
		}
		
		private void get_events_cb(int id, string response) {
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root))
				return;
			
			SimpleMarkup.Node? evs = mr.root.get_child_by_name("lfm").get_child_by_name("events");
			if(evs == null) {
				print("could not find events\n");
				return;
			}
			SimpleMarkup.Node[]? es = evs.get_children_by_name("event");
			EventData[] eda = {};
			if(es == null) {
				print("could not find events\n");
				return;
			}
			else {
				foreach(SimpleMarkup.Node n in es) {
					EventData ed = EventData();
					var artss = n.get_child_by_name("artists");
					if(artss != null) {
						var arts = artss.get_children_by_name("artist");
						string[] sa = {};
						foreach(var ars in arts) {
							sa += ars.text;
						}
						if(sa.length > 0)
							ed.artists = sa;
						else
							ed.artists = null;
					}
					var idn = n.get_child_by_name("id");
					if(idn != null) {
						ed.id = idn.text;
					}
					var nnn = n.get_child_by_name("title");
					if(nnn != null) {
						ed.id = nnn.text;
					}
					var vn = n.get_child_by_name("venue");
					SimpleMarkup.Node? vnn = vn.get_child_by_name("name");
					ed.venue_name = vnn.text;
					ed.venue_url = vn.get_child_by_name("url").text;
					vnn = vn.get_child_by_name("location");
					ed.venue_city = vnn.get_child_by_name("city").text;
					ed.venue_country = vnn.get_child_by_name("country").text;
					ed.date = n.get_child_by_name("startDate").text;
					eda += ed;
				}
				this.event_data = eda;
			}
			//send result
			Idle.add( () => {
				received_events(this.name);
				return false;
			});
		}
		
		public void get_info() {
			string artist_escaped;
			string buffer;
			
			artist_escaped = parent_session.web.escape(this.name);
			buffer = "%s?method=artist.getinfo&api_key=%s&artist=%s&autocorrect=1".printf(ROOT_URL, this.api_key, artist_escaped);
			
			if(this.username != null)
				buffer = buffer + "&username=%s".printf(this.username);
			
			if(this.lang != null)
				buffer = buffer + "&lang=%s".printf(lang);
			
			int id = parent_session.web.request_data(buffer);
			var rhc = new ResponseHandlerContainer(this.get_info_cb, id);
			parent_session.handlers.insert(id, rhc);
		}
		
		public void get_correction() {
			string artist_escaped;
			string buffer;
			
			artist_escaped = parent_session.web.escape(this.name);
			buffer = "%s?method=artist.getcorrection&artist=%s&api_key=%s".printf(ROOT_URL, artist_escaped, this.api_key);
			
			int id = parent_session.web.request_data(buffer);
			var rhc = new ResponseHandlerContainer(this.get_correction_cb, id);
			parent_session.handlers.insert(id, rhc);
		}
		
		private void get_info_cb(int id, string response) {
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root))
				return;
			
			SimpleMarkup.Node artist = mr.root.get_child_by_name("lfm").get_child_by_name("artist");
			if(artist == null) {
				print("could not find artist node\n");
				return;
			}
			
			//artist name
			SimpleMarkup.Node artist_name_node = artist.get_child_by_name("name");
			if(artist_name_node == null) {
				print("could not find artist name node\n");
				return;
			}
			
			//images
			SimpleMarkup.Node[]? images = artist.get_children_by_name("image");
			if(images == null) {
				print("could not find artist images\n");
			}
			else {
				image_uris = new HashTable<string, string>(str_hash, str_equal);
				foreach(SimpleMarkup.Node n in images) {
					string a = n.attributes["size"];
					string s = n.text;
					image_uris.insert(a, s);
				}
			}
			
			//similar
			SimpleMarkup.Node? simil = artist.get_child_by_name("similar");
			if(simil!= null) {
				SimpleMarkup.Node[]? artist_nodes = simil.get_children_by_name("artist");
				string[] s = {};
				foreach(SimpleMarkup.Node a in artist_nodes) {
					SimpleMarkup.Node name_node = a.get_child_by_name("name");
					string name_string = name_node.text;
					s += name_string;
				}
				if(s.length == 0)
					s = null;
				this.similar = s;
			}
			//tags
			SimpleMarkup.Node? tgs = artist.get_child_by_name("tags");
			if(tags!= null) {
				SimpleMarkup.Node[]? tag_nodes = tgs.get_children_by_name("tag");
				string[] s = {};
				foreach(SimpleMarkup.Node a in tag_nodes) {
					SimpleMarkup.Node name_node = a.get_child_by_name("name");
					string name_string = name_node.text;
					s += name_string;
				}
				if(s.length == 0)
					s = null;
				this.tags = s;
			}
			//send result
			Idle.add( () => {
				received_info(artist_name_node.text);
				return false;
			});
		}
		
		private void get_correction_cb(int id, string response) {
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root))
				return;
			
			SimpleMarkup.Node? crrections = mr.root.get_child_by_name("lfm").get_child_by_name("corrections");
			if(crrections == null) {
				print("could not find corrections\n");
				return;
			}
			SimpleMarkup.Node[]? corr = crrections.get_children_by_name("correction");
			string[] sa = {};
			if(corr == null) {
				print("could not find corrections\n");
				return;
			}
			else {
				foreach(SimpleMarkup.Node n in corr) {
					SimpleMarkup.Node nme = n.get_child_by_name("artist").get_child_by_name("name");
					string s = nme.text;
					sa += s;
				}
				if(sa.length == 0)
					sa = null;
				this.corrections = sa;
			}
			//send result
			Idle.add( () => {
				received_corrections();
				return false;
			});
		}
	}
}

