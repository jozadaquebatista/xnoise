/* vlfm-session.vala
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
 *     Jörn Magens
 */

using Xnoise;

namespace Lastfm {

    public struct EventData {
        public string id;
        public string title;
        public string[] artists;
        public string? venue_name;
        public string? venue_city;
        public string? venue_country;
        public string? venue_url;
        public string? date;
    }
    
    public static bool check_response_status_ok(ref SimpleMarkup.Node? nd) {
        if(nd == null) {
            print("xml reading 1 with errors\n");
            return false;
        }
        var lfm = nd.get_child_by_name("lfm");
        if(lfm == null) {
            print("xml reading 2 with errors\n");
            return false;
        }
        if(lfm.attributes["status"] == null || lfm.attributes["status"] != "ok") {
            var error = lfm.get_child_by_name("error");
            print("bad status response\n");
            print("LastFm error code %s: %s\n", error.attributes["code"], error.text);
            return false;
        }
        return true;
    }
    
    public delegate void ResponseHandler(int id, string response);
    
    public class ResponseHandlerContainer : GLib.Object {
        public ResponseHandlerContainer(ResponseHandler? _func = null, int _id  = -1) {
            this.func = _func;
            this.id = _id;
        }
        public unowned ResponseHandler? func;
        public int id;
    }

    private static const string ROOT_URL = "http://ws.audioscrobbler.com/2.0/";

    public class Session : GLib.Object {
        
        public enum AuthenticationType {
            MOBILE,
            DESKTOP
        }
        
        private string auth_token;
        private string api_key;
        private string secret;
        private string session_key;
        //private bool _logged_in = false;
        private AuthenticationType _auth_type;
        private WebAccess _web;
        private string? _username = null;
        private string? lang = null;
        
        public bool logged_in                  { get; set; }
        public AuthenticationType auth_type    { get { return _auth_type; } }
        public WebAccess web                   { get { return _web; } }
        public string? username                { get { return _username; } }
        
        public HashTable<int, ResponseHandlerContainer> handlers = 
           new HashTable<int, ResponseHandlerContainer>(direct_hash, direct_equal);
        
        public signal void login_successful(string user);
        
        public Session(AuthenticationType auth_type = AuthenticationType.MOBILE, string api_key, string secret, string? lang = null) {
            this._auth_type = auth_type;
            this.api_key = api_key;
            this.secret = secret;
            this.lang = lang;
            _web = new WebAccess();
            a = _web.reply_received.connect(this.web_reply_received);
        }
        
        private ulong a =0;
        
        public void abort() {
            handlers.remove_all();
        }
        
        public void login(string user, string pass) {
            if(GlobalAccess.main_cancellable.is_cancelled())
                return;
            this.logged_in = false;
            string pass_hash = Checksum.compute_for_string(ChecksumType.MD5, pass);
            string buffer    = "%s%s".printf(user, pass_hash);
            this.auth_token  = Checksum.compute_for_string(ChecksumType.MD5, buffer);
            if(auth_type == AuthenticationType.MOBILE) {
                //Build an api_sig
                buffer = "api_key%sauthToken%smethod%susername%s%s".printf(
                   this.api_key,
                   this.auth_token,
                   "auth.getmobilesession",
                   user,
                   this.secret
                );
                string api_sig = Checksum.compute_for_string(ChecksumType.MD5, buffer);
                
                //Build the login url
                buffer = "%s?method=%s&username=%s&authToken=%s&api_key=%s&api_sig=%s".printf(
                   ROOT_URL,
                   "auth.getmobilesession",
                   user,
                   this.auth_token,
                   this.api_key,
                   api_sig
                );
                
                int id = web.request_data(buffer);
                var rhc = new ResponseHandlerContainer(this.login_cb, id);
                handlers.insert(id, rhc);
            }
            else if(auth_type == AuthenticationType.DESKTOP) {
                print("not fully implemented. User acknowledgment step in browser is missing\n");
                return;
            }
        }
        
        private void login_token_cb(int id, string response) {
            //print("finish login response a: \n%s\n", response);
            if(GlobalAccess.main_cancellable.is_cancelled())
                return;
            var r = new SimpleMarkup.Reader.from_string(response);
            r.read();
            
            if(!check_response_status_ok(ref r.root)) {
                this._username = null;
                logged_in = false;
                return;
            }
            var lfm = r.root.get_child_by_name("lfm");
            if(lfm == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            var token = lfm.get_child_by_name("token");
            if(token == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            string token_text = token.text;
            //user authentication
            string buffer = "%s?api_key=%s&token=%s".printf(
               "http://www.last.fm/api/auth/",
               this.api_key,
               token_text
            );
            //This uri has to be called in a browser and the user has to verify access
            //before the authorization process can be finished
            print("user authentication: %s\n", buffer);
            
            //Build an api_sig
            buffer = "api_key%smethod%stoken%s%s".printf(
               this.api_key,
               "auth.getSession",
               token_text,
               this.secret
            );
            string api_sig = Checksum.compute_for_string(ChecksumType.MD5, buffer);
            
            //Build the login url
            buffer = "%s?method=%s&api_key=%s&token=%s&api_sig=%s".printf(
               ROOT_URL,
               "auth.getSession",
               this.api_key,
               token_text,
               api_sig
            );
            int idx = web.request_data(buffer);
            var rhc = new ResponseHandlerContainer(this.login_cb, idx);
            handlers.insert(idx, rhc);
        }
        
        private void login_cb(int id, string response) {
            if(GlobalAccess.main_cancellable.is_cancelled())
                return;
            //print("finish login response b: \n%s\n", response);
            var r = new SimpleMarkup.Reader.from_string(response);
            r.read();
            
            if(!check_response_status_ok(ref r.root)) {
                this._username = null;
                logged_in = false;
                return;
            }
            
            var lfm = r.root.get_child_by_name("lfm");
            if(lfm == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            var sess = lfm.get_child_by_name("session");
            if(sess == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            var key = sess.get_child_by_name("key");
            if(key == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            this.session_key = key.text;
            var u = sess.get_child_by_name("name");
            if(u == null) {
                this._username = null;
                logged_in = false;
                return;
            }
            this._username = u.text;
            logged_in = true;
            
            Idle.add( () => {
                logged_in = true;
                this.login_successful(this._username);
                return false;
            });
            
        }

        private void web_reply_received(WebAccess sender, int id, string? response) {
            if(id < 0)
                return;
            ResponseHandlerContainer rhc = handlers.lookup(id);
            if(rhc != null && rhc.func != null && rhc.id > -1 && rhc.id == id) {
                if(response != null)
                    rhc.func(id, response);
            }
            handlers.remove(id);
        }
        
        public Artist factory_make_artist(string artist_name) {
            return new Lastfm.Artist(this, artist_name, api_key, _username, session_key, lang);
        }
        
        public Album factory_make_album(string artist_name, string album_name) {
            return new Lastfm.Album(this, artist_name, album_name, api_key, _username, session_key, lang);
        }
        
        public Track factory_make_track(string artist_name, string? album_name = null, string track_name) {
            return new Lastfm.Track(this, artist_name, album_name, track_name, api_key, _username, this.session_key, lang, secret);
        }
    }
}

