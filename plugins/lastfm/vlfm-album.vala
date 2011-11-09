/* vlfm-album.vala
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

	public class Album : GLib.Object {
		//ht of size - image uri
		public HashTable<string, string> image_uris = null;
		public string[] toptags;            // album toptags
		public string artist_name;
		public string album_name;
		private string api_key;
		public unowned Session parent_session;
		private string? username;
		private string? session_key;
		private string? lang;
		public string? releasedate;
		public string reply_artist;
		public string reply_album;
		
		public signal void received_info(string albumname);
		
		public Album(Session session, string _artist_name, string _album_name,
		             string api_key, string? username = null, string? session_key = null,
		             string? lang = null) {
			this.artist_name = _artist_name;
			this.album_name = _album_name;
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
		
		public void get_info() {
			string artist_escaped, album_escaped;
			string buffer;
			
			artist_escaped = parent_session.web.escape(this.artist_name);
			album_escaped  = parent_session.web.escape(this.album_name);
			buffer = "%s?method=album.getinfo&api_key=%s&album=%s&artist=%s&autocorrect=1".printf(ROOT_URL, this.api_key, album_escaped, artist_escaped);
			
			if(this.username != null)
				buffer = buffer + "&username=%s".printf(this.username);
			
			if(this.lang != null)
				buffer = buffer + "&lang=%s".printf(lang);
			
			int id = parent_session.web.request_data(buffer);
			var rhc = new ResponseHandlerContainer(this.get_info_cb, id);
			parent_session.handlers.insert(id, rhc);
		}
		
		private void get_info_cb(int id, string response) {
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root))
				return;
			
			SimpleMarkup.Node album = mr.root.get_child_by_name("lfm").get_child_by_name("album");
			if(album == null) {
				print("could not find album node\n");
				return;
			}
			
			//album name
			SimpleMarkup.Node album_name  = album.get_child_by_name("name");
			if(album_name == null) {
				print("could not find album name node\n");
				return;
			}
			reply_album = album_name.text;
			
			//artist name
			SimpleMarkup.Node artist_name  = album.get_child_by_name("artist");
			if(artist_name == null) {
				print("could not find artist name node\n");
				return;
			}
			reply_artist = artist_name.text;
			
			//album release date
			SimpleMarkup.Node releasedate_node  = album.get_child_by_name("releasedate");
			if(releasedate_node == null) {
				print("could not get album release date\n");
				return;
			}
			releasedate = releasedate_node.text;
			//images
			SimpleMarkup.Node[]? images = album.get_children_by_name("image");
			if(images == null) {
				print("could not find album images\n");
			}
			else {
				image_uris = new HashTable<string, string>(str_hash, str_equal);
				foreach(SimpleMarkup.Node n in images) {
					string a = n.attributes["size"];
					string s = n.text;
					image_uris.insert(a, s);
				}
			}
			
			//toptags
			SimpleMarkup.Node? tptgs = album.get_child_by_name("toptags");
			if(tptgs!= null) {
				SimpleMarkup.Node[]? tag_nodes = tptgs.get_children_by_name("tag");
				string[] s = {};
				foreach(SimpleMarkup.Node a in tag_nodes) {
					SimpleMarkup.Node name_node = a.get_child_by_name("name");
					string name_string = name_node.text;
					s += name_string;
				}
				if(s.length == 0)
					s = null;
				this.toptags = s;
			}
			//send result
			Idle.add( () => {
				received_info(album_name.text);
				return false;
			});
		}
	}
}

