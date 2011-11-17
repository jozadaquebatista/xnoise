/* vlfm-web-access.vala
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
 

using Soup;

namespace Lastfm {
	public class WebAccess : GLib.Object {
		private Soup.SessionAsync soup_session;
		private int cnt = 1;
		private HashTable<int, Soup.Message> messages =
		   new HashTable<int, Soup.Message>(direct_hash, direct_equal);
	
		public signal void reply_received(int id, string data);
	
		public WebAccess() {
		}
	
		~WebAccess() {
			if(soup_session != null)
				soup_session.abort();
		}
	
		public static string escape(string uri_part) {
			return Soup.URI.encode(uri_part, "&+_");
		}
	
		public int post_data(string? url) {
			if(url == null || url.strip() == "")
				return -1;
			//print("post url: %s\n", url);
			if(soup_session == null)
				soup_session = new Soup.SessionAsync();
			var message = new Soup.Message("POST", url);
			soup_session.queue_message(message, soup_cb);
		
			messages.insert(cnt, message);
			int cnt_old = cnt;
			cnt++;
		
			return cnt_old; //return message id
		}
	
		public int request_data(string? url) {
			if(url == null || url.strip() == "")
				return -1;
			//print("url: %s\n", url);
			if(soup_session == null)
				soup_session = new Soup.SessionAsync();
			//print("\ngetting page from: %s\n\n", url);
			var message = new Soup.Message("GET", url);
			soup_session.queue_message(message, soup_cb);
		
			messages.insert(cnt, message);
			int cnt_old = cnt;
			cnt++;
		
			return cnt_old; //return message id
		}
	
		private void soup_cb(Soup.Session sender, Message message) {
			if(sender != this.soup_session)
				return;
		
			if(message == null ||
			   message.response_body == null ||
			   message.response_body.data == null)
				return;
		
			string response = (string)message.response_body.flatten().data;
			int id = 0;
		
			foreach(int i in messages.get_keys()) {
				if(messages.lookup(i) == message) {
					id = i;
					break;
				}
			}
			if(id == 0)
				return;
		
			messages.remove(id);
		
			Idle.add( () => {
				this.reply_received(id, response);
				return false;
			});
		}
	}
}

