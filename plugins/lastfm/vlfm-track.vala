/* vlfm-track.vala
 *
 * Copyright (C) 2011-2012  Jörn Magens
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

	public class Track : GLib.Object {
		public string artist_name;
		public string album_name;
		public string title_name;
		private string api_key;
		public unowned Session parent_session;
		private string? username;
		private string? session_key;
		private string? lang;
		public string? releasedate;
		private string secret;
		
		public signal void scrobbled(string artist, string? album = null, string title, bool success = false);
		
		public Track(Session session, string? _artist_name, string? _album_name,
		             string? _title_name,
		             string api_key, string? username = null,
		             string? session_key = null, string? lang = null, string _secret) {
			this.artist_name = (_artist_name != null ? _artist_name : "unknown artist");
			this.album_name  = (_album_name != null ? _album_name : "unknown album");
			this.title_name  = (_title_name != null ? _title_name : "unknown title");
			this.api_key = api_key;
			this.parent_session = session;
			this.username = username;
			this.session_key = session_key;
			this.lang = lang;
			this.secret = _secret;
			this.parent_session.login_successful.connect( (sender, un) => {
				assert(sender == this.parent_session);
				this.username = un;
			});
			//print("constr track\n");
		}
		
		//~Track() {
		//	print("track dtor\n");
		//}
		
		public bool love() {
			if(!parent_session.logged_in) {
				print("not logged in!\n");
				return false;
			}
			var ub = new Lastfm.UrlBuilder();
			ub.add_param(UrlParamType.API_KEY, this.api_key);
			ub.add_param(UrlParamType.ARTIST, this.artist_name);
			ub.add_param(UrlParamType.METHOD, "track.love");
			ub.add_param(UrlParamType.SESSION_KEY, this.session_key);
			ub.add_param(UrlParamType.TITLE, this.title_name);
			ub.add_param(UrlParamType.SECRET, this.secret);
			string? turl = ub.get_url(ROOT_URL, true);
			if(turl == null) {
				print("Error building trck.love url\n");
				return false;
			}
			
			int id = parent_session.web.post_data(turl);
			var rhc = new ResponseHandlerContainer(this.love_cb, id);
			parent_session.handlers.insert(id, rhc);
			return true;
		}

		private void love_cb(int id, string response) {
			//print("response:\n%s\n", response);
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root)) {
				print("Can not love a track in last.fm");
				return;
			}
		}

		public bool unlove() {
			if(!parent_session.logged_in) {
				print("not logged in!\n");
				return false;
			}
			
			var ub = new Lastfm.UrlBuilder();
			ub.add_param(UrlParamType.API_KEY, this.api_key);
			ub.add_param(UrlParamType.ARTIST, this.artist_name);
			ub.add_param(UrlParamType.METHOD, "track.unlove");
			ub.add_param(UrlParamType.SESSION_KEY, this.session_key);
			ub.add_param(UrlParamType.TITLE, this.title_name);
			ub.add_param(UrlParamType.SECRET, this.secret);
			string? turl = ub.get_url(ROOT_URL, true);
			if(turl == null) {
				print("Error building trck.love url\n");
				return false;
			}
			int id = parent_session.web.post_data(turl);
			var rhc = new ResponseHandlerContainer(this.unlove_cb, id);
			parent_session.handlers.insert(id, rhc);
			return true;
		}

		private void unlove_cb(int id, string response) {
			print("response:\n%s\n", response);
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root)) {
				print("Can not unlove a track in last.fm");
				return;
			}
		}

		public bool updateNowPlaying() {
			if(Xnoise.Params.get_int_value("lfm_use_scrobble") == 0)
				return true; //successfully doing nothing
			if(!parent_session.logged_in) {
				print("not logged in!\n");
				return false;
			}
			var ub = new Lastfm.UrlBuilder();
			ub.add_param(UrlParamType.API_KEY, this.api_key);
			ub.add_param(UrlParamType.ARTIST, this.artist_name);
			ub.add_param(UrlParamType.METHOD, "track.updatenowplaying");
			ub.add_param(UrlParamType.SESSION_KEY, this.session_key);
			ub.add_param(UrlParamType.TITLE, this.title_name);
			ub.add_param(UrlParamType.SECRET, this.secret);
			string? turl = ub.get_url(ROOT_URL, true);
			if(turl == null) {
				print("Error building updateNowPlaying url\n");
				return false;
			}
			int id = parent_session.web.post_data(turl);
			var rhc = new ResponseHandlerContainer(this.now_playing_cb, id);
			parent_session.handlers.insert(id, rhc);
			return true;
		}

		private void now_playing_cb(int id, string response) {
			//print("response:\n%s\n", response);
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root)) {
				print("Can not update now playing to last.fm");
				return;
			}
		}

		// start_time: Unix time format of track play start time
		public bool scrobble(int64 start_time) {
			if(Xnoise.Params.get_int_value("lfm_use_scrobble") == 0)
				return true; //successfully doing nothing
			//this.unlove();
			//return true;
			
			if(start_time == 0) {
				print("Missing start time in scrobble\n");
				return false;
			}
			
			if(!parent_session.logged_in) {
				print("not logged in!\n");
				return false;
			}
			
			var ub = new Lastfm.UrlBuilder();
			ub.add_param(UrlParamType.ALBUM, this.album_name);
			ub.add_param(UrlParamType.API_KEY, this.api_key);
			ub.add_param(UrlParamType.ARTIST, this.artist_name);
			//ub.add_param(UrlParamType.DURATION, length);
			ub.add_param(UrlParamType.METHOD, "track.scrobble");
			ub.add_param(UrlParamType.SESSION_KEY, this.session_key);
			ub.add_param(UrlParamType.TIMESTAMP, start_time);
			ub.add_param(UrlParamType.TITLE, this.title_name);
			//ub.add_param(UrlParamType.TRACKNUMBER, trackno);
			ub.add_param(UrlParamType.SECRET, this.secret);
			string? turl = ub.get_url(ROOT_URL, true);
			if(turl == null) {
				print("Error building scrobbble url\n");
				return false;
			}
			int id = parent_session.web.post_data(turl);
			var rhc = new ResponseHandlerContainer(this.scrobble_cb, id);
			parent_session.handlers.insert(id, rhc);
			return true;
		}
		
		private void scrobble_cb(int id, string response) {
			//print("response:\n%s\n", response);
			var mr = new Xnoise.SimpleMarkup.Reader.from_string(response);
			mr.read();
			
			if(!check_response_status_ok(ref mr.root)) {
				string ar = this.artist_name;
				string al = this.album_name;
				string ti = this.title_name;
				Idle.add( () => {
					scrobbled(ar, al, ti, false);
					return false;
				});
			}
			
			var n = mr.root.get_child_by_name("lfm").get_child_by_name("scrobbles");
			
			if(n.attributes["accepted"] == "1") {
				string ar = this.artist_name;
				string al = this.album_name;
				string ti = this.title_name;
				Idle.add( () => {
					scrobbled(ar, al, ti, true);
					return false;
				});
			}
			else {
				string ar = this.artist_name;
				string al = this.album_name;
				string ti = this.title_name;
				Idle.add( () => {
					scrobbled(ar, al, ti, false);
					return false;
				});
			}
		}
	}
}

